# 04_analysis_main.R: main estimates at the three fee drops (event hours in 00_setup.R).
#  Summary table: hourly activity before and after each drop (mean and SD across hours)
#  A  RD in time (+-36 h, hour-of-day FE, side-specific trends, 1-hour donut, Newey-West SEs), also with market controls (log Ethereum L1 and Bitcoin txs);
#     placebo RDs on L1 and Bitcoin; randomization inference; elasticities
#  B  Base vs Arbitrum before Arbitrum's own drop: DiD, staggered TWFE, daily event study
#  C  RD by transaction type
source(here::here("code", "00_setup.R"))
sink(file.path(DIR_LOG, "04_analysis_main.md"), split = TRUE)
cat("# 04 main analysis\nRun ", format(Sys.time(), usetz = TRUE), "\n", sep = "")
ct <- yaml::read_yaml(CONTRACT_FILE)   # panel.rds must have passed 03_validate_panels.R and be unchanged since
stopifnot(isTRUE(ct$all_valid), unname(tools::md5sum(PANEL_FILE)) == ct$md5)
PNL <- readRDS(PANEL_FILE)
l2_hourly <- PNL$l2_hourly; l2_hourly_type <- PNL$l2_hourly_type; l2_newsenders <- PNL$l2_newsenders; control_hourly <- PNL$control_hourly; eth_usd_daily <- PNL$eth_usd_daily

# ---- hourly panel: one row per chain and UTC hour ----
D <- list()
for (ch in CHAINS) {
  W <- l2_hourly[chain == ch, .(n = sum(n), n_fail = sum(n[failed == 1]), n_hf = sum(n[hf == 1]), n_ot = sum(n[hf == 0]), fee = sum(fee), senders = sum(n_senders)), by = hr]
  W <- merge(W, l2_newsenders[chain == ch, .(hr, new_senders)], by = "hr", all.x = TRUE)[is.na(new_senders), new_senders := 0]
  D[[ch]] <- W[, `:=`(chain = ch, fpt = fee / n, lfpt = log(fee / n), y_all = log(n), y_snd = log(senders), y_fail = log1p(n_fail), y_new = log1p(new_senders), y_hf = log1p(n_hf), y_ot = log(n_ot),
                      fail_sh = n_fail / n)][order(hr)]
}
D <- rbindlist(D)[hr >= as.POSIXct("2024-03-01", tz = "UTC") & hr < as.POSIXct("2024-04-15", tz = "UTC")]   # new senders need a burn-in from Feb 15
D <- merge(D, control_hourly[, .(hr, n_eth, y_l1 = log(n_eth), y_btc = log(n_btc))], by = "hr", all.x = TRUE)
D[, `:=`(hod = hour(hr), day = as.IDate(hr, tz = "UTC"))]; stopifnot(!anyDuplicated(D, by = c("chain", "hr")))
cat(sprintf("Hourly panel: %d chain-hours, %s..%s UTC\n", nrow(D), min(D$hr), max(D$hr)))

# ---- summary statistics: 7 days before / after each chain's drops (Arbitrum also between its two steps) ----
# Senders are counted separately for successful and failed txs, so a sender with both in the same hour counts twice.
d7 <- 7 * 86400; t_b <- EVENTS$t0[1]; t_a1 <- EVENTS$t0[2]; t_a2 <- EVENTS$t0[3]
SP <- data.table(chain = c("base", "base", "arbitrum", "arbitrum", "arbitrum"), period = c("7 days before", "7 days after", "7 days before step 1", "between steps 1 and 2", "7 days after step 2"),
                 from = c(t_b - d7, t_b, t_a1 - d7, t_a1, t_a2), to = c(t_b, t_b + d7, t_a1, t_a2, t_a2 + d7))
SUM <- list()
for (i in seq_len(nrow(SP))) {
  s <- SP[i]
  SUM[[i]] <- merge(D[chain == s$chain & hr >= s$from & hr < s$to], eth_usd_daily[, .(day, usd = close)], by = "day")[, .(chain = s$chain, period = s$period, hours = .N,
    txs_mean = mean(n), txs_sd = sd(n), fee_usd_mean = mean(fpt * usd), fee_usd_sd = sd(fpt * usd), senders_mean = mean(senders), senders_sd = sd(senders))]
}
SUM <- rbindlist(SUM)
cat("## Summary: hourly transactions, fee per transaction (US$) and active senders, mean and SD across hours\n"); print(SUM)
fwrite(SUM, file.path(DIR_TAB, "summary_hourly.csv"))

