# 04_analysis_main.R: main estimates at the three fee drops (event hours in 00_setup.R).
#  A  RD in time (+-36 h, hour-of-day FE, side-specific trends, 1-hour donut, Newey-West SEs), also with market controls (log Ethereum L1 and Bitcoin txs);
#     placebo RDs on L1 and Bitcoin; randomization inference; elasticities
#  B  Base vs Arbitrum before Arbitrum's own drop
#  C  RD by transaction type
source(here::here("code", "00_setup.R"))
new_log("04 main analysis")
load_panel(c("l2_hourly", "l2_hourly_type", "l2_newsenders", "control_hourly", "eth_usd_daily"))

# ---- hourly panel ----
hourly <- function(ch) { H <- l2_hourly[chain == ch]
  W <- H[, .(n = sum(n), n_fail = sum(n[failed == 1]), n_hf = sum(n[hf == 1]), n_ot = sum(n[hf == 0]), fee = sum(fee), senders = sum(n_senders)), by = hr]
  W <- merge(W, l2_newsenders[chain == ch, .(hr, new_senders)], by = "hr", all.x = TRUE)[is.na(new_senders), new_senders := 0]
  W[, `:=`(chain = ch, fpt = fee / n, lfpt = log(fee / n), y_all = log(n), y_snd = log(senders), y_fail = log1p(n_fail), y_new = log1p(new_senders), y_hf = log1p(n_hf), y_ot = log(n_ot),
           fail_sh = n_fail / n)][order(hr)] }
D <- rbindlist(lapply(CHAINS, hourly))[hr >= as.POSIXct("2024-03-01", tz = "UTC") & hr < as.POSIXct("2024-04-15", tz = "UTC")]   # new senders need a burn-in from Feb 15
D <- merge(D, control_hourly[, .(hr, n_eth, y_l1 = log(n_eth), y_btc = log(n_btc))], by = "hr", all.x = TRUE)
D[, `:=`(hod = hour(hr), day = as.IDate(hr, tz = "UTC"))]; check_unique(D, c("chain", "hr"), "hourly panel")
say(sprintf("Hourly panel: %d chain-hours, %s..%s UTC", nrow(D), min(D$hr), max(D$hr)))

# ---- A. RD in time, market controls, RI ----
ys <- c(lfpt = "log fee per tx (first stage)", y_all = "log txs", y_snd = "log distinct senders", y_new = "log new senders", y_fail = "log failed txs",
        fail_sh = "failed share", y_hf = "log txs, HF senders", y_ot = "log txs, other senders", y_l1 = "placebo: log Ethereum L1 txs", y_btc = "placebo: log Bitcoin txs")
rd <- function(ch, t0, y, W = 1.5, dat = D, covs = NULL) { d <- dat[chain == ch & hr >= t0 - W * 86400 & hr < t0 + W * 86400 & !(hr %in% c(t0 - 3600, t0))][, `:=`(post = as.integer(hr >= t0), tt = as.numeric(hr - t0, units = "days"))]
  if (nrow(d) < 24 * W || d[, uniqueN(post)] < 2) return(c(NA, NA)); f <- feols(as.formula(paste(y, "~", paste(c("post + tt + tt:post", covs), collapse = " + "), "| hod")), data = d, vcov = NW(6) ~ hr); c(coef(f)[["post"]], se(f)[["post"]]) }
candf <- function(t0) { cd <- t0 + seq(-80, 80) * 12 * 3600   # fake events at the same clock hour (and +12 h), > 3 days from any event
  cd[cd >= as.POSIXct("2024-03-03", tz = "UTC") & cd <= as.POSIXct("2024-04-12 12:00", tz = "UTC") & sapply(cd, function(t) all(abs(as.numeric(t - EVENTS$t0, units = "days")) > 3))] }
