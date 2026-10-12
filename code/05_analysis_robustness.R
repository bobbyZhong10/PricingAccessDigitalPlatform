# 05_analysis_robustness.R: robustness of the effect on log hourly txs.
#  A  window (12-72 h) x mean difference vs side trends x donut (0/1/3 h), each with its own RI
#  B-E  weekly differencing; market controls (Ethereum L1, Bitcoin); Base vs not-yet-treated Arbitrum; Base net of campaign wallets; NW(24) and day-clustered SEs
#  F  placebo at the Ethereum L1 fork hour, outcomes differenced against the previous day or week
source(here::here("code", "00_setup.R"))
new_log("05 robustness")
load_panel(c("l2_hourly", "control_hourly", "base_hourly_campaign"))

H0 <- l2_hourly[, .(n = sum(n), n_ok = sum(n[failed == 0]), fee = sum(fee), senders = sum(n_senders)), by = .(hr, chain)]
D <- merge(H0, control_hourly[, .(hr, n_eth, n_btc)], by = "hr", all.x = TRUE)
D <- merge(D, base_hourly_campaign[, .(hr, n_camp = n_campaign, chain = "base")], by = c("hr", "chain"), all.x = TRUE)[is.na(n_camp), n_camp := 0]
D <- D[hr >= as.POSIXct("2024-02-22", tz = "UTC") & hr < as.POSIXct("2024-04-15", tz = "UTC")][order(chain, hr)]
D[, `:=`(y = log(n), lfpt = log(fee / n), y_net = log(pmax(n_ok - n_camp, 1)), y_eth = log(n_eth), y_btc = log(n_btc), hod = hour(hr))]
D[, y_wk := y - shift(y, 168), by = chain]; check_unique(D, c("chain", "hr"), "robustness panel")
say(sprintf("Panel %s..%s UTC; campaign share of Base successful txs 03-14..21: %.3f", min(D$hr), max(D$hr),
            D[chain == "base" & hr >= as.POSIXct("2024-03-14", tz = "UTC") & hr < as.POSIXct("2024-03-22", tz = "UTC"), sum(n_camp) / sum(n_ok)]))

est <- function(ch, t0, yv, W, trend = TRUE, donut = 1, vc = "nw6", ctrl = NULL, covs = NULL) {
  d <- D[chain == ch & hr >= t0 - W * 3600 & hr < t0 + W * 3600 & !(hr >= t0 - donut * 3600 & hr < t0 + max(donut - 1, 0) * 3600 + (donut > 0) * 3600)]
  if (nrow(d) < 12) return(c(NA, NA)); d[, `:=`(post = as.integer(hr >= t0), tt = as.numeric(hr - t0, units = "days"))]
  d[, yy := if (is.null(ctrl)) get(yv) else get(yv) - get(ctrl)]; d <- d[is.finite(yy)]; if (d[, uniqueN(post)] < 2) return(c(NA, NA))
  rhs <- paste(c(if (trend) "post + tt + tt:post" else "post", covs), collapse = " + ")
  fml <- as.formula(paste("yy ~", rhs, if (W > 12) "| hod"))   # short windows cannot carry hour-of-day FE
  V <- switch(vc, nw6 = NW(6) ~ hr, nw24 = NW(24) ~ hr, day = ~ as.IDate(hr, tz = "UTC"))
  f <- tryCatch(feols(fml, data = d, vcov = V), error = function(e) NULL); if (is.null(f)) c(NA, NA) else c(coef(f)[["post"]], se(f)[["post"]]) }
ri <- function(ch, yv, W, trend, donut, e, t0, ctrl = NULL, covs = NULL) { cd <- t0 + seq(-90, 90) * 12 * 3600   # fake events at the same clock hour (and +12 h)
  cd <- cd[cd >= as.POSIXct("2024-02-26", tz = "UTC") & cd <= as.POSIXct("2024-04-12", tz = "UTC") & sapply(cd, function(t) all(abs(as.numeric(t - EVENTS$t0, units = "hours")) > W + 24))]
  fk <- sapply(cd, function(t) est(ch, t, yv, W, trend, donut, ctrl = ctrl, covs = covs)[1]); c(p = mean(abs(fk) >= abs(e), na.rm = TRUE), n = sum(!is.na(fk))) }

