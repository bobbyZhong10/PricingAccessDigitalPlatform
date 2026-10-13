# 06_analysis_users.R: who responds. Entrants = addresses first active on 2024-03-01..27 (March) or in MAY_WINDOW (May); burst rule as in 00_setup.R.
# Classes: burst accounts (code: class3 == "campaign"), bot-like entrants ("bot") and the rest (non-burst, "genuine").
#  A  entry and later activity around each drop: local randomization (W = 12/24/72 h), RI, marginal entrants; Base vs Arbitrum DiD
#  B  daily entrant cohorts
#  C  burst accounts on Base by day; the burst rule against its size-only and funder-burst bounds (original and corrected funder)
#  D  burst vs non-burst entry; decomposition of Base's change in daily txs
#  E  response by the sender's own pre-drop fee level, net of a placebo window pair; within-sender elasticity per event
#  F  validation of the burst construct (thresholds in 00_setup.R): V1 LayerZero list, V2 funder-entrant-sweep components and entity growth,
#     V3 hourly entry by class, V4 burst target types, V5 Google Trends, V6 fees, L1 rent, profit and the cost of an identity
#  G  who runs the burst accounts (concentration, repeat entities, cross-chain, what they received) and the second Base fee cut (May gas-limit increases):
#     first actions, Arbitrum as comparison chain, window variants, hourly entry by class at all five cuts
#  H  threshold mechanics of four fee cuts: dollar stakes and friction bounds (Chetty 2012), value of an identity (entry thresholds, Bresnahan & Reiss 1991)
source(here::here("code", "00_setup.R"))
sink(file.path(DIR_LOG, "06_analysis_users.md"), split = TRUE)
cat("# 06 users\nRun ", format(Sys.time(), usetz = TRUE), "\n", sep = "")
ct <- yaml::read_yaml(CONTRACT_FILE)   # panel.rds must have passed 03_validate_panels.R and be unchanged since
stopifnot(isTRUE(ct$all_valid), unname(tools::md5sum(PANEL_FILE)) == ct$md5)
PNL <- readRDS(PANEL_FILE)
E <- PNL$entrants; sender_window <- PNL$sender_window; base_tx_by_class <- PNL$base_tx_by_class; l2_hourly <- PNL$l2_hourly; eth_usd_daily <- PNL$eth_usd_daily
acts <- paste0("act_", gsub("-", "_", RETENTION_MONTHS)); E[, months5 := rowSums(.SD), .SDcols = acts]   # months active of the five retention months
cat(sprintf("Entrants: %s\n", paste(E[, .N, by = chain][, sprintf("%s %d", chain, N)], collapse = "; ")))

# ---- A. entry and later activity around each drop ----
# Local randomization: within W hours of t0 (t0 - 1 and t0 dropped), compare entrants who arrived after vs before t0.
#   jump in log entrants per hour = log(Nbar_1) - log(Nbar_0),   Nbar_s = mean entrants per hour on side s (0 = before, 1 = after)
#   jump in outcome v = vbar_1 - vbar_0,   vbar_s = sum_h N_h * v_h / sum_h N_h over the hours h of side s (entrant-weighted mean)
#   marginal entrants: m_v = (Nbar_1 * vbar_1 - Nbar_0 * vbar_0) / (Nbar_1 - Nbar_0); 95% CI from 300 bootstrap draws of hours within each side
# RI: the same jumps at fake times on a 6-hour grid (03-01 12:00..03-27 12:00) more than W + 24 h from any event, with the window inside
# 03-01..03-28; p = (1 + #{fake |jump| >= |jump|}) / (1 + K), K fakes (reported with at least 5 fakes). Row 1 of JUMP is the actual event, the rest are the fakes.
ys <- c(act_2024_04 = "active Apr 2024", act_2024_06 = "active Jun 2024", act_2024_09 = "active Sep 2024", act_2024_12 = "active Dec 2024", act_2025_03 = "active Mar 2025",
        any_later = "any activity in sampled months", months_active = "months active (of 10 sampled)", single_tx_wk1 = "single tx in first week", bot_wk1 = sprintf("bot-like (>= %d txs in week 1)", BOT_MIN_WEEK1))
H <- E[, c(list(N = .N), lapply(.SD, mean)), by = .(chain, hr), .SDcols = names(ys)][order(chain, hr)]   # entrants per hour and their mean outcomes
grid <- seq(as.POSIXct("2024-03-01 12:00", tz = "UTC"), as.POSIXct("2024-03-27 12:00", tz = "UTC"), by = 6 * 3600)
RA <- list()
for (i in seq_len(nrow(EVENTS))) for (W in c(12, 24, 72)) {
  ch <- EVENTS$chain[i]; t0 <- EVENTS$t0[i]
  ok <- grid - W * 3600 >= as.POSIXct("2024-03-01", tz = "UTC") & grid + W * 3600 <= as.POSIXct("2024-03-28", tz = "UTC")
  for (j in seq_len(nrow(EVENTS))) ok <- ok & abs(as.numeric(grid - EVENTS$t0[j], units = "hours")) > W + 24
  times <- c(t0, grid[ok]); JUMP <- matrix(NA_real_, length(times), length(ys) + 1)   # columns: log entrants per hour, then ys
  for (k in seq_along(times)) {
    d <- H[chain == ch & hr >= times[k] - W * 3600 & hr < times[k] + W * 3600 & !(hr %in% c(times[k] - 3600, times[k]))][, post := as.integer(hr >= times[k])]
    s <- d[, c(list(N = mean(N)), lapply(.SD, weighted.mean, w = N)), by = post, .SDcols = names(ys)][order(post)]
    if (nrow(s) < 2) next
    JUMP[k, ] <- c(log(s$N[2]) - log(s$N[1]), unlist(s[2, names(ys), with = FALSE]) - unlist(s[1, names(ys), with = FALSE]))
    if (k == 1) s1 <- s
  }
  if (is.na(JUMP[1, 1])) next
  fk <- JUMP[-1, , drop = FALSE]; fk <- fk[!is.na(fk[, 1]), , drop = FALSE]
  ri <- rep(NA_real_, ncol(JUMP)); if (nrow(fk) >= 5) for (j in seq_len(ncol(JUMP))) ri[j] <- (1 + sum(abs(fk[, j]) >= abs(JUMP[1, j]))) / (1 + nrow(fk))
  r0 <- unlist(s1[1, names(ys), with = FALSE]); r1 <- unlist(s1[2, names(ys), with = FALSE])
  marg <- (s1$N[2] * r1 - s1$N[1] * r0) / (s1$N[2] - s1$N[1])
  set.seed(1); d0 <- H[chain == ch & hr >= t0 - W * 3600 & hr < t0 + W * 3600 & !(hr %in% c(t0 - 3600, t0))][, post := as.integer(hr >= t0)]
  BS <- matrix(NA_real_, length(ys), 300)
  for (bb in 1:300) {
    s <- d0[, .SD[sample(.N, replace = TRUE)], by = post][, c(list(N = mean(N)), lapply(.SD, weighted.mean, w = N)), by = post, .SDcols = names(ys)][order(post)]
    BS[, bb] <- (s$N[2] * unlist(s[2, names(ys), with = FALSE]) - s$N[1] * unlist(s[1, names(ys), with = FALSE])) / (s$N[2] - s$N[1])
  }
  tab <- data.table(event = EVENTS$event[i], W = W, entrants_per_hour_before = s1$N[1], entrants_per_hour_after = s1$N[2], y = c("log entrants per hour", ys),
                    before = c(log(s1$N[1]), r0), jump = JUMP[1, ], ri_p = ri, n_fake = nrow(fk),
                    marginal = c(NA, marg), m_lo = c(NA, apply(BS, 1, quantile, .025, na.rm = TRUE)), m_hi = c(NA, apply(BS, 1, quantile, .975, na.rm = TRUE)))
  cat(sprintf("## A. %s, W = %d h each side: entrants/hour %.0f -> %.0f\n", EVENTS$event[i], W, s1$N[1], s1$N[2])); print(tab[, !c("event", "W", "entrants_per_hour_before", "entrants_per_hour_after")])
  RA[[length(RA) + 1]] <- tab
}
RA <- rbindlist(RA)
fwrite(RA, file.path(DIR_TAB, "entry_retention_local_randomization.csv"))
# DiD at Base's drop (W = 12 h): did_v = jump_v(Base) - jump_v(Arbitrum), Arbitrum not yet treated; RI over grid times more than 36 h from any event, p as above
t0 <- EVENTS$t0[1]; ok <- rep(TRUE, length(grid))
for (j in seq_len(nrow(EVENTS))) ok <- ok & abs(as.numeric(grid - EVENTS$t0[j], units = "hours")) > 36
times <- c(t0, grid[ok]); DD <- matrix(NA_real_, length(times), length(ys) + 1)   # row 1 = actual, then fakes
for (k in seq_along(times)) {
  J2 <- matrix(NA_real_, 2, length(ys) + 1)   # rows: Base, Arbitrum
  for (c2 in 1:2) {
    d <- H[chain == CHAINS[c2] & hr >= times[k] - 12 * 3600 & hr < times[k] + 12 * 3600 & !(hr %in% c(times[k] - 3600, times[k]))][, post := as.integer(hr >= times[k])]
    s <- d[, c(list(N = mean(N)), lapply(.SD, weighted.mean, w = N)), by = post, .SDcols = names(ys)][order(post)]
    if (nrow(s) == 2) J2[c2, ] <- c(log(s$N[2]) - log(s$N[1]), unlist(s[2, names(ys), with = FALSE]) - unlist(s[1, names(ys), with = FALSE]))
  }
  if (k == 1) J2_actual <- J2
  DD[k, ] <- J2[1, ] - J2[2, ]
}
fk <- DD[-1, , drop = FALSE]; fk <- fk[!is.na(fk[, 1]), , drop = FALSE]
ri <- rep(NA_real_, ncol(DD)); for (j in seq_len(ncol(DD))) ri[j] <- (1 + sum(abs(fk[, j]) >= abs(DD[1, j]))) / (1 + nrow(fk))
RD2 <- data.table(y = c("log entrants per hour", ys), base = J2_actual[1, ], arbitrum = J2_actual[2, ], did = DD[1, ], ri_p = ri)
cat(sprintf("## A. DiD at Base's drop (W = 12 h): Base change minus Arbitrum change; RI over %d fake times\n", nrow(fk))); print(RD2)
fwrite(RD2, file.path(DIR_TAB, "entry_retention_did_base_vs_arbitrum.csv"))