say(sprintf("RI: %s fake event hours per event", paste(sapply(EVENTS$t0, function(t) length(candf(t))), collapse = "/")))
R <- rbindlist(lapply(seq_len(nrow(EVENTS)), function(i) { ch <- EVENTS$chain[i]; t0 <- EVENTS$t0[i]; cand <- candf(t0)
  rr <- rbindlist(lapply(names(ys), function(y) { e <- rd(ch, t0, y); fk <- sapply(cand, function(t) rd(ch, t, y)[1])
    data.table(event = EVENTS$event[i], y = ys[[y]], est = e[1], se = e[2], ri_p = mean(abs(fk) >= abs(e[1]), na.rm = TRUE), fake_sd = sd(fk, na.rm = TRUE)) }))
  mk <- c("y_l1", "y_btc"); dd <- rd(ch, t0, "y_all", covs = mk); fk <- sapply(cand, function(t) rd(ch, t, "y_all", covs = mk)[1])
  rbind(rr, data.table(event = EVENTS$event[i], y = "log txs, RD with market controls (L1, Bitcoin)", est = dd[1], se = dd[2], ri_p = mean(abs(fk) >= abs(dd[1]), na.rm = TRUE), fake_sd = sd(fk, na.rm = TRUE))) }))
say("## A. RD in time (+-36 h), with market controls, and placebo RDs on L1 and Bitcoin: estimate (NW SE) [RI p]")
logp(dcast(R[, .(y = factor(y, unique(y)), event = factor(event, EVENTS$event), v = sprintf("%.3f (%.3f) [RI %.2f]", est, se, ri_p))], y ~ event, value.var = "v"))
EL <- dcast(R[y %in% ys[c("lfpt", "y_all", "y_snd")], .(event = factor(event, EVENTS$event), y, est)], event ~ y, value.var = "est")
setnames(EL, ys[c("lfpt", "y_all", "y_snd")], c("rd_log_fee", "rd_log_txs", "rd_log_senders")); setcolorder(EL, c("event", "rd_log_fee", "rd_log_txs", "rd_log_senders"))
EL[, `:=`(elasticity_txs = rd_log_txs / rd_log_fee, elasticity_senders = rd_log_senders / rd_log_fee)]
say("## A. Elasticities = RD log txs (or senders) / RD log fee per tx"); logp(rnd(EL))
fwrite(R, res("tables", "events.csv")); fwrite(EL, res("tables", "elasticities.csv"))
# Figure 1: fee per tx (US$) and hourly txs indexed to the 36 h before each drop, L2 vs Ethereum L1, +-48 h
m_fee <- "Fee per transaction (US$)"; m_tx <- "Transactions per hour\n(36 h before the drop = 100)"
F1 <- rbindlist(lapply(seq_len(nrow(EVENTS)), function(i) { t0 <- EVENTS$t0[i]
  d <- merge(D[chain == EVENTS$chain[i] & hr >= t0 - 48 * 3600 & hr < t0 + 48 * 3600], eth_usd_daily[, .(day, usd = close)], by = "day")[, h := as.numeric(hr - t0, units = "hours")]
  b <- d[h < 0 & h >= -36, .(n = mean(n), n_eth = mean(n_eth))]
  rbind(d[, .(h, measure = m_fee, series = "Base or Arbitrum (fee drop)", v = fpt * usd)], d[, .(h, measure = m_tx, series = "Base or Arbitrum (fee drop)", v = 100 * n / b$n)],
        d[, .(h, measure = m_tx, series = "Ethereum L1 (market reference)", v = 100 * n_eth / b$n_eth)])[, label := EVENTS$label[i]] }))
F1[, `:=`(label = factor(label, EVENTS$label), measure = factor(measure, c(m_fee, m_tx)), series = factor(series, c("Base or Arbitrum (fee drop)", "Ethereum L1 (market reference)")))]
g <- ggplot(F1[order(-as.integer(series))], aes(h, v, colour = series)) +
  geom_hline(data = data.table(measure = factor(m_tx, levels(F1$measure)), y = 100), aes(yintercept = y), colour = COL[["ink2"]], linewidth = 0.3) +
  geom_vline(xintercept = 0, colour = COL[["ink"]], linewidth = 0.4) + geom_line(linewidth = 0.5) +
  facet_grid(measure ~ label, scales = "free_y", switch = "y") +
  scale_y_log10(breaks = function(l) if (l[2] < 10) c(0.003, 0.01, 0.03, 0.1, 0.3, 1) else c(25, 50, 100, 200, 400, 800),
                labels = function(b) if (all(b < 10, na.rm = TRUE)) scales::dollar(b) else b) +
  scale_x_continuous(breaks = seq(-48, 48, 24)) + scale_colour_manual(values = c(COL[["main"]], COL[["ref"]])) +
  labs(x = "Hours from the fee drop", y = NULL) + theme_fig() + theme(strip.placement = "outside", strip.text.y.left = element_text(angle = 90, hjust = 0.5))