# ---- A. RD in time, market controls, RI ----
# RD in time at event hour t0 of chain c, hours t within 36 h of t0, excluding t0 - 1 and t0 (1-hour donut):
#   y_t = a + b * Post_t + c1 * (t - t0) + c2 * (t - t0) * Post_t [+ g' X_t] + hour-of-day FE + e_t,   Post_t = 1[t >= t0], t - t0 in days
# b is the jump at t0; Newey-West SEs with 6 lags. X_t = (log Ethereum L1 txs, log Bitcoin txs) in the market-control version.
# Randomization inference (RI): the same regression at fake event hours t0 + 12 h * k (same clock hour or +12 h, 03-03..04-12, > 3 days from any event);
# p = share of fake |b| >= |b|. Element 1 of each estimate vector below is the actual event, the rest are the fakes.
CAND <- list()
for (i in seq_len(nrow(EVENTS))) {
  cd <- EVENTS$t0[i] + seq(-80, 80) * 12 * 3600; far <- rep(TRUE, length(cd))
  for (j in seq_len(nrow(EVENTS))) far <- far & abs(as.numeric(cd - EVENTS$t0[j], units = "days")) > 3
  CAND[[i]] <- cd[cd >= as.POSIXct("2024-03-03", tz = "UTC") & cd <= as.POSIXct("2024-04-12 12:00", tz = "UTC") & far]
}
cat(sprintf("RI: %s fake event hours per event\n", paste(lengths(CAND), collapse = "/")))
ys <- c(lfpt = "log fee per tx (first stage)", y_all = "log txs", y_snd = "log distinct senders", y_new = "log new senders", y_fail = "log failed txs",
        fail_sh = "failed share", y_hf = "log txs, HF senders", y_ot = "log txs, other senders", y_l1 = "placebo: log Ethereum L1 txs", y_btc = "placebo: log Bitcoin txs")
RS <- data.table(y = c(names(ys), "y_all"), covs = c(rep("", length(ys)), "+ y_l1 + y_btc"), label = c(ys, "log txs, RD with market controls (L1, Bitcoin)"))
R <- list()
for (i in seq_len(nrow(EVENTS))) for (j in seq_len(nrow(RS))) {
  ch <- EVENTS$chain[i]; times <- c(EVENTS$t0[i], CAND[[i]]); b <- s <- rep(NA_real_, length(times))
  for (k in seq_along(times)) {
    d <- D[chain == ch & hr >= times[k] - 36 * 3600 & hr < times[k] + 36 * 3600 & !(hr %in% c(times[k] - 3600, times[k]))][, `:=`(post = as.integer(hr >= times[k]), tt = as.numeric(hr - times[k], units = "days"))]
    if (nrow(d) < 36 || d[, uniqueN(post)] < 2) next
    f <- feols(as.formula(paste(RS$y[j], "~ post + tt + tt:post", RS$covs[j], "| hod")), data = d, vcov = NW(6) ~ hr)
    b[k] <- coef(f)[["post"]]; s[k] <- se(f)[["post"]]
  }
  R[[length(R) + 1]] <- data.table(event = EVENTS$event[i], y = RS$label[j], est = b[1], se = s[1], ri_p = mean(abs(b[-1]) >= abs(b[1]), na.rm = TRUE), fake_sd = sd(b[-1], na.rm = TRUE))
}
R <- rbindlist(R)
cat("## A. RD in time (+-36 h), with market controls, and placebo RDs on L1 and Bitcoin: estimate (NW SE) [RI p]\n")
print(dcast(R[, .(y = factor(y, unique(y)), event = factor(event, EVENTS$event), v = sprintf("%.3f (%.3f) [RI %.2f]", est, se, ri_p))], y ~ event, value.var = "v"))
# Elasticity (Wald estimator) = b(log txs or log senders) / b(log fee per tx), both from the RD above
EL <- dcast(R[y %in% ys[c("lfpt", "y_all", "y_snd")], .(event = factor(event, EVENTS$event), y, est)], event ~ y, value.var = "est")
setnames(EL, ys[c("lfpt", "y_all", "y_snd")], c("rd_log_fee", "rd_log_txs", "rd_log_senders")); setcolorder(EL, c("event", "rd_log_fee", "rd_log_txs", "rd_log_senders"))
EL[, `:=`(elasticity_txs = rd_log_txs / rd_log_fee, elasticity_senders = rd_log_senders / rd_log_fee)]
cat("## A. Elasticities = RD log txs (or senders) / RD log fee per tx\n"); print(EL)
fwrite(R, file.path(DIR_TAB, "events.csv")); fwrite(EL, file.path(DIR_TAB, "elasticities.csv"))