# ---- B. daily cohorts ----
DC <- E[, .(N = .N, single_tx_wk1 = mean(single_tx_wk1), active_apr24 = mean(act_2024_04), active_sep24 = mean(act_2024_09), active_mar25 = mean(act_2025_03), months_active_of5 = mean(months5)),
        by = .(chain, day)][day >= as.IDate("2024-03-04") & day <= as.IDate("2024-03-26")][order(chain, day)]
cat("## B. Daily entrant cohorts (UTC entry day)\n"); print(DC); fwrite(DC, file.path(DIR_TAB, "daily_cohorts.csv"))

# ---- C. burst accounts on Base ----
X <- E[chain == "base" & !is.na(wave)]
cat(sprintf("C. Base entrants %s..%s: %d; in campaign bursts %d; funded by bursting funders %d\n", ENTRANT_WINDOW[1], ENTRANT_WINDOW[2], nrow(X), sum(X$wave), sum(X$batch)))
# concentration: share of the day's entrants whose first recipient / method / funder is the day's most common one (top1) or among the 10 most common (top10)
WD <- X[, .(N = .N, to_top1 = max(table(first_to)) / .N, to_top10 = sum(head(sort(table(first_to), decreasing = TRUE), 10)) / .N, sel_top1 = max(table(first_sel)) / .N,
            funder_top1 = max(table(funder_any)) / .N, funder_top10 = sum(head(sort(table(funder_any), decreasing = TRUE), 10)) / .N, no_funder_seen = mean(is.na(funder_any)),
            campaign = mean(wave), bursting_funder = mean(batch), months_active = mean(months5), months_active_noncampaign = mean(months5[wave == 0]), N_noncampaign = sum(wave == 0)), by = day][order(day)]
cat("## C. By entry day (Base): concentration of first recipient, method and funder\n"); print(WD)
cat("## C. Top first recipient x method and top funders on the largest campaign days\n")
for (d in as.IDate(c("2024-03-15", "2024-03-16", "2024-03-20"))) { y <- X[day == d]
  print(y[, .N, by = .(first_to, first_sel)][order(-N)][1:5][, share := round(N / nrow(y), 3)][]); print(y[!is.na(funder_any), .N, by = funder_any][order(-N)][1:5][, share := round(N / nrow(y), 3)][]) }
fwrite(WD, file.path(DIR_TAB, "campaigns_by_day_base.csv"))
# Burst rule bounds: the main burst rule against a size-only rule and a rule that also requires bursting funders (00_setup.R), the latter with the original
# funder (any first incoming transfer, which may postdate entry) and the corrected funder (first funder before the first outgoing tx, section F); bot-like
# entrants are a separate class under every rule. Pre = 03-08..12; post = 03-14 (Base) or 03-15 (Arbitrum) to 03-21. Entry ratio = post / pre entrants per day;
# wedge = all-entrant / non-burst entry ratio.
rules <- c(wave = "main: burst vs own pre-shock level", wave_size = sprintf("bound: size only (>= %s a day)", format(WAVE_SIZE_ALT, big.mark = ",")),
           wave_funded = "bound: burst funded by bursting funders", wave_funded2 = "bound: burst funded by bursting funders (corrected funder)")
RB <- list()
for (ch in CHAINS) for (v in names(rules)) {
  Z <- E[chain == ch & !is.na(wave)][, cls := fcase(bot_wk1 == 1, "bot", get(v) == 1, "campaign", default = "genuine")]
  Zpre <- Z[day >= ENTRANT_WINDOW[1] & day <= as.IDate("2024-03-12")]; Zpost <- Z[day >= as.IDate(if (ch == "base") "2024-03-14" else "2024-03-15") & day <= ENTRANT_WINDOW[2]]
  RB[[length(RB) + 1]] <- data.table(chain = ch, v = v, rule = rules[[v]], campaign_share_pre = Zpre[, mean(cls == "campaign")], campaign_share_post = Zpost[, mean(cls == "campaign")],
    genuine_entry_ratio = (Zpost[cls == "genuine", .N] / uniqueN(Zpost$day)) / (Zpre[cls == "genuine", .N] / uniqueN(Zpre$day)),
    campaign_entry_ratio = (Zpost[cls == "campaign", .N] / uniqueN(Zpost$day)) / (Zpre[cls == "campaign", .N] / uniqueN(Zpre$day)),
    all_entry_ratio = (Zpost[, .N] / uniqueN(Zpost$day)) / (Zpre[, .N] / uniqueN(Zpre$day)),
    genuine_months_pre = Zpre[cls == "genuine", mean(months5)], genuine_months_post = Zpost[cls == "genuine", mean(months5)], campaign_months_post = Zpost[cls == "campaign", mean(months5)])
}
RB <- rbindlist(RB)[, wedge := all_entry_ratio / genuine_entry_ratio]
cat("## C. Burst rule bounds (entry ratios = post / pre entrants per day; months active of the five retention months)\n"); print(RB[, !"v"])
fwrite(RB[v != "wave_funded2", !c("v", "all_entry_ratio", "wedge")], file.path(DIR_TAB, "campaign_rule_bounds.csv"))
fwrite(RB[v %like% "funded", .(chain, rule = v, campaign_share_pre, campaign_share_post, genuine_entry_ratio, campaign_entry_ratio, all_entry_ratio, genuine_months_pre,
                               genuine_months_post, campaign_months_post, wedge)], file.path(DIR_TAB, "val_bound_corrected.csv"))

# ---- D. burst vs non-burst entry ----
EW <- E[!is.na(wave)][, grp2 := fcase(class3 == "campaign", "campaign", class3 == "bot", sprintf("bot-like (>= %d txs, week 1)", BOT_MIN_WEEK1), default = "genuine")]
EW[, grp := fcase(class3 != "genuine", grp2, batch == 1, "genuine: bursting funder", default = "genuine: other")]
cat("## D. Entrants by group and chain (03-08..21)\n"); print(EW[, .N, by = .(chain, grp)][, share := round(N / sum(N), 3), by = chain][order(chain, grp)])
ev <- copy(EVENTS)[, `:=`(pre0 = as.IDate(c("2024-03-08", "2024-03-10", "2024-03-15")), pre1 = as.IDate(c("2024-03-12", "2024-03-13", "2024-03-18")),
                          post0 = as.IDate(c("2024-03-14", "2024-03-15", "2024-03-20")), post1 = as.IDate(c("2024-03-21", "2024-03-18", "2024-03-21")))]