save_fig(g, "fig1_fee_drops_hourly.png", 10, 6.2)

# ---- B. Base vs Arbitrum (not yet treated) ----
t_base <- EVENTS$t0[1]; t_arb <- EVENTS$t0[2]; t_arb2 <- EVENTS$t0[3]
D[, per := fcase(hr < t_base, "pre", hr < t_arb, "Base only", hr < t_arb2, "Arb step 1", default = "both")]
say("## B. Median fee per tx (US$) and mean txs per hour by chain and period")
logp(dcast(merge(D, eth_usd_daily[, .(day, usd = close)], by = "day")[, .(fee_usd = signif(median(fpt * usd), 3)), by = .(chain, per)], chain ~ factor(per, c("pre", "Base only", "Arb step 1", "both")), value.var = "fee_usd"))
logp(dcast(D[, .(txs_per_hour = round(mean(n))), by = .(chain, per)], chain ~ factor(per, c("pre", "Base only", "Arb step 1", "both")), value.var = "txs_per_hour"))
ys2 <- c(y_all = "log txs", y_hf = "log txs, high-frequency senders", y_ot = "log txs, other senders", y_fail = "log failed txs", fail_sh = "failed share",
         y_new = "log new senders", y_snd = "log distinct senders (sum over classes)")
W2 <- D[hr >= t_base - 7 * 86400 & hr < t_arb][, treat := as.integer(chain == "base" & hr >= t_base)]
R2 <- rbindlist(lapply(names(ys2), function(y) { f <- feols(as.formula(paste(y, "~ treat | chain^hod + hr")), data = W2, vcov = NW(24) ~ chain + hr)
  fc <- feols(as.formula(paste(y, "~ treat | chain^hod + hr")), data = W2, cluster = ~day); data.table(y = ys2[[y]], est = coef(f)[[1]], se_nw = se(f)[[1]], se_day = se(fc)[[1]]) }))
say(sprintf("## B. DiD Base vs Arbitrum, hours in [%s, %s): %d chain-hours (%d Base post hours)", t_base - 7 * 86400, t_arb, nrow(W2), W2[treat == 1, .N])); logp(rnd(R2))
W3 <- D[hr >= t_base - 7 * 86400][, treat := as.integer((chain == "base" & hr >= t_base) | (chain == "arbitrum" & hr >= t_arb))]
R3 <- rbindlist(lapply(names(ys2), function(y) { f <- feols(as.formula(paste(y, "~ treat | chain^hod + hr")), data = W3, cluster = ~day); data.table(y = ys2[[y]], est = coef(f)[[1]], se_day = se(f)[[1]]) }))
say("## B. Staggered TWFE with both drops (two units; heterogeneous-timing caveat)"); logp(rnd(R3))
W2[, day_rel := floor(as.numeric(hr - t_base, units = "hours") / 24)]   # day bins; sub-day bins would be collinear with chain x hour-of-day FE
burst <- D[chain == "base" & hr < t_base & hr >= t_base - 7 * 86400][n > 3 * median(n), hr]   # one-off Base bursts, excluded from the event study
say(sprintf("Base pre-drop burst hours excluded from the event study: %s", paste(format(burst, "%m-%d %H:%M"), collapse = ", ")))
ys_es <- c(y_all = "All transactions", y_snd = "Active senders", y_new = "New senders", y_ot = "Transactions, other senders", y_hf = "Transactions, high-frequency senders", y_fail = "Failed transactions")
ES <- rbindlist(lapply(names(ys_es), function(y) { f <- feols(as.formula(paste(y, "~ i(day_rel, chain == 'base', ref = -1) | chain^hod + hr")), data = W2[!(hr %in% burst)], vcov = NW(24) ~ chain + hr)
  ct <- as.data.table(coeftable(f), keep.rownames = "term")
  rbind(ct[, .(y = ys_es[[y]], day_rel = as.integer(sub("day_rel::(-?\\d+):.*", "\\1", term)), est = Estimate, se = `Std. Error`)], data.table(y = ys_es[[y]], day_rel = -1L, est = 0, se = 0)) }))