# ---- A. specification grid ----
G <- CJ(i = 1:3, W = c(12, 24, 36, 72), trend = c(FALSE, TRUE), donut = c(0, 1, 3), y = c("y", "lfpt"))
G <- G[!(W == 12 & donut == 3) & !(W == 24 & trend)]   # W = 24 with trends and hour-of-day FE is not identified
G[, c("est", "se", "ri_p", "n_fake") := { r <- lapply(seq_len(.N), function(j) { e <- est(EVENTS$chain[i[j]], EVENTS$t0[i[j]], y[j], W[j], trend[j], donut[j])
    rr <- if (y[j] == "y") ri(EVENTS$chain[i[j]], y[j], W[j], trend[j], donut[j], e[1], EVENTS$t0[i[j]]) else c(NA, NA); c(e, rr) }); lapply(1:4, function(k) sapply(r, `[`, k)) }]
G[, `:=`(event = factor(EVENTS$event[i], EVENTS$event), outcome = fifelse(y == "y", "log txs", "log fee per tx"), spec = paste0("W", W, ifelse(trend, " trend", " mean"), " donut", donut))]
say("## A. Log txs: estimate [RI p]"); logp(dcast(G[y == "y", .(event, spec, v = sprintf("%.2f [%.2f]", est, ri_p))], spec ~ event, value.var = "v"))
say("## A. First stage (log fee per tx)"); logp(dcast(G[y == "lfpt", .(event, spec, v = sprintf("%.2f", est))], spec ~ event, value.var = "v"))
say("Share of specifications with estimate > 0 and RI p <= 0.10: ", paste(sprintf("%s %.2f", EVENTS$event, sapply(1:3, function(k) G[y == "y" & i == k, mean(est > 0 & ri_p <= 0.10, na.rm = TRUE)])), collapse = "; "))

# ---- B-E. other checks ----
row <- function(lab, f) rbindlist(lapply(1:3, function(i) { r <- f(i); data.table(check = lab, event = EVENTS$event[i], est = r[1], se = r[2], ri_p = r[3]) }))
chk <- rbind(
  row("B. weekly-differenced log txs (mean diff, 36 h)", function(i) { e <- est(EVENTS$chain[i], EVENTS$t0[i], "y_wk", 36, FALSE, 1); c(e, ri(EVENTS$chain[i], "y_wk", 36, FALSE, 1, e[1], EVENTS$t0[i])[1]) }),
  row("C1. market controls: log L1 and Bitcoin txs as covariates (trend, 36 h)", function(i) { e <- est(EVENTS$chain[i], EVENTS$t0[i], "y", 36, TRUE, 1, covs = c("y_eth", "y_btc"))
    c(e, ri(EVENTS$chain[i], "y", 36, TRUE, 1, e[1], EVENTS$t0[i], covs = c("y_eth", "y_btc"))[1]) }),
  row("C2. market controls, mean difference within 72 h", function(i) { e <- est(EVENTS$chain[i], EVENTS$t0[i], "y", 72, FALSE, 1, covs = c("y_eth", "y_btc"))
    c(e, ri(EVENTS$chain[i], "y", 72, FALSE, 1, e[1], EVENTS$t0[i], covs = c("y_eth", "y_btc"))[1]) }),
  row("E1. main spec, NW(24) SE", function(i) c(est(EVENTS$chain[i], EVENTS$t0[i], "y", 36, TRUE, 1, "nw24"), NA)),
  row("E2. main spec, SE clustered by day", function(i) c(est(EVENTS$chain[i], EVENTS$t0[i], "y", 36, TRUE, 1, "day"), NA)))
