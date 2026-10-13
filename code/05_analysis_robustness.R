# 05_analysis_robustness.R: robustness of the effect on log hourly txs.
#  A  window (12-72 h) x mean difference vs side trends x donut (0/1/3 h), each with its own RI
#  B-E  weekly differencing; market controls (Ethereum L1, Bitcoin); Base vs not-yet-treated Arbitrum; Base net of campaign wallets; NW(24) and day-clustered SEs
#  F  placebo at the Ethereum L1 fork hour, outcomes differenced against the previous day or week
source(here::here("code", "00_setup.R"))
sink(file.path(DIR_LOG, "05_analysis_robustness.md"), split = TRUE)
cat("# 05 robustness\nRun ", format(Sys.time(), usetz = TRUE), "\n", sep = "")
ct <- yaml::read_yaml(CONTRACT_FILE)   # panel.rds must have passed 03_validate_panels.R and be unchanged since
stopifnot(isTRUE(ct$all_valid), unname(tools::md5sum(PANEL_FILE)) == ct$md5)
PNL <- readRDS(PANEL_FILE)
l2_hourly <- PNL$l2_hourly; control_hourly <- PNL$control_hourly; base_hourly_campaign <- PNL$base_hourly_campaign

H0 <- l2_hourly[, .(n = sum(n), n_ok = sum(n[failed == 0]), fee = sum(fee), senders = sum(n_senders)), by = .(hr, chain)]
D <- merge(H0, control_hourly[, .(hr, n_eth, n_btc)], by = "hr", all.x = TRUE)
D <- merge(D, base_hourly_campaign[, .(hr, n_camp = n_campaign, chain = "base")], by = c("hr", "chain"), all.x = TRUE)[is.na(n_camp), n_camp := 0]
D <- D[hr >= as.POSIXct("2024-02-22", tz = "UTC") & hr < as.POSIXct("2024-04-15", tz = "UTC")][order(chain, hr)]
D[, `:=`(y = log(n), lfpt = log(fee / n), y_net = log(pmax(n_ok - n_camp, 1)), y_eth = log(n_eth), y_btc = log(n_btc), hod = hour(hr))]
D[, y_wk := y - shift(y, 168), by = chain]; stopifnot(!anyDuplicated(D, by = c("chain", "hr")))
cat(sprintf("Panel %s..%s UTC; campaign share of Base successful txs 03-14..21: %.3f\n", min(D$hr), max(D$hr),
            D[chain == "base" & hr >= as.POSIXct("2024-03-14", tz = "UTC") & hr < as.POSIXct("2024-03-22", tz = "UTC"), sum(n_camp) / sum(n_ok)]))

# ---- specifications for A-E (one row each) ----
# A: specification grid. W = 24 with trends and hour-of-day FE is not identified; W = 12 has no room for a 3-hour donut.
G <- CJ(i = 1:3, W = c(12, 24, 36, 72), trend = c(FALSE, TRUE), donut = c(0, 1, 3), y = c("y", "lfpt"))
G <- G[!(W == 12 & donut == 3) & !(W == 24 & trend)]
G[, `:=`(check = "grid", vc = "nw6", covs = "", ri = y == "y")]
mk <- "+ y_eth + y_btc"
CHK <- rbind(
  data.table(check = "B. weekly-differenced log txs (mean diff, 36 h)", i = 1:3, W = 36, trend = FALSE, donut = 1, y = "y_wk", vc = "nw6", covs = "", ri = TRUE),
  data.table(check = "C1. market controls: log L1 and Bitcoin txs as covariates (trend, 36 h)", i = 1:3, W = 36, trend = TRUE, donut = 1, y = "y", vc = "nw6", covs = mk, ri = TRUE),
  data.table(check = "C2. market controls, mean difference within 72 h", i = 1:3, W = 72, trend = FALSE, donut = 1, y = "y", vc = "nw6", covs = mk, ri = TRUE),
  data.table(check = "E1. main spec, NW(24) SE", i = 1:3, W = 36, trend = TRUE, donut = 1, y = "y", vc = "nw24", covs = "", ri = FALSE),
  data.table(check = "E2. main spec, SE clustered by day", i = 1:3, W = 36, trend = TRUE, donut = 1, y = "y", vc = "day", covs = "", ri = FALSE),
  data.table(check = c("D. Base successful txs net of campaign wallets and collectors (trend, 36 h)", "D. Base successful txs net of campaign wallets and collectors (mean diff, 72 h)"),
             i = 1, W = c(36, 72), trend = c(TRUE, FALSE), donut = 1, y = "y_net", vc = "nw6", covs = "", ri = TRUE))