# Figure 1: fee per tx (US$) and hourly txs indexed to the 36 h before each drop, L2 vs Ethereum L1, +-48 h
m_fee <- "Fee per transaction (US$)"; m_tx <- "Transactions per hour\n(36 h before the drop = 100)"
F1 <- list()
for (i in seq_len(nrow(EVENTS))) {
  t0 <- EVENTS$t0[i]
  d <- merge(D[chain == EVENTS$chain[i] & hr >= t0 - 48 * 3600 & hr < t0 + 48 * 3600], eth_usd_daily[, .(day, usd = close)], by = "day")[, h := as.numeric(hr - t0, units = "hours")]
  b <- d[h < 0 & h >= -36, .(n = mean(n), n_eth = mean(n_eth))]
  F1[[i]] <- rbind(d[, .(h, measure = m_fee, series = "Base or Arbitrum (fee drop)", v = fpt * usd)], d[, .(h, measure = m_tx, series = "Base or Arbitrum (fee drop)", v = 100 * n / b$n)],
                   d[, .(h, measure = m_tx, series = "Ethereum L1 (market reference)", v = 100 * n_eth / b$n_eth)])[, label := EVENTS$label[i]]
}
F1 <- rbindlist(F1)
F1[, `:=`(label = factor(label, EVENTS$label), measure = factor(measure, c(m_fee, m_tx)), series = factor(series, c("Base or Arbitrum (fee drop)", "Ethereum L1 (market reference)")))]
g <- ggplot(F1[order(-as.integer(series))], aes(h, v, colour = series)) +
  geom_hline(data = data.table(measure = factor(m_tx, levels(F1$measure)), y = 100), aes(yintercept = y), colour = COL[["ink2"]], linewidth = 0.3) +
  geom_vline(xintercept = 0, colour = COL[["ink"]], linewidth = 0.4) + geom_line(linewidth = 0.5) +
  facet_grid(measure ~ label, scales = "free_y", switch = "y") +
  scale_y_log10(breaks = c(0.003, 0.01, 0.03, 0.1, 0.3, 1, 25, 50, 100, 200, 400, 800),   # fee row uses the dollar breaks, index row the others
                labels = c("$0.003", "$0.01", "$0.03", "$0.10", "$0.30", "$1.00", "25", "50", "100", "200", "400", "800")) +
  scale_x_continuous(breaks = seq(-48, 48, 24)) + scale_colour_manual(values = c(COL[["main"]], COL[["ref"]])) +
  labs(x = "Hours from the fee drop", y = NULL) + THEME_FIG + theme(strip.placement = "outside", strip.text.y.left = element_text(angle = 90, hjust = 0.5))
ggsave(file.path(DIR_FIG, "fig1_fee_drops_hourly.png"), g, width = 10, height = 6.2, dpi = 200, bg = "white")

# ---- B. Base vs Arbitrum (not yet treated) ----
t_base <- EVENTS$t0[1]; t_arb <- EVENTS$t0[2]; t_arb2 <- EVENTS$t0[3]
D[, per := fcase(hr < t_base, "pre", hr < t_arb, "Base only", hr < t_arb2, "Arb step 1", default = "both")]
cat("## B. Median fee per tx (US$) and mean txs per hour by chain and period\n")
print(dcast(merge(D, eth_usd_daily[, .(day, usd = close)], by = "day")[, .(fee_usd = signif(median(fpt * usd), 3)), by = .(chain, per)], chain ~ factor(per, c("pre", "Base only", "Arb step 1", "both")), value.var = "fee_usd"))
print(dcast(D[, .(txs_per_hour = round(mean(n))), by = .(chain, per)], chain ~ factor(per, c("pre", "Base only", "Arb step 1", "both")), value.var = "txs_per_hour"))
ys2 <- c(y_all = "log txs", y_hf = "log txs, high-frequency senders", y_ot = "log txs, other senders", y_fail = "log failed txs", fail_sh = "failed share",
         y_new = "log new senders", y_snd = "log distinct senders (sum over classes)")