# fee change over the daily windows: log(median over the post hours of the hourly median fee per tx) - log(same, pre hours), as the price in 04
HF <- PNL$fee_quantiles_hourly[, .(chain, day = as.IDate(hr, tz = "UTC"), p50)]
dlf <- numeric(nrow(ev))
for (i in seq_len(nrow(ev))) { h <- HF[chain == ev$chain[i]]; dlf[i] <- log(h[day >= ev$post0[i] & day <= ev$post1[i], median(p50)]) - log(h[day >= ev$pre0[i] & day <= ev$pre1[i], median(p50)]) }
ev[, dlf := dlf]
cat("## D. Fee change over the daily windows (log, median fee per tx)\n"); print(ev[, .(event, pre = paste(pre0, pre1), post = paste(post0, post1), dlf = round(dlf, 3))])
# Daily entry by group g: dlog_g = log(mean daily entrants post + 1) - log(mean daily entrants pre + 1); entry elasticity = dlog_g / fee change;
# 95% CIs from 500 bootstrap draws of days within each window (post days drawn first, then pre days), also for dlog_g - dlog_genuine.
R1 <- list()
for (i in seq_len(nrow(ev))) {
  e <- ev[i]
  Dd <- rbind(EW[chain == e$chain, .N, by = .(day, g = grp2)], EW[chain == e$chain & class3 == "genuine", .N, by = .(day, g = grp)])
  Dd <- dcast(Dd, day ~ g, value.var = "N", fill = 0); grps <- setdiff(names(Dd), "day")
  pre <- Dd[day >= e$pre0 & day <= e$pre1]; post <- Dd[day >= e$post0 & day <= e$post1]
  m0 <- m1 <- pt <- numeric(0)
  for (g in grps) { m0[g] <- mean(pre[[g]]); m1[g] <- mean(post[[g]]); pt[g] <- log(mean(post[[g]]) + 1) - log(mean(pre[[g]]) + 1) }
  set.seed(1); bs <- matrix(NA_real_, length(grps), 500)
  for (bb in 1:500) {
    po <- post[sample(.N, replace = TRUE)]; pr <- pre[sample(.N, replace = TRUE)]
    for (gi in seq_along(grps)) bs[gi, bb] <- log(mean(po[[grps[gi]]]) + 1) - log(mean(pr[[grps[gi]]]) + 1)
  }
  bd <- bs - matrix(bs[grps == "genuine", ], nrow = length(grps), ncol = 500, byrow = TRUE)
  R1[[i]] <- data.table(event = e$event, grp = grps, pre_per_day = m0, post_per_day = m1, dlog = pt, lo = apply(bs, 1, quantile, .025), hi = apply(bs, 1, quantile, .975),
                        entry_elasticity = pt / e$dlf, diff_vs_genuine = pt - pt[grps == "genuine"], diff_lo = apply(bd, 1, quantile, .025), diff_hi = apply(bd, 1, quantile, .975))
}
R1 <- rbindlist(R1)
cat("## D. Daily entrants pre vs post: log change, entry elasticity, difference vs genuine (day bootstrap)\n"); print(R1)
# Hourly entry within 24 h of t0 (t0 - 1 and t0 dropped; >= 6 hours each side): dlog_g = log(mean hourly entrants after + 1) - log(mean before + 1),
# g = genuine, campaign, and their difference; RI over fake times on a 6-hour grid (03-09 12:00..03-24 12:00) more than 48 h from any event, p as in section A.
HE <- dcast(EW[, .N, by = .(chain, hr, grp2)], chain + hr ~ grp2, value.var = "N", fill = 0); setnames(HE, "campaign", "camp")
grid2 <- seq(as.POSIXct("2024-03-09 12:00", tz = "UTC"), as.POSIXct("2024-03-24 12:00", tz = "UTC"), by = 6 * 3600)
ok <- rep(TRUE, length(grid2)); for (j in seq_len(nrow(EVENTS))) ok <- ok & abs(as.numeric(grid2 - EVENTS$t0[j], units = "hours")) > 48
R2 <- list()
for (i in seq_len(nrow(ev))) {
  times <- c(ev$t0[i], grid2[ok]); S2 <- matrix(NA_real_, length(times), 3)   # row 1 = actual, then fakes; columns: genuine, campaign, campaign - genuine
  for (k in seq_along(times)) {
    d <- HE[chain == ev$chain[i] & hr >= times[k] - 24 * 3600 & hr < times[k] + 24 * 3600 & !(hr %in% c(times[k] - 3600, times[k]))]
    if (d[hr >= times[k], .N] < 6 || d[hr < times[k], .N] < 6) next
    gn <- d[hr >= times[k], log(mean(genuine) + 1)] - d[hr < times[k], log(mean(genuine) + 1)]; cp <- d[hr >= times[k], log(mean(camp) + 1)] - d[hr < times[k], log(mean(camp) + 1)]
    S2[k, ] <- c(gn, cp, cp - gn)
  }
  fk <- S2[-1, , drop = FALSE]; fk <- fk[stats::complete.cases(fk), , drop = FALSE]
  R2[[i]] <- data.table(event = ev$event[i], genuine_dlog = S2[1, 1], campaign_dlog = S2[1, 2], diff = S2[1, 3], ri_p_genuine = (1 + sum(abs(fk[, 1]) >= abs(S2[1, 1]))) / (1 + nrow(fk)),
                        ri_p_campaign = (1 + sum(abs(fk[, 2]) >= abs(S2[1, 2]))) / (1 + nrow(fk)), ri_p_diff = (1 + sum(abs(fk[, 3]) >= abs(S2[1, 3]))) / (1 + nrow(fk)), n_fake = nrow(fk))
}
R2 <- rbindlist(R2)
cat("## D. Hourly entrants, +-24 h: log change genuine vs campaign, RI over fake hours\n"); print(R2)
TD <- dcast(base_tx_by_class[, .(txs = sum(txs)), by = .(period = fifelse(day <= as.IDate("2024-03-12"), "pre", "post"), cls)][, txs_per_day := txs / 7], cls ~ period, value.var = "txs_per_day", fill = 0)
TD[, change := post - pre][, share_of_change := change / sum(change)]; setcolorder(TD, c("cls", "pre", "post"))
cat("## D. Base: change in daily txs (03-06..12 vs 03-14..20) by sender class\n"); print(TD)
fwrite(R1, file.path(DIR_TAB, "campaign_vs_genuine_daily.csv")); fwrite(R2, file.path(DIR_TAB, "campaign_vs_genuine_hourly_ri.csv")); fwrite(TD, file.path(DIR_TAB, "tx_decomposition_base.csv"))

# ---- E. response by pre-drop fee level (US$ per tx); changes net of a no-fee-change placebo window pair ----
# Senders with >= 2 txs and a positive fee in the first window, followed into the second window (FEE_WINDOWS):
#   dy_i = log(1 + txs per day, second window) - log(1 + txs per day, first window)
#   dlf_i = log fee per tx, second window - first window (senders with txs and fees in both)
#   level_i = fee per tx in the first window x mean ETH/USD over that window, grouped into bins
# Per bin b: did_y = mean dy - mean dy over the placebo window pair, did_f likewise; elasticity = did_y / did_f with a delta-method SE.
px <- eth_usd_daily[, .(day, usd = close)]
bins <- c(0, 0.005, 0.01, 0.02, 0.05, 0.10, 0.25, 0.50, Inf); bin_labs <- c("<0.5c", "0.5-1c", "1-2c", "2-5c", "5-10c", "10-25c", "25-50c", ">50c")
evl <- data.table(name = EVENTS$event, chain = EVENTS$chain, pre = c("pre", "pre1", "post1"), post = c("post", "post1", "post2"))   # windows in FEE_WINDOWS
WP <- rbind(evl[, .(chain, pre, post)], data.table(chain = CHAINS, pre = "placebo_pre", post = "placebo_post"))   # every window pair needed
SW <- list()   # per-bin summary of sender-level changes, by "chain pre post"
for (k in seq_len(nrow(WP))) {
  ch <- WP$chain[k]; w0 <- FEE_WINDOWS[chain == ch & window == WP$pre[k]]; w1 <- FEE_WINDOWS[chain == ch & window == WP$post[k]]
  X <- merge(sender_window[chain == ch & window == WP$pre[k] & n >= 2, .(id, n0 = n, f0 = fee)], sender_window[chain == ch & window == WP$post[k], .(id, n1 = n, f1 = fee)],
             by = "id", all.x = TRUE)[is.na(n1), `:=`(n1 = 0, f1 = 0)]
  X <- X[f0 > 0]   # sponsored senders have no fee level
  X[, `:=`(lvl_usd = f0 / n0 * px[day >= w0$start & day <= w0$end, mean(usd)], dy = log1p(n1 / (as.integer(w1$end - w1$start) + 1L)) - log1p(n0 / (as.integer(w0$end - w0$start) + 1L)),
           dlf = fifelse(n1 > 0 & f1 > 0, log(f1 / n1) - log(f0 / n0), NA_real_))]
  X[, bin := cut(lvl_usd, bins, labels = bin_labs, right = FALSE)]
  SW[[paste(ch, WP$pre[k], WP$post[k])]] <- X[, .(N = .N, dy = mean(dy), se_dy = sd(dy) / sqrt(.N), dlf = mean(dlf, na.rm = TRUE), se_dlf = sd(dlf, na.rm = TRUE) / sqrt(sum(!is.na(dlf))), lvl = median(lvl_usd)), by = bin]
}
RL <- list()
for (i in seq_len(nrow(evl))) {
  e <- evl[i]
  M <- merge(SW[[paste(e$chain, e$pre, e$post)]], SW[[paste(e$chain, "placebo_pre", "placebo_post")]], by = "bin", suffixes = c("", "_pl"))
  M[, `:=`(event = e$name, did_y = dy - dy_pl, se_y = sqrt(se_dy^2 + se_dy_pl^2), did_f = dlf - dlf_pl, se_f = sqrt(se_dlf^2 + se_dlf_pl^2))]
  M[, `:=`(elasticity = did_y / did_f, se_el = abs(did_y / did_f) * sqrt((se_y / did_y)^2 + (se_f / did_f)^2))]
  RL[[i]] <- M[order(bin)]
}
RL <- rbindlist(RL)
cat("## E. Response by pre-drop fee level; elasticity = did_y / did_f\n")
print(RL[, .(event, bin, N, lvl = signif(lvl, 2), did_y = round(did_y, 3), se_y = round(se_y, 3), did_f = round(did_f, 2), elasticity = round(elasticity, 3), se_el = round(se_el, 3))])
# Intensive margin per event (Table 3): sender-weighted mean of the bin elasticities, bins with N >= 500. Bins hold disjoint senders (and disjoint placebo
# senders), so the estimates are independent:  e = sum_b w_b e_b,  w_b = N_b / sum N,  SE = sqrt(sum_b w_b^2 SE_b^2).
WSE <- RL[N >= 500, .(senders = sum(N), bins = .N, elasticity = sum(N * elasticity) / sum(N), se = sqrt(sum((N / sum(N))^2 * se_el^2)), bin_min = min(elasticity), bin_max = max(elasticity)), by = event]
cat("## E. Within-sender elasticity per event (sender-weighted over bins with N >= 500)\n"); print(WSE); fwrite(WSE, file.path(DIR_TAB, "within_sender_elasticity.csv"))
fwrite(RL[, c(list(event = event, bin = bin, N = N, fee_level_usd = lvl), .SD), .SDcols = c("did_y", "se_y", "did_f", "se_f", "elasticity", "se_el", "dy", "se_dy", "dlf", "se_dlf", "N_pl", "dy_pl", "se_dy_pl", "dlf_pl", "se_dlf_pl")],
       file.path(DIR_TAB, "response_by_fee_level.csv"))
# Figure: elasticity by the sender's pre-drop fee level (bins with >= 500 senders)
# Confidence intervals beyond +-0.12 are cut at the panel edge and marked with an arrow.
lim <- 0.12
FL <- RL[N >= 500][, `:=`(label = factor(EVENTS$label[match(event, EVENTS$event)], EVENTS$label), lo = pmax(elasticity - 1.96 * se_el, -lim), hi = pmin(elasticity + 1.96 * se_el, lim))]
g <- ggplot(FL, aes(lvl, elasticity)) + geom_hline(yintercept = 0, colour = COL[["ink2"]], linewidth = 0.3) +
  geom_linerange(aes(ymin = lo, ymax = hi), colour = COL[["main"]], linewidth = 0.6) + geom_point(colour = COL[["main"]], size = 2.2) +
  geom_segment(data = FL[elasticity + 1.96 * se_el > lim], aes(x = lvl, xend = lvl, y = lim - 0.01, yend = lim), colour = COL[["main"]], linewidth = 0.6, arrow = arrow(length = unit(5, "pt"))) +
  facet_wrap(~ label, nrow = 1) + scale_x_log10(labels = scales::dollar, breaks = c(0.03, 0.1, 0.3, 1)) + coord_cartesian(ylim = c(-lim, lim)) +
  labs(x = "Sender's fee per transaction before the drop (US$, log scale; bin median)", y = "Elasticity of the sender's transactions\nwith respect to the fee (95% CI)") + THEME_FIG