SPEC <- rbind(G, CHK, use.names = TRUE)

# Local RD in time at event hour t0, hours t within W hours of t0, excluding a donut of d hours on each side (t0 - d .. t0 + d - 1):
#   trend:     y_t = a + b * Post_t + c1 * (t - t0) + c2 * (t - t0) * Post_t [+ g' X_t] [+ hour-of-day FE] + e_t,   Post_t = 1[t >= t0]
#   mean diff: y_t = a + b * Post_t [+ g' X_t] [+ hour-of-day FE] + e_t
# Hour-of-day FE only when W > 12 h (shorter windows cannot carry them); X_t = (log L1 txs, log Bitcoin txs) in C1/C2.
# SEs: Newey-West with 6 or 24 lags, or clustered by day. RI: the same regression at fake event hours t0 + 12 h * k in 02-26..04-12 that are
# more than W + 24 h from any event; p = share of fake |b| >= |b|. Element 1 of b and s is the actual event, the rest are the fakes.
RES <- list()
for (r in seq_len(nrow(SPEC))) {
  sp <- SPEC[r]; ch <- EVENTS$chain[sp$i]; t0 <- EVENTS$t0[sp$i]; times <- t0
  if (sp$ri) {
    cd <- t0 + seq(-90, 90) * 12 * 3600; far <- rep(TRUE, length(cd))
    for (j in seq_len(nrow(EVENTS))) far <- far & abs(as.numeric(cd - EVENTS$t0[j], units = "hours")) > sp$W + 24
    times <- c(t0, cd[cd >= as.POSIXct("2024-02-26", tz = "UTC") & cd <= as.POSIXct("2024-04-12", tz = "UTC") & far])
  }
  b <- s <- rep(NA_real_, length(times))
  for (k in seq_along(times)) {
    d <- D[chain == ch & hr >= times[k] - sp$W * 3600 & hr < times[k] + sp$W * 3600 & !(hr >= times[k] - sp$donut * 3600 & hr < times[k] + sp$donut * 3600)]
    if (nrow(d) < 12) next
    d[, `:=`(post = as.integer(hr >= times[k]), tt = as.numeric(hr - times[k], units = "days"), yy = get(sp$y))]
    d <- d[is.finite(yy)]; if (d[, uniqueN(post)] < 2) next
    fml <- as.formula(paste("yy ~", if (sp$trend) "post + tt + tt:post" else "post", sp$covs, if (sp$W > 12) "| hod"))
    f <- try(feols(fml, data = d, vcov = switch(sp$vc, nw6 = NW(6) ~ hr, nw24 = NW(24) ~ hr, day = ~ as.IDate(hr, tz = "UTC"))), silent = TRUE)
    if (inherits(f, "try-error")) next
    b[k] <- coef(f)[["post"]]; s[k] <- se(f)[["post"]]
  }
  RES[[r]] <- data.table(est = b[1], se = s[1], ri_p = if (sp$ri) mean(abs(b[-1]) >= abs(b[1]), na.rm = TRUE) else NA_real_, n_fake = if (sp$ri) sum(!is.na(b[-1])) else NA_integer_)
}
SPEC <- cbind(SPEC, rbindlist(RES))
SPEC[, event := factor(EVENTS$event[i], EVENTS$event)]

# ---- A. specification grid ----
G <- SPEC[check == "grid"][, `:=`(outcome = fifelse(y == "y", "log txs", "log fee per tx"), spec = paste0("W", W, ifelse(trend, " trend", " mean"), " donut", donut))]
cat("## A. Log txs: estimate [RI p]\n"); print(dcast(G[y == "y", .(event, spec, v = sprintf("%.2f [%.2f]", est, ri_p))], spec ~ event, value.var = "v"))
cat("## A. First stage (log fee per tx)\n"); print(dcast(G[y == "lfpt", .(event, spec, v = sprintf("%.2f", est))], spec ~ event, value.var = "v"))
cat("Share of specifications with estimate > 0 and RI p <= 0.10:", G[y == "y", .(share = mean(est > 0 & ri_p <= 0.10, na.rm = TRUE)), by = event][, paste(sprintf("%s %.2f", event, share), collapse = "; ")], "\n")