# DiD, Base (treated from t_B) vs Arbitrum (not yet treated before t_A1), hours t in [t_B - 7 days, t_A1):
#   y_ct = b * Treat_ct + chain x hour-of-day FE + hour FE + e_ct,   Treat_ct = 1[c = Base, t >= t_B]
# SEs: Newey-West (24 lags) on the chain-hour panel, and clustered by day.
W2 <- D[hr >= t_base - 7 * 86400 & hr < t_arb][, treat := as.integer(chain == "base" & hr >= t_base)]
R2 <- list()
for (y in names(ys2)) {
  f <- feols(as.formula(paste(y, "~ treat | chain^hod + hr")), data = W2, vcov = NW(24) ~ chain + hr)
  fc <- feols(as.formula(paste(y, "~ treat | chain^hod + hr")), data = W2, cluster = ~day)
  R2[[y]] <- data.table(y = ys2[[y]], est = coef(f)[[1]], se_nw = se(f)[[1]], se_day = se(fc)[[1]])
}
R2 <- rbindlist(R2)
cat(sprintf("## B. DiD Base vs Arbitrum, hours in [%s, %s): %d chain-hours (%d Base post hours)\n", t_base - 7 * 86400, t_arb, nrow(W2), W2[treat == 1, .N])); print(R2)
# Staggered TWFE with both drops, hours t >= t_B - 7 days (two units; heterogeneous-timing caveat); SEs clustered by day:
#   y_ct = b * Treat_ct + chain x hour-of-day FE + hour FE + e_ct,   Treat_ct = 1[c = Base, t >= t_B] + 1[c = Arbitrum, t >= t_A1]
W3 <- D[hr >= t_base - 7 * 86400][, treat := as.integer((chain == "base" & hr >= t_base) | (chain == "arbitrum" & hr >= t_arb))]
R3 <- list()
for (y in names(ys2)) {
  f <- feols(as.formula(paste(y, "~ treat | chain^hod + hr")), data = W3, cluster = ~day)
  R3[[y]] <- data.table(y = ys2[[y]], est = coef(f)[[1]], se_day = se(f)[[1]])
}
R3 <- rbindlist(R3)
cat("## B. Staggered TWFE with both drops (two units; heterogeneous-timing caveat)\n"); print(R3)
# Event study on the DiD sample, by day relative to Base's drop (day bins; sub-day bins would be collinear with chain x hour-of-day FE):
#   y_ct = sum_{k != -1} b_k * 1[day_t = k] * 1[c = Base] + chain x hour-of-day FE + hour FE + e_ct,   day_t = floor((t - t_B) / 24 h)
# Newey-West SEs (24 lags); one-off Base burst hours before the drop are dropped.
W2[, day_rel := floor(as.numeric(hr - t_base, units = "hours") / 24)]
burst <- D[chain == "base" & hr < t_base & hr >= t_base - 7 * 86400][n > 3 * median(n), hr]
cat(sprintf("Base pre-drop burst hours excluded from the event study: %s\n", paste(format(burst, "%m-%d %H:%M"), collapse = ", ")))
ys_es <- c(y_all = "All transactions", y_snd = "Active senders", y_new = "New senders", y_ot = "Transactions, other senders", y_hf = "Transactions, high-frequency senders", y_fail = "Failed transactions")
ES <- list()
for (y in names(ys_es)) {
  f <- feols(as.formula(paste(y, "~ i(day_rel, chain == 'base', ref = -1) | chain^hod + hr")), data = W2[!(hr %in% burst)], vcov = NW(24) ~ chain + hr)
  ct <- as.data.table(coeftable(f), keep.rownames = "term")
  ES[[y]] <- rbind(ct[, .(y = ys_es[[y]], day_rel = as.integer(sub("day_rel::(-?\\d+):.*", "\\1", term)), est = Estimate, se = `Std. Error`)], data.table(y = ys_es[[y]], day_rel = -1L, est = 0, se = 0))
}
ES <- rbindlist(ES)
cat("## B. Event study by day (ref = day -1; day 0 = the 15 hours before Arbitrum's drop)\n"); print(dcast(ES, day_rel ~ y, value.var = "est")[, lapply(.SD, round, 3)])
fwrite(R2, file.path(DIR_TAB, "did_base_vs_arbitrum.csv")); fwrite(R3, file.path(DIR_TAB, "did_staggered.csv")); fwrite(ES[order(y, day_rel)], file.path(DIR_TAB, "event_study_base_vs_arbitrum.csv"))
# Figure 2: Base minus Arbitrum by day, relative to the day before Base's drop
F2 <- ES[y %in% ys_es[c("y_all", "y_snd", "y_new")]][, `:=`(y = factor(y, ys_es[c("y_all", "y_snd", "y_new")]), ref = day_rel == -1)]
g <- ggplot(F2, aes(day_rel, est)) + geom_hline(yintercept = 0, colour = COL[["ink2"]], linewidth = 0.3) + geom_vline(xintercept = -0.5, colour = COL[["ink"]], linewidth = 0.4) +
  geom_linerange(aes(ymin = est - 1.96 * se, ymax = est + 1.96 * se), colour = COL[["main"]], linewidth = 0.6) +
  geom_point(aes(shape = ref), colour = COL[["main"]], fill = "white", size = 2.4, stroke = 0.8) + scale_shape_manual(values = c(16, 21), guide = "none") +
  facet_wrap(~ y, nrow = 1) + scale_x_continuous(breaks = -7:0) +
  labs(x = "Days from Base's fee drop (day 0 = the 15 hours before Arbitrum's own drop)", y = "Base minus Arbitrum, log points\n(day -1 = 0; 95% CI)") + THEME_FIG