ggsave(file.path(DIR_FIG, "elasticity_by_fee_level.png"), g, width = 10, height = 3.6, dpi = 200, bg = "white")

# ---- F. validation of the burst construct (thresholds in 00_setup.R) ----
# Composition windows as in section C: pre = 03-08..12; post = 03-14..21 (Base) or 03-15..21 (Arbitrum). Classes by rule: bot-like first, then campaign.
# Rules: main burst rule; bound 1 (size only); bound 2 with the corrected funder (first funder before the first outgoing tx).
# Day-block bootstrap: BOOT_REPS draws of entry days with replacement within each period (seed SEED).
rules2 <- c(wave = "main: burst vs own pre-shock level", wave_size = sprintf("bound 1: size only (>= %s a day)", format(WAVE_SIZE_ALT, big.mark = ",")),
            wave_funded2 = "bound 2: burst funded by bursting funders (corrected funder)")
EV <- E[!is.na(wave)][, period := fcase(day <= as.IDate("2024-03-12"), "pre", day >= as.IDate(fifelse(chain == "base", "2024-03-14", "2024-03-15")), "post", default = NA_character_)][!is.na(period)]
for (h in HUB_MIN) EV[, (paste0("clu", h)) := as.integer(get(paste0("csize", h)) >= CLUSTER_MIN)]
EV[, `:=`(cluF = as.integer(csizeF500 >= CLUSTER_MIN), cluX = as.integer(clu500 == 1 & in_largest500 == 0))]   # sensitivity: funder edges only; largest component excluded
# V1 and V2a, per chain x rule x period:
#   P_k(y) = sum_d y_kd / sum_d n_kd for class k (campaign, genuine, bot) and y = on LayerZero list (lz), funder on list (funder_lz), in a component of >= 20 (clu)
#   ratio = P_campaign(lz) / P_genuine(lz) (V1 primary: Base, main rule, post); diff = P_campaign(clu500) - P_genuine(clu500) (V2a primary: same cell)
VV <- list()
for (ch in CHAINS) for (v in names(rules2)) for (pd in c("pre", "post")) {
  Z <- EV[chain == ch & period == pd][, cls := fcase(bot_wk1 == 1, "bot", get(v) == 1, "campaign", default = "genuine")]
  DY <- Z[, .(n = .N, lz = sum(lz), nf = sum(!is.na(funder_lz)), flz = sum(funder_lz, na.rm = TRUE), c200 = sum(clu200), c500 = sum(clu500), c2000 = sum(clu2000), cF = sum(cluF), cX = sum(cluX),
              sync = sum(sync)), by = .(day, cls)]
  DY <- dcast(DY, day ~ cls, value.var = c("n", "lz", "nf", "flz", "c200", "c500", "c2000", "cF", "cX", "sync"), fill = 0)
  for (k in c("campaign", "genuine", "bot")) for (s in c("n", "lz", "nf", "flz", "c200", "c500", "c2000", "cF", "cX", "sync")) if (!paste(s, k, sep = "_") %in% names(DY)) DY[, (paste(s, k, sep = "_")) := 0]
  ratio <- (sum(DY$lz_campaign) / sum(DY$n_campaign)) / (sum(DY$lz_genuine) / sum(DY$n_genuine))
  diff <- sum(DY$c500_campaign) / sum(DY$n_campaign) - sum(DY$c500_genuine) / sum(DY$n_genuine)
  set.seed(SEED); bs <- matrix(NA_real_, BOOT_REPS, 2)
  for (b in seq_len(BOOT_REPS)) { s <- DY[sample(.N, replace = TRUE)]
    bs[b, ] <- c((sum(s$lz_campaign) / sum(s$n_campaign)) / (sum(s$lz_genuine) / sum(s$n_genuine)), sum(s$c500_campaign) / sum(s$n_campaign) - sum(s$c500_genuine) / sum(s$n_genuine)) }
  VV[[length(VV) + 1]] <- data.table(chain = ch, rule = rules2[[v]], period = pd, days = nrow(DY),
    n_campaign = sum(DY$n_campaign), n_genuine = sum(DY$n_genuine), n_bot = sum(DY$n_bot),
    lz_campaign = sum(DY$lz_campaign) / sum(DY$n_campaign), lz_genuine = sum(DY$lz_genuine) / sum(DY$n_genuine), lz_bot = sum(DY$lz_bot) / sum(DY$n_bot),
    lz_ratio = ratio, lz_ratio_lo = quantile(bs[, 1], .025, na.rm = TRUE), lz_ratio_hi = quantile(bs[, 1], .975, na.rm = TRUE),
    funder_lz_campaign = sum(DY$flz_campaign) / sum(DY$nf_campaign), funder_lz_genuine = sum(DY$flz_genuine) / sum(DY$nf_genuine),
    clu200_campaign = sum(DY$c200_campaign) / sum(DY$n_campaign), clu200_genuine = sum(DY$c200_genuine) / sum(DY$n_genuine),
    clu500_campaign = sum(DY$c500_campaign) / sum(DY$n_campaign), clu500_genuine = sum(DY$c500_genuine) / sum(DY$n_genuine),
    clu500_diff = diff, clu500_diff_lo = quantile(bs[, 2], .025, na.rm = TRUE), clu500_diff_hi = quantile(bs[, 2], .975, na.rm = TRUE),
    clu2000_campaign = sum(DY$c2000_campaign) / sum(DY$n_campaign), clu2000_genuine = sum(DY$c2000_genuine) / sum(DY$n_genuine),
    cluF_campaign = sum(DY$cF_campaign) / sum(DY$n_campaign), cluF_genuine = sum(DY$cF_genuine) / sum(DY$n_genuine),
    cluX_campaign = sum(DY$cX_campaign) / sum(DY$n_campaign), cluX_genuine = sum(DY$cX_genuine) / sum(DY$n_genuine),
    sync_campaign = sum(DY$sync_campaign) / sum(DY$n_campaign), sync_genuine = sum(DY$sync_genuine) / sum(DY$n_genuine))
}
VV <- rbindlist(VV)
cat("## F. V1 (LayerZero list) and V2a (components of >= 20 entrants), by chain, rule and period; ratio and diff with day-bootstrap 95% CIs\n"); print(VV)
fwrite(VV, file.path(DIR_TAB, "val_lz_clusters.csv"))
# V2b: address vs entity growth by class (main rule):
#   address ratio = (entrants per day, post) / (entrants per day, pre); entity ratio = (mean daily number of distinct components, post) / (same, pre)
#   gap = log(address ratio) - log(entity ratio); 95% CI from BOOT_REPS draws of days within each period
EG <- list()
for (ch in CHAINS) for (h in HUB_MIN) {
  Z <- EV[chain == ch][, cls := fcase(bot_wk1 == 1, "bot", wave == 1, "campaign", default = "genuine")]
  for (k in c("all", "campaign", "genuine")) {
    DY <- Z[, .(n = sum(k == "all" | cls == k), ent = uniqueN(get(paste0("cid", h))[k == "all" | cls == k])), by = .(period, day)]   # days without such entrants count as zero
    pre <- DY[period == "pre"]; post <- DY[period == "post"]
    ar <- mean(post$n) / mean(pre$n); er <- mean(post$ent) / mean(pre$ent)
    set.seed(SEED); bs <- numeric(BOOT_REPS)
    for (b in seq_len(BOOT_REPS)) { po <- post[sample(.N, replace = TRUE)]; pr <- pre[sample(.N, replace = TRUE)]; bs[b] <- log(mean(po$n) / mean(pr$n)) - log(mean(po$ent) / mean(pr$ent)) }
    EG[[length(EG) + 1]] <- data.table(chain = ch, service_threshold = h, class = k, addr_per_day_pre = mean(pre$n), addr_per_day_post = mean(post$n), ent_per_day_pre = mean(pre$ent),
                                       ent_per_day_post = mean(post$ent), address_ratio = ar, entity_ratio = er, log_gap = log(ar) - log(er),
                                       log_gap_lo = quantile(bs[is.finite(bs)], .025), log_gap_hi = quantile(bs[is.finite(bs)], .975), finite_draws = mean(is.finite(bs)))   # draws with no pre-period entrants are undefined
  }
}
EG <- rbindlist(EG)
cat("## F. V2b address vs entity growth (main rule), by service threshold\n"); print(EG); fwrite(EG, file.path(DIR_TAB, "val_entity_growth.csv"))
cat("## F. Corrected funder: share of window entrants with a funder before the first outgoing tx, and how the ETH funder was found\n")
print(EV[, .(funder_seen = mean(funder2_seen), eth_top_level = mean(f_eth_via %in% "top-level"), eth_internal = mean(f_eth_via %in% "internal")), by = .(chain, period)])

# V3 (descriptive): entrants per hour by class, 03-08..21, with the fee drops and the Dencun-related events
HC <- E[!is.na(wave), .N, by = .(chain, hr, cls = fcase(class3 == "bot", "Bot-like", class3 == "campaign", "Burst account", default = "Non-burst"))]
HC <- HC[CJ(chain = CHAINS, hr = seq(as.POSIXct(ENTRANT_WINDOW[1], tz = "UTC"), as.POSIXct(ENTRANT_WINDOW[2] + 1, tz = "UTC") - 3600, by = 3600), cls = c("Non-burst", "Burst account", "Bot-like")),
         on = .(chain, hr, cls)][is.na(N), N := 0][, cls := factor(cls, c("Non-burst", "Burst account", "Bot-like"))]
MK <- rbind(data.table(chain = CHAINS, t = as.POSIXct("2024-03-13 13:55", tz = "UTC"), what = "L1 Dencun fork"),
            data.table(chain = "base", t = as.POSIXct("2024-03-13 16:26", tz = "UTC"), what = "'EIP-4844 is Based' mint deployed"),
            EVENTS[, .(chain, t = t0, what = event)])