# ---- B-E. other checks ----
# C3. Base minus Arbitrum at Base's drop, before Arbitrum's drop (36 h before, 15 h after; t_B - 1 dropped); NW(6) SEs:
#   y_Base,t - y_Arb,t = a + b * Post_t + hour-of-day FE + e_t
tb <- EVENTS$t0[1]; BA <- merge(D[chain == "base", .(hr, yb = y)], D[chain == "arbitrum", .(hr, ya = y)], by = "hr")[, `:=`(d = yb - ya, hod = hour(hr))]
fb <- feols(d ~ post | hod, data = BA[hr >= tb - 36 * 3600 & hr < EVENTS$t0[2] & hr != tb - 3600][, post := as.integer(hr >= tb)], vcov = NW(6) ~ hr)
chk <- rbind(SPEC[check != "grid" & !grepl("^D", check), .(check, event = as.character(event), est, se, ri_p)],
             data.table(check = "C3. Base minus Arbitrum, before Arbitrum's drop (36 h pre, 15 h post)", event = EVENTS$event[1], est = coef(fb)[[1]], se = se(fb)[[1]], ri_p = NA),
             SPEC[grepl("^D", check), .(check, event = as.character(event), est, se, ri_p)])
cat("## B-E. Other checks\n"); print(chk)
fwrite(G[, .(event, outcome, spec, window_h = W, trend, donut_h = donut, est, se, ri_p, n_fake)], file.path(DIR_TAB, "robust_grid.csv")); fwrite(chk, file.path(DIR_TAB, "robust_checks.csv"))

# ---- F. placebo at the L1 fork hour (neither L2 had changed pricing) ----
# Statistic at hour t: mean of the differenced outcome over [t, t + 10 h) minus its mean over [t - 10 h, t); outcomes differenced against the same hour
# of the previous day or week. RI over the same clock hour on other days whose window and comparison hours are more than 11 h from any L2 event.
P <- H0[order(chain, hr)][, `:=`(y = log(n), f = log(fee / n))]
P[, `:=`(y_d = y - shift(y, 24), f_d = f - shift(f, 24), y_w = y - shift(y, 168), f_w = f - shift(f, 168)), by = chain]
burst <- as.POSIXct(c("2024-03-13 19:00:00", "2024-03-13 20:00:00"), tz = "UTC")   # one-off Base burst in the placebo window
fakes <- L1_FORK + 86400 * c(-12:-2, 8:20); near_d <- near_w <- rep(FALSE, length(fakes))
for (j in seq_len(nrow(EVENTS))) {
  near_d <- near_d | abs(as.numeric(EVENTS$t0[j] - fakes, units = "hours")) <= 11 | abs(as.numeric(EVENTS$t0[j] - (fakes - 24 * 3600), units = "hours")) <= 11
  near_w <- near_w | abs(as.numeric(EVENTS$t0[j] - fakes, units = "hours")) <= 11 | abs(as.numeric(EVENTS$t0[j] - (fakes - 168 * 3600), units = "hours")) <= 11
}
fakes_d <- fakes[!near_d]; fakes_w <- fakes[!near_w]
PL <- list()
for (ch in CHAINS) for (v in c("y_d", "f_d", "y_w", "f_w")) for (drop_burst in c(FALSE, TRUE)) {
  times <- c(L1_FORK, if (grepl("_w$", v)) fakes_w else fakes_d); m <- rep(NA_real_, length(times))   # element 1 = L1 fork hour
  for (k in seq_along(times)) {
    d <- P[chain == ch & hr >= times[k] - 10 * 3600 & hr < times[k] + 10 * 3600 & !(k == 1 & drop_burst & hr %in% burst)]
    m[k] <- d[hr >= times[k], mean(get(v), na.rm = TRUE)] - d[hr < times[k], mean(get(v), na.rm = TRUE)]
  }
  PL[[length(PL) + 1]] <- data.table(chain = ch, outcome = v, burst_dropped = drop_burst, est = m[1], ri_p = mean(abs(m[-1]) >= abs(m[1]), na.rm = TRUE), fake_sd = sd(m[-1], na.rm = TRUE))
}
PL <- rbindlist(PL)
PL[, outcome := c(y_d = "log txs, minus same hour previous day", f_d = "log fee per tx, minus same hour previous day", y_w = "log txs, minus same hour previous week", f_w = "log fee per tx, minus same hour previous week")[outcome]]
cat(sprintf("## F. Placebo at the L1 fork hour (+-10 h); RI over the same clock hour on %d / %d other days (daily / weekly differenced)\n", length(fakes_d), length(fakes_w))); print(PL)
fwrite(PL, file.path(DIR_TAB, "placebo_l1_fork.csv"))
cat("\n## sessionInfo\n```\n"); print(sessionInfo()); cat("```\n"); sink()