say("## B. Event study by day (ref = day -1; day 0 = the 15 hours before Arbitrum's drop)"); logp(dcast(ES, day_rel ~ y, value.var = "est")[, lapply(.SD, round, 3)])
fwrite(R2, res("tables", "did_base_vs_arbitrum.csv")); fwrite(R3, res("tables", "did_staggered.csv")); fwrite(ES[order(y, day_rel)], res("tables", "event_study_base_vs_arbitrum.csv"))
# Figure 2: Base minus Arbitrum by day, relative to the day before Base's drop
F2 <- ES[y %in% ys_es[c("y_all", "y_snd", "y_new")]][, `:=`(y = factor(y, ys_es[c("y_all", "y_snd", "y_new")]), ref = day_rel == -1)]
g <- ggplot(F2, aes(day_rel, est)) + geom_hline(yintercept = 0, colour = COL[["ink2"]], linewidth = 0.3) + geom_vline(xintercept = -0.5, colour = COL[["ink"]], linewidth = 0.4) +
  geom_linerange(aes(ymin = est - 1.96 * se, ymax = est + 1.96 * se), colour = COL[["main"]], linewidth = 0.6) +
  geom_point(aes(shape = ref), colour = COL[["main"]], fill = "white", size = 2.4, stroke = 0.8) + scale_shape_manual(values = c(16, 21), guide = "none") +
  facet_wrap(~ y, nrow = 1) + scale_x_continuous(breaks = -7:0) +
  labs(x = "Days from Base's fee drop (day 0 = the 15 hours before Arbitrum's own drop)", y = "Base minus Arbitrum, log points\n(day -1 = 0; 95% CI)") + theme_fig()
save_fig(g, "fig2_event_study_base_vs_arbitrum.png", 10, 3.6)

# ---- C. by transaction type (successful txs) ----
TY <- l2_hourly_type[failed == 0 & hr >= as.POSIXct("2024-03-01", tz = "UTC") & hr < as.POSIXct("2024-04-15", tz = "UTC"), .(n = sum(n), fee = sum(fee)), by = .(chain, typ, hr)]
TY[, `:=`(ly = log(n), lfpt = log(fee / n), hod = hour(hr))]
say("## C. Share of successful txs by type, 2024-03-01..12"); logp(dcast(TY[hr < as.POSIXct("2024-03-13", tz = "UTC"), .(n = sum(n)), by = .(chain, typ)][, share := round(n / sum(n), 3), by = chain], typ ~ chain, value.var = "share"))
RT <- rbindlist(lapply(seq_len(nrow(EVENTS)), function(i) rbindlist(lapply(sort(unique(TY$typ)), function(tp) {
  d <- TY[typ == tp]; ey <- rd(EVENTS$chain[i], EVENTS$t0[i], "ly", dat = d); ef <- rd(EVENTS$chain[i], EVENTS$t0[i], "lfpt", dat = d); fk <- sapply(candf(EVENTS$t0[i]), function(t) rd(EVENTS$chain[i], t, "ly", dat = d)[1])
  data.table(event = EVENTS$event[i], type = tp, d_log_txs = ey[1], se_txs = ey[2], ri_p = mean(abs(fk) >= abs(ey[1]), na.rm = TRUE), d_log_fee = ef[1], elasticity = ey[1] / ef[1]) }))))
say("## C. RD in time by type (successful txs); elasticity = d log txs / d log fee per tx"); logp(rnd(RT))
fwrite(RT, res("tables", "type_rd.csv"))
save_log("04_analysis_main")