HC[, chain_lab := factor(fifelse(chain == "base", "Base", "Arbitrum"), c("Base", "Arbitrum"))]; MK[, chain_lab := factor(fifelse(chain == "base", "Base", "Arbitrum"), c("Base", "Arbitrum"))]
g <- ggplot(HC, aes(hr, N + 1, colour = cls)) + geom_vline(data = MK, aes(xintercept = t), colour = COL[["ink2"]], linewidth = 0.3, linetype = "dashed") +
  geom_line(linewidth = 0.4) + facet_wrap(~ chain_lab, ncol = 1) + scale_y_log10(labels = scales::comma) +
  scale_colour_manual(values = c(COL[["ref"]], COL[["main"]], COL[["ink"]])) + scale_x_datetime(date_breaks = "2 days", date_labels = "%d %b") +
  labs(x = NULL, y = "Entrants per hour + 1 (log scale)") + THEME_FIG
ggsave(file.path(DIR_FIG, "entrants_by_class_hourly_march.png"), g, width = 10, height = 5.6, dpi = 200, bg = "white")
cat("## F. V3 event markers (dashed lines in the hourly entrants figure)\n"); print(MK[, .(chain, t, what)])

# V4 (descriptive): Base burst groups after the drop by target type. Contract = the target emitted logs on 03-13..22 (01 section L);
# type: zero-value or native transfer to an account without code; NFT mint or badge (ERC-721 Transfer events); token transfer or claim (ERC-20 Transfer events); other.
CT <- PNL$campaign_targets
CG <- EV[chain == "base" & period == "post" & wave == 1, .(N = .N, days = uniqueN(day), months5 = mean(months5), lz = mean(lz), clu500 = mean(clu500), sync = mean(sync),
                                                            single_tx_wk1 = mean(single_tx_wk1)), by = .(first_to, first_sel)]
CG <- merge(CG, CT[, .(first_to = addr, contract, n_721, n_20)], by = "first_to", all.x = TRUE)
CG[, type := fcase(is.na(contract), "unclassified", contract == 0 & first_sel == "0x", "native or zero-value transfer to an account without code", contract == 1 & n_721 > 0, "NFT mint or badge",
                   contract == 1 & n_20 > 0, "token transfer or claim", default = "other")]
cat("## F. V4 Base burst entrants after the drop by target type\n")
print(CG[, .(groups = .N, entrants = sum(N), share = sum(N) / CG[, sum(N)], months5 = weighted.mean(months5, N), lz = weighted.mean(lz, N), clu500 = weighted.mean(clu500, N),
             sync = weighted.mean(sync, N)), by = type][order(-entrants)])
cat("## F. V4 largest 20 Base burst groups after the drop\n"); print(CG[order(-N)][1:min(20, .N)])
fwrite(CG[order(-N)], file.path(DIR_TAB, "val_campaign_targets_base.csv"))

# V5 (descriptive): Google Trends, worldwide daily search interest. Main reading: March 2024 sum of "Base airdrop" vs "Arbitrum airdrop" on the shared scale.
GT <- PNL$gtrends_daily
cat("## F. V5 Google Trends: sums by month and the peak day of each series (shared = one request with all four terms, common scale)\n")
GTS <- merge(dcast(GT[, .(v = sum(value)), by = .(request, keyword, month = format(date, "%Y-%m"))], request + keyword ~ month, value.var = "v"),
             GT[, .(peak_date = date[which.max(value)], peak = max(value), days_nonzero = sum(value > 0)), by = .(request, keyword)], by = c("request", "keyword"))
print(GTS); fwrite(GTS, file.path(DIR_TAB, "val_google_trends.csv"))

# V6 (accounting): daily fee revenue, L1 rent and profit (growthepie, US$), 7-day means before and after each drop, and the cost of an identity
#   cost of an identity = m x p, m = median first-week txs of burst (or non-burst) entrants after the drop, p = median hourly fee per tx (US$) in the window
#   (section H prices identities with growthepie's daily median fee instead, the price used for all four cuts)
EC <- PNL$l2_economics_daily
win <- data.table(event = EVENTS$event, chain = EVENTS$chain, pre0 = as.IDate(c("2024-03-07", "2024-03-07", "2024-03-15")), pre1 = as.IDate(c("2024-03-13", "2024-03-13", "2024-03-18")),
                  post0 = as.IDate(c("2024-03-14", "2024-03-15", "2024-03-20")), post1 = as.IDate(c("2024-03-20", "2024-03-18", "2024-03-26")))
HU <- merge(l2_hourly[, .(n = sum(n), fee = sum(fee)), by = .(chain, hr)][, day := as.IDate(hr, tz = "UTC")], eth_usd_daily[, .(day, usd = close)], by = "day")[, fpt_usd := fee / n * usd]   # also used in H
V6 <- list()
for (i in seq_len(nrow(win))) {
  w <- win[i]; e0 <- EC[chain == w$chain & date >= w$pre0 & date <= w$pre1]; e1 <- EC[chain == w$chain & date >= w$post0 & date <= w$post1]
  p0 <- HU[chain == w$chain & day >= w$pre0 & day <= w$pre1, median(fpt_usd)]; p1 <- HU[chain == w$chain & day >= w$post0 & day <= w$post1, median(fpt_usd)]
  m_c <- EV[chain == w$chain & period == "post" & class3 == "campaign", median(n_week1)]; m_g <- EV[chain == w$chain & period == "post" & class3 == "genuine", median(n_week1)]
  V6[[i]] <- data.table(event = w$event, fees_pre = mean(e0$fees_usd), fees_post = mean(e1$fees_usd), rent_pre = mean(e0$rent_usd), rent_post = mean(e1$rent_usd),
                        profit_pre = mean(e0$profit_usd), profit_post = mean(e1$profit_usd), fee_per_tx_pre = p0, fee_per_tx_post = p1, m_campaign = m_c, m_genuine = m_g,
                        identity_cost_campaign_pre = m_c * p0, identity_cost_campaign_post = m_c * p1)
}
V6 <- rbindlist(V6)[, `:=`(dlog_fees = log(fees_post / fees_pre), dlog_rent = log(rent_post / rent_pre), margin_pre = profit_pre / fees_pre, margin_post = profit_post / fees_post)]
cat("## F. V6 fees, L1 rent and profit (US$ per day), fee per tx and the cost of an identity (US$)\n"); print(V6); fwrite(V6, file.path(DIR_TAB, "val_economics.csv"))

# ---- G. who runs the burst accounts, and does a second fee cut bring them again? ----
# Burst = campaign class (main rule, bot-like excluded); entity = funder-entrant-sweep component at service threshold 500 (section F).
# Concentration: share of Base post-cut entrants of a class in its largest 1 / 10 / 100 entities.
EP <- EV[chain == "base" & period == "post"]; G1 <- list()
for (k in c("campaign", "genuine")) { ce <- EP[class3 == k, .N, by = cid500][order(-N)]
  G1[[k]] <- data.table(class = k, entrants = sum(ce$N), entities = nrow(ce), top1 = ce$N[1] / sum(ce$N), top10 = sum(head(ce$N, 10)) / sum(ce$N), top100 = sum(head(ce$N, 100)) / sum(ce$N)) }
G1 <- rbindlist(G1); cat("## G. Concentration of Base post-cut entrants in the largest entities\n"); print(G1)
# Repeat entities: for each burst day d, share of that day's burst entrants whose entity already had burst entrants on an earlier day (from 03-08)
BB <- E[chain == "base" & !is.na(wave) & class3 == "campaign"]; G2 <- list()
for (d in sort(unique(BB[day >= as.IDate("2024-03-14"), day]))) { prev <- BB[day < d]; cur <- BB[day == d]
  G2[[length(G2) + 1]] <- data.table(day = as.IDate(d), burst_entrants = nrow(cur), entities = uniqueN(cur$cid500), repeat_entity_share = cur[, mean(cid500 %in% prev$cid500)],
                                     new_entities = cur[!(cid500 %in% prev$cid500), uniqueN(cid500)]) }
G2 <- rbindlist(G2); cat("## G. Base burst entrants by day: share from entities that had burst entrants earlier\n"); print(G2)
# Cross-chain: the entrant's address, or its non-service ETH funder, also appears among the other chain's window entrants / their funders
G3 <- EV[period == "post", .(entrants = .N, address_on_other_chain = mean(other_chain_addr), funder_seen = mean(!is.na(other_chain_funder)),
                             funder_on_other_chain = mean(other_chain_funder, na.rm = TRUE)), by = .(chain, class3)][order(chain, class3)]
cat("## G. Cross-chain presence of post-cut entrants and their funders\n"); print(G3)
# What Base post-cut entrants received after their first outgoing tx (to 04-15). Token names looked up on Blockscout (base.blockscout.com), 2026-10-12.
TOKN <- c("0xd7d919ea0c33a97ad6e7bd4f510498e2ec98cb78" = "PEN (memecoin, bulk airdrop)", "0xfc73b6b8de5a86311e6bb1fa5628dbd152849d90" = "'bloo foster coin' (phishing claim token)",
          "0x713eb9f3984f603789fe6f3c592a806f0f37849a" = "'AERO' (phishing claim token)", "0xcb50a5b07eca2230e45df637827cc69eaf8ac414" = "'BLAST2L.COM coupon' (phishing NFT)",
          "0x250db3fdfeba4cd5ea9727fe90a14cf1d1bad03c" = "'Toshi' (phishing claim token)", "0x5c5450fd644ddba94cee81439ef8d59d6a50470f" = "'Toshi' (phishing claim token)",
          "0x3e116e35fd29ddb14990429653c6fae5a903ec21" = "'Brett' (phishing claim token)")
G5 <- EP[, .(entrants = .N, received_tokens = mean(tok_after), received_eth = mean(eth_after)), by = class3]
cat("## G. Base post-cut entrants receiving tokens / ETH after entry\n"); print(G5)
RT5 <- PNL$receipts_by_token[class3 == "campaign"][order(-recipients)][1:min(10, .N)][, `:=`(share_of_burst = recipients / EP[class3 == "campaign", .N], name = TOKN[tok])]
cat("## G. Most common tokens received by burst entrants (all window days)\n"); print(RT5); cat("## G. Transfers sent by the largest burst target 0xfb10c1\n"); print(PNL$fb_sent)
fwrite(RT5, file.path(DIR_TAB, "burst_tokens_received_base.csv"))