ggsave(file.path(DIR_FIG, "fig2_event_study_base_vs_arbitrum.png"), g, width = 10, height = 3.6, dpi = 200, bg = "white")

# ---- C. by transaction type (successful txs) ----
TY <- l2_hourly_type[failed == 0 & hr >= as.POSIXct("2024-03-01", tz = "UTC") & hr < as.POSIXct("2024-04-15", tz = "UTC"), .(n = sum(n), fee = sum(fee)), by = .(chain, typ, hr)]
TY[, `:=`(ly = log(n), lfpt = log(fee / n), hod = hour(hr))]
cat("## C. Share of successful txs by type, 2024-03-01..12\n"); print(dcast(TY[hr < as.POSIXct("2024-03-13", tz = "UTC"), .(n = sum(n)), by = .(chain, typ)][, share := round(n / sum(n), 3), by = chain], typ ~ chain, value.var = "share"))
# The RD of section A for each type j: y = log successful txs of type j (with RI over the same fake hours) and log fee per tx of type j;
# elasticity = b(log txs) / b(log fee per tx).
RT <- list()
for (i in seq_len(nrow(EVENTS))) for (tp in sort(unique(TY$typ))) {
  ch <- EVENTS$chain[i]; times <- c(EVENTS$t0[i], CAND[[i]]); b <- s <- rep(NA_real_, length(times)); bf <- NA_real_
  for (k in seq_along(times)) for (y in if (k == 1) c("ly", "lfpt") else "ly") {
    d <- TY[typ == tp & chain == ch & hr >= times[k] - 36 * 3600 & hr < times[k] + 36 * 3600 & !(hr %in% c(times[k] - 3600, times[k]))][, `:=`(post = as.integer(hr >= times[k]), tt = as.numeric(hr - times[k], units = "days"))]
    if (nrow(d) < 36 || d[, uniqueN(post)] < 2) next
    f <- feols(as.formula(paste(y, "~ post + tt + tt:post | hod")), data = d, vcov = NW(6) ~ hr)
    if (y == "ly") { b[k] <- coef(f)[["post"]]; s[k] <- se(f)[["post"]] } else bf <- coef(f)[["post"]]
  }
  RT[[length(RT) + 1]] <- data.table(event = EVENTS$event[i], type = tp, d_log_txs = b[1], se_txs = s[1], ri_p = mean(abs(b[-1]) >= abs(b[1]), na.rm = TRUE), d_log_fee = bf, elasticity = b[1] / bf)
}
RT <- rbindlist(RT)
cat("## C. RD in time by type (successful txs); elasticity = d log txs / d log fee per tx\n"); print(RT)
fwrite(RT, file.path(DIR_TAB, "type_rd.csv"))
cat("\n## sessionInfo\n```\n"); print(sessionInfo()); cat("```\n"); sink()