tb <- EVENTS$t0[1]; BA <- merge(D[chain == "base", .(hr, yb = y)], D[chain == "arbitrum", .(hr, ya = y)], by = "hr")[, `:=`(d = yb - ya, hod = hour(hr))]
fb <- feols(d ~ post | hod, data = BA[hr >= tb - 36 * 3600 & hr < EVENTS$t0[2] & hr != tb - 3600][, post := as.integer(hr >= tb)], vcov = NW(6) ~ hr)
chk <- rbind(chk, data.table(check = "C3. Base minus Arbitrum, before Arbitrum's drop (36 h pre, 15 h post)", event = EVENTS$event[1], est = coef(fb)[[1]], se = se(fb)[[1]], ri_p = NA))
for (s in list(list(W = 36, trend = TRUE, lab = "trend, 36 h"), list(W = 72, trend = FALSE, lab = "mean diff, 72 h"))) { e <- est("base", tb, "y_net", s$W, s$trend, 1)
  chk <- rbind(chk, data.table(check = sprintf("D. Base successful txs net of campaign wallets and collectors (%s)", s$lab), event = EVENTS$event[1], est = e[1], se = e[2], ri_p = ri("base", "y_net", s$W, s$trend, 1, e[1], tb)[1])) }
say("## B-E. Other checks"); logp(rnd(chk))
fwrite(G[, .(event, outcome, spec, window_h = W, trend, donut_h = donut, est, se, ri_p, n_fake)], res("tables", "robust_grid.csv")); fwrite(chk, res("tables", "robust_checks.csv"))

# ---- F. placebo at the L1 fork hour (neither L2 had changed pricing) ----
P <- H0[order(chain, hr)][, `:=`(y = log(n), f = log(fee / n))]
P[, `:=`(y_d = y - shift(y, 24), f_d = f - shift(f, 24), y_w = y - shift(y, 168), f_w = f - shift(f, 168)), by = chain]
stat <- function(ch, t0, v, W = 10, drop = NULL) { d <- P[chain == ch & hr >= t0 - W * 3600 & hr < t0 + W * 3600 & !(hr %in% drop)]; d[hr >= t0, mean(get(v), na.rm = TRUE)] - d[hr < t0, mean(get(v), na.rm = TRUE)] }
burst <- as.POSIXct(c("2024-03-13 19:00:00", "2024-03-13 20:00:00"), tz = "UTC")   # one-off Base burst in the placebo window
fakes <- L1_FORK + 86400 * c(-12:-2, 8:20)
touch <- function(t, lag) any(sapply(EVENTS$t0, function(e) abs(as.numeric(e - t, units = "hours")) <= 11 || abs(as.numeric(e - (t - lag * 3600), units = "hours")) <= 11))
fakes_d <- fakes[!sapply(fakes, touch, lag = 24)]; fakes_w <- fakes[!sapply(fakes, touch, lag = 168)]
PL <- rbindlist(lapply(CHAINS, function(ch) rbindlist(lapply(c("y_d", "f_d", "y_w", "f_w"), function(v) rbindlist(lapply(list(NULL, burst), function(dr) {
  e <- stat(ch, L1_FORK, v, drop = dr); fk <- sapply(if (grepl("_w$", v)) fakes_w else fakes_d, function(t) stat(ch, t, v))
  data.table(chain = ch, outcome = v, burst_dropped = !is.null(dr), est = e, ri_p = mean(abs(fk) >= abs(e), na.rm = TRUE), fake_sd = sd(fk, na.rm = TRUE)) }))))))
PL[, outcome := c(y_d = "log txs, minus same hour previous day", f_d = "log fee per tx, minus same hour previous day", y_w = "log txs, minus same hour previous week", f_w = "log fee per tx, minus same hour previous week")[outcome]]
say(sprintf("## F. Placebo at the L1 fork hour (+-10 h); RI over the same clock hour on %d / %d other days (daily / weekly differenced)", length(fakes_d), length(fakes_w))); logp(rnd(PL))
fwrite(PL, res("tables", "placebo_l1_fork.csv"))
save_log("05_analysis_robustness")