# Second Base fee cut (platform raised the gas limit 05-28 19:00 and 05-30 20:00). Pre = 05-21..27, post = 05-29..06-04 (05-28 left out), 7 days each.
# March: pre = 03-08..12 (5 days), post = 03-14..21 (8 days). New = entrants with no earlier activity (March: since chain launch; May: since 02-15).
#   entry ratio_k = (entrants of class k per day, post) / (same, pre); wedge = all-entrant ratio / non-burst (genuine) ratio
MY <- PNL$may_entrants[chain == "base"][, period := fcase(day <= MAY_PRE_END, "pre", day >= MAY_PRE_END + 2, "post", default = NA_character_)][!is.na(period)]
CMP <- rbind(EV[chain == "base", .(n = .N), by = .(period, class3)][, `:=`(days = fifelse(period == "pre", 5, 8), event = "1. March 2024 (L1 data cost, Dencun)")],
             MY[, .(n = .N), by = .(period, class3)][, `:=`(days = 7, event = "2. May 2024 (gas limit raised by Base)")])
# Common definition for both events: all new senders with no outgoing tx since 02-15 (hourly panels), same windows
NS <- rbind(PNL$l2_newsenders[chain == "base", .(day = as.IDate(hr, tz = "UTC"), n = new_senders, event = "1. March 2024 (L1 data cost, Dencun)")][
              , period := fcase(day >= as.IDate("2024-03-08") & day <= as.IDate("2024-03-12"), "pre", day >= as.IDate("2024-03-14") & day <= ENTRANT_WINDOW[2], "post", default = NA_character_)],
            PNL$may_hourly[chain == "base", .(day = as.IDate(hr, tz = "UTC"), n = new_senders, event = "2. May 2024 (gas limit raised by Base)")][
              , period := fcase(day >= MAY_WINDOW[1] & day <= MAY_PRE_END, "pre", day >= MAY_PRE_END + 2 & day <= MAY_WINDOW[2], "post", default = NA_character_)])
CMP <- rbind(CMP, CMP[, .(n = sum(n), class3 = "all"), by = .(period, days, event)],
             NS[!is.na(period), .(n = sum(n), days = uniqueN(day), class3 = "all new senders (none since 02-15)"), by = .(event, period)], use.names = TRUE)[, per_day := n / days]
GM <- dcast(CMP, event + class3 ~ period, value.var = "per_day")[, `:=`(ratio = post / pre, added_per_day = post - pre)]
GM[, wedge := ratio[class3 == "all"] / ratio[class3 == "genuine"], by = event]
cat("## G. Entrants per day by class around the first (March) and second (May) Base fee cuts\n"); print(GM)
# May entrants: persistence (months active of 4 sampled months), multi-identity entities, and a one-hop link to a March burst operator (02 section H)
GMY <- MY[, .(entrants = .N, months4 = mean(months4), single_tx_wk1 = mean(n_week1 == 1), clu500 = mean(csize500 >= CLUSTER_MIN), march_operator = mean(march_operator)),
          by = .(period, class3)][order(period, class3)]
cat("## G. May entrants: persistence, entities, one-hop link to a March burst operator\n"); print(GMY)
cat(sprintf("March burst operators (non-service funders or sweep targets of >= %d March burst entrants): %d; active again in May: %d\n", CLUSTER_MIN,
            PNL$may_ops$march_burst_operators, PNL$may_ops$active_again_in_may))
# Common persistence horizon for both events: months active among Sep 2024, Dec 2024 and Mar 2025 (activity on days 1-10 of each month), by class and period.
# May entrants reach these months sooner after entry (3-10 months) than March entrants (6-12 months), which favours May.
PC <- rbind(EV[chain == "base", .(event = "1. March", period, class3, m3 = act_2024_09 + act_2024_12 + act_2025_03)], MY[, .(event = "2. May", period, class3, m3 = act_2024_09 + act_2024_12 + act_2025_03)])
PC <- PC[, .(entrants = .N, months_active_of3 = mean(m3), any_active = mean(m3 > 0)), by = .(event, period, class3)][order(event, -rank(period), class3)]
cat("## G. Persistence on a common horizon (Sep 2024, Dec 2024, Mar 2025), Base entrants by event, period and class\n"); print(PC)
fwrite(PC, file.path(DIR_TAB, "persistence_common_horizon_base.csv"))
cme <- MY[period == "post" & class3 == "campaign", .N, by = cid500][order(-N)]
cat(sprintf("May post-cut burst entrants: %d in %d entities; largest 10 hold %.3f, largest 100 %.3f\n", sum(cme$N), nrow(cme), sum(head(cme$N, 10)) / sum(cme$N), sum(head(cme$N, 100)) / sum(cme$N)))
# Who runs the burst accounts, one long table (table / key / v1-v3): March concentration (v2, v3 = share in the largest 10 / 100 entities), repeat entities by day,
# cross-chain presence, receipts after entry, May concentration, and March burst operators active again in May (v1 = operators, v2 = active again, v3 = share)
fwrite(rbindlist(list(G1[, .(table = "concentration", key = class, v1 = entrants, v2 = top10, v3 = top100)], G2[, .(table = "repeat_by_day", key = as.character(day), v1 = burst_entrants, v2 = repeat_entity_share, v3 = new_entities)],
             G3[, .(table = paste("cross_chain", chain), key = class3, v1 = entrants, v2 = address_on_other_chain, v3 = funder_on_other_chain)],
             G5[, .(table = "received_after_entry", key = class3, v1 = entrants, v2 = received_tokens, v3 = received_eth)],
             list(table = "concentration_may", key = "campaign", v1 = sum(cme$N), v2 = sum(head(cme$N, 10)) / sum(cme$N), v3 = sum(head(cme$N, 100)) / sum(cme$N)),
             list(table = "march_operators_in_may", key = "operators", v1 = PNL$may_ops$march_burst_operators, v2 = PNL$may_ops$active_again_in_may,
                        v3 = PNL$may_ops$active_again_in_may / PNL$may_ops$march_burst_operators))), file.path(DIR_TAB, "burst_operators_base.csv"))
fwrite(GM, file.path(DIR_TAB, "second_cut_entry_base.csv")); fwrite(GMY, file.path(DIR_TAB, "second_cut_entrants_base.csv"))
# What the burst accounts did first. First action of post-cut entrants on Base by 4-byte selector: native or zero-value transfer; DEX swap (SWAP_SELECTORS);
# mint or claim (CLAIM_MINT_SELECTORS); token transfer or approval; other contract call.
FA <- rbind(EV[chain == "base" & period == "post" & class3 != "bot", .(event = "1. March", class3, first_sel)], MY[period == "post" & class3 != "bot", .(event = "2. May", class3, first_sel)])
FA[, type := fcase(is.na(first_sel) | first_sel == "0x", "native or zero-value transfer", first_sel %in% SWAP_SELECTORS, "DEX swap", first_sel %in% CLAIM_MINT_SELECTORS, "mint or claim",
                   first_sel %in% c("0xa9059cbb", "0x095ea7b3"), "token transfer or approval", default = "other contract call")]
FA <- FA[, .N, by = .(event, class3, type)][, share := N / sum(N), by = .(event, class3)][order(event, class3, -N)]
cat("## G. First action of post-cut Base entrants by class and type\n"); print(FA); fwrite(FA, file.path(DIR_TAB, "first_actions_base.csv"))
# Largest May burst groups after the cut: target role where it is a canonical contract deployment, method signature from 4byte.directory (checked 2026-10-13)
TO_NAMES <- c("0x4752ba5dbc23f44d87826276bf6fd6b1c372ad24" = "Uniswap V2 Router02", "0x3fc91a3afd70395cd496c647d5a6cc9d4b2b7fad" = "Uniswap Universal Router",
              "0xdef1c0ded9bec7f1a1670819833240f027b25eff" = "0x Exchange Proxy")
SIGS <- c("0x" = "native or zero-value transfer", "0x7ff36ab5" = "swapExactETHForTokens", "0xb6f9de95" = "swapExactETHForTokensSupportingFeeOnTransferTokens",
          "0x24856bc3" = "execute(bytes,bytes[])", "0x3593564c" = "execute(bytes,bytes[],uint256)", "0x415565b0" = "transformERC20", "0x2f52ebb7" = "claim(uint256,bytes32[]) (Merkle airdrop)",
          "0x84bb1e42" = "claim(address,uint256,address,uint256,(bytes32[],uint256,uint256,address),bytes) (thirdweb drop)",
          "0xe0db3fcf" = "deposit(address,address,address,uint256,uint256,int64,uint32,bytes,uint256)", "0xa9059cbb" = "transfer(address,uint256)")
TG <- MY[period == "post" & class3 == "campaign", .(N = .N, days = uniqueN(day)), by = .(first_to, first_sel)][order(-N)][1:min(15, .N)]
TG[, `:=`(share = N / MY[period == "post" & class3 == "campaign", .N], target = TO_NAMES[first_to], method = SIGS[first_sel])]
cat("## G. Largest May burst groups after the cut (first recipient x method)\n"); print(TG); fwrite(TG, file.path(DIR_TAB, "burst_targets_may_base.csv"))
# Comparison chain for the second cut: Arbitrum, which changed no fees in May 2024; its entrants are classified with the same rules (02 section H).
# relative ratio_k = (Base entrants of class k per day, post / pre) / (Arbitrum, same); 95% CI from BOOT_REPS draws of days within each chain x window.
# Window variants: main; post ending 06-02 (Base's Onchain Summer opened on 06-03) or 05-30 (before its buildathon opened on 05-31); pre from 05-24 (after the spot ETH ETF approval on 05-23).
WV <- data.table(variant = c("main", "post to 06-02", "post to 05-30", "pre from 05-24"), pre0 = as.IDate(c("2024-05-21", "2024-05-21", "2024-05-21", "2024-05-24")), pre1 = MAY_PRE_END,
                 post0 = MAY_PRE_END + 2, post1 = as.IDate(c("2024-06-04", "2024-06-02", "2024-05-30", "2024-06-04")))
DY <- dcast(PNL$may_entrants[, .N, by = .(chain, day, class3)], chain + day ~ class3, value.var = "N", fill = 0)[, all := bot + campaign + genuine]
cat("## G. May entrants per day by chain and class\n"); print(dcast(DY, day ~ chain, value.var = c("campaign", "genuine")))
RW <- list()
for (i in seq_len(nrow(WV))) for (k in c("campaign", "genuine", "all")) {
  w <- WV[i]; pr <- DY[day >= w$pre0 & day <= w$pre1]; po <- DY[day >= w$post0 & day <= w$post1]
  xb0 <- pr[chain == "base"][[k]]; xb1 <- po[chain == "base"][[k]]; xa0 <- pr[chain == "arbitrum"][[k]]; xa1 <- po[chain == "arbitrum"][[k]]
  set.seed(SEED); bs <- numeric(BOOT_REPS)
  for (b in seq_len(BOOT_REPS)) bs[b] <- log(mean(sample(xb1, replace = TRUE)) / mean(sample(xb0, replace = TRUE))) - log(mean(sample(xa1, replace = TRUE)) / mean(sample(xa0, replace = TRUE)))
  RW[[length(RW) + 1]] <- data.table(variant = w$variant, pre = paste(w$pre0, w$pre1), post = paste(w$post0, w$post1), class3 = k, base_ratio = mean(xb1) / mean(xb0),
                                     arbitrum_ratio = mean(xa1) / mean(xa0), relative = (mean(xb1) / mean(xb0)) / (mean(xa1) / mean(xa0)),
                                     rel_lo = exp(quantile(bs[is.finite(bs)], .025)), rel_hi = exp(quantile(bs[is.finite(bs)], .975)))
}
RW <- rbindlist(RW)
cat("## G. Second cut: Base entry ratios relative to Arbitrum, by class and window variant (day-bootstrap 95% CI)\n"); print(RW); fwrite(RW, file.path(DIR_TAB, "second_cut_vs_arbitrum.csv"))
# Hourly entry by class at the five cuts: the RD of 04 (+-36 h, hour-of-day FE, side-specific trends, 1-hour donut, Newey-West SEs with 6 lags) on hourly entrant counts:
#   log(1 + N_kt) = a + b * Post_t + c1 * (t - t0) + c2 * (t - t0) * Post_t + hour-of-day FE + e_t,   k = burst accounts, non-burst entrants
HG <- rbind(CJ(chain = CHAINS, hr = seq(as.POSIXct(ENTRANT_WINDOW[1], tz = "UTC"), as.POSIXct(ENTRANT_WINDOW[2] + 1, tz = "UTC") - 3600, by = 3600), class3 = c("campaign", "genuine")),
            CJ(chain = "base", hr = seq(as.POSIXct(MAY_WINDOW[1], tz = "UTC"), as.POSIXct(MAY_WINDOW[2] + 1, tz = "UTC") - 3600, by = 3600), class3 = c("campaign", "genuine")))
HK <- rbind(E[!is.na(wave) & class3 != "bot", .N, by = .(chain, hr, class3)], PNL$may_entrants[chain == "base" & class3 != "bot", .N, by = .(chain, hr, class3)])[HG, on = .(chain, hr, class3)]
HK[is.na(N), N := 0][, `:=`(y = log1p(N), hod = hour(hr))]
EV5 <- rbind(EVENTS[, .(event, chain, t0)], EVENTS_MAY[, .(event, chain, t0)]); RK <- list()
for (i in seq_len(nrow(EV5))) for (k in c("campaign", "genuine")) {
  t0 <- EV5$t0[i]
  d <- HK[chain == EV5$chain[i] & class3 == k & hr >= t0 - 36 * 3600 & hr < t0 + 36 * 3600 & !(hr %in% c(t0 - 3600, t0))][, `:=`(post = as.integer(hr >= t0), tt = as.numeric(hr - t0, units = "days"))]
  f <- feols(y ~ post + tt + tt:post | hod, data = d, vcov = NW(6) ~ hr)
  RK[[length(RK) + 1]] <- data.table(event = EV5$event[i], class3 = k, jump = coef(f)[["post"]], se = se(f)[["post"]], per_hour_before = d[post == 0, mean(N)], per_hour_after = d[post == 1, mean(N)])
}
RK <- rbindlist(RK)
cat("## G. Hourly RD in log(1 + entrants per hour) by class at the five cuts\n"); print(RK); fwrite(RK, file.path(DIR_TAB, "entry_rd_by_class.csv"))
# Figure: entrants per hour by class around the May gas-limit increases (same layout as the March figure)
H6 <- PNL$may_entrants[chain == "base", .N, by = .(hr, cls = fcase(class3 == "bot", "Bot-like", class3 == "campaign", "Burst account", default = "Non-burst"))]
H6 <- H6[CJ(hr = seq(as.POSIXct(MAY_WINDOW[1], tz = "UTC"), as.POSIXct(MAY_WINDOW[2] + 1, tz = "UTC") - 3600, by = 3600), cls = c("Non-burst", "Burst account", "Bot-like")),
         on = .(hr, cls)][is.na(N), N := 0][, cls := factor(cls, c("Non-burst", "Burst account", "Bot-like"))]
g <- ggplot(H6, aes(hr, N + 1, colour = cls)) + geom_vline(xintercept = EVENTS_MAY$t0, colour = COL[["ink2"]], linewidth = 0.3, linetype = "dashed") + geom_line(linewidth = 0.4) +
  scale_y_log10(labels = scales::comma) + scale_colour_manual(values = c(COL[["ref"]], COL[["main"]], COL[["ink"]])) + scale_x_datetime(date_breaks = "2 days", date_labels = "%d %b") +
  labs(x = NULL, y = "Entrants per hour + 1 (log scale)") + THEME_FIG
ggsave(file.path(DIR_FIG, "entrants_by_class_hourly_may.png"), g, width = 10, height = 3.4, dpi = 200, bg = "white")
# Figure: Base entrants per hour by class around the two cuts on a common clock, days from the cut (March: 03-14 00:00; May: first step 05-28 19:00)
F2c <- rbind(HC[chain == "base", .(hr, cls, N, event = "A. First cut: March 2024 (L1 data cost)", t0 = EVENTS$t0[1])],
             H6[, .(hr, cls, N, event = "B. Second cut: May 2024 (gas limit raised by Base)", t0 = EVENTS_MAY$t0[1])])[, d := as.numeric(hr - t0, units = "days")][d >= -6 & d < 7]
g <- ggplot(F2c, aes(d, N + 1, colour = cls)) + geom_vline(xintercept = 0, colour = COL[["ink"]], linewidth = 0.4) +
  geom_vline(data = data.table(event = "B. Second cut: May 2024 (gas limit raised by Base)", x = as.numeric(EVENTS_MAY$t0[2] - EVENTS_MAY$t0[1], units = "days")), aes(xintercept = x),
             colour = COL[["ink2"]], linewidth = 0.3, linetype = "dashed") + geom_line(linewidth = 0.4) + facet_wrap(~ event, ncol = 1) +
  scale_y_log10(labels = scales::comma) + scale_x_continuous(breaks = seq(-6, 6, 2)) + scale_colour_manual(values = c(COL[["ref"]], COL[["main"]], COL[["ink"]])) +
  labs(x = "Days from the fee cut (May: first gas-limit step; dashed: second step)", y = "Base entrants per hour + 1 (log scale)") + THEME_FIG
ggsave(file.path(DIR_FIG, "entrants_by_class_two_cuts.png"), g, width = 10, height = 5.6, dpi = 200, bg = "white")

# ---- H. threshold mechanics: dollar stakes against frictions across four fee cuts (Base March and May; Arbitrum steps 1 and 2) ----
# Windows: Base March pre 03-08..12, post 03-14..21; Arbitrum step 1 pre 03-10..13, post 03-15..18; step 2 pre 03-15..18, post 03-20..21 (section D);
# Base May pre 05-21..27, post 05-29..06-04 (section G).
# p = the price a typical tx pays: median over the window's days of growthepie's daily median fee per tx (US$); dlp = log(p_pre) - log(p_post).
# (The mean fee per tx, fees / txs x ETH/USD, is reported alongside; after the May cut it is dominated by a few high-priority txs.)
# Individual entrant: q = median first-week txs of non-burst entrants before the cut; dollar stake of the cut = (p_pre - p_post) x q (Chetty 2012, eq. 17 in dollars).
# Operator: m = median first-week txs of burst accounts after the cut; identities per burst entity-day after the cut (median entity, and the entity of the
# average account = sum N^2 / sum N); stake = (p_pre - p_post) x m x identities.
# Entry response of class k: ratio_k = (entrants per day, post) / (entrants per day, pre), days without entrants counted as zero; 95% CI from BOOT_REPS
# draws of days within each window (draws with no pre-period entrants dropped).
# Value of an identity: cost per identity c = m x p; operators that enter only after the cut break even at a value per identity in [c_post, c_pre).
EVT <- data.table(event = c("Base, March 2024 (L1 cost pass-through)", "Arbitrum step 1 (L1 cost pass-through)", "Arbitrum step 2 (fee floor cut by the platform)",
                            "Base, May 2024 (capacity raised by the platform)"), short = c("Base Mar", "Arb 1", "Arb 2", "Base May"),
                  chain = c("base", "arbitrum", "arbitrum", "base"), src = c("mar", "mar", "mar", "may"),
                  pre0 = as.IDate(c("2024-03-08", "2024-03-10", "2024-03-15", "2024-05-21")), pre1 = as.IDate(c("2024-03-12", "2024-03-13", "2024-03-18", "2024-05-27")),
                  post0 = as.IDate(c("2024-03-14", "2024-03-15", "2024-03-20", "2024-05-29")), post1 = as.IDate(c("2024-03-21", "2024-03-18", "2024-03-21", "2024-06-04")))
HY <- merge(PNL$may_hourly[chain == "base"][, day := as.IDate(hr, tz = "UTC")], PNL$eth_usd_daily_may[, .(day, usd = close)], by = "day")[, fpt_usd := fee / n * usd]
GD <- PNL$multichain_daily
TH <- list()
for (i in seq_len(nrow(EVT))) {
  w <- EVT[i]; H <- if (w$src == "mar") HU[chain == w$chain] else HY
  X <- if (w$src == "mar") E[chain == w$chain & !is.na(wave)] else PNL$may_entrants[chain == "base"]
  X <- X[(day >= w$pre0 & day <= w$pre1) | (day >= w$post0 & day <= w$post1)][, period := fifelse(day <= w$pre1, "pre", "post")]
  p0 <- GD[chain == w$chain & date >= w$pre0 & date <= w$pre1, median(cost)]; p1 <- GD[chain == w$chain & date >= w$post0 & date <= w$post1, median(cost)]
  q <- X[period == "pre" & class3 == "genuine", median(n_week1)]; m <- X[period == "post" & class3 == "campaign", median(n_week1)]
  IE <- X[period == "post" & class3 == "campaign", .N, by = .(day, cid500)]; aw <- sum(IE$N^2) / sum(IE$N)
  BE <- X[class3 == "campaign", .(ent = uniqueN(cid500), acc = .N), by = .(period, day)]
  DD <- dcast(X[class3 != "bot", .N, by = .(day, class3)], day ~ class3, value.var = "N", fill = 0)
  DD <- merge(data.table(day = c(seq(w$pre0, w$pre1, by = 1), seq(w$post0, w$post1, by = 1))), DD, by = "day", all.x = TRUE)[, period := fifelse(day <= w$pre1, "pre", "post")]
  for (v in c("campaign", "genuine")) { if (!v %in% names(DD)) DD[, (v) := 0]; DD[is.na(get(v)), (v) := 0] }
  pr <- DD[period == "pre"]; po <- DD[period == "post"]
  set.seed(SEED); bs <- matrix(NA_real_, BOOT_REPS, 2)
  for (b in seq_len(BOOT_REPS)) { a0 <- pr[sample(.N, replace = TRUE)]; a1 <- po[sample(.N, replace = TRUE)]
    bs[b, ] <- c(log(mean(a1$genuine) / mean(a0$genuine)), log(mean(a1$campaign) / mean(a0$campaign))) }
  TH[[i]] <- data.table(event = w$event, short = w$short, p_pre = p0, p_post = p1, dlp = log(p0) - log(p1), p_mean_pre = H[day >= w$pre0 & day <= w$pre1, median(fpt_usd)],
    p_mean_post = H[day >= w$post0 & day <= w$post1, median(fpt_usd)], q_nonburst = q, stake_individual = (p0 - p1) * q,
    m_burst = m, ids_per_entity_day_median = median(IE$N), ids_per_entity_day_acct_weighted = aw, stake_operator_median = (p0 - p1) * m * median(IE$N), stake_operator_acct_weighted = (p0 - p1) * m * aw,
    nonburst_ratio = po[, mean(genuine)] / pr[, mean(genuine)], nonburst_lo = exp(quantile(bs[is.finite(bs[, 1]), 1], .025)), nonburst_hi = exp(quantile(bs[is.finite(bs[, 1]), 1], .975)),
    burst_ratio = po[, mean(campaign)] / pr[, mean(campaign)], burst_lo = exp(quantile(bs[is.finite(bs[, 2]), 2], .025)), burst_hi = exp(quantile(bs[is.finite(bs[, 2]), 2], .975)),
    burst_finite_draws = mean(is.finite(bs[, 2])), cost_identity_pre = m * p0, cost_identity_post = m * p1,
    burst_entities_per_day_pre = sum(BE[period == "pre", ent]) / nrow(pr), burst_entities_per_day_post = sum(BE[period == "post", ent]) / nrow(po),
    burst_accounts_per_day_pre = pr[, mean(campaign)], burst_accounts_per_day_post = po[, mean(campaign)])
}
TH <- rbindlist(TH)[, eta_nonburst := log(nonburst_ratio) / dlp]
cat("## H. Fee per tx (median; mean in p_mean_*), dollar stakes of each cut, and entry responses with day-bootstrap 95% CIs\n")
print(TH[, .(short, p_pre, p_post, dlp, p_mean_pre, p_mean_post, q_nonburst, stake_individual, nonburst_ratio, nonburst_lo, nonburst_hi, eta_nonburst)])
print(TH[, .(short, m_burst, ids_per_entity_day_median, ids_per_entity_day_acct_weighted, stake_operator_acct_weighted, burst_ratio, burst_lo, burst_hi, burst_finite_draws)])
# Friction bounds on the extensive-margin elasticity of non-burst entry (Chetty 2012, Proposition 2) for the two Base cuts, delta = frictions as a share of expenditure:
#   rho_k = 2 delta / dlp_k;  eta_L,k = eta_hat_k / (1 + rho_k);  eta_U,k = eta_hat_k / (1 - rho_k) if rho_k < 1, else unbounded
#   delta_min = smallest delta at which the two events' bounds overlap (max_k eta_L,k <= min_k eta_U,k); eta at delta_min = sum_k dlp_k eta_hat_k / sum_k dlp_k (Chetty eq. 18)
TB <- TH[short %in% c("Base Mar", "Base May")]
DG <- data.table(delta = seq(0, 3, by = 0.001))
for (i in 1:2) DG[, (paste0(c("L", "U"), i)) := list(TB$eta_nonburst[i] / (1 + 2 * delta / TB$dlp[i]), fifelse(2 * delta / TB$dlp[i] < 1, TB$eta_nonburst[i] / (1 - 2 * delta / TB$dlp[i]), Inf))]
dmin <- DG[pmax(L1, L2) <= pmin(U1, U2), min(delta)]
cat(sprintf("Chetty delta_min (frictions as a share of fee spending) reconciling the two Base cuts: %.3f; eta at delta_min: %.3f\n", dmin, sum(TB$dlp * TB$eta_nonburst) / sum(TB$dlp)))
# Dollar frictions F per individual entrant: a near-zero response is possible only if the stake <= 2F (Chetty Corollary 2), a response is guaranteed if the stake > 2F.
FB <- c(TB[short == "Base May", stake_individual] / 2, TB[short == "Base Mar", stake_individual] / 2)
cat(sprintf("Dollar frictions per individual entrant consistent with both Base cuts (response in March, none in May): F in [%.3f, %.3f) US$\n", FB[1], FB[2]))
# Value of an identity (entry thresholds): operators entering after the cut break even in [c_post, c_pre); density = added burst entities (accounts) per day per US$0.01 of the band
VB <- TH[, .(short, band_low = cost_identity_post, band_high = cost_identity_pre, added_entities_per_day = burst_entities_per_day_post - burst_entities_per_day_pre,
             added_accounts_per_day = burst_accounts_per_day_post - burst_accounts_per_day_pre)][, `:=`(entities_per_cent = added_entities_per_day / ((band_high - band_low) * 100),
                                                                                                      accounts_per_cent = added_accounts_per_day / ((band_high - band_low) * 100))]
cat("## H. Value of an identity: break-even band unlocked by each cut and the added burst operators / accounts\n"); print(VB)
fwrite(TH, file.path(DIR_TAB, "threshold_stakes.csv")); fwrite(VB, file.path(DIR_TAB, "identity_value_bands.csv"))
# Table 1 (paper): the fee cuts, their timing and origin, and the median fee per tx in the windows used for entry comparisons
T1E <- data.table(short = TH$short, time_utc = c(format(EVENTS$t0, "%Y-%m-%d %H:00"), paste(format(EVENTS_MAY$t0, "%Y-%m-%d %H:00"), collapse = " and ")),
                  origin = c("Ethereum Dencun (EIP-4844) passed through: Base Ecotone upgrade", "Ethereum Dencun passed through: Arbitrum ArbOS 20", "Arbitrum governance: minimum L2 base fee 0.1 to 0.01 gwei",
                             "Base raised the block gas limit 60M to 75M to 90M (capacity)"),
                  set_by = c("cost pass-through", "cost pass-through", "platform", "platform"))
T1E <- merge(T1E, TH[, .(short, median_fee_pre = p_pre, median_fee_post = p_post, dlog_fee = -dlp, stake_individual, stake_operator_acct_weighted)], by = "short")[order(match(short, TH$short))]
cat("## H. Table 1: the fee cuts\n"); print(T1E); fwrite(T1E, file.path(DIR_TAB, "table1_fee_cuts.csv"))
# Platform economics of the four cuts (growthepie, US$ per day): fee revenue, L1 rent (data costs) and profit, mean over each window's days
#   dlog_x = log(mean x post) - log(mean x pre); margin = profit / fees
ECO <- list()
for (i in seq_len(nrow(EVT))) { w <- EVT[i]; e0 <- PNL$l2_economics_daily[chain == w$chain & date >= w$pre0 & date <= w$pre1]; e1 <- PNL$l2_economics_daily[chain == w$chain & date >= w$post0 & date <= w$post1]
  ECO[[i]] <- data.table(short = w$short, set_by = T1E[short == w$short, set_by], fees_pre = mean(e0$fees_usd), fees_post = mean(e1$fees_usd), rent_pre = mean(e0$rent_usd), rent_post = mean(e1$rent_usd),
                         profit_pre = mean(e0$profit_usd), profit_post = mean(e1$profit_usd)) }
ECO <- rbindlist(ECO)[, `:=`(dlog_fees = log(fees_post / fees_pre), dlog_rent = log(rent_post / rent_pre), dlog_profit = log(profit_post / profit_pre), margin_pre = profit_pre / fees_pre, margin_post = profit_post / fees_post)]
cat("## H. Platform economics of the four cuts (US$ per day)\n"); print(ECO); fwrite(ECO, file.path(DIR_TAB, "platform_economics.csv"))
cat("\n## sessionInfo\n```\n"); print(sessionInfo()); cat("```\n"); sink()
