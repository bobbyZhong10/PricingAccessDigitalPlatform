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
#  I  robustness of the composition results: hourly entry with classes fixed in time (RI), address vs entity growth under alternative linkage rules,
#     leave-one-out (largest burst day, target, component; size-only rule)
#  J  the 20 largest burst groups (March, May), look-alike addresses (address poisoning), the largest target's share of daily active addresses,
#     the cost of a manufactured address, non-burst entry at the four cuts with one estimator (dollars vs log fee)
#  K  2024-01..06, one definition of a new address on both chains: waves of new addresses before and after the fee regime changed (placebo dates), the same
#     against Ethereum L1 as a comparison chain without a fee cut, and entry outside waves at the four cuts against placebo windows
#  L  the Base March entry effect against L1: daily event study, window ratios against pre-cut and all placebo dates, delay vs new entry, persistence
#  M  where the extra non-burst entrants' first ETH came from (exchanges, bridges, individuals), cross-chain entry, funding clusters and entities
#  N  both Base cuts with one estimator against L1 and Arbitrum (placebo sets, p floors, non-overlapping windows); funding entities behind May entry
#  O  May waves day by day; Base against OP Mainnet (growthepie)
#  P  the cut hour by outcome and estimator; matched hours against not-yet-cut Arbitrum
#  Q  funding entities behind non-burst entry: accounting variants and the composition deflator; the implied entity effect
#  R  headline numbers from one sample; inference for the primary statistic (6 low-fee days, 7 days, the 4-7-day path; largest placebos; wave and
#     burst size floors); designs that fail in different ways; entrant classes on equal 6-day windows
#  S  the cut hour with pre-cut fake hours; checks against a Base-specific demand shock (first recipients and their categories, Base minus OP adjusted,
#     the ETH rally, the cut day in blocks of hours, first actions)
#  T  the four cuts in one table (jump at the hour, entry minus L1 up to each chain's next cut)
#  U  the daily fee path on four chains; the March cut on OP Mainnet against L1; a donor pool of chains without a fee cut against the L1 comparison
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

# ---- I. robustness of the composition results: classes fixed in time, entities under alternative linkage rules, leave-one-out ----
# I1. Classes fixed in time. The burst rule labels whole UTC days and Base's March cut is at 00:00 UTC, so a group's entrants before midnight can be labelled
# non-burst and those after it burst. Here a first-action group (recipient x method) is a burst group if it bursts on any day of its window, and its entrants
# (bot-like excluded) count as burst-group entrants in every hour. Hourly RD as in section G, on log(1 + entrants per hour) of class g:
#   log(1 + N_gt) = a + b * Post_t + c1 * (t - t0) + c2 * (t - t0) * Post_t + hour-of-day FE + e_t,   +-36 h, 1-hour donut, Newey-West SEs (6 lags)
#   g = burst-group entrants; the same without the commemorative mint (Base, March); other entrants.
# RI: the same regression at fake hours on a 6-hour grid whose +-36 h window lies inside the entrant window and that are more than 36 h from every cut in it;
# p = (1 + #{fake |b| >= |b|}) / (1 + K), K fakes.
MINT <- "0x273ca93a52b817294830ed7572aa591ccfa647fd"   # "EIP-4844 is Based" mint, deployed 03-13 16:26 (section F, V3)
GI <- rbind(E[!is.na(wave) & class3 != "bot", .(win = "march", chain, hr, pair = paste(first_to, first_sel), first_to, wave)],
            PNL$may_entrants[chain == "base" & class3 != "bot", .(win = "may", chain, hr, pair = paste(first_to, first_sel), first_to, wave)])
GI[, grp := fifelse(any(wave == 1), "burst group", "other"), by = .(win, chain, pair)]
CLS <- c("burst group", "burst group without the mint", "other")
HI <- rbind(GI[, .N, by = .(win, chain, hr, cls = grp)], GI[grp == "burst group" & first_to != MINT, .N, by = .(win, chain, hr)][, cls := "burst group without the mint"])
LIM <- list(march = as.POSIXct(c(ENTRANT_WINDOW[1], ENTRANT_WINDOW[2] + 1), tz = "UTC"), may = as.POSIXct(c(MAY_WINDOW[1], MAY_WINDOW[2] + 1), tz = "UTC"))
HI <- HI[rbind(CJ(win = "march", chain = CHAINS, hr = seq(LIM$march[1], LIM$march[2] - 3600, by = 3600), cls = CLS), CJ(win = "may", chain = "base", hr = seq(LIM$may[1], LIM$may[2] - 3600, by = 3600), cls = CLS)),
         on = .(win, chain, hr, cls)][is.na(N), N := 0][, `:=`(y = log1p(N), hod = hour(hr))]
EV5w <- rbind(EVENTS[, .(event, chain, t0, win = "march")], EVENTS_MAY[, .(event, chain, t0, win = "may")]); RI1 <- list()
for (i in seq_len(nrow(EV5w))) for (k in CLS) {
  w <- EV5w$win[i]; cd <- seq(LIM[[w]][1] + 36 * 3600, LIM[[w]][2] - 36 * 3600, by = 6 * 3600); far <- rep(TRUE, length(cd))
  for (j in which(EV5w$win == w)) far <- far & abs(as.numeric(cd - EV5w$t0[j], units = "hours")) > 36
  times <- c(EV5w$t0[i], cd[far]); b <- s <- rep(NA_real_, length(times))
  for (kk in seq_along(times)) {
    d <- HI[win == w & chain == EV5w$chain[i] & cls == k & hr >= times[kk] - 36 * 3600 & hr < times[kk] + 36 * 3600 & !(hr %in% c(times[kk] - 3600, times[kk]))][
      , `:=`(post = as.integer(hr >= times[kk]), tt = as.numeric(hr - times[kk], units = "days"))]
    if (kk == 1) nb <- d[, .(before = mean(N[post == 0]), after = mean(N[post == 1]))]
    f <- try(feols(y ~ post + tt + tt:post | hod, data = d, vcov = NW(6) ~ hr), silent = TRUE)   # a fake window with no entrants of the class has nothing to estimate
    if (inherits(f, "try-error")) next
    b[kk] <- coef(f)[["post"]]; s[kk] <- se(f)[["post"]]
  }
  RI1[[length(RI1) + 1]] <- data.table(event = EV5w$event[i], class = k, jump = b[1], se = s[1], ri_p = (1 + sum(abs(b[-1]) >= abs(b[1]), na.rm = TRUE)) / (1 + sum(!is.na(b[-1]))),
                                       n_fake = sum(!is.na(b[-1])), per_hour_before = nb$before, per_hour_after = nb$after)
}
RI1 <- rbindlist(RI1)
cat("## I1. Hourly RD in log(1 + entrants per hour), classes fixed in time (burst groups = groups that burst on any window day), RI over fake hours\n"); print(RI1)
fwrite(RI1, file.path(DIR_TAB, "entry_rd_fixed_classes.csv"))
# Figure: Base entrants per hour at burst groups and elsewhere, both cuts on a common clock (as Figure 2, classes fixed in time; bot-like excluded)
F2g <- rbind(HI[win == "march" & chain == "base" & cls != "burst group without the mint", .(hr, cls, N, event = "A. First cut: March 2024 (L1 data cost)", t0 = EVENTS$t0[1])],
             HI[win == "may" & cls != "burst group without the mint", .(hr, cls, N, event = "B. Second cut: May 2024 (gas limit raised by Base)", t0 = EVENTS_MAY$t0[1])])[
  , `:=`(d = as.numeric(hr - t0, units = "days"), cls = factor(fifelse(cls == "burst group", "Entrants at burst groups (any day)", "Other entrants"),
                                                                c("Other entrants", "Entrants at burst groups (any day)")))][d >= -6 & d < 7]
g <- ggplot(F2g, aes(d, N + 1, colour = cls)) + geom_vline(xintercept = 0, colour = COL[["ink"]], linewidth = 0.4) +
  geom_vline(data = data.table(event = "B. Second cut: May 2024 (gas limit raised by Base)", x = as.numeric(EVENTS_MAY$t0[2] - EVENTS_MAY$t0[1], units = "days")), aes(xintercept = x),
             colour = COL[["ink2"]], linewidth = 0.3, linetype = "dashed") + geom_line(linewidth = 0.4) + facet_wrap(~ event, ncol = 1) +
  scale_y_log10(labels = scales::comma) + scale_x_continuous(breaks = seq(-6, 6, 2)) + scale_colour_manual(values = c(COL[["ref"]], COL[["main"]])) +
  labs(x = "Days from the fee cut (May: first gas-limit step; dashed: second step)", y = "Base entrants per hour + 1 (log scale)") + THEME_FIG
ggsave(file.path(DIR_FIG, "entrants_by_group_two_cuts.png"), g, width = 10, height = 5.6, dpi = 200, bg = "white")

# I2. Address vs entity growth under the linkage rules of 02 section C3 (components at service thresholds 50-2,000; burst groups as one entity each; non-burst
# entrants as singletons; both), for all entrants, without the largest post-cut burst target or the largest component, and with or without the largest
# post-cut burst day. address ratio = (addresses per day, post) / (same, pre); entity ratio = (entities per day, post) / (same, pre);
# gap = log(address ratio) - log(entity ratio); 95% CIs from BOOT_REPS draws of days within each period; days without entrants of a class count as zero.
ED <- PNL$entity_daily
WIN <- data.table(event = c("march", "march", "may"), chain = c("base", "arbitrum", "base"), pre0 = as.IDate(c("2024-03-08", "2024-03-08", "2024-05-21")),
                  pre1 = as.IDate(c("2024-03-12", "2024-03-12", "2024-05-27")), post0 = as.IDate(c("2024-03-14", "2024-03-15", "2024-05-29")), post1 = as.IDate(c("2024-03-21", "2024-03-21", "2024-06-04")))
EGL <- list()
for (w in seq_len(nrow(WIN))) {
  D0 <- ED[event == WIN$event[w] & chain == WIN$chain[w]]
  bigday <- D0[rule == "h500" & subset == "all" & class == "campaign" & day >= WIN$post0[w] & day <= WIN$post1[w]][which.max(n_addr), day]
  for (r in unique(D0$rule)) for (s in unique(D0$subset)) for (k in c("all", "campaign", "genuine")) for (dropday in c(FALSE, TRUE)) {
    days <- data.table(day = c(seq(WIN$pre0[w], WIN$pre1[w], by = 1), seq(WIN$post0[w], WIN$post1[w], by = 1)))[!(dropday & day == bigday)]
    DY <- merge(days, D0[rule == r & subset == s & class == k, .(day, n_addr, n_ent)], by = "day", all.x = TRUE)
    DY[is.na(n_addr), `:=`(n_addr = 0L, n_ent = 0L)][, period := fifelse(day <= WIN$pre1[w], "pre", "post")]
    pre <- DY[period == "pre"]; post <- DY[period == "post"]
    set.seed(SEED); bs <- matrix(NA_real_, BOOT_REPS, 2)
    for (bb in seq_len(BOOT_REPS)) { i1 <- sample.int(nrow(post), replace = TRUE); i0 <- sample.int(nrow(pre), replace = TRUE)
      bs[bb, ] <- c(log(mean(post$n_ent[i1]) / mean(pre$n_ent[i0])), log(mean(post$n_addr[i1]) / mean(pre$n_addr[i0])) - log(mean(post$n_ent[i1]) / mean(pre$n_ent[i0]))) }
    ok <- is.finite(bs[, 1]) & is.finite(bs[, 2])
    EGL[[length(EGL) + 1]] <- data.table(event = WIN$event[w], chain = WIN$chain[w], rule = r, subset = s, class = k, without_largest_burst_day = dropday, largest_burst_day = bigday,
      address_ratio = mean(post$n_addr) / mean(pre$n_addr), entity_ratio = mean(post$n_ent) / mean(pre$n_ent), entity_lo = exp(quantile(bs[ok, 1], .025)), entity_hi = exp(quantile(bs[ok, 1], .975)),
      log_gap = log(mean(post$n_addr) / mean(pre$n_addr)) - log(mean(post$n_ent) / mean(pre$n_ent)), gap_lo = quantile(bs[ok, 2], .025), gap_hi = quantile(bs[ok, 2], .975), finite_draws = mean(ok))
  }
}
EGL <- rbindlist(EGL)
cat("## I2. Address vs entity growth by linkage rule, all entrants (subset all; with and without the largest burst day)\n")
print(EGL[class == "all" & subset == "all", .(event, chain, rule, without_largest_burst_day, address_ratio, entity_ratio, entity_lo, entity_hi, log_gap, gap_lo, gap_hi)])
cat("## I2. Range across linkage rules and subsets: entity ratio and log gap, all entrants\n")
print(EGL[class == "all", .(entity_ratio_min = min(entity_ratio), entity_ratio_max = max(entity_ratio), address_ratio_min = min(address_ratio), address_ratio_max = max(address_ratio),
                            log_gap_min = min(log_gap), log_gap_max = max(log_gap), gap_lo_min = min(gap_lo)), by = .(event, chain, without_largest_burst_day)])
fwrite(EGL, file.path(DIR_TAB, "entity_growth_linkage.csv"))

# I3. Key composition numbers of the burst and second-cut tables under leave-one-out variants (Base): all entrants; without the largest post-cut burst day;
# without the largest post-cut burst target; without the largest funding-graph component (h = 500); and, in March, classes from the size-only rule (no
# pre-cut baseline). ratio = (entrants of a class per day, post) / (same, pre); wedge = all / non-burst ratio; shares are among post-cut entrants of a class.
LO <- list()
for (ev in c("march", "may")) {
  Z0 <- if (ev == "march") EV[chain == "base", .(period, day, class3, cls_size = fcase(bot_wk1 == 1, "bot", wave_size == 1, "campaign", default = "genuine"), first_to, first_sel, cid500,
                                                 csize500, sync, lz, m3 = act_2024_09 + act_2024_12 + act_2025_03)] else
                            MY[, .(period, day, class3, cls_size = NA_character_, first_to, first_sel, cid500, csize500, sync = NA_integer_, lz = NA_integer_, m3 = act_2024_09 + act_2024_12 + act_2025_03)]
  bigday <- Z0[period == "post" & class3 == "campaign", .N, by = day][which.max(N), day]
  tt <- Z0[period == "post" & class3 == "campaign", .N, by = first_to][which.max(N), first_to]
  for (vr in c("all", "without largest burst day", "without largest burst target", "without largest component", "size-only rule")) {
    if (vr == "size-only rule" && ev == "may") next
    Z <- switch(vr, all = copy(Z0), `without largest burst day` = Z0[day != bigday], `without largest burst target` = Z0[!(first_to %in% tt)],
                `without largest component` = Z0[csize500 < max(Z0$csize500)], `size-only rule` = copy(Z0)[, class3 := cls_size])
    nd <- Z[, .(d = uniqueN(day)), by = period]; npre <- nd[period == "pre", d]; npost <- nd[period == "post", d]
    rt <- Z[, .(n = .N), by = .(period, class3)]
    rb <- (rt[period == "post" & class3 == "campaign", n] / npost) / (rt[period == "pre" & class3 == "campaign", n] / npre)
    rg <- (rt[period == "post" & class3 == "genuine", n] / npost) / (rt[period == "pre" & class3 == "genuine", n] / npre)
    ra <- (Z[period == "post", .N] / npost) / (Z[period == "pre", .N] / npre)
    P1 <- Z[period == "post"]; ce <- P1[class3 == "campaign", .N, by = cid500][order(-N)]
    LO[[length(LO) + 1]] <- data.table(event = ev, variant = vr, dropped = fcase(vr == "without largest burst day", as.character(bigday), vr == "without largest burst target", tt, default = ""),
      metric = c("burst entry ratio", "non-burst entry ratio", "all-entrant ratio", "wedge (all / non-burst)", "burst share of post-cut entrants", "largest 10 entities' share of burst",
                 "largest 100 entities' share of burst", "burst in components >= 20", "non-burst in components >= 20", "burst synchronized", "non-burst synchronized",
                 "burst months active of 3", "non-burst months active of 3", "burst on LayerZero list", "non-burst on LayerZero list", "burst first action plain transfer"),
      value = c(rb, rg, ra, ra / rg, P1[, mean(class3 == "campaign")], sum(head(ce$N, 10)) / sum(ce$N), sum(head(ce$N, 100)) / sum(ce$N),
                P1[class3 == "campaign", mean(csize500 >= CLUSTER_MIN)], P1[class3 == "genuine", mean(csize500 >= CLUSTER_MIN)], P1[class3 == "campaign", mean(sync)], P1[class3 == "genuine", mean(sync)],
                P1[class3 == "campaign", mean(m3)], P1[class3 == "genuine", mean(m3)], P1[class3 == "campaign", mean(lz)], P1[class3 == "genuine", mean(lz)],
                P1[class3 == "campaign", mean(is.na(first_sel) | first_sel == "0x")]))
  }
}
LO <- rbindlist(LO)
cat("## I3. Composition under leave-one-out variants (Base)\n"); print(dcast(LO, event + metric ~ variant, value.var = "value")[order(event, match(metric, unique(LO$metric)))])
fwrite(LO, file.path(DIR_TAB, "composition_leave_one_out.csv"))

# ---- J. what the burst groups are, and what a manufactured address cost ----
# J1. The 20 largest post-cut burst groups (first recipient x method), March and May (Base): size, timing, single use, synchrony and Sybil-list overlap (March),
# persistence (months active of Sep 2024, Dec 2024, Mar 2025), funding-graph clustering and entities, how the first ETH funder was found, target type (March).
DS <- list()
for (ev in c("march", "may")) {
  Z <- if (ev == "march") EV[chain == "base" & period == "post" & class3 == "campaign", .(first_to, first_sel, day, hr, n_week1, sync, lz, cid500, csize500, f_eth_via, m3 = act_2024_09 + act_2024_12 + act_2025_03)] else
                          MY[period == "post" & class3 == "campaign", .(first_to, first_sel, day, hr, n_week1, sync = NA_integer_, lz = NA_integer_, cid500, csize500, f_eth_via, m3 = act_2024_09 + act_2024_12 + act_2025_03)]
  top <- Z[, .N, by = .(first_to, first_sel)][order(-N)][1:min(20, .N)]
  for (g in seq_len(nrow(top))) {
    y <- Z[first_to == top$first_to[g] & first_sel == top$first_sel[g]]; ce <- y[, .N, by = cid500][order(-N)]; pd <- y[, .N, by = day][which.max(N)]
    DS[[length(DS) + 1]] <- data.table(event = ev, rank = g, first_to = top$first_to[g], first_sel = top$first_sel[g], accounts = nrow(y), share_of_burst = nrow(y) / nrow(Z), days = uniqueN(y$day),
      peak_day = pd$day, peak_day_share = pd$N / nrow(y), peak_hour_accounts = y[, .N, by = hr][, max(N)], single_tx_wk1 = mean(y$n_week1 == 1), synchronized = mean(y$sync),
      on_layerzero_list = mean(y$lz), months_active_of3 = mean(y$m3), in_components_ge20 = mean(y$csize500 >= CLUSTER_MIN), entities = nrow(ce), largest_entity_share = ce$N[1] / nrow(y),
      funded_internal = mean(y$f_eth_via %in% "internal"), funded_top_level = mean(y$f_eth_via %in% "top-level"))
  }
}
DS <- rbindlist(DS)
DS <- merge(DS, PNL$campaign_targets[, .(first_to = addr, target_contract = contract, target_logs_721 = n_721, target_logs_20 = n_20)], by = "first_to", all.x = TRUE)[order(event, rank)]
# funding of the March groups (02 section C3), pooled over how the funder was found: share funded before entry, mean ETH sent per account, mean ETH never sent on
# (unswept), share that ever sent ETH out, initiators of internal funding txs, distinct top-level funders
FG <- PNL$entrant_funding[period == "post" & class3 == "campaign", .(accounts_f = sum(n), funded = sum(funded * n) / sum(n), eth_mean = sum(eth_sum) / sum(n), eth_unswept_mean = sum(eth_unswept) / sum(n),
                                                                   swept = sum(swept * n) / sum(n), initiators = sum(initiators), top_level_funders = sum(top_level_funders)), by = grp]
DS[event == "march", grp := paste(first_to, first_sel)]
DS <- merge(DS, FG, by = "grp", all.x = TRUE)[order(event, rank)][, grp := NULL]
cat("## J1. The 20 largest post-cut burst groups, March and May (Base)\n"); print(DS)
fwrite(DS, file.path(DIR_TAB, "campaign_dossier.csv")); fwrite(PNL$entrant_funding, file.path(DIR_TAB, "campaign_funding.csv"))
# J2. Address poisoning check: entrants whose first action is a plain transfer; share sent to themselves, and among transfers to another address the share
# whose address matches the recipient's first and last four hex digits (02 section C3; chance 16^-4 on each side, about 1.5e-5)
cat("## J2. Look-alike addresses among plain-transfer entrants (address-poisoning signature)\n"); print(PNL$lookalike); fwrite(PNL$lookalike, file.path(DIR_TAB, "lookalike_poisoning.csv"))
# J3. First-time senders at the largest post-cut burst target as a share of the daily active addresses growthepie reports for Base, by day
DAA <- list()
for (ev in c("march", "may")) {
  tgt <- DS[event == ev & rank == 1, first_to]; dd <- if (ev == "march") seq(as.IDate("2024-03-12"), as.IDate("2024-03-21"), by = 1) else seq(as.IDate("2024-05-26"), as.IDate("2024-06-04"), by = 1)
  en <- if (ev == "march") E[chain == "base" & !is.na(wave) & day %in% dd, .(entrants = .N, target_senders = sum(first_to %in% tgt)), by = day] else
                           PNL$may_entrants[chain == "base" & day %in% dd, .(entrants = .N, target_senders = sum(first_to %in% tgt)), by = day]
  DAA[[ev]] <- merge(PNL$multichain_daily[chain == "base" & date %in% dd, .(day = date, daa)], en, by = "day", all.x = TRUE)[, `:=`(event = ev, target = tgt, target_share_of_daa = target_senders / daa,
                                                                                                                                       entrant_share_of_daa = entrants / daa)]
}
DAA <- rbindlist(DAA); cat("## J3. Largest burst target's first-time senders and all entrants as shares of growthepie's daily active addresses (Base)\n"); print(DAA)
fwrite(DAA, file.path(DIR_TAB, "daa_share_base.csv"))
# J4. What a manufactured address cost (Base, March, the 20 largest post-cut burst groups and the other burst accounts pooled):
#   first tx: the hourly mean fee of successful native txs (l2_hourly_type) in the hours the group's accounts entered; before the cut: the same number of txs at
#   the mean native fee of 03-08..12; funding: internal funding txs' fees shared over the entrants each paid (02 section C3) and one native tx per top-level
#   funding transfer at the post-cut mean native fee (before the cut: at the pre-cut fee; internal funding scaled by the ratio of the two native fees);
#   capital: ETH sent to the accounts before entry; stranded = ETH in accounts that never sent ETH on (unswept) net of their first-tx fee; US$ at the mean
#   ETH/USD close of 03-14..21. fee share = fees / (fees + stranded capital), after the cut and, holding stranded capital fixed, at pre-cut fees
NT <- merge(PNL$l2_hourly_type[chain == "base" & typ == "native" & failed == 0, .(n = sum(n), fee = sum(fee)), by = hr][, day := as.IDate(hr, tz = "UTC")], eth_usd_daily[, .(day, usd = close)], by = "day")[, fee_usd := fee / n * usd]
fee_pre <- NT[day >= as.IDate("2024-03-08") & day <= as.IDate("2024-03-12"), sum(fee * usd) / sum(n)]; fee_post <- NT[day >= as.IDate("2024-03-14") & day <= as.IDate("2024-03-21"), sum(fee * usd) / sum(n)]
usd_post <- eth_usd_daily[day >= as.IDate("2024-03-14") & day <= as.IDate("2024-03-21"), mean(close)]
BG <- EV[chain == "base" & period == "post" & class3 == "campaign"][, grp := paste(first_to, first_sel)]
BG[, grp := fifelse(grp %in% PNL$entrant_funding[class3 == "campaign" & !grepl("^other", grp), grp], grp, "other campaign")]
PF <- merge(BG[, .N, by = .(grp, hr)], NT[, .(hr, fee_usd)], by = "hr", all.x = TRUE)[, .(accounts = sum(N), first_tx_fee_paid = sum(N * fee_usd)), by = grp]
FU <- PNL$entrant_funding[period == "post" & class3 == "campaign", .(fee_int_eth = sum(fee_int_sum), n_top = sum(n_top_sum), eth_sum = sum(eth_sum), eth_unswept = sum(eth_unswept),
                                                                     unswept_share = 1 - sum(swept * n) / sum(n)), by = grp]
CPA <- merge(PF, FU, by = "grp", all.x = TRUE)[, `:=`(first_tx_fee = first_tx_fee_paid / accounts, funding_fee = (fee_int_eth * usd_post + n_top * fee_post) / accounts,
                                                       capital_sent = eth_sum * usd_post / accounts)]
CPA[, capital_stranded := pmax(eth_unswept * usd_post / accounts - first_tx_fee * unswept_share, 0)]
CPA[, `:=`(fees_post = first_tx_fee + funding_fee, fees_pre_counterfactual = fee_pre + (n_top / accounts) * fee_pre + (fee_int_eth * usd_post / accounts) * fee_pre / fee_post)]
CPA[, `:=`(fee_share_post = fees_post / (fees_post + capital_stranded), fee_share_pre_counterfactual = fees_pre_counterfactual / (fees_pre_counterfactual + capital_stranded),
           pre_over_post = fees_pre_counterfactual / fees_post)]
cat(sprintf("## J4. Cost per manufactured address (US$): mean native fee per tx %.4f before (03-08..12), %.4f after (03-14..21); ETH/USD %.0f\n", fee_pre, fee_post, usd_post)); print(CPA[order(-accounts)])
fwrite(CPA[order(-accounts)], file.path(DIR_TAB, "cost_per_address_base.csv"))
# J5. Non-burst entry at the four cuts with one estimator (windows of section H): entrants per day post / pre for non-burst entrants and for ordinary entrants
# (non-burst, outside funding-graph components of >= 20 entrants), whole post window and its first two days vs the rest; day-bootstrap 95% CIs.
# Dose-response across the four cuts, weighted least squares through the origin, weights w_e = 1 / var_e(bootstrap log ratio):
#   log(ratio_e) = beta * stake_e + u_e   (dollars; stake = first-week savings of an individual entrant, section H)
#   log(ratio_e) = eta * dlp_e + u_e      (constant elasticity in the fee; dlp = fall in the log median fee, section H)
#   chi2 = sum_e w_e * u_e^2 with 3 degrees of freedom; predictions from the Base March point alone are reported too.
FC <- list()
for (i in seq_len(nrow(EVT))) {
  w <- EVT[i]; X <- if (w$src == "mar") E[chain == w$chain & !is.na(wave)] else PNL$may_entrants[chain == "base"]
  X <- X[(day >= w$pre0 & day <= w$pre1) | (day >= w$post0 & day <= w$post1)][class3 == "genuine"]
  DD <- merge(data.table(day = c(seq(w$pre0, w$pre1, by = 1), seq(w$post0, w$post1, by = 1))), X[, .(genuine = .N, ordinary = sum(csize500 < CLUSTER_MIN)), by = day], by = "day", all.x = TRUE)
  DD[is.na(genuine), `:=`(genuine = 0L, ordinary = 0L)][, part := fcase(day <= w$pre1, "pre", day <= w$post0 + 1, "post days 1-2", default = "post days 3+")]
  for (k in c("genuine", "ordinary")) for (pp in c("post", "post days 1-2", "post days 3+")) {
    pr <- DD[part == "pre"][[k]]; po <- if (pp == "post") DD[part != "pre"][[k]] else DD[part == pp][[k]]
    if (!length(po)) next
    set.seed(SEED); bs <- numeric(BOOT_REPS)
    for (bb in seq_len(BOOT_REPS)) bs[bb] <- log(mean(sample(po, replace = TRUE)) / mean(sample(pr, replace = TRUE)))
    FC[[length(FC) + 1]] <- data.table(short = w$short, class = k, window = pp, days = length(po), ratio = mean(po) / mean(pr), lo = exp(quantile(bs[is.finite(bs)], .025)),
                                       hi = exp(quantile(bs[is.finite(bs)], .975)), var_log = var(bs[is.finite(bs)]), stake = TH[short == w$short, stake_individual], dlp = TH[short == w$short, dlp])
  }
}
FC <- rbindlist(FC)
cat("## J5. Non-burst and ordinary entry at the four cuts, whole post window and its parts\n"); print(FC)
FF <- list()
for (k in c("genuine", "ordinary")) {
  d <- FC[class == k & window == "post"][, `:=`(ly = log(ratio), wt = 1 / var_log)]
  for (m in c("stake", "dlp")) {
    f <- lm(as.formula(paste("ly ~ 0 +", m)), data = d, weights = wt)   # log(ratio_e) = coef * x_e + u_e, x = stake (dollars) or dlp (log fee)
    cal <- d[short == "Base Mar", ly / get(m)]                          # calibration on the Base March point alone
    # se with the variances taken as known, 1 / sqrt(sum_e w_e x_e^2) (summary.lm rescales by the residual variance); weight_share = each cut's weight in the slope
    FF[[length(FF) + 1]] <- data.table(class = k, model = fifelse(m == "stake", "dollars saved", "log fee (constant elasticity)"), coef = coef(f)[[1]], se = 1 / sqrt(sum(d$wt * d[[m]]^2)),
                                       weight_share = d$wt * d[[m]]^2 / sum(d$wt * d[[m]]^2),
                                       chi2 = sum(d$wt * resid(f)^2), p = pchisq(sum(d$wt * resid(f)^2), df = nrow(d) - 1, lower.tail = FALSE),
                                       short = d$short, observed = d$ratio, fitted = exp(fitted(f)), calibrated_on_base_march = exp(cal * d[[m]]), lo = d$lo, hi = d$hi)
  }
}
FF <- rbindlist(FF)
cat("## J5. Dollars vs log fee across the four cuts (WLS through the origin; chi2 with 3 df; Base-March calibration)\n"); print(FF)
fwrite(FC, file.path(DIR_TAB, "four_cut_entry.csv")); fwrite(FF, file.path(DIR_TAB, "four_cut_fits.csv"))

# ---- K. waves of new addresses by fee regime, and entry at the four cuts against placebo dates, 2024-01..06 (Base and Arbitrum; 02 section I) ----
# One definition at every date and on both chains: a new address has no outgoing tx in the previous LONG_LOOKBACK days; waves follow the trailing rule of
# 02 section I; entry outside waves excludes wave addresses and heavy new addresses (>= BOT_MIN_WEEK1 txs on the entry day).
# K1. Crossing date c: first day from which the chain's daily median fee per tx (growthepie, US$) stays below CROSS_FEE for 7 days. Outcomes per day:
#   y1 = log(1 + new addresses in waves); y2 = the same without the largest wave group of the 2 x SHIFT_DAYS days around the date; y3 = number of waves;
#   y4 = log(new addresses outside waves).
# Shift at date t: S(t) = mean of y over t .. t + SHIFT_DAYS - 1 minus mean over t - SHIFT_DAYS .. t - 1. Placebo dates: every t at least SHIFT_DAYS days
# from c whose windows lie inside LONG_FROM..LONG_END; percentile = share of placebo S(t) below S(c); p (one-sided) = (1 + #{S(t) >= S(c)}) / (1 + K).
# Reading, set before the long series was downloaded: S(c) for y2 above the 95th placebo percentile on Base with the same sign on Arbitrum -> waves shift
# with the fee regime; 90th-95th -> consistent with a shift; below the 90th -> waves are not tied to the fee regime.
# Variant (set after seeing the series): the anticipation days ANTICIP_DAYS, without waves on either Layer-2 just before the cuts, left out of the window
# before each date. K1 and K2 use groups by recipient x method; K3 compares with Ethereum L1 in both groupings (recipient x method if LONG_CONTROL_SELECTOR, and recipient only).
LD <- PNL$long_daily[, nonwave := new - wave_new - (heavy - wave_heavy)]; LW <- PNL$long_waves; LDm <- LD[grouping == "target x method" & chain %in% CHAINS]
CR <- list()
for (ch in CHAINS) { g <- PNL$multichain_daily[chain == ch & date >= LONG_FROM & date <= as.IDate(LONG_END)][order(date)]
  run7 <- frollsum(as.integer(g$cost < CROSS_FEE), 7, align = "left"); CR[[ch]] <- data.table(chain = ch, crossing = g$date[which(run7 == 7)[1]]) }
# Second definition (secondary, for comparison): c = the date fees first fell to cents (Base 03-14; Arbitrum 03-19, its floor cut).
CR <- rbind(rbindlist(CR)[, definition := sprintf("median fee below US$%.2f for 7 days", CROSS_FEE)],
            data.table(chain = CHAINS, crossing = as.IDate(c(EVENTS$t0[1], EVENTS$t0[3])), definition = "fee cut date"))
cat("## K1. Crossing dates\n"); print(CR)
KS <- list()
for (gp in unique(LD$grouping)) for (ad in c("kept", "left out")) for (ch in unique(LD[grouping == gp, chain])) {
  D <- LD[grouping == gp & chain == ch][order(day)]
  ts <- D[day - SHIFT_DAYS >= LONG_FROM & day + SHIFT_DAYS - 1 <= as.IDate(LONG_END), day]
  for (k in seq_along(ts)) {
    t <- ts[k]; WW <- LW[grouping == gp & chain == ch & day >= t - SHIFT_DAYS & day < t + SHIFT_DAYS]
    top <- WW[, .(tot = sum(n)), by = .(first_to, first_sel)][order(-tot)][1]
    Z <- merge(D[day >= t - SHIFT_DAYS & day < t + SHIFT_DAYS], WW[first_to %in% top$first_to & first_sel %in% top$first_sel, .(ex = sum(n)), by = day], by = "day", all.x = TRUE)
    Z[is.na(ex), ex := 0][, post := day >= t]
    if (ad == "left out") Z <- Z[post == TRUE | !(day %in% ANTICIP_DAYS)]   # anticipation days out of the window before t
    KS[[length(KS) + 1]] <- data.table(grouping = gp, anticipation_days = ad, chain = ch, t = t,
      S1 = Z[post == TRUE, mean(log1p(wave_new))] - Z[post == FALSE, mean(log1p(wave_new))], S2 = Z[post == TRUE, mean(log1p(wave_new - ex))] - Z[post == FALSE, mean(log1p(wave_new - ex))],
      S3 = Z[post == TRUE, mean(waves)] - Z[post == FALSE, mean(waves)], S4 = Z[post == TRUE, mean(log(nonwave))] - Z[post == FALSE, mean(log(nonwave))],
      wave_share_pre = Z[post == FALSE, sum(wave_new) / sum(new)], wave_share_post = Z[post == TRUE, sum(wave_new) / sum(new)])
  }
}
KS <- rbindlist(KS)
KT <- list()
for (ad in c("kept", "left out")) for (j in seq_len(nrow(CR))) for (v in c("S1", "S2", "S3", "S4")) {
  K0 <- KS[grouping == "target x method" & anticipation_days == ad]
  ch <- CR$chain[j]; cday <- CR$crossing[j]; a <- K0[chain == ch & t == cday, get(v)]; pl <- K0[chain == ch & abs(as.integer(t - cday)) >= SHIFT_DAYS, get(v)]
  if (!length(a)) next
  KT[[length(KT) + 1]] <- data.table(anticipation_days = ad, chain = ch, definition = CR$definition[j], crossing = cday, outcome = c(S1 = "log(1 + new addresses in waves)", S2 = "same, without the largest wave group",
    S3 = "waves per day", S4 = "log new addresses outside waves")[[v]], shift = a, placebo_K = length(pl), placebo_percentile = mean(pl < a), p_one_sided = (1 + sum(pl >= a)) / (1 + length(pl)),
    p_floor = 1 / (1 + length(pl)),
    placebo_p90 = quantile(pl, .90, names = FALSE), placebo_p95 = quantile(pl, .95, names = FALSE))
}
KT <- rbindlist(KT)[, reading := fcase(placebo_percentile > 0.95, "above the 95th placebo percentile", placebo_percentile > 0.90, "90th-95th", default = "below the 90th")]
cat("## K1. Regime shift at the crossing date against placebo dates\n"); print(KT)
cat("## K1. Waves and new addresses per day, before vs after the crossing date (LONG_FROM..LONG_END)\n")
print(merge(LDm, CR[definition != "fee cut date"], by = "chain")[, .(days = .N, new = mean(new), in_waves = mean(wave_new), wave_share = sum(wave_new) / sum(new), waves = mean(waves), largest_wave = max(largest_wave),
                                     size_only_share = sum(size_new) / sum(new), outside_waves = mean(nonwave)), by = .(chain, regime = fifelse(day < crossing, "before crossing", "after crossing"))])
fwrite(KS, file.path(DIR_TAB, "long_regime_shifts.csv")); fwrite(KT, file.path(DIR_TAB, "long_regime_test.csv"))
# Figure: new addresses per day in waves and outside waves, 2024-01..06, with each chain's crossing date (solid) and fee cuts (dashed)
FL <- rbind(LDm[, .(chain, day, v = wave_new, series = "In waves")], LDm[, .(chain, day, v = nonwave, series = "Outside waves")])[, chain_lab := factor(fifelse(chain == "base", "Base", "Arbitrum"), c("Base", "Arbitrum"))]
CUTS <- rbind(EVENTS[, .(chain, d = as.IDate(t0))], EVENTS_MAY[1, .(chain, d = as.IDate(t0))])[, chain_lab := factor(fifelse(chain == "base", "Base", "Arbitrum"), c("Base", "Arbitrum"))]
g <- ggplot(FL, aes(day, v + 1, colour = series)) + geom_vline(data = CUTS, aes(xintercept = d), colour = COL[["ink2"]], linewidth = 0.3, linetype = "dashed") +
  geom_vline(data = CR[definition != "fee cut date", .(crossing, chain_lab = factor(fifelse(chain == "base", "Base", "Arbitrum"), c("Base", "Arbitrum")))], aes(xintercept = crossing), colour = COL[["ink"]], linewidth = 0.4) +
  geom_line(linewidth = 0.4) + facet_wrap(~ chain_lab, ncol = 1) + scale_y_log10(labels = scales::comma) + scale_colour_manual(values = c(COL[["main"]], COL[["ref"]])) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b %Y") + labs(x = NULL, y = "New addresses per day + 1 (log scale)") + THEME_FIG
ggsave(file.path(DIR_FIG, "waves_2024_by_chain.png"), g, width = 10, height = 5.6, dpi = 200, bg = "white")
# K3. Comparison with Ethereum L1 (LONG_CONTROL), whose fees stayed at dollars: groups by recipient x method on all three chains when L1 call data are read
# (LONG_CONTROL_SELECTOR), and by recipient only on all three. At each Layer-2 crossing date c (both definitions of K1): S on the Layer-2, S on L1 on the same
# date, and their difference D = S_L2 - S_L1, each against the same statistic at placebo dates at least SHIFT_DAYS from c (percentile; p one-sided as in K1);
# anticipation days kept or left out of the window before each date.
GPK3 <- unique(LD[chain == LONG_CONTROL, grouping]); KC <- list()
for (gp in GPK3) for (ad in c("kept", "left out")) for (j in seq_len(nrow(CR))) for (v in c("S1", "S2", "S3", "S4")) {
  K0 <- KS[grouping == gp & anticipation_days == ad]; ch <- CR$chain[j]; cday <- CR$crossing[j]
  X2 <- merge(K0[chain == ch, .(t, l2 = get(v))], K0[chain == LONG_CONTROL, .(t, l1 = get(v))], by = "t")[, d := l2 - l1]
  a <- X2[t == cday]; pl <- X2[abs(as.integer(t - cday)) >= SHIFT_DAYS]
  if (!nrow(a)) next
  KC[[length(KC) + 1]] <- data.table(grouping = gp, anticipation_days = ad, chain = ch, definition = CR$definition[j], crossing = cday, outcome = c(S1 = "log(1 + new addresses in waves)",
    S2 = "same, without the largest wave group", S3 = "waves per day", S4 = "log new addresses outside waves")[[v]], placebo_K = nrow(pl),
    shift_l2 = a$l2, pct_l2 = mean(pl$l2 < a$l2), shift_l1 = a$l1, pct_l1 = mean(pl$l1 < a$l1), diff = a$d, pct_diff = mean(pl$d < a$d), p_diff = (1 + sum(pl$d >= a$d)) / (1 + nrow(pl)),
    p_floor = 1 / (1 + nrow(pl)))
}
KC <- rbindlist(KC)
cat("## K3. Shift on each Layer-2 at its crossing date vs Ethereum L1 on the same date, with placebo percentiles\n"); print(KC)
cat("## K3. Waves per day and new addresses by chain, before vs from 03-14\n")
print(LD[grouping %in% GPK3, .(days = .N, new = mean(new), in_waves = mean(wave_new), wave_share = sum(wave_new) / sum(new), waves = mean(waves), outside_waves = mean(nonwave)),
         by = .(grouping, chain, period = fifelse(day < as.IDate(EVENTS$t0[1]), "before 03-14", "from 03-14"))][order(grouping, chain, -rank(period))])
fwrite(KC, file.path(DIR_TAB, "long_control_test.csv"))
# Figure: as the K1 figure, with Ethereum L1 as the comparison chain (no fee cut; fees at dollars); groups as in K1 when L1 call data are read, else by recipient
LAB <- c(base = "Base", arbitrum = "Arbitrum", ethereum = "Ethereum L1 (comparison: no fee cut)"); GPF <- if ("target x method" %in% GPK3) "target x method" else "target"
FL3 <- rbind(LD[grouping == GPF, .(chain, day, v = wave_new, series = "In waves")], LD[grouping == GPF, .(chain, day, v = nonwave, series = "Outside waves")])[, chain_lab := factor(LAB[chain], LAB)]
g <- ggplot(FL3, aes(day, v + 1, colour = series)) + geom_vline(data = CUTS[, .(d, chain_lab = factor(LAB[chain], LAB))], aes(xintercept = d), colour = COL[["ink2"]], linewidth = 0.3, linetype = "dashed") +
  geom_line(linewidth = 0.4) + facet_wrap(~ chain_lab, ncol = 1) + scale_y_log10(labels = scales::comma) + scale_colour_manual(values = c(COL[["main"]], COL[["ref"]])) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b %Y") + labs(x = NULL, y = "New addresses per day + 1 (log scale)") + THEME_FIG
ggsave(file.path(DIR_FIG, "waves_2024_with_l1.png"), g, width = 10, height = 7.6, dpi = 200, bg = "white")
# K2. Entry outside waves at the four cuts (windows of section H): r = log(mean per day, post window) - log(mean per day, pre window), whole post window and post
# days 3+. Placebo: the same pair of windows moved to every start date in LONG_FROM..LONG_END whose span stays more than 7 days from every one of the four
# cuts' window spans on that chain; p = (1 + #{|r_placebo| >= |r|}) / (1 + K). Dose-response across the four cuts with var_e = placebo variance of r_e:
#   r_e = beta * stake_e + u_e  (dollars saved by an individual entrant, section H);   r_e = eta * dlp_e + u_e  (constant elasticity in the fee)
#   WLS through the origin with weights 1 / var_e; chi2 = sum_e u_e^2 / var_e, 3 degrees of freedom.
KP <- list()
for (i in seq_len(nrow(EVT))) for (pp in c("post", "post days 3+")) {
  w <- EVT[i]; p0 <- w$post0 + fifelse(pp == "post", 0L, 2L)
  if (p0 > w$post1) next
  D <- LDm[chain == w$chain]; span <- EVT[chain == w$chain, .(a = pre0 - 7L, b = post1 + 7L)]
  sh <- seq(as.integer(LONG_FROM - w$pre0), as.integer(as.IDate(LONG_END) - w$post1)); rr <- rep(NA_real_, length(sh))
  for (k in seq_along(sh)) {
    a0 <- w$pre0 + sh[k]; a1 <- w$pre1 + sh[k]; b0 <- p0 + sh[k]; b1 <- w$post1 + sh[k]
    if (sh[k] != 0 && any(a0 <= span$b & b1 >= span$a)) next
    rr[k] <- log(D[day >= b0 & day <= b1, mean(nonwave)]) - log(D[day >= a0 & day <= a1, mean(nonwave)])
  }
  r <- rr[sh == 0]; pl <- rr[sh != 0 & !is.na(rr)]
  KP[[length(KP) + 1]] <- data.table(short = w$short, window = pp, ratio = exp(r), placebo_K = length(pl), p = (1 + sum(abs(pl) >= abs(r))) / (1 + length(pl)), p_floor = 1 / (1 + length(pl)), placebo_sd = sd(pl),
                                     placebo_lo = exp(quantile(pl, .025, names = FALSE)), placebo_hi = exp(quantile(pl, .975, names = FALSE)),
                                     stake = TH[short == w$short, stake_individual], dlp = TH[short == w$short, dlp])
}
KP <- rbindlist(KP)
cat("## K2. Entry outside waves at the four cuts against placebo windows (2024-01..06)\n"); print(KP)
KF <- list(); d <- KP[window == "post"][, `:=`(ly = log(ratio), wt = 1 / placebo_sd^2)]
for (m in c("stake", "dlp")) {
  f <- lm(as.formula(paste("ly ~ 0 +", m)), data = d, weights = wt)   # r_e = coef * x_e + u_e, x = stake (dollars) or dlp (log fee)
  # se with the placebo variances taken as known, 1 / sqrt(sum_e w_e x_e^2); weight_share = each cut's weight in the slope
  KF[[m]] <- data.table(model = fifelse(m == "stake", "dollars saved", "log fee (constant elasticity)"), coef = coef(f)[[1]], se = 1 / sqrt(sum(d$wt * d[[m]]^2)),
                        weight_share = d$wt * d[[m]]^2 / sum(d$wt * d[[m]]^2),
                        chi2 = sum(d$wt * resid(f)^2), p = pchisq(sum(d$wt * resid(f)^2), df = nrow(d) - 1, lower.tail = FALSE), short = d$short, observed = d$ratio, fitted = exp(fitted(f)))
}
KF <- rbindlist(KF); cat("## K2. Dollars vs log fee, variances from the placebo windows\n"); print(KF)
fwrite(KP, file.path(DIR_TAB, "four_cut_placebo.csv")); fwrite(KF, file.path(DIR_TAB, "four_cut_fits_placebo.csv"))

# ---- L. The Base March entry effect: dynamics, placebo dates before the cut, delay, persistence ----
# Daily entry outside waves (long series: 60-day new-address definition, recipient x method groups): y_d = log(new addresses outside waves and not heavy);
# D_d = y_d(Base) - y_d(Ethereum L1), the chain without a fee change. Cut day c = 2024-03-14 (Ecotone at 00:00 UTC, so day c is after the cut).
# Days that no placebo window may contain (as N1): c - 1 (Dencun on L1), c, 03-19 (Arbitrum's floor cut) and the Base May steps 05-28..30.
# L1 event study: E_k = D_{c+k} - mean(D_{c-7..c-1}), k = -14..14; band = 5th-95th percentile of the same statistic at placebo dates t whose window t-14..t+14
#   ends before c - 1 (pre-cut dates only).
# L2 window ratio: r_w = mean(y over c..c+w-1) - mean(y over c-w..c-1), for Base and for D (Base minus L1), w = 6 (the low-fee days), 7, 14, 28; against all placebo dates in
#   2024-01..06 and against pre-cut dates only (window ends before c - 1). Percentile = share of placebo r below r_w; p = (1 + #{placebo r >= r_w}) / (1 + K).
# L3 delay or new entry: baseline B = c-42..c-15, run-up A = c-14..c-1, after P = c..c+13, on D. dip = mean(A) - mean(B) (negative if people waited for the
#   announced cut); after = mean(P) - mean(B); net = mean(A and P) - mean(B), the excess over the 28 days around the cut (zero if entry was only retimed).
# L4 persistence: share of non-burst window entrants active on days 1-10 of 2024-09, 2024-12 or 2025-03, entrants in the 6 days before vs the 6 days after
#   each chain's first cut hour (Base: 03-08..13 vs 03-14..19); ratio after / before with a 95% interval from BOOT_REPS draws of entry days within each period.
LDT <- PNL$long_daily[grouping == "target x method"][, y := log(new - wave_new - (heavy - wave_heavy))]
DL <- merge(LDT[chain == "base", .(day, yb = y)], LDT[chain == LONG_CONTROL, .(day, yl = y)], by = "day")[, d := yb - yl][order(day)]
cc <- as.IDate(EVENTS$t0[1]); BAD <- unique(c(as.IDate(L1_FORK), as.IDate(EVENTS$t0), as.IDate(EVENTS_MAY$t0[1]) + 0:2))
# L1: event study with a band from pre-cut placebo dates
ES <- list()
for (t in c(as.integer(cc), as.integer(DL[day - 14L >= LONG_FROM & day + 14L < cc - 1L, day]))) {
  ref <- DL[day >= t - 7L & day <= t - 1L, mean(d)]
  ES[[length(ES) + 1]] <- DL[day >= t - 14L & day <= t + 14L, .(placebo = t != as.integer(cc), k = as.integer(day) - t, e = d - ref)]
}
ES <- rbindlist(ES)
EST <- merge(ES[placebo == FALSE, .(k, e)], ES[placebo == TRUE, .(placebo_K = .N, lo = quantile(e, 0.05, names = FALSE), hi = quantile(e, 0.95, names = FALSE)), by = k], by = "k")
cat("## L1. Event study: log entry outside waves, Base minus Ethereum L1, relative to the week before the cut (band: 5th-95th percentile, pre-cut placebo dates)\n"); print(EST)
# shaded: the 6 low-fee days (k = 0..5); dotted: 03-05 (record deposits on Base, event_calendar) and 03-20 (Base's fee rose thirtyfold)
MK <- data.table(k = as.integer(as.IDate(c("2024-03-05", "2024-03-20")) - cc), lab = c("5 Mar: record deposits", "20 Mar: fee x30"))
g <- ggplot(EST, aes(k, e)) + annotate("rect", xmin = -0.5, xmax = 5.5, ymin = -Inf, ymax = Inf, fill = COL[["grid"]], alpha = 0.6) +
  geom_ribbon(aes(ymin = lo, ymax = hi), fill = COL[["band"]]) + geom_hline(yintercept = 0, colour = COL[["ref"]], linewidth = 0.3) +
  geom_vline(xintercept = -0.5, colour = COL[["ink2"]], linewidth = 0.3, linetype = "dashed") + geom_vline(data = MK, aes(xintercept = k), colour = COL[["ink2"]], linewidth = 0.3, linetype = "dotted") +
  geom_text(data = MK, aes(x = k, y = Inf, label = lab), vjust = 1.3, hjust = -0.05, size = 2.6, colour = COL[["ink2"]]) +
  geom_line(colour = COL[["main"]], linewidth = 0.5) + geom_point(colour = COL[["main"]], size = 1.2) +
  labs(x = "Days from the Base fee cut (14 Mar 2024; shaded: the six low-fee days)", y = "Log entry outside waves, Base minus Ethereum L1\n(relative to the week before)") + THEME_FIG
ggsave(file.path(DIR_FIG, "entry_event_study_base_l1.png"), g, width = 7, height = 4, dpi = 200, bg = "white")
# L2: window ratios against all placebo dates and against pre-cut dates only
LR <- list()
for (w in c(6L, 7L, 14L, 28L)) for (v in c("yb", "d")) {
  ts <- DL[day - w >= LONG_FROM & day + w - 1L <= as.IDate(LONG_END), as.integer(day)]; rr <- rep(NA_real_, length(ts))
  for (k in seq_along(ts)) {
    win <- (ts[k] - w):(ts[k] + w - 1L)
    if (ts[k] != as.integer(cc) && any(win %in% as.integer(BAD))) next
    rr[k] <- DL[day >= ts[k] & day <= ts[k] + w - 1L, mean(get(v))] - DL[day >= ts[k] - w & day <= ts[k] - 1L, mean(get(v))]
  }
  r <- rr[ts == as.integer(cc)]
  for (pl in c("all dates", "pre-cut dates only")) {
    keep <- !is.na(rr) & ts != as.integer(cc) & (pl == "all dates" | ts + w - 1L < as.integer(cc) - 1L); x <- rr[keep]
    LR[[length(LR) + 1]] <- data.table(window_days = w, series = fifelse(v == "yb", "Base", "Base minus Ethereum L1"), placebo = pl, ratio = exp(r), placebo_K = length(x),
                                       placebo_pct = mean(x < r), p_one_sided = (1 + sum(x >= r)) / (1 + length(x)), p_floor = 1 / (1 + length(x)), placebo_p95 = exp(quantile(x, 0.95, names = FALSE)))
  }
}
LR <- rbindlist(LR); cat("## L2. Entry outside waves after vs before the Base cut (ratio), against placebo dates\n"); print(LR)
# L3: delay or new entry
LD3 <- list()
for (t in as.integer(DL[day - 42L >= LONG_FROM & day + 13L <= as.IDate(LONG_END), day])) {
  if (t != as.integer(cc) && any(((t - 42L):(t + 13L)) %in% as.integer(BAD))) next
  b <- DL[day >= t - 42L & day <= t - 15L, mean(d)]
  LD3[[length(LD3) + 1]] <- data.table(t = t, dip = DL[day >= t - 14L & day <= t - 1L, mean(d)] - b, after = DL[day >= t & day <= t + 13L, mean(d)] - b,
                                       net = DL[day >= t - 14L & day <= t + 13L, mean(d)] - b)
}
LD3 <- rbindlist(LD3); LT3 <- list()
for (v in c("dip", "after", "net")) for (pl in c("all dates", "pre-cut dates only")) {
  a <- LD3[t == as.integer(cc), get(v)]; x <- LD3[t != as.integer(cc) & (pl == "all dates" | t + 13L < as.integer(cc) - 1L), get(v)]
  LT3[[length(LT3) + 1]] <- data.table(statistic = v, placebo = pl, value = a, placebo_K = length(x), placebo_pct = mean(x < a),
                                       p_low = (1 + sum(x <= a)) / (1 + length(x)), p_high = (1 + sum(x >= a)) / (1 + length(x)), p_floor = 1 / (1 + length(x)))
}
LT3 <- rbindlist(LT3); cat("## L3. Delay or new entry: Base minus L1, run-up (dip), after, and the 28 days together (net), relative to days c-42..c-15\n"); print(LT3)
# L4: persistence of non-burst entrants before and after each chain's first cut
E4 <- PNL$entrants[!is.na(wave) & class3 == "genuine"][, act := as.integer(act_2024_09 | act_2024_12 | act_2025_03)]
L4 <- list(); set.seed(SEED)
for (ch in CHAINS) {
  t0 <- EVENTS[chain == ch, min(t0)]
  X <- E4[chain == ch & hr >= t0 - 6 * 86400 & hr < t0 + 6 * 86400][, after := hr >= t0][, .(n = .N, act = sum(act)), by = .(day, after)]
  d0 <- X[after == FALSE]; d1 <- X[after == TRUE]; s0 <- d0[, sum(act) / sum(n)]; s1 <- d1[, sum(act) / sum(n)]; bb <- rep(NA_real_, BOOT_REPS)
  for (b in seq_len(BOOT_REPS)) { i0 <- sample(nrow(d0), replace = TRUE); i1 <- sample(nrow(d1), replace = TRUE); bb[b] <- (sum(d1$act[i1]) / sum(d1$n[i1])) / (sum(d0$act[i0]) / sum(d0$n[i0])) }
  L4[[ch]] <- data.table(chain = ch, entrants_before = d0[, sum(n)], entrants_after = d1[, sum(n)], active_before = s0, active_after = s1, ratio = s1 / s0,
                         lo = quantile(bb, 0.025, names = FALSE), hi = quantile(bb, 0.975, names = FALSE))
}
L4 <- rbindlist(L4); cat("## L4. Non-burst window entrants active later (Sep 2024, Dec 2024 or Mar 2025, days 1-10): 6 days before vs 6 days after the chain's first cut hour\n"); print(L4)
fwrite(EST, file.path(DIR_TAB, "entry_event_study_base_l1.csv")); fwrite(LR, file.path(DIR_TAB, "entry_ratio_placebo_windows.csv"))
fwrite(LT3, file.path(DIR_TAB, "entry_delay_test.csv")); fwrite(L4, file.path(DIR_TAB, "entrant_persistence_cut.csv"))

# ---- M. Where the extra non-burst entrants came from: how their first ETH arrived ----
# Source of a non-burst window entrant's first ETH (the ETH funder before its first outgoing tx, 01 section J), by the funder's role:
#   a service funder (>= 500 distinct ETH recipients on 02-15..03-07), named in panel funder_labels: an exchange hot wallet (a withdrawal from an exchange),
#   an exchange's deposit funder (gas sent to a customer's deposit address), a bridge or relayer (funds moved from another chain), or untagged;
#   an individual funder (fewer recipients): a direct transfer, or on Base a contract transfer attributed to the account that started the tx;
#   no ETH funder: a token funder only, or none (ETH bridged from Ethereum to the same address does not count as funding by another account).
# Entrants per day in the 6 days before and the 6 days after the chain's first cut hour t0 (Base: 03-08..13 vs 03-14..19, the days of low fees; Arbitrum:
# 03-08 15:00 .. 03-20 15:00); ratio after / before; share of the increase = change per day in the source / change per day in all non-burst entrants. Also the
# shares that entered the other Layer-2 in the window and that are on the LayerZero provisional Sybil list.
E5 <- merge(PNL$entrants[!is.na(wave) & class3 == "genuine"], PNL$funder_labels[, .(chain, f_service = address, category)], by = c("chain", "f_service"), all.x = TRUE)
E5[, source := fcase(!is.na(f_service) & category %in% "exchange", "exchange withdrawal", !is.na(f_service) & category %in% "exchange deposit funder", "exchange deposit address",
                     !is.na(f_service) & category %in% "bridge", "bridge or relayer", !is.na(f_service), "untagged service", f_eth_via %in% "internal", "individual, contract transfer",
                     f_eth_via %in% "top-level", "individual, direct transfer", funder2_seen == 1, "token funder only", default = "no funder found")]
E5 <- merge(E5, EVENTS[, .(t0 = min(t0)), by = chain], by = "chain")[hr >= t0 - 6 * 86400 & hr < t0 + 6 * 86400]; M5 <- list()
for (ch in CHAINS) {
  t0 <- EVENTS[chain == ch, min(t0)]
  X <- E5[chain == ch, .(before = sum(hr < t0) / 6, after = sum(hr >= t0) / 6), by = source]
  M5[[ch]] <- X[, `:=`(chain = ch, ratio = after / before, share_before = before / sum(before), share_after = after / sum(after), share_of_increase = (after - before) / sum(after - before))]
}
M5 <- rbindlist(M5)[order(chain, -share_of_increase)]
cat("## M1. Non-burst window entrants per day by source of their first ETH, 6 days before vs 6 days after the chain's first cut hour\n"); print(M5)
M6 <- E5[, .(entrants = .N, entered_other_layer2 = mean(other_chain_addr, na.rm = TRUE), on_layerzero_list = mean(lz, na.rm = TRUE)), by = .(chain, after = hr >= t0)][order(chain, after)]
cat("## M2. Non-burst window entrants that also entered the other Layer-2 in the window, and that are on the LayerZero provisional Sybil list\n"); print(M6)
# M3. Funding clusters behind non-burst entrants (same 6 v 6 days): entrants per day by the size of their funder-entrant-sweep component (h = 500): alone,
# 2 to CLUSTER_MIN - 1, CLUSTER_MIN or more; and the funding entities (components) behind them per day, all and in components below CLUSTER_MIN entrants.
# Entities are counted within each 24-hour block from the cut hour and averaged over the six blocks on each side (as Q1 counts them per day).
M7 <- list()
for (ch in CHAINS) {
  t0 <- EVENTS[chain == ch, min(t0)]; h0 <- 6; h1 <- 6
  X <- E5[chain == ch][, `:=`(after = hr >= t0, blk = floor(as.numeric(hr - t0, units = "days")), cl = fcase(csize500 == 1, "alone", csize500 < CLUSTER_MIN, "cluster of 2-19", default = "cluster of 20+"))]
  EB5 <- X[, .(e = uniqueN(cid500), e20 = uniqueN(cid500[csize500 < CLUSTER_MIN])), by = .(after, blk)]
  M7[[ch]] <- rbind(X[, .(before = sum(!after) / h0, after = sum(after) / h1), by = cl][, .(measure = paste("addresses,", cl), before, after)],
                    data.table(measure = "addresses, all", before = X[after == FALSE, .N] / h0, after = X[after == TRUE, .N] / h1),
                    data.table(measure = "funding entities, all", before = EB5[after == FALSE, sum(e)] / h0, after = EB5[after == TRUE, sum(e)] / h1),
                    data.table(measure = "funding entities, components below 20", before = EB5[after == FALSE, sum(e20)] / h0, after = EB5[after == TRUE, sum(e20)] / h1))[
    , `:=`(chain = ch, ratio = after / before)]
}
M7 <- rbindlist(M7); cat("## M3. Non-burst window entrants per day by funding cluster, and the funding entities behind them, 6 days before vs 6 days after the chain's first cut hour\n"); print(M7)
fwrite(M5, file.path(DIR_TAB, "entrant_funding_source.csv")); fwrite(M6, file.path(DIR_TAB, "entrant_cross_chain.csv")); fwrite(M7, file.path(DIR_TAB, "entrant_entities_nonburst.csv"))

# ---- N. Both Base cuts with one estimator: waves and entry outside waves against Ethereum L1 and Arbitrum; funding entities behind May entry ----
# N1. Long series (recipient x method groups). Cut day c with g step days left out: March c = 03-14, g = 0 (Ecotone at 00:00, day c is after the cut);
#   May c = 05-28, g = 3 (gas-limit steps 05-28 19:00 and 05-30 20:00). Window length w = 6 (Base's low-fee days in March), 7, 14, 28: before = c-w..c-1,
#   after = c+g..c+g+w-1.
#   Outcomes per chain-day: y1 = log(1 + new addresses in waves); y2 = the same without the chain's largest wave group of the window; y3 = waves per day;
#   y4 = log(new addresses outside waves and not heavy). Shift = mean after - mean before; S = shift on Base - shift on the comparison chain: Ethereum L1
#   (no fee change), or Arbitrum (no change in May; in March it was cut too, at 03-14 15:00 and 03-19, so S compares Base with another treated chain).
#   Placebo dates t: windows t-w..t+g+w-1 inside LONG_FROM..LONG_END holding none of the cut days (03-13 L1 Dencun, 03-14, 03-19, 05-28..30). Placebo sets:
#   all such dates; pre-cut (windows end before the cut; for May they also start after 03-19); the cents regime (windows start after 03-19, for May); the
#   cents regime without Base's gas-target steps of 03-26 and 04-01 (event_calendar). Percentile = share of placebo S below S; p = (1 + #{placebo S >= S}) /
#   (1 + K), floor 1 / (1 + K); disjoint_K = the largest number of placebo windows that do not overlap.
#   Reading (ISR round 5): above the 95th percentile against both comparisons, also without the largest group -> waves rose more than at any ordinary date;
#   below the 90th against both -> no wave response.
cat("## N0. Event calendar (data/external/event_calendar.csv)\n"); print(PNL$event_calendar[, .(date, time_utc, event, relevance)])
LDN <- PNL$long_daily[grouping == "target x method"][, nonwave := new - wave_new - (heavy - wave_heavy)]; LWN <- PNL$long_waves[grouping == "target x method"]
BADN <- as.integer(c(as.IDate(L1_FORK), as.IDate(EVENTS$t0), as.IDate(EVENTS_MAY$t0[1]) + 0:2)); GTS <- as.integer(PNL$event_calendar[event %like% "^Base gas target", date])
CUT2 <- data.table(cut = c("Base March", "Base May"), c = as.integer(c(as.IDate(EVENTS$t0[1]), as.IDate(EVENTS_MAY$t0[1]))), g = c(0L, 3L)); A319 <- as.integer(as.IDate(EVENTS$t0[3]))
NS <- list()
for (j in seq_len(nrow(CUT2))) for (w in c(6L, 7L, 14L, 28L)) {
  cj <- CUT2$c[j]; g <- CUT2$g[j]
  for (t in seq(as.integer(as.IDate(LONG_FROM)) + w, as.integer(as.IDate(LONG_END)) - g - w + 1L)) {
    span <- (t - w):(t + g + w - 1L)
    if (t != cj && any(span %in% BADN)) next
    win <- c((t - w):(t - 1L), (t + g):(t + g + w - 1L))
    for (ch in c("base", "arbitrum", LONG_CONTROL)) {
      D <- LDN[chain == ch & as.integer(day) %in% win][, post := as.integer(day) >= t + g]; WW <- LWN[chain == ch & as.integer(day) %in% win]
      top <- WW[, .(tot = sum(n)), by = .(first_to, first_sel)][order(-tot)][1]
      D <- merge(D, WW[first_to %in% top$first_to & first_sel %in% top$first_sel, .(ex = sum(n)), by = day], by = "day", all.x = TRUE)[is.na(ex), ex := 0]
      NS[[length(NS) + 1]] <- data.table(cut = CUT2$cut[j], w = w, t = t, chain = ch, gas_step = any(span %in% GTS),
        y1 = D[post == TRUE, mean(log1p(wave_new))] - D[post == FALSE, mean(log1p(wave_new))], y2 = D[post == TRUE, mean(log1p(wave_new - ex))] - D[post == FALSE, mean(log1p(wave_new - ex))],
        y3 = D[post == TRUE, mean(waves)] - D[post == FALSE, mean(waves)], y4 = D[post == TRUE, mean(log(nonwave))] - D[post == FALSE, mean(log(nonwave))])
    }
  }
}
NS <- rbindlist(NS); NT <- list()
OUTN <- c(y1 = "log(1 + new addresses in waves)", y2 = "same, without the largest wave group", y3 = "waves per day", y4 = "log new addresses outside waves")
for (j in seq_len(nrow(CUT2))) for (w0 in c(6L, 7L, 14L, 28L)) for (cp in c(LONG_CONTROL, "arbitrum")) for (v in names(OUTN))
  for (pl in c("all dates", "pre-cut dates", "cents regime (after 03-19)", "cents regime without Base gas-target steps")) {
  cj <- CUT2$c[j]; g <- CUT2$g[j]
  if (CUT2$cut[j] == "Base March" && pl %like% "^cents") next
  X <- merge(NS[cut == CUT2$cut[j] & w == w0 & chain == "base", .(t, b = get(v), gas_step)], NS[cut == CUT2$cut[j] & w == w0 & chain == cp, .(t, k = get(v))], by = "t")[, d := b - k]
  a <- X[t == cj]; x <- X[t != cj]
  if (pl == "pre-cut dates") x <- x[t + g + w0 - 1L < cj - (CUT2$cut[j] == "Base March") & (CUT2$cut[j] == "Base March" | t - w0 > A319)]
  if (pl %like% "^cents") x <- x[t - w0 > A319]
  if (pl == "cents regime without Base gas-target steps") x <- x[gas_step == FALSE]
  dk <- 0L; le <- -Inf
  for (u in sort(x$t)) if (u - w0 > le) { dk <- dk + 1L; le <- u + g + w0 - 1L }   # greedy count of non-overlapping windows
  NT[[length(NT) + 1]] <- data.table(cut = CUT2$cut[j], window_days = w0, comparison = cp, outcome = OUTN[[v]], placebo = pl, shift_base = a$b, shift_comparison = a$k, diff = a$d,
                                     placebo_K = nrow(x), disjoint_K = dk, pct_diff = mean(x$d < a$d), p_one_sided = (1 + sum(x$d >= a$d)) / (1 + nrow(x)), p_floor = 1 / (1 + nrow(x)),
                                     pct_base_alone = mean(x$b < a$b))
}
NT <- rbindlist(NT)
cat("## N1. Both Base cuts, one estimator: shift on Base minus the comparison chain, against placebo dates (May: step days 05-28..30 left out)\n"); print(NT)
NR <- NT[outcome != OUTN[["y3"]], .(lo = min(pct_diff[outcome != OUTN[["y4"]]]), hi = max(pct_diff[outcome != OUTN[["y4"]]]), outside = pct_diff[outcome == OUTN[["y4"]]],
                                    waves_per_day = NT[cut == .BY$cut & window_days == .BY$window_days & placebo == .BY$placebo & comparison == .BY$comparison & outcome == OUTN[["y3"]], pct_diff]),
         by = .(cut, window_days, placebo, comparison)]   # lo / hi: the lower / higher percentile of y1 and y2
NR <- NR[, .(l1_lo = lo[comparison == LONG_CONTROL], l1_hi = hi[comparison == LONG_CONTROL], arbitrum_lo = lo[comparison == "arbitrum"], arbitrum_hi = hi[comparison == "arbitrum"],
             waves_per_day_vs_l1 = waves_per_day[comparison == LONG_CONTROL], waves_per_day_vs_arbitrum = waves_per_day[comparison == "arbitrum"],
             outside_vs_l1 = outside[comparison == LONG_CONTROL], outside_vs_arbitrum = outside[comparison == "arbitrum"]), by = .(cut, window_days, placebo)]
NR[, reading := fcase(pmin(arbitrum_lo, l1_lo) > 0.95, "waves: above the 95th against both, with and without the largest group",
                      pmax(arbitrum_hi, l1_hi) < 0.90, "waves: below the 90th against both", default = "waves: in between")]
cat("## N1. Reading by cut, window and placebo set (percentiles; wave volume y1/y2, waves per day, entry outside waves)\n"); print(NR)
# N2. Funding entities behind non-burst entry on Base, May window 05-21..06-04 (as M3 for March): before vs after the first step hour, and with the step
#   days 05-28..30 left out; addresses by funding cluster (h = 500) and the components behind them. Arbitrum's May entrants have no funding graph.
MN <- PNL$may_entrants[chain == "base" & class3 == "genuine"][, cl := fcase(csize500 == 1, "alone", csize500 < CLUSTER_MIN, "cluster of 2-19", default = "cluster of 20+")]
t1 <- EVENTS_MAY$t0[1]; N2 <- list()
for (va in c("before vs after the first step hour", "step days 05-28..30 left out")) {
  X <- if (va == "step days 05-28..30 left out") MN[!(day %in% (as.IDate(t1) + 0:2))][, after := day > as.IDate(t1)] else copy(MN)[, after := hr >= t1]
  h0 <- if (va == "step days 05-28..30 left out") as.numeric(as.IDate(t1) - MAY_WINDOW[1]) else as.numeric(t1 - as.POSIXct(MAY_WINDOW[1]), units = "days")
  h1 <- if (va == "step days 05-28..30 left out") as.numeric(MAY_WINDOW[2] - as.IDate(t1) - 2L) else as.numeric(as.POSIXct(MAY_WINDOW[2] + 1L) - t1, units = "days")
  N2[[va]] <- rbind(X[, .(before = sum(!after) / h0, after = sum(after) / h1), by = cl][, .(measure = paste("addresses,", cl), before, after)],
                    data.table(measure = "addresses, all", before = X[after == FALSE, .N] / h0, after = X[after == TRUE, .N] / h1),
                    data.table(measure = "funding entities, all", before = X[after == FALSE, uniqueN(cid500)] / h0, after = X[after == TRUE, uniqueN(cid500)] / h1),
                    data.table(measure = "funding entities, components below 20", before = X[after == FALSE & csize500 < CLUSTER_MIN, uniqueN(cid500)] / h0,
                               after = X[after == TRUE & csize500 < CLUSTER_MIN, uniqueN(cid500)] / h1))[, `:=`(variant = va, ratio = after / before)]
}
N2 <- rbindlist(N2); cat("## N2. Base May: non-burst window entrants per day by funding cluster, and the funding entities behind them\n"); print(N2)
fwrite(NS, file.path(DIR_TAB, "base_cuts_shifts.csv")); fwrite(NT, file.path(DIR_TAB, "base_cuts_test.csv")); fwrite(NR, file.path(DIR_TAB, "base_cuts_reading.csv")); fwrite(N2, file.path(DIR_TAB, "may_entities_nonburst.csv"))

# ---- O. May waves day by day, and Base against OP Mainnet ----
# O1. Waves per day around the May steps (long series): E_k = D_{c+k} - mean(D over the reference days), D = waves per day on Base minus the comparison chain
#   (none, Ethereum L1 or Arbitrum), k = -14..21, c = 05-28 (steps on c and c+2). Reference days: c-14..c-1, or c-28..c-8, which leaves out the week before.
#   Band: 5th-95th percentile of E_k over placebo dates t whose span (first reference day .. t+21) starts after 03-19 and holds no cut day. first_week =
#   mean of E_k over k = 3..9 (the week after the step days), with its placebo percentile. Step 1 was announced after it took effect, step 2 two days ahead.
WD <- dcast(LDN[, .(chain, day = as.integer(day), waves)], day ~ chain, value.var = "waves"); cmay <- CUT2[cut == "Base May", c]; O1 <- list()
for (rf in c("c-14..c-1", "c-28..c-8")) for (cp in c("none", LONG_CONTROL, "arbitrum")) {
  r0 <- if (rf == "c-14..c-1") -14L else -28L; r1 <- if (rf == "c-14..c-1") -1L else -8L
  for (t in c(cmay, WD[day + r0 > A319 & day + 21L <= as.integer(as.IDate(LONG_END)), day])) {
    if (t != cmay && any(((t + r0):(t + 21L)) %in% BADN)) next
    Z <- WD[day >= t + r0 & day <= t + 21L][, d := base - (if (cp == "none") 0 else get(cp))]
    O1[[length(O1) + 1]] <- Z[day >= t - 14L, .(reference = rf, comparison = cp, t = t, placebo = t != cmay, k = day - t, e = d - Z[day >= t + r0 & day <= t + r1, mean(d)])]
  }
}
O1 <- rbindlist(O1)
OT <- merge(O1[placebo == FALSE, .(reference, comparison, k, e)], O1[placebo == TRUE, .(placebo_K = .N, lo = quantile(e, 0.05, names = FALSE), hi = quantile(e, 0.95, names = FALSE)),
            by = .(reference, comparison, k)], by = c("reference", "comparison", "k"))
OW <- O1[k >= 3 & k <= 9, .(first_week = mean(e)), by = .(reference, comparison, t, placebo)]
OW <- merge(OW[placebo == FALSE, .(reference, comparison, fw = first_week)], OW[placebo == TRUE, .(reference, comparison, pfw = first_week)], by = c("reference", "comparison"), allow.cartesian = TRUE)[
  , .(first_week = fw[1], placebo_K = .N, placebo_pct = mean(pfw < fw[1]), p_one_sided = (1 + sum(pfw >= fw[1])) / (1 + .N), p_floor = 1 / (1 + .N)), by = .(reference, comparison)]
cat("## O1. Base May: waves per day relative to the reference days (Base alone, minus L1, minus Arbitrum), with a band from cents-regime placebo dates\n"); print(OT)
cat("## O1. Mean over the week after the step days (k = 3..9) against the same statistic at placebo dates\n"); print(OW)
cat("## O1. Waves per day on the three chains, 05-14..06-11 (step days 05-28 and 05-30)\n")
print(dcast(LDN[day >= as.IDate(EVENTS_MAY$t0[1]) - 14L & day <= as.IDate(EVENTS_MAY$t0[1]) + 14L, .(day, chain, waves)], day ~ chain, value.var = "waves"))
FO <- rbind(OT[reference == "c-14..c-1" & comparison %in% c("none", LONG_CONTROL)])[, panel := factor(fifelse(comparison == "none", "A. Base alone", "B. Base minus Ethereum L1"), c("A. Base alone", "B. Base minus Ethereum L1"))]
g <- ggplot(FO, aes(k, e)) + geom_ribbon(aes(ymin = lo, ymax = hi), fill = COL[["band"]]) + geom_hline(yintercept = 0, colour = COL[["ref"]], linewidth = 0.3) +
  geom_vline(xintercept = c(-0.5, 1.5), colour = COL[["ink2"]], linewidth = 0.3, linetype = "dashed") + geom_line(colour = COL[["main"]], linewidth = 0.5) + geom_point(colour = COL[["main"]], size = 1.1) +
  facet_wrap(~ panel, ncol = 2) + labs(x = "Days from the first gas-limit step (28 May 2024; second step on day 2)", y = "Waves per day, relative to the two weeks before") + THEME_FIG
ggsave(file.path(DIR_FIG, "may_waves_event_study.png"), g, width = 9, height = 3.8, dpi = 200, bg = "white")
# O2. Base against OP Mainnet, which got the same Ecotone cut at the same second (growthepie daily data): D = log(Base) - log(OP Mainnet) for daily active
#   addresses, transactions and the median fee per tx (first stage). Shift as in N1 (March: before c-w..c-1, after c..c+w-1; May: step days left out), against
#   placebo dates in LONG_FROM..LONG_END whose window holds no cut day (BADN, as N1), all and pre-cut (windows end before c - 1). Event
#   study of active addresses as in section L (relative to c-7..c-1; band from pre-cut placebo dates).
GD <- dcast(PNL$multichain_daily[chain %in% c("base", "optimism") & date >= LONG_FROM & date <= as.IDate(LONG_END), .(chain, day = as.integer(date), daa = log(daa), tx = log(txcount), fee = log(cost))],
            day ~ chain, value.var = c("daa", "tx", "fee"))[, `:=`(d_daa = daa_base - daa_optimism, d_tx = tx_base - tx_optimism, d_fee = fee_base - fee_optimism)]
BADG <- BADN; O2 <- list()   # one set of cut days for every placebo set
for (j in seq_len(nrow(CUT2))) for (w0 in c(7L, 14L, 28L)) {
  cj <- CUT2$c[j]; g <- CUT2$g[j]; ts <- GD[day - w0 >= as.integer(as.IDate(LONG_FROM)) & day + g + w0 - 1L <= as.integer(as.IDate(LONG_END)), day]; rr <- list()
  for (t in ts) {
    if (t != cj && any(((t - w0):(t + g + w0 - 1L)) %in% BADG)) next
    Z <- GD[(day >= t - w0 & day <= t - 1L) | (day >= t + g & day <= t + g + w0 - 1L)][, post := day >= t + g]
    rr[[length(rr) + 1]] <- data.table(t = t, d_daa = Z[post == TRUE, mean(d_daa)] - Z[post == FALSE, mean(d_daa)], d_tx = Z[post == TRUE, mean(d_tx)] - Z[post == FALSE, mean(d_tx)],
                                       d_fee = Z[post == TRUE, mean(d_fee)] - Z[post == FALSE, mean(d_fee)], base_daa = Z[post == TRUE, mean(daa_base)] - Z[post == FALSE, mean(daa_base)],
                                       op_daa = Z[post == TRUE, mean(daa_optimism)] - Z[post == FALSE, mean(daa_optimism)])
  }
  rr <- rbindlist(rr)
  for (v in c("d_daa", "d_tx", "d_fee")) for (pl in c("all dates", "pre-cut dates")) {
    a <- rr[t == cj]; x <- rr[t != cj & (pl == "all dates" | t + g + w0 - 1L < cj - 1L)]
    O2[[length(O2) + 1]] <- data.table(cut = CUT2$cut[j], window_days = w0, outcome = c(d_daa = "log active addresses", d_tx = "log transactions", d_fee = "log median fee per tx")[[v]],
                                       placebo = pl, base_shift = a$base_daa, op_shift = a$op_daa, base_minus_op = a[[v]], placebo_K = nrow(x), placebo_pct = mean(x[[v]] < a[[v]]),
                                       p_one_sided = (1 + sum(x[[v]] >= a[[v]])) / (1 + nrow(x)), p_floor = 1 / (1 + nrow(x)))
  }
}
O2 <- rbindlist(O2)
cat("## O2. Base minus OP Mainnet (same Ecotone cut, same second), growthepie daily data; base_shift and op_shift refer to active addresses\n"); print(O2)
ES2 <- list(); cmar <- CUT2[cut == "Base March", c]
for (t in c(cmar, GD[day - 14L >= as.integer(as.IDate(LONG_FROM)) & day + 14L < cmar - 1L, day])) {
  ref <- GD[day >= t - 7L & day <= t - 1L, mean(d_daa)]; ES2[[length(ES2) + 1]] <- GD[day >= t - 14L & day <= t + 14L, .(placebo = t != cmar, k = day - t, e = d_daa - ref)]
}
ES2 <- rbindlist(ES2)
ES2 <- merge(ES2[placebo == FALSE, .(k, e)], ES2[placebo == TRUE, .(placebo_K = .N, lo = quantile(e, 0.05, names = FALSE), hi = quantile(e, 0.95, names = FALSE)), by = k], by = "k")
cat("## O2. Event study: log active addresses, Base minus OP Mainnet, relative to the week before the March cut (band: pre-cut placebo dates)\n"); print(ES2)
fwrite(OT, file.path(DIR_TAB, "may_waves_event_study.csv")); fwrite(OW, file.path(DIR_TAB, "may_waves_first_week.csv")); fwrite(O2, file.path(DIR_TAB, "base_minus_op_mainnet.csv"))
fwrite(ES2, file.path(DIR_TAB, "base_minus_op_event_study.csv"))

# ---- P. The hour of the cut: who entered, and why the hourly estimates differ ----
# Hourly counts in the entrant windows (03-08..21 on both chains; 05-21..06-04 on Base): window entrants (never active on the chain before, all classes);
# non-burst entrants (classes by UTC day); entrants at groups that never burst in the window (classes fixed in time, section I1); distinct funding entities
# (components, h = 500) among non-burst entrants; non-burst entrants alone in their component; new senders (no outgoing tx since 02-15, as in 04 section A).
# (a) RD in time as in 04 section A: log(1 + y_t) = a + b Post_t + c1 (t - t0) + c2 (t - t0) Post_t + hour-of-day FE + e_t, +-36 h, 1-hour donut, Newey-West (6 lags).
# (b) Local randomization as in section A, W = 12 and 24 h: log(mean y after) - log(mean y before), same donut.
# RI for (a) and (b): fake hours on a 6-hour grid whose +-36 h window lies in the entrant window, more than 36 h from every cut in it (as section I1).
# (c) Base March: hours 00-14 of 03-14 against the same hours of 03-08..13, Base minus Arbitrum (not yet cut); placebo days 03-08..13, each against the other
#   pre-cut days (and without 03-13, Dencun day).
HP <- rbind(PNL$entrants[!is.na(wave), .(win = "march", chain, hr, class3, cid500, csize500)], PNL$may_entrants[chain == "base", .(win = "may", chain, hr, class3, cid500, csize500)])[
  , .(window_entrants = .N, nonburst = sum(class3 == "genuine"), entities = uniqueN(cid500[class3 == "genuine"]), alone = sum(class3 == "genuine" & csize500 == 1)), by = .(win, chain, hr)]
HP <- merge(HP, HI[cls == "other", .(win, chain, hr, never_burst_groups = N)], by = c("win", "chain", "hr"), all = TRUE)
HP <- merge(HP, rbind(PNL$l2_newsenders[, .(win = "march", chain, hr, new_senders)], PNL$may_hourly[chain == "base", .(win = "may", chain, hr, new_senders)]), by = c("win", "chain", "hr"), all.x = TRUE)
HP <- merge(rbind(CJ(win = "march", chain = CHAINS, hr = seq(LIM$march[1], LIM$march[2] - 3600, by = 3600)), CJ(win = "may", chain = "base", hr = seq(LIM$may[1], LIM$may[2] - 3600, by = 3600))),
            HP, by = c("win", "chain", "hr"), all.x = TRUE)
YP <- c(new_senders = "new senders", window_entrants = "window entrants", nonburst = "non-burst entrants (day classes)", never_burst_groups = "entrants at never-burst groups",
        entities = "funding entities (non-burst)", alone = "non-burst entrants alone in their component")
for (v in names(YP)) HP[is.na(get(v)), (v) := 0]
HP[, hod := hour(hr)]; RP <- list()
for (i in seq_len(nrow(EV5w))) for (v in names(YP)) {
  w <- EV5w$win[i]; cd <- seq(LIM[[w]][1] + 36 * 3600, LIM[[w]][2] - 36 * 3600, by = 6 * 3600); far <- rep(TRUE, length(cd))
  for (j in which(EV5w$win == w)) far <- far & abs(as.numeric(cd - EV5w$t0[j], units = "hours")) > 36
  times <- c(EV5w$t0[i], cd[far]); B <- matrix(NA_real_, length(times), 4)   # columns: RD estimate, RD se, local randomization W = 12, W = 24
  for (kk in seq_along(times)) {
    d <- HP[win == w & chain == EV5w$chain[i] & hr >= times[kk] - 36 * 3600 & hr < times[kk] + 36 * 3600 & !(hr %in% c(times[kk] - 3600, times[kk]))][
      , `:=`(y = log1p(get(v)), n = get(v), post = as.integer(hr >= times[kk]), tt = as.numeric(hr - times[kk], units = "days"))]
    f <- try(feols(y ~ post + tt + tt:post | hod, data = d, vcov = NW(6) ~ hr), silent = TRUE)   # log(1 + y_t) = a + b Post_t + c1 tt + c2 tt Post_t + hod FE
    if (!inherits(f, "try-error")) B[kk, 1:2] <- c(coef(f)[["post"]], se(f)[["post"]])
    for (m in 1:2) { W0 <- c(12, 24)[m]; dd <- d[abs(as.numeric(hr - times[kk], units = "hours")) <= W0]
      B[kk, 2 + m] <- log(dd[post == 1, mean(n)]) - log(dd[post == 0, mean(n)]) }
  }
  for (m in 1:3) { col <- c(1, 3, 4)[m]; fk <- B[-1, col][is.finite(B[-1, col])]
    RP[[length(RP) + 1]] <- data.table(event = EV5w$event[i], outcome = YP[[v]], estimator = c("RD +-36 h (04 section A)", "local randomization, W = 12 h", "local randomization, W = 24 h")[m],
                                       estimate = B[1, col], se = if (m == 1) B[1, 2] else NA_real_, ri_p = (1 + sum(abs(fk) >= abs(B[1, col]))) / (1 + length(fk)), n_fake = length(fk), p_floor = 1 / (1 + length(fk))) }
}
RP <- rbindlist(RP)
cat("## P1. The cut hour: outcome x estimator, estimate (NW se for the RD) and RI p\n"); print(RP[order(event, estimator, outcome)])
# (c) matched hours 00-14 against the pre-cut days, Base minus Arbitrum
MH0 <- HP[win == "march" & hour(hr) <= 14 & as.IDate(hr) >= ENTRANT_WINDOW[1] & as.IDate(hr) <= as.IDate(EVENTS$t0[1])][, d := as.IDate(hr)]
MH0 <- MH0[, lapply(.SD, sum), by = .(chain, d), .SDcols = names(YP)]; PM <- list()
for (v in names(YP)) for (dd in as.list(sort(unique(MH0$d)))) for (nd in c("all pre-cut days", "without 03-13")) {
  if (nd == "without 03-13" && dd == as.IDate(L1_FORK)) next
  oth <- setdiff(MH0[d < as.IDate(EVENTS$t0[1]), unique(d)], c(dd, if (nd == "without 03-13") as.IDate(L1_FORK)))
  e <- MH0[chain == "base" & d == dd, log(get(v))] - MH0[chain == "base" & d %in% oth, log(mean(get(v)))] - (MH0[chain == "arbitrum" & d == dd, log(get(v))] - MH0[chain == "arbitrum" & d %in% oth, log(mean(get(v)))])
  PM[[length(PM) + 1]] <- data.table(outcome = YP[[v]], baseline = nd, day = dd, cut_day = dd == as.IDate(EVENTS$t0[1]), estimate = e)
}
PM <- rbindlist(PM)
PM <- merge(PM[cut_day == TRUE, .(outcome, baseline, estimate)], PM[cut_day == FALSE, .(placebo_days = .N, placebo_min = min(estimate), placebo_max = max(estimate)), by = .(outcome, baseline)], by = c("outcome", "baseline"))
cat("## P2. Base March, hours 00-14 of the cut day against the same hours of the pre-cut days, Base minus not-yet-cut Arbitrum (placebo days: range)\n"); print(PM)
fwrite(RP, file.path(DIR_TAB, "hour_rd_outcomes.csv")); fwrite(PM, file.path(DIR_TAB, "hour_matched_base_arbitrum.csv"))

# ---- Q. Funding entities behind non-burst entry at both Base cuts: accounting variants and the composition deflator ----
# Non-burst window entrants on Base. Days: March c-6..c-1 vs c..c+5 (6 v 6, c = 03-14); May c-5..c-1 vs c+3..c+7 (5 v 5, c = 05-28, step days left out).
# Per day: addresses; distinct funding entities (components, h = 500); entities with an entrant not funded by a service (exchange, bridge or other service);
# entities with an entrant active later (days 1-10 of 2024-09, 2024-12 or 2025-03); addresses alone in their component. Ratio after / before of daily means,
# all days and weekdays only, 95% interval from BOOT_REPS draws of days within each side. Deflator = log(entities / addresses), after minus before (daily
# means); implied entity effect = exp(L1-differenced address effect outside waves over 6 days, the primary window, or 7 days; N1) x exp(deflator), assuming
# L1's counterfactual moves entities and addresses alike. In March the deflator's windows (c-6..c-1 vs c..c+5) are those of the 6-day address effect.
QD <- rbind(PNL$entrants[!is.na(wave) & chain == "base" & class3 == "genuine", .(cut = "Base March", day, cid500, csize500, f_service, act = act_2024_09 | act_2024_12 | act_2025_03)],
            PNL$may_entrants[chain == "base" & class3 == "genuine", .(cut = "Base May", day, cid500, csize500, f_service, act = act_2024_09 | act_2024_12 | act_2025_03)])
QD <- QD[, .(addresses = .N, entities = uniqueN(cid500), entities_not_service_funded = uniqueN(cid500[is.na(f_service)]), entities_active_later = uniqueN(cid500[act == 1]),
             alone = sum(csize500 == 1)), by = .(cut, day)]
QD <- merge(QD, data.table(cut = CUT2$cut, c = as.IDate(CUT2$c), b0 = c(-6L, -5L), a0 = c(0L, 3L), a1 = c(5L, 7L)), by = "cut")[
  , side := fcase(day >= c + b0 & day <= c - 1L, "before", day >= c + a0 & day <= c + a1, "after", default = NA_character_)][!is.na(side)][, weekday := !(wday(day) %in% c(1L, 7L))]
QM <- c("addresses", "entities", "entities_not_service_funded", "entities_active_later", "alone"); QA <- list(); set.seed(SEED)
for (cu in CUT2$cut) for (dt in c("all days", "weekdays")) {
  X <- QD[cut == cu & (dt == "all days" | weekday)]; x0 <- X[side == "before"]; x1 <- X[side == "after"]; BB <- matrix(NA_real_, BOOT_REPS, length(QM) + 1)
  for (b in seq_len(BOOT_REPS)) { i0 <- sample(nrow(x0), replace = TRUE); i1 <- sample(nrow(x1), replace = TRUE)
    BB[b, ] <- c(colMeans(x1[i1, ..QM]) / colMeans(x0[i0, ..QM]), log(mean(x1$entities[i1]) / mean(x1$addresses[i1])) - log(mean(x0$entities[i0]) / mean(x0$addresses[i0]))) }
  QA[[length(QA) + 1]] <- data.table(cut = cu, days = dt, measure = c(QM, "deflator: log(entities / addresses), after - before"), days_before = nrow(x0), days_after = nrow(x1),
    before = c(colMeans(x0[, ..QM]), NA), after = c(colMeans(x1[, ..QM]), NA),
    ratio = c(colMeans(x1[, ..QM]) / colMeans(x0[, ..QM]), log(mean(x1$entities) / mean(x1$addresses)) - log(mean(x0$entities) / mean(x0$addresses))),
    lo = apply(BB, 2, quantile, 0.025, names = FALSE), hi = apply(BB, 2, quantile, 0.975, names = FALSE))
}
QA <- rbindlist(QA)
QI <- merge(QA[days == "all days" & measure %like% "^deflator", .(cut, deflator = ratio, d_lo = lo, d_hi = hi)],
            NT[window_days %in% c(6L, 7L) & comparison == LONG_CONTROL & outcome == OUTN[["y4"]] & placebo == "pre-cut dates", .(cut, window_days, address_effect = exp(diff), address_pct_precut = pct_diff)],
            by = "cut")[
  , `:=`(implied_entity_effect = address_effect * exp(deflator), implied_lo = address_effect * exp(d_lo), implied_hi = address_effect * exp(d_hi))]
cat("## Q1. Non-burst entry on Base, daily means after vs before each cut (equal windows), 95% day-bootstrap intervals; the last row is the composition deflator\n"); print(QA)
cat("## Q2. Implied entity effect = L1-differenced 6- or 7-day address effect outside waves x exp(deflator) (interval from the deflator only)\n"); print(QI)
fwrite(QA, file.path(DIR_TAB, "entity_accounting.csv")); fwrite(QI, file.path(DIR_TAB, "entity_effect_implied.csv"))

# ---- R. Headline numbers from one sample, and the inference table for the Base March effect ----
# R1. Base March, equal windows; every ratio is a ratio of daily means on Base alone (not net of L1). Long series (60-day new addresses, recipient x method
#   waves): days c-w..c-1 vs c..c+w-1, w = 6 (the days of low fees), 7, 14, 28; counted new addresses, new addresses outside waves, and the share of the added
#   new addresses that came in waves = change in waves per day / change in new addresses per day. Window entrants (never active on Base before; days c-6..c-1
#   vs c..c+5): all entrants, and under each rule of section C (main burst rule; size only; burst funded by bursting funders; the same with the corrected
#   funder) the classes bot-like (>= BOT_MIN_WEEK1 txs in week 1), batch (the rule's flag) and non-burst (the rest); outside_ratio = non-burst after / before,
#   batch_share_of_added = change in batch entrants per day / change in all entrants per day.
R1 <- list(); cc <- as.IDate(EVENTS$t0[1])
for (w in c(6L, 7L, 14L, 28L)) {
  B <- LDN[chain == "base" & day >= cc - w & day <= cc + w - 1L][, post := day >= cc]; s <- B[, lapply(.SD, mean), by = post, .SDcols = c("new", "wave_new", "nonwave")][order(post)]
  R1[[length(R1) + 1]] <- data.table(sample = "long series (60-day new addresses)", window = sprintf("%d v %d days", w, w), rule = "waves (recipient x method)",
    all_before = s$new[1], all_after = s$new[2], all_ratio = s$new[2] / s$new[1], outside_ratio = s$nonwave[2] / s$nonwave[1],
    batch_share_of_added = (s$wave_new[2] - s$wave_new[1]) / (s$new[2] - s$new[1]))
}
EB <- PNL$entrants[!is.na(wave) & chain == "base" & day >= cc - 6L & day <= cc + 5L][, post := day >= cc]
for (r in c("wave", "wave_size", "wave_funded", "wave_funded2")) {
  EB[, cls := fcase(bot_wk1 == 1, "bot", get(r) %in% 1, "batch", default = "nonburst")]   # classes as in section C: bot > batch > non-burst
  s <- EB[, .(all = .N / 6, batch = sum(cls == "batch") / 6, nonburst = sum(cls == "nonburst") / 6), by = post][order(post)]
  R1[[length(R1) + 1]] <- data.table(sample = "window entrants (never active on Base)", window = "6 v 6 days", rule = c(wave = "main burst rule", wave_size = "size only (>= 5,000 a day)",
    wave_funded = "burst funded by bursting funders", wave_funded2 = "same, corrected funder")[[r]], all_before = s$all[1], all_after = s$all[2], all_ratio = s$all[2] / s$all[1],
    outside_ratio = s$nonburst[2] / s$nonburst[1], batch_share_of_added = (s$batch[2] - s$batch[1]) / (s$all[2] - s$all[1]))
}
R1 <- rbindlist(R1); cat("## R1. Base March headline numbers from one sample at a time (counted new accounts, entry outside batches, batch share of the added accounts)\n"); print(R1)
# R2. Inference for the primary statistic: the shift in log entry outside waves, Base minus L1 (as N1), over the 6 days of low fees (w = 6: c..c+5 vs
#   c-6..c-1; Base's median fee rose thirtyfold on c+6, section U), and over 7 days (c..c+6 vs c-7..c-1) alongside; against pre-cut placebo dates and all
#   dates: estimate, rank, K, non-overlapping K and their values, placebo mean and SD, and z = (estimate - placebo mean) / placebo SD. The placebo rank is in
#   the spirit of Andrews's (2003) end-of-sample instability test: under the null the cut window is one more draw from the process behind the pre-cut windows.
#   Model check: an AR(1) fitted to D_t = y_t(Base) - y_t(L1) over LONG_FROM..c-2 gives Var(S) = a' Sigma a for S = mean of the w days from c minus mean of the
#   w days before, Sigma_ij = sigma^2 / (1 - phi^2) * phi^|i - j|; z_AR1 = S / sqrt(Var(S)). Placebo dates as N1: windows holding none of the cut days BADN.
#   Window path: wb days before vs wa days from c, (wb, wa) = (4, 4), (5, 5), (6, 6), (7, 7), and (6, 5), which leaves out 03-19 (record fee revenue).
#   AR(1): a = (-1/wb, ..., 1/wa, ...). The largest all-dates placebos (6 v 6 and 7 v 7) are listed with Base's and L1's own shifts, the slope of D over their
#   before-window (per day; OLS on day), and the dated events (event_calendar) inside their windows; the cut's own row comes first.
D2 <- merge(LDN[chain == "base", .(day, yb = log(nonwave))], LDN[chain == LONG_CONTROL, .(day, yl = log(nonwave))], by = "day")[, d := yb - yl][order(day)]
fa <- arima(D2[day <= cc - 2L, d], order = c(1, 0, 0)); phi <- coef(fa)[["ar1"]]; R2 <- list(); RT <- list()
WP <- data.table(wb = c(6L, 7L, 4L, 5L, 6L), wa = c(6L, 7L, 4L, 5L, 5L))
for (i in seq_len(nrow(WP))) {
  wb <- WP$wb[i]; w <- WP$wa[i]
  ts <- as.integer(D2[day - wb >= LONG_FROM & day + w - 1L <= as.IDate(LONG_END), day]); X2 <- list()
  for (t in ts) {
    if (t != as.integer(cc) && any(((t - wb):(t + w - 1L)) %in% BADN)) next
    Z <- D2[as.integer(day) >= t - wb & as.integer(day) <= t + w - 1L][, `:=`(post = as.integer(day) >= t, k = as.integer(day) - t)]
    X2[[length(X2) + 1]] <- data.table(t = t, d = Z[post == TRUE, mean(d)] - Z[post == FALSE, mean(d)], base_alone = Z[post == TRUE, mean(yb)] - Z[post == FALSE, mean(yb)],
                                       l1_alone = Z[post == TRUE, mean(yl)] - Z[post == FALSE, mean(yl)], slope_before = coef(lm(d ~ k, data = Z[post == FALSE]))[["k"]])   # d_k = a + b k, k = -w..-1
  }
  X2 <- rbindlist(X2); a2 <- X2[t == as.integer(cc), d]
  m <- wb + w; Sig <- fa$sigma2 / (1 - phi^2) * phi^abs(matrix(1:m, m, m) - matrix(1:m, m, m, byrow = TRUE)); av <- c(rep(-1 / wb, wb), rep(1 / w, w))
  for (pl in c("pre-cut dates", "all dates")) {
    x <- X2[t != as.integer(cc) & (pl == "all dates" | t + w - 1L < as.integer(cc) - 1L)][order(t)]; sel <- integer(0); le <- -Inf
    for (u in x$t) if (u - wb > le) { sel <- c(sel, u); le <- u + w - 1L }   # greedy count of non-overlapping windows
    R2[[length(R2) + 1]] <- data.table(statistic = sprintf("%d v %d days%s, log entry outside waves, Base minus L1", wb, w, if (wb != w) " (03-19 left out)" else ""), window = sprintf("%d v %d", wb, w),
                         window_days = w, placebo = pl, estimate = a2, ratio = exp(a2),
                         placebo_K = nrow(x), rank_p = (1 + sum(x$d >= a2)) / (1 + nrow(x)), disjoint_K = length(sel), disjoint_values = paste(sprintf("%.2f", x[t %in% sel, d]), collapse = ", "),
                         placebo_max = max(x$d), placebo_mean = mean(x$d), placebo_sd = sd(x$d), z_placebo = (a2 - mean(x$d)) / sd(x$d),
                         base_alone = X2[t == as.integer(cc), base_alone], base_alone_rank_p = (1 + sum(x$base_alone >= X2[t == as.integer(cc), base_alone])) / (1 + nrow(x)),
                         ar1_phi = phi, ar1_sd_of_shift = sqrt(drop(t(av) %*% Sig %*% av)), z_ar1 = a2 / sqrt(drop(t(av) %*% Sig %*% av)))
  }
  top <- rbind(X2[t == as.integer(cc)], X2[t != as.integer(cc)][order(-d)][1:6])
  if (i <= 2L) for (k in seq_len(nrow(top))) RT[[length(RT) + 1]] <- top[k, .(window_days = w, start = as.IDate(t), cut = t == as.integer(cc), d, base_alone, l1_alone, slope_before,
    events_in_window = paste(PNL$event_calendar[as.integer(date) >= t - w & as.integer(date) <= t + w - 1L, sprintf("%s %s", format(date, "%m-%d"), substr(event, 1, 60))], collapse = " | "))]
  if (i == 1L) a26 <- a2
  if (i == 2L) a27 <- a2
}
R2 <- rbindlist(R2); RT <- rbindlist(RT)
cat("## R2. Inference for the primary statistic (shift outside waves, Base minus L1, over the 6 low-fee days), 7 days, the 4- and 5-day path, and without 03-19\n"); print(R2)
cat("## R2. The cut and the largest all-dates placebos: Base minus L1, Base alone, L1 alone, before-window slope, and the dated events inside their windows\n"); print(RT)
# R2b. The primary statistic across wave size floors F (WAVE_FLOORS, panel long_floor_daily; F = SPIKE_MIN is the rule): entry outside waves = new - wave
#   addresses at F - (heavy - heavy wave addresses at F), on Base and L1 alike; 6- and 7-day shifts, placebo sets and rank as R2; Base alone, 6 v 6 days, the
#   share of the added new addresses in waves at F. Window entrants (Base, 6 v 6 days) under the burst rule of 02 section C with F in place of SPIKE_MIN (group =
#   first recipient x method; burst day if N >= F and N >= SPIKE_K x the group's median daily count over ENTRANT_WINDOW[1]..PRE_END, zeros included): non-burst
#   entrants and funding entities per day after / before, the deflator as Q1, and the implied entity effect = exp(6-day estimate at F + deflator at F).
FLD <- merge(PNL$long_floor_daily, LDN[chain %in% c("base", LONG_CONTROL), .(chain, day, new, heavy)], by = c("chain", "day"))[, nonwave := new - wave_new - (heavy - wave_heavy)]
EF <- PNL$entrants[!is.na(wave) & chain == "base"][, pair := paste(first_to, first_sel)]
PRF <- EF[, .N, by = .(day, pair)]
PRF <- merge(PRF, PRF[day <= PRE_END, .(base = median(c(N, rep(0L, as.integer(PRE_END - ENTRANT_WINDOW[1]) + 1L - .N)))), by = pair], by = "pair", all.x = TRUE)[is.na(base), base := 0]
EF <- merge(EF[day >= cc - 6L & day <= cc + 5L], PRF[, .(day, pair, N, base)], by = c("day", "pair"))[, post := day >= cc]
RW <- list()
for (fl in WAVE_FLOORS) {
  DF <- merge(FLD[floor == fl & chain == "base", .(day = as.integer(day), yb = log(nonwave))], FLD[floor == fl & chain == LONG_CONTROL, .(day = as.integer(day), yl = log(nonwave))], by = "day")[, d := yb - yl]
  B6 <- FLD[floor == fl & chain == "base" & day >= cc - 6L & day <= cc + 5L][, post := day >= cc][, .(new = mean(new), wave_new = mean(wave_new)), by = post][order(post)]
  QF <- EF[!(bot_wk1 %in% 1) & !(N >= fl & N >= SPIKE_K * base), .(a = .N, e = uniqueN(cid500)), by = .(day, post)]
  defl <- QF[post == TRUE, log(mean(e) / mean(a))] - QF[post == FALSE, log(mean(e) / mean(a))]
  for (w in c(6L, 7L)) {
    XF <- list()
    for (t in DF[day - w >= as.integer(as.IDate(LONG_FROM)) & day + w - 1L <= as.integer(as.IDate(LONG_END)), day]) {
      if (t != as.integer(cc) && any(((t - w):(t + w - 1L)) %in% BADN)) next
      XF[[length(XF) + 1]] <- data.table(t = t, d = DF[day >= t & day <= t + w - 1L, mean(d)] - DF[day >= t - w & day <= t - 1L, mean(d)])
    }
    XF <- rbindlist(XF); a <- XF[t == as.integer(cc), d]
    for (pl in c("pre-cut dates", "all dates")) {
      x <- XF[t != as.integer(cc) & (pl == "all dates" | t + w - 1L < as.integer(cc) - 1L), d]
      RW[[length(RW) + 1]] <- data.table(wave_size_floor = fl, window_days = w, placebo = pl, estimate = a, ratio = exp(a), placebo_K = length(x), rank = 1L + sum(x >= a),
                                         rank_p = (1 + sum(x >= a)) / (1 + length(x)), placebo_max = max(x), wave_share_of_added_6v6 = (B6$wave_new[2] - B6$wave_new[1]) / (B6$new[2] - B6$new[1]),
                                         nonburst_ratio_6v6 = QF[post == TRUE, mean(a)] / QF[post == FALSE, mean(a)], entity_ratio_6v6 = QF[post == TRUE, mean(e)] / QF[post == FALSE, mean(e)],
                                         deflator = defl, implied_entity_effect = exp(a + defl))
    }
  }
}
RW <- rbindlist(RW); cat("## R2b. The primary statistic, the breakdown and the implied entity effect across wave and burst size floors (Base minus L1)\n"); print(RW)
FW <- rbind(RW[placebo == "pre-cut dates", .(floor = wave_size_floor, v = ratio, series = sprintf("Entry outside waves, Base minus L1, %d days", window_days))],
            RW[placebo == "pre-cut dates" & window_days == 6L, .(floor = wave_size_floor, v = implied_entity_effect, series = "Implied funding entities, 6 days")])
g <- ggplot(FW, aes(floor, v, colour = series)) + geom_vline(xintercept = SPIKE_MIN, colour = COL[["ink2"]], linewidth = 0.3, linetype = "dashed") + geom_hline(yintercept = 1, colour = COL[["ref"]], linewidth = 0.3) +
  geom_line(linewidth = 0.5) + geom_point(size = 1.4) + scale_x_log10(breaks = WAVE_FLOORS, labels = scales::comma) + scale_colour_manual(values = c(COL[["main"]], COL[["ink"]], COL[["ref"]])) +
  labs(x = "Minimum new addresses a day for a wave or burst (log scale; dashed: the rule)", y = "Ratio after / before", colour = NULL) + THEME_FIG
ggsave(file.path(DIR_FIG, "wave_floors.png"), g, width = 8, height = 4, dpi = 200, bg = "white")
a2 <- a26
# R3. Designs that fail in different ways, with the assumption each needs (one row each; numbers from sections L, N, O, P)
R3 <- rbind(
  data.table(design = "Event-study leads, days -14..-1 (Base minus L1)", result = sprintf("%d of 14 leads outside the 5th-95th pre-cut band", EST[k < 0, sum(e < lo | e > hi)]), assumption = "no trend in Base minus L1 before the cut"),
  data.table(design = "Shift outside waves over the 6 low-fee days, Base minus L1 (7 days alongside)", result = sprintf("x%.2f; above all %d pre-cut placebos (%d non-overlapping); %.1f placebo SDs; 7 days x%.2f, above all %d",
             exp(a26), R2[window == "6 v 6" & placebo == "pre-cut dates", placebo_K], R2[window == "6 v 6" & placebo == "pre-cut dates", disjoint_K], R2[window == "6 v 6" & placebo == "pre-cut dates", z_placebo],
             exp(a27), R2[window == "7 v 7" & placebo == "pre-cut dates", placebo_K]),
             assumption = "L1 tracks Base's counterfactual; placebo windows exchangeable with the cut window"),
  data.table(design = "Run-up dip vs after (28 days around the cut, vs c-42..c-15)", result = sprintf("dip %.2f, after %.2f, net %.2f", LT3[statistic == "dip" & placebo == "all dates", value], LT3[statistic == "after" & placebo == "all dates", value], LT3[statistic == "net" & placebo == "all dates", value]),
             assumption = "a delay would show as a dip that offsets the rise"),
  data.table(design = "Hours 00-14 of the cut day, Base minus not-yet-cut Arbitrum", result = PM[baseline == "all pre-cut days" & outcome %in% c("new senders", "entrants at never-burst groups", "funding entities (non-burst)"),
             paste(sprintf("%s %+.2f (placebo days %.2f..%.2f)", outcome, estimate, placebo_min, placebo_max), collapse = "; ")], assumption = "Arbitrum's hours before its own cut track Base's"),
  data.table(design = "Base minus OP Mainnet, same upgrade, 7 days (active addresses)", result = sprintf("%+.2f log, placebo percentile %.2f", O2[cut == "Base March" & window_days == 7L & outcome == "log active addresses" & placebo == "pre-cut dates", base_minus_op],
             O2[cut == "Base March" & window_days == 7L & outcome == "log active addresses" & placebo == "pre-cut dates", placebo_pct]), assumption = "same fee change in week one; counts include batch accounts (activity, not participants)"))
cat("## R3. Evidence that fails in different ways\n"); print(R3)
# R4. Who the new accounts are, on the same 6 v 6 days (03-08..13 vs 03-14..19): Base window entrants by class (main burst rule; bot-like separate): entrants
#   and funding entities (components, h = 500) per day before and after, ratio; share of all entrants after the cut and of the added entrants; after the cut:
#   share in a funding cluster of >= CLUSTER_MIN, first tx in a same-block group (sync), share of the class held by its largest 10 / 100 components, months
#   active of Sep 2024, Dec 2024, Mar 2025 (0-3), on the LayerZero provisional Sybil list, address or funder also entering Arbitrum, tokens / ETH received after entry.
R4 <- EB[, .(entrants_before = sum(!post) / 6, entrants_after = sum(post) / 6,
             in_cluster_20 = mean(csize500[post] >= CLUSTER_MIN), same_block_group = mean(sync[post] == 1, na.rm = TRUE),
             months_active_of3 = mean((act_2024_09 + act_2024_12 + act_2025_03)[post]), layerzero_list = mean(lz[post], na.rm = TRUE),
             other_l2_address = mean(other_chain_addr[post], na.rm = TRUE), other_l2_funder = mean(other_chain_funder[post], na.rm = TRUE),
             tokens_after = mean(tok_after[post], na.rm = TRUE), eth_after = mean(eth_after[post], na.rm = TRUE)), by = class3]
R4 <- merge(EB[, .(e = uniqueN(cid500)), by = .(class3, post, day)][, .(entities_before = sum(e[!post]) / 6, entities_after = sum(e[post]) / 6), by = class3], R4, by = "class3")   # entities per day
R4 <- merge(R4, EB[post == TRUE, .N, by = .(class3, cid500)][order(-N), .(top10_share = sum(head(N, 10)) / sum(N), top100_share = sum(head(N, 100)) / sum(N)), by = class3], by = "class3")
R4[, `:=`(entrant_ratio = entrants_after / entrants_before, entity_ratio = entities_after / entities_before, share_after = entrants_after / sum(entrants_after),
          share_of_added = (entrants_after - entrants_before) / sum(entrants_after - entrants_before))]
cat("## R4. Base window entrants by class, 6 days before vs 6 days after the cut (03-08..13 vs 03-14..19)\n"); print(R4)
fwrite(R1, file.path(DIR_TAB, "headline_one_sample.csv")); fwrite(R2, file.path(DIR_TAB, "inference_primary.csv")); fwrite(RT, file.path(DIR_TAB, "inference_top_placebos.csv"))
fwrite(RW, file.path(DIR_TAB, "inference_wave_size_floors.csv"))
fwrite(R3, file.path(DIR_TAB, "evidence_designs.csv")); fwrite(R4, file.path(DIR_TAB, "entrant_classes_6v6.csv"))

# ---- S. The cut hour with pre-cut fake hours, and checks against a Base-specific demand shock ----
# S1. RD in time as in section P, with RI over fake hours that all lie before the cut: a 6-hour grid whose +-36 h window ends at least 1 hour before the cut
#   and lies inside the series (new senders: the whole hourly series from 02-15, or from 05-14 in May; other outcomes: the entrant window).
NSH <- rbind(PNL$l2_newsenders[, .(win = "march", chain, hr, new_senders)], PNL$may_hourly[chain == "base", .(win = "may", chain, hr, new_senders)])[, `:=`(y = log1p(new_senders), hod = hour(hr))]
S1 <- list()
for (i in seq_len(nrow(EV5w))) for (v in names(YP)) {
  w <- EV5w$win[i]; ch <- EV5w$chain[i]; t0 <- EV5w$t0[i]
  SR <- if (v == "new_senders") NSH[win == w & chain == ch] else HP[win == w & chain == ch][, y := log1p(get(v))]
  cd <- seq(min(SR$hr) + 36 * 3600, t0 - 37 * 3600, by = 6 * 3600)
  for (jj in which(EV5w$win == w)) cd <- cd[abs(as.numeric(cd - EV5w$t0[jj], units = "hours")) > 36]   # also more than 36 h from the other cuts in the window
  times <- c(t0, cd); b <- rep(NA_real_, length(times)); s1 <- NA_real_
  for (kk in seq_along(times)) {
    d <- SR[hr >= times[kk] - 36 * 3600 & hr < times[kk] + 36 * 3600 & !(hr %in% c(times[kk] - 3600, times[kk]))][, `:=`(post = as.integer(hr >= times[kk]), tt = as.numeric(hr - times[kk], units = "days"))]
    f <- try(feols(y ~ post + tt + tt:post | hod, data = d, vcov = NW(6) ~ hr), silent = TRUE)   # log(1 + y_t) = a + b Post_t + c1 tt + c2 tt Post_t + hod FE
    if (!inherits(f, "try-error")) { b[kk] <- coef(f)[["post"]]; if (kk == 1) s1 <- se(f)[["post"]] }
  }
  fk <- b[-1][is.finite(b[-1])]
  S1[[length(S1) + 1]] <- data.table(event = EV5w$event[i], outcome = YP[[v]], estimate = b[1], se = s1, ri_p_precut = (1 + sum(abs(fk) >= abs(b[1]))) / (1 + length(fk)), n_fake = length(fk),
                                     p_floor = 1 / (1 + length(fk)), fakes_from = format(min(cd)), fakes_to = format(max(cd)))
}
S1 <- rbindlist(S1); cat("## S1. The cut hour: RD with RI over fake hours before the cut only\n"); print(S1)
# S2. Is the March rise one app's boom? Base non-burst window entrants, days c-6..c-1 vs c..c+5: entrants and funding entities per day, all and without the
#   entrants whose first recipient is among the 10 or 20 most common first recipients after the cut.
E6 <- PNL$entrants[!is.na(wave) & chain == "base" & class3 == "genuine" & day >= cc - 6L & day <= cc + 5L][, post := day >= cc]
TOPR <- E6[post == TRUE & !is.na(first_to), .N, by = first_to][order(-N)]; S2 <- list()
for (k in c(0L, 10L, 20L)) {
  X <- if (k == 0L) E6 else E6[!(first_to %in% TOPR$first_to[seq_len(k)])]
  s <- X[, .(n = .N, e = uniqueN(cid500)), by = .(post, day)][, .(entrants = sum(n) / 6, entities = sum(e) / 6), by = post][order(post)]   # entities per day
  S2[[length(S2) + 1]] <- data.table(sample = if (k == 0L) "all non-burst entrants" else sprintf("without the top %d first recipients", k), entrants_before = s$entrants[1], entrants_after = s$entrants[2],
                                     entrant_ratio = s$entrants[2] / s$entrants[1], entity_ratio = s$entities[2] / s$entities[1], top_share_after = if (k == 0L) NA_real_ else sum(TOPR$N[seq_len(k)]) / E6[post == TRUE, .N])
}
S2 <- rbindlist(S2); cat("## S2. Base March non-burst entry without the most common first recipients after the cut\n"); print(S2)
# The 50 most common first recipients, named in panel recipient_labels, with their entrants per day before and after; and non-burst entry by the category of
#   the first recipient (the fifty named ones; all other recipients as one group)
TOPL <- merge(TOPR[1:50, .(first_to, rank = .I)], PNL$recipient_labels[, .(first_to = address, name_tag, category, first_call)], by = "first_to", all.x = TRUE)
TOPL <- merge(TOPL, E6[first_to %in% TOPL$first_to, .(before = sum(!post) / 6, after = sum(post) / 6), by = first_to], by = "first_to")[, ratio := after / before][order(rank)]
cat(sprintf("## S2. The 50 most common first recipients of non-burst entrants after the cut (%.0f%% of them): entrants per day, 6 days before vs after\n", 100 * sum(TOPR$N[1:50]) / E6[post == TRUE, .N]))
print(TOPL, nrows = 60)
#   Boom-type recipients: NFT mints and claims, other tokens (memecoins and others) and the trading-bot router. Entities per day; shares of the rise in
#   addresses and in entities are relative to all non-burst entrants; single_tx_after = share of the category's post-cut entrants with one tx in their first
#   week (an exchange deposit address or a one-off bridge sends one). Also entry without the bridge and exchange recipients.
E6L <- merge(E6, TOPL[, .(first_to, category)], by = "first_to", all.x = TRUE)[is.na(category), category := "other recipients"][
  , grp := fifelse(category %in% c("nft mint or claim", "other token", "trading bot"), "boom-type recipients", "all but boom-type recipients")]
TOT <- E6L[, .(n = .N, e = uniqueN(cid500)), by = .(post, day)][, .(da = (sum(n[post]) - sum(n[!post])) / 6, de = (sum(e[post]) - sum(e[!post])) / 6)]
S2C <- rbind(E6L[, .(n = .N, e = uniqueN(cid500)), by = .(category, post, day)], E6L[, .(n = .N, e = uniqueN(cid500)), by = .(category = grp, post, day)],
             E6L[!(category %in% c("bridge", "exchange")), .(category = "all but bridge and exchange recipients", n = .N, e = uniqueN(cid500)), by = .(post, day)], use.names = TRUE)[
  , .(before = sum(n[!post]) / 6, after = sum(n[post]) / 6, entities_before = sum(e[!post]) / 6, entities_after = sum(e[post]) / 6), by = category][
  , `:=`(ratio = after / before, entity_ratio = entities_after / entities_before, share_of_increase = (after - before) / TOT$da, share_of_entity_increase = (entities_after - entities_before) / TOT$de)][
  order(category %like% "boom-type|^all but", -share_of_increase)]
S2C <- merge(S2C, rbind(E6L[post == TRUE, .(single_tx_after = mean(single_tx_wk1 == 1, na.rm = TRUE)), by = category], E6L[post == TRUE, .(single_tx_after = mean(single_tx_wk1 == 1, na.rm = TRUE)), by = .(category = grp)],
                        E6L[post == TRUE & !(category %in% c("bridge", "exchange")), .(category = "all but bridge and exchange recipients", single_tx_after = mean(single_tx_wk1 == 1, na.rm = TRUE))]),
             by = "category", sort = FALSE)
cat("## S2. Non-burst entrants per day by the category of their first recipient (the 50 named; boom-type recipients together), 6 days before vs after\n"); print(S2C)
# S3. Daily non-burst entrants and funding entities, both chains, window days (cuts: Base 03-14 00:00; Arbitrum 03-14 15:00 and 03-19 08:00). Day d is
#   plotted at d (its midpoint), so a cut at hour h of day d is drawn at d - 0.5 + h / 24; dotted: 03-20, when Base's fee rose thirtyfold.
S3 <- PNL$entrants[!is.na(wave) & class3 == "genuine", .(entrants = .N, entities = uniqueN(cid500)), by = .(chain, day)][order(chain, day)]
cat("## S3. Daily non-burst window entrants and the funding entities behind them\n"); print(dcast(S3, day ~ chain, value.var = c("entrants", "entities")))
FS3 <- melt(S3, id.vars = c("chain", "day"), variable.name = "measure")[, `:=`(chain_lab = factor(fifelse(chain == "base", "Base", "Arbitrum"), c("Base", "Arbitrum")),
                                                                              measure = fifelse(measure == "entrants", "Non-burst entrants", "Funding entities behind them"))]
g <- ggplot(FS3, aes(day, value, colour = measure)) + geom_vline(data = EVENTS[, .(d = as.Date(t0) - 0.5 + hour(t0) / 24, chain_lab = factor(fifelse(chain == "base", "Base", "Arbitrum"), c("Base", "Arbitrum")))], aes(xintercept = d),
  colour = COL[["ink2"]], linewidth = 0.3, linetype = "dashed") +
  geom_vline(data = data.table(d = as.Date("2024-03-20") - 0.5, chain_lab = factor("Base", c("Base", "Arbitrum"))), aes(xintercept = d), colour = COL[["ink2"]], linewidth = 0.3, linetype = "dotted") +
  geom_line(linewidth = 0.5) + geom_point(size = 1) + facet_wrap(~ chain_lab, ncol = 2, scales = "free_y") +
  scale_colour_manual(values = c(COL[["main"]], COL[["ref"]])) + scale_y_continuous(labels = scales::comma) + labs(x = NULL, y = "Per day") + THEME_FIG
ggsave(file.path(DIR_FIG, "entities_daily_march.png"), g, width = 9, height = 3.6, dpi = 200, bg = "white")
# S4. Base minus OP Mainnet with Base's batch accounts removed: Base active addresses minus its new addresses in waves that day (most batch accounts are
#   active only on their entry day), OP raw; also without 03-16 (the largest batch day). 6-day (primary) and 7-day shifts against pre-cut placebo dates, as O2.
GA <- merge(GD[, .(day, daa_base, daa_optimism)], LDN[chain == "base", .(day = as.integer(day), wave_new)], by = "day")[, d_adj := log(pmax(exp(daa_base) - wave_new, 1)) - daa_optimism][, d_raw := daa_base - daa_optimism]
S4 <- list()
for (w in c(6L, 7L)) for (v in c("d_raw", "d_adj")) for (drop316 in c(FALSE, TRUE)) {
  rr <- list()
  for (t in GA[day - w >= as.integer(as.IDate(LONG_FROM)) & day + w - 1L <= as.integer(as.IDate(LONG_END)), day]) {
    if (t != as.integer(cc) && any(((t - w):(t + w - 1L)) %in% BADG)) next
    Z <- GA[day >= t - w & day <= t + w - 1L & !(drop316 & day == as.integer(cc) + 2L)][, post := day >= t]; rr[[length(rr) + 1]] <- data.table(t = t, s = Z[post == TRUE, mean(get(v))] - Z[post == FALSE, mean(get(v))])
  }
  rr <- rbindlist(rr); a <- rr[t == as.integer(cc), s]; x <- rr[t != as.integer(cc) & t + w - 1L < as.integer(cc) - 1L, s]
  S4[[length(S4) + 1]] <- data.table(window_days = w, base_count = fifelse(v == "d_raw", "all active addresses", "without new addresses in waves"), without_03_16 = drop316, base_minus_op = a,
                                     placebo_K = length(x), placebo_pct = mean(x < a), rank_p = (1 + sum(x >= a)) / (1 + length(x)))
}
S4 <- rbindlist(S4); cat("## S4. Base minus OP Mainnet, 6 and 7 days, with Base's batch accounts removed and without 03-16 (pre-cut placebos)\n"); print(S4)
# S5. Timing against the ETH price: daily Base-minus-L1 entry outside waves (relative to the week before the cut) and the ETH/USD close, 03-01..03-21; mean of
#   the entry gap over ETH's rise to its peak (all before the cut). An inflow driven by the rally predicts a rising gap then.
S5 <- merge(D2[day >= as.IDate("2024-03-01") & day <= as.IDate("2024-03-21"), .(day, gap = d - D2[day >= cc - 7L & day <= cc - 1L, mean(d)])], PNL$eth_usd_daily[, .(day, eth_usd = close)], by = "day", all.x = TRUE)
cat("## S5. Base minus L1 entry outside waves (relative to the week before the cut) and ETH/USD, 03-01..03-21\n"); print(S5)
cat(sprintf("S5: ETH peak %s at %.0f; mean entry gap on ETH's rise (03-01 to the peak) %.3f\n", S5[which.max(eth_usd), day], S5[, max(eth_usd, na.rm = TRUE)], S5[day <= S5[which.max(eth_usd), day], mean(gap)]))
cat("## S5. Funding sources of the extra non-burst entrants (from M1): exchange withdrawals vs all\n"); print(M5[chain == "base" & source %in% c("exchange withdrawal", "individual, direct transfer", "bridge or relayer"), .(source, ratio, share_of_increase)])
fwrite(S1, file.path(DIR_TAB, "hour_rd_precut_ri.csv")); fwrite(S2, file.path(DIR_TAB, "entry_without_top_recipients.csv")); fwrite(TOPL, file.path(DIR_TAB, "entry_top_recipients.csv"))
fwrite(S2C, file.path(DIR_TAB, "entry_by_recipient_category.csv")); fwrite(S3, file.path(DIR_TAB, "entities_daily_march.csv"))
# S6. The cut day hour by hour: non-burst window entrants and the funding entities behind them on 03-14 in blocks of hours (00-05, 06-11, 12-14, 15-23;
#   Arbitrum's first cut is at 15:00), against the same blocks on each of the six days before (03-08..13): count on the cut day, mean, minimum and maximum
#   before, log change from the mean, and Base minus Arbitrum for the blocks before Arbitrum's cut; the hourly median fee per tx (fee_quantiles_hourly, in ETH,
#   times the day's ETH/USD close) on the cut day and before, by block. Placebo days: each of 03-08..13 against the mean of the other five, Base minus Arbitrum,
#   for entrants and entities in the blocks before 15:00; the cut day against the mean of all six. Figure: hourly non-burst entrants on 03-13..15 against the
#   range of the same hour of day over 03-08..13, and the hourly median fee on both chains.
HB <- PNL$entrants[!is.na(wave) & class3 == "genuine" & day >= cc - 6L & day <= cc][, blk := fcase(hour(hr) <= 5, "00-05", hour(hr) <= 11, "06-11", hour(hr) <= 14, "12-14", default = "15-23")]
HB <- HB[, .(entrants = .N, entities = uniqueN(cid500)), by = .(chain, day, blk)]
S6 <- merge(HB[day == cc, .(chain, blk, cut_day_entrants = entrants, cut_day_entities = entities)],
            HB[day < cc, .(pre_mean = mean(entrants), pre_min = min(entrants), pre_max = max(entrants), pre_mean_entities = mean(entities), pre_max_entities = max(entities)), by = .(chain, blk)], by = c("chain", "blk"))[
  , `:=`(log_change = log(cut_day_entrants / pre_mean), log_change_entities = log(cut_day_entities / pre_mean_entities), above_all_prior_days = cut_day_entrants > pre_max)]
S6 <- merge(S6, S6[chain == "base", .(blk, b = log_change)][S6[chain == "arbitrum", .(blk, a = log_change)], on = "blk"][blk != "15-23", .(blk, base_minus_arbitrum = b - a)], by = "blk", all.x = TRUE)[order(chain, blk)]
FQ6 <- merge(PNL$fee_quantiles_hourly[as.IDate(hr) >= cc - 6L & as.IDate(hr) <= cc + 1L][, day := as.IDate(hr)], PNL$eth_usd_daily[, .(day, usd = close)], by = "day")[
  , `:=`(fee_usd = p50 * usd, blk = fcase(hour(hr) <= 5, "00-05", hour(hr) <= 11, "06-11", hour(hr) <= 14, "12-14", default = "15-23"))]
S6 <- merge(S6, FQ6[day == cc, .(cut_day_fee_usd = median(fee_usd), cut_day_fee_max_usd = max(fee_usd)), by = .(chain, blk)], by = c("chain", "blk"))
S6 <- merge(S6, FQ6[day < cc, .(pre_fee_usd = median(fee_usd)), by = .(chain, blk)], by = c("chain", "blk"))[order(chain, blk)]
cat("## S6. The cut day in blocks of hours: non-burst entrants and funding entities on 03-14 against the same hours of 03-08..13, and the hourly median fee\n"); print(S6)
PD <- list()
for (dd in seq(as.integer(cc) - 6L, as.integer(cc))) for (v in c("entrants", "entities")) {
  oth <- setdiff(seq(as.integer(cc) - 6L, as.integer(cc) - 1L), dd)
  X <- HB[blk != "15-23", .(own = log(get(v)[as.integer(day) == dd]) - log(mean(get(v)[as.integer(day) %in% oth]))), by = .(chain, blk)]
  PD[[length(PD) + 1]] <- X[, .(day = dd, measure = v, d = own[chain == "base"] - own[chain == "arbitrum"]), by = blk]
}
S6P <- rbindlist(PD)[, .(cut_day = d[day == as.integer(cc)], placebo_days = sum(day < as.integer(cc)), placebo_min = min(d[day < as.integer(cc)]), placebo_max = max(d[day < as.integer(cc)])), by = .(measure, blk)][
  , above_all_placebo_days := cut_day > placebo_max]
cat("## S6. Base minus Arbitrum in blocks of hours before Arbitrum's cut: the cut day against each pre-cut day (against the other five)\n"); print(S6P)
HH <- HP[win == "march" & as.IDate(hr) >= cc - 6L & as.IDate(hr) <= cc + 1L, .(chain, hr, nonburst, hod = hour(hr), day = as.IDate(hr))]
HH <- merge(HH[day >= cc - 1L], HH[day < cc, .(lo = min(nonburst), hi = max(nonburst), mid = mean(nonburst)), by = .(chain, hod)], by = c("chain", "hod"))[
  , chain_lab := factor(fifelse(chain == "base", "Base (cut 14 Mar 00:00)", "Arbitrum (cut 14 Mar 15:00)"), c("Base (cut 14 Mar 00:00)", "Arbitrum (cut 14 Mar 15:00)"))]
g <- ggplot(HH, aes(hr)) + geom_ribbon(aes(ymin = lo, ymax = hi), fill = COL[["band"]]) + geom_line(aes(y = mid), colour = COL[["ref"]], linewidth = 0.3) +
  geom_vline(data = EVENTS[t0 < as.POSIXct(cc + 1L, tz = "UTC"), .(t0, chain_lab = factor(fifelse(chain == "base", "Base (cut 14 Mar 00:00)", "Arbitrum (cut 14 Mar 15:00)"),
             c("Base (cut 14 Mar 00:00)", "Arbitrum (cut 14 Mar 15:00)")))], aes(xintercept = t0), colour = COL[["ink2"]], linewidth = 0.3, linetype = "dashed") +
  geom_line(aes(y = nonburst), colour = COL[["main"]], linewidth = 0.5) + facet_wrap(~ chain_lab, ncol = 1, scales = "free_y") + scale_y_continuous(labels = scales::comma) +
  scale_x_datetime(date_breaks = "12 hours", date_labels = "%d %b\n%H:00") + labs(x = "Hour (UTC)", y = "Non-burst entrants per hour\n(band: same hour, 8-13 Mar)") + THEME_FIG
FF <- FQ6[day >= cc - 1L & day <= cc + 1L, .(hr, fee_usd, chain_lab = factor(fifelse(chain == "base", "Base", "Arbitrum"), c("Base", "Arbitrum")))]
g2 <- ggplot(FF, aes(hr, fee_usd, colour = chain_lab)) + geom_vline(xintercept = EVENTS[t0 < as.POSIXct(cc + 1L, tz = "UTC"), t0], colour = COL[["ink2"]], linewidth = 0.3, linetype = "dashed") +
  geom_line(linewidth = 0.5) + scale_y_log10(labels = scales::dollar) + scale_colour_manual(values = c(COL[["main"]], COL[["ref"]])) +
  scale_x_datetime(date_breaks = "12 hours", date_labels = "%d %b\n%H:00") + labs(x = "Hour (UTC)", y = "Median fee per tx\n(US$, log scale)", colour = NULL) + THEME_FIG
ggsave(file.path(DIR_FIG, "cut_day_hours.png"), gridExtra::arrangeGrob(g + labs(x = NULL), g2, ncol = 1, heights = c(2, 1)), width = 9, height = 6.8, dpi = 200, bg = "white")
# S7. First action of Base non-burst window entrants, 6 days before vs after the cut (03-08..13 vs 03-14..19), by 4-byte selector as section G: native or
#   zero-value transfer; DEX swap (SWAP_SELECTORS); mint or claim (CLAIM_MINT_SELECTORS); token transfer or approval; other contract call. Entrants and funding
#   entities per day, ratio, share of the rise; and all non-burst entry without the DEX-swap first actions. The selector lists miss most mints and several swap
#   routers, so a swap-like class adds first recipients named as DEX routers, aggregators or a trading bot (recipient_labels). A first action is not intent.
E6[, type := fcase(is.na(first_sel) | first_sel == "0x", "native or zero-value transfer", first_sel %in% SWAP_SELECTORS, "DEX swap", first_sel %in% CLAIM_MINT_SELECTORS, "mint or claim",
                   first_sel %in% c("0xa9059cbb", "0x095ea7b3"), "token transfer or approval", default = "other contract call")]
E6[, swap_like := type == "DEX swap" | first_to %in% PNL$recipient_labels[category %in% c("dex router", "dex aggregator", "trading bot"), address]]
S7 <- rbind(E6[, .(n = .N, e = uniqueN(cid500)), by = .(type, post, day)],
            E6[type != "DEX swap", .(type = "all but DEX-swap first actions", n = .N, e = uniqueN(cid500)), by = .(post, day)],
            E6[swap_like == TRUE, .(type = "swap-like: DEX-swap selector or a named DEX router, aggregator or trading bot", n = .N, e = uniqueN(cid500)), by = .(post, day)],
            E6[swap_like == FALSE, .(type = "all but swap-like first actions", n = .N, e = uniqueN(cid500)), by = .(post, day)],
            E6[, .(type = "all", n = .N, e = uniqueN(cid500)), by = .(post, day)], use.names = TRUE)[
  , .(before = sum(n[!post]) / 6, after = sum(n[post]) / 6, entities_before = sum(e[!post]) / 6, entities_after = sum(e[post]) / 6), by = type][
  , `:=`(ratio = after / before, entity_ratio = entities_after / entities_before, share_of_rise = (after - before) / E6[, (sum(post) - sum(!post)) / 6])]
cat("## S7. Base non-burst window entrants by first action, 6 days before vs after the cut\n"); print(S7)
fwrite(S4, file.path(DIR_TAB, "base_minus_op_adjusted.csv")); fwrite(S5, file.path(DIR_TAB, "timing_eth.csv")); fwrite(S6, file.path(DIR_TAB, "cut_day_hours.csv"))
fwrite(S7, file.path(DIR_TAB, "entry_by_first_action.csv")); fwrite(S6P, file.path(DIR_TAB, "cut_day_hours_placebo_days.csv"))

# ---- T. The four cuts in one table: the jump at the cut hour (pre-cut fake hours) and the entry shift up to the chain's next cut ----
# Per cut, on the cutting chain: (1) the RD jump at the cut hour in new senders, entrants at never-burst groups and funding entities, each with RI over fake
# hours before the cut (section S1). (2) The shift in log entry outside waves (long series), cutting chain minus Ethereum L1, as N1 with equal windows of w
# days: pre = c-w..c-1, post = c+g..c+g+w-1, c = the day of the cut, g = days left out (Base March 0, cut at 00:00; Arbitrum steps 1 and 2: 1, the cut day;
# Base May 3, the step days 05-28..30); the post window ends before the chain's next cut and the pre window starts after its previous cut, w <= 7 (Arbitrum
# step 1: 03-15..18; step 2: 03-15..18 vs 03-20..23). Placebo dates: windows of the same shape holding no cut day (BADN); pre-cut = ending before 03-13 (for
# May, also starting after 03-19). (3) The median fee per tx (growthepie daily median, US$) over the same pre and post days, its log change, and the dollars
# a typical non-burst entrant saves in its first week = (fee pre - fee post) x median first-week txs of non-burst entrants before the cut (section H).
CUT4 <- data.table(short = c("Base Mar (6 low-fee days)", "Base Mar", "Arb 1", "Arb 2", "Base May"), th_short = c("Base Mar", "Base Mar", "Arb 1", "Arb 2", "Base May"),
                   event = c(EVENTS$event[1], EVENTS$event, EVENTS_MAY$event[1]), chain = c("base", "base", "arbitrum", "arbitrum", "base"),
                   c = as.integer(as.IDate(c(EVENTS$t0[1], EVENTS$t0, EVENTS_MAY$t0[1]))), g = c(0L, 0L, 1L, 1L, 3L), w = c(6L, 7L, 4L, 4L, 7L))   # Base March also over its 6 low-fee days
T1 <- list()
for (i in seq_len(nrow(CUT4))) {
  ch <- CUT4$chain[i]; cj <- CUT4$c[i]; g <- CUT4$g[i]; w0 <- CUT4$w[i]; X4 <- list()
  for (t in seq(as.integer(as.IDate(LONG_FROM)) + w0, as.integer(as.IDate(LONG_END)) - g - w0 + 1L)) {
    if (t != cj && any(((t - w0):(t + g + w0 - 1L)) %in% BADN)) next
    D <- LDN[chain %in% c(ch, LONG_CONTROL) & as.integer(day) %in% c((t - w0):(t - 1L), (t + g):(t + g + w0 - 1L))][, post := as.integer(day) >= t + g]
    X4[[length(X4) + 1]] <- D[, .(s = mean(log(nonwave[post])) - mean(log(nonwave[!post]))), by = chain][, .(t = t, own = s[chain == ch], l1 = s[chain == LONG_CONTROL])]
  }
  X4 <- rbindlist(X4)[, d := own - l1]; a <- X4[t == cj]
  for (pl in c("pre-cut dates", "all dates")) {
    x <- X4[t != cj]
    if (pl == "pre-cut dates") x <- if (CUT4$short[i] == "Base May") x[t - w0 > A319 & t + g + w0 - 1L < cj] else x[t + g + w0 - 1L < as.integer(as.IDate(L1_FORK))]
    dk <- 0L; le <- -Inf
    for (u in sort(x$t)) if (u - w0 > le) { dk <- dk + 1L; le <- u + g + w0 - 1L }   # greedy count of non-overlapping windows
    fe <- PNL$multichain_daily[chain == ch]; f0 <- fe[as.integer(date) >= cj - w0 & as.integer(date) <= cj - 1L, median(cost)]; f1 <- fe[as.integer(date) >= cj + g & as.integer(date) <= cj + g + w0 - 1L, median(cost)]
    T1[[length(T1) + 1]] <- data.table(cut = CUT4$short[i], event = CUT4$event[i], placebo = pl, window_days = w0,
      pre_days = sprintf("%s..%s", format(as.IDate(cj - w0), "%m-%d"), format(as.IDate(cj - 1L), "%m-%d")), post_days = sprintf("%s..%s", format(as.IDate(cj + g), "%m-%d"), format(as.IDate(cj + g + w0 - 1L), "%m-%d")),
      median_fee_pre_usd = f0, median_fee_post_usd = f1, log_fee_change = log(f1) - log(f0), saving_first_week_usd = (f0 - f1) * TH[short == CUT4$th_short[i], q_nonburst],
      jump_new_senders = S1[event == CUT4$event[i] & outcome == YP[["new_senders"]], estimate], p_new_senders_precut_fakes = S1[event == CUT4$event[i] & outcome == YP[["new_senders"]], ri_p_precut],
      jump_never_burst_groups = S1[event == CUT4$event[i] & outcome == YP[["never_burst_groups"]], estimate], p_never_burst_precut_fakes = S1[event == CUT4$event[i] & outcome == YP[["never_burst_groups"]], ri_p_precut],
      jump_entities = S1[event == CUT4$event[i] & outcome == YP[["entities"]], estimate], p_entities_precut_fakes = S1[event == CUT4$event[i] & outcome == YP[["entities"]], ri_p_precut],
      fakes_entrant_outcomes = S1[event == CUT4$event[i] & outcome == YP[["entities"]], n_fake],
      shift_outside_waves_own = a$own, shift_outside_waves_l1 = a$l1, shift_minus_l1 = a$d, ratio_minus_l1 = exp(a$d), placebo_K = nrow(x), disjoint_K = dk,
      placebo_pct = mean(x$d < a$d), p_one_sided = (1 + sum(x$d >= a$d)) / (1 + nrow(x)), p_floor = 1 / (1 + nrow(x)))
  }
}
T1 <- rbindlist(T1)
cat("## T1. The four cuts: fee change over the comparison days, jump at the hour (RI over pre-cut fake hours), entry outside waves minus L1 up to the next cut\n"); print(T1)
fwrite(T1, file.path(DIR_TAB, "four_cuts_summary.csv"))

# ---- U. How long the March fee stayed low, whether the same cut moved OP Mainnet, and how Ethereum L1 compares with other chains ----
# U1. Daily median fee per tx (growthepie, US$) on Base, OP Mainnet, Arbitrum and Ethereum L1, 2024-03-01..04-07; medians over the 6 and 7 days before the
#   cut (03-08..13, 03-07..13), the 6 low-fee days (03-14..19), days 6-13 (03-20..27) and the Table 1 windows for Base (03-08..12 vs 03-14..21), with the log
#   change from the 6 days before. Figure: the daily fee on the four chains, 02-15..04-15 (log scale), cut days dashed.
FP <- PNL$multichain_daily[chain %in% c("base", "optimism", "arbitrum", LONG_CONTROL) & date >= as.IDate("2024-02-15") & date <= as.IDate("2024-04-15")]
cat("## U1. Daily median fee per tx (US$), 03-01..04-07\n"); print(dcast(FP[date >= as.IDate("2024-03-01") & date <= as.IDate("2024-04-07")], date ~ chain, value.var = "cost"), nrows = 50)
PER <- data.table(period = c("before, 6 days: 03-08..13", "before, 7 days: 03-07..13", "days 0-5: 03-14..19", "days 6-13: 03-20..27", "Table 1 before: 03-08..12", "Table 1 after: 03-14..21"),
                  d0 = as.IDate(c("2024-03-08", "2024-03-07", "2024-03-14", "2024-03-20", "2024-03-08", "2024-03-14")), d1 = as.IDate(c("2024-03-13", "2024-03-13", "2024-03-19", "2024-03-27", "2024-03-12", "2024-03-21")))
U1 <- FP[PER, on = .(date >= d0, date <= d1), .(period, chain, cost), allow.cartesian = TRUE][, .(median_fee_usd = median(cost)), by = .(period, chain)]
U1 <- merge(U1, U1[period == "before, 6 days: 03-08..13", .(chain, ref = median_fee_usd)], by = "chain")[, log_change_from_before := log(median_fee_usd) - log(ref)][, ref := NULL][order(match(period, PER$period), chain)]
cat("## U1. Median fee per tx by period (median of daily medians, US$) and the log change from the 6 days before the cut\n"); print(U1)
LABU <- c(base = "Base", optimism = "OP Mainnet", arbitrum = "Arbitrum", ethereum = "Ethereum L1")
g <- ggplot(FP[, .(date, cost, chain_lab = factor(LABU[chain], LABU))], aes(date, cost, colour = chain_lab, linetype = chain_lab)) +
  geom_vline(xintercept = as.Date(c(EVENTS$t0[1], EVENTS$t0[3])), colour = COL[["ink2"]], linewidth = 0.3, linetype = "dashed") + geom_line(linewidth = 0.5) +
  scale_y_log10(labels = scales::dollar) + scale_colour_manual(values = c(COL[["main"]], COL[["ref"]], COL[["ink2"]], COL[["ink"]])) + scale_linetype_manual(values = c("solid", "solid", "dashed", "dotted")) +
  labs(x = NULL, y = "Median fee per transaction (US$, log scale)", colour = NULL, linetype = NULL) + THEME_FIG
ggsave(file.path(DIR_FIG, "fee_daily_march.png"), g, width = 8, height = 4, dpi = 200, bg = "white")
# U2. Did the same cut move OP Mainnet? growthepie daily log active addresses, log transactions and log median fee: OP Mainnet minus Ethereum L1, Base minus
#   L1 and Base minus OP Mainnet; shift over w = 7 and 6 days (c..c+w-1 vs c-w..c-1, c = 03-14) against placebo dates holding no cut day (BADN), pre-cut
#   (windows end before 03-13) and all dates. Event study of log active addresses for the three pairs as in section L (relative to c-7..c-1; band from pre-cut
#   placebo dates). growthepie's active addresses include batch accounts on every chain.
GE <- dcast(PNL$multichain_daily[chain %in% c("base", "optimism", LONG_CONTROL) & date >= LONG_FROM & date <= as.IDate(LONG_END), .(chain, day = as.integer(date), daa = log(daa), tx = log(txcount), fee = log(cost))],
            day ~ chain, value.var = c("daa", "tx", "fee"))
PAIRS <- data.table(pair = c("OP Mainnet minus Ethereum L1", "Base minus Ethereum L1", "Base minus OP Mainnet"), a = c("optimism", "base", "base"), b = c(LONG_CONTROL, LONG_CONTROL, "optimism"))
U2 <- list(); ESU <- list(); cmar <- as.integer(cc)
for (i in seq_len(nrow(PAIRS))) {
  for (v in c("daa", "tx", "fee")) GE[, (paste0("d_", v)) := get(paste0(v, "_", PAIRS$a[i])) - get(paste0(v, "_", PAIRS$b[i]))]
  for (w0 in c(7L, 6L)) {
    rr <- list()
    for (t in GE[day - w0 >= as.integer(as.IDate(LONG_FROM)) & day + w0 - 1L <= as.integer(as.IDate(LONG_END)), day]) {
      if (t != cmar && any(((t - w0):(t + w0 - 1L)) %in% BADN)) next
      Z <- GE[day >= t - w0 & day <= t + w0 - 1L][, post := day >= t]
      rr[[length(rr) + 1]] <- data.table(t = t, d_daa = Z[post == TRUE, mean(d_daa)] - Z[post == FALSE, mean(d_daa)], d_tx = Z[post == TRUE, mean(d_tx)] - Z[post == FALSE, mean(d_tx)],
                                         d_fee = Z[post == TRUE, mean(d_fee)] - Z[post == FALSE, mean(d_fee)])
    }
    rr <- rbindlist(rr)
    for (v in c("d_daa", "d_tx", "d_fee")) for (pl in c("pre-cut dates", "all dates")) {
      a <- rr[t == cmar, get(v)]; x <- rr[t != cmar & (pl == "all dates" | t + w0 - 1L < cmar - 1L), get(v)]
      U2[[length(U2) + 1]] <- data.table(pair = PAIRS$pair[i], window_days = w0, outcome = c(d_daa = "log active addresses", d_tx = "log transactions", d_fee = "log median fee per tx")[[v]],
                                         placebo = pl, shift = a, placebo_K = length(x), placebo_pct = mean(x < a), p_high = (1 + sum(x >= a)) / (1 + length(x)), p_low = (1 + sum(x <= a)) / (1 + length(x)),
                                         p_floor = 1 / (1 + length(x)))
    }
  }
  for (t in c(cmar, GE[day - 14L >= as.integer(as.IDate(LONG_FROM)) & day + 14L < cmar - 1L, day])) {
    ref <- GE[day >= t - 7L & day <= t - 1L, mean(d_daa)]; ESU[[length(ESU) + 1]] <- GE[day >= t - 14L & day <= t + 14L, .(pair = PAIRS$pair[i], placebo = t != cmar, k = day - t, e = d_daa - ref)]
  }
}
U2 <- rbindlist(U2); ESU <- rbindlist(ESU)
ESU <- merge(ESU[placebo == FALSE, .(pair, k, e)], ESU[placebo == TRUE, .(placebo_K = .N, lo = quantile(e, 0.05, names = FALSE), hi = quantile(e, 0.95, names = FALSE)), by = .(pair, k)], by = c("pair", "k"))
cat("## U2. The March cut on OP Mainnet: shifts of growthepie series, OP Mainnet minus L1, Base minus L1, Base minus OP Mainnet, against placebo dates\n"); print(U2)
cat("## U2. Event study: log active addresses for the three pairs, relative to the week before the cut (band: 5th-95th percentile, pre-cut placebo dates)\n"); print(dcast(ESU, k ~ pair, value.var = c("e", "lo", "hi")))
g <- ggplot(ESU[, panel := factor(pair, PAIRS$pair)], aes(k, e)) + geom_ribbon(aes(ymin = lo, ymax = hi), fill = COL[["band"]]) + geom_hline(yintercept = 0, colour = COL[["ref"]], linewidth = 0.3) +
  geom_vline(xintercept = -0.5, colour = COL[["ink2"]], linewidth = 0.3, linetype = "dashed") + geom_line(colour = COL[["main"]], linewidth = 0.5) + geom_point(colour = COL[["main"]], size = 1.1) +
  facet_wrap(~ panel, ncol = 3) + labs(x = "Days from the Ecotone cut on Base and OP Mainnet (14 Mar 2024)", y = "Log active addresses, difference\n(relative to the week before)") + THEME_FIG
ggsave(file.path(DIR_FIG, "op_mainnet_event_study.png"), g, width = 10, height = 3.6, dpi = 200, bg = "white")
# U3. Is Ethereum L1 a flattering comparison? Donor chains: growthepie chains with daily active addresses and fees on every day of LONG_FROM..LONG_END whose
#   median fee over the 6 low-fee days (03-14..19) fell less than 1 log against the 6 days before, other than Base, OP Mainnet, Arbitrum and L1. Outcome: log
#   daily active addresses (aggregate, batch accounts included, so this checks the comparison chain, not the primary outcome). 6-day shift at 03-14 (as R2) of
#   Base minus each donor, minus the donors' mean log, and minus L1; of L1 minus the donor mean; and of each chain alone; against pre-cut and all-dates placebo
#   dates holding no cut day (BADN).
FC <- PNL$multichain_daily[date >= LONG_FROM & date <= as.IDate(LONG_END), .(full = sum(!is.na(daa) & daa > 0 & !is.na(cost) & cost > 0) == as.integer(as.IDate(LONG_END) - LONG_FROM) + 1L,
                                                                             dfee = log(median(cost[date >= cc & date <= cc + 5L])) - log(median(cost[date >= cc - 6L & date < cc]))), by = chain]
DON <- FC[full == TRUE & !is.na(dfee) & dfee > -1 & !(chain %in% c("base", "optimism", "arbitrum", LONG_CONTROL)), chain]
cat(sprintf("## U3. Donor chains (fee fell less than 1 log over the low-fee days): %s\n", paste(DON, collapse = ", "))); print(FC[order(dfee)])
GU <- dcast(PNL$multichain_daily[chain %in% c("base", LONG_CONTROL, DON) & date >= LONG_FROM & date <= as.IDate(LONG_END), .(chain, day = as.integer(date), y = log(daa))], day ~ chain, value.var = "y")
GU[, donor_mean := rowMeans(.SD), .SDcols = DON]
for (v in c(LONG_CONTROL, "donor_mean", DON)) GU[, (paste0("base minus ", v)) := base - get(v)]
GU[, `L1 minus donor_mean` := get(LONG_CONTROL) - donor_mean]
U3 <- list()
for (v in c(paste("base minus", c(LONG_CONTROL, "donor_mean", DON)), "L1 minus donor_mean", "base", LONG_CONTROL, DON)) {
  rr <- list()
  for (t in GU[day - 6L >= as.integer(as.IDate(LONG_FROM)) & day + 5L <= as.integer(as.IDate(LONG_END)), day]) {
    if (t != as.integer(cc) && any(((t - 6L):(t + 5L)) %in% BADN)) next
    rr[[length(rr) + 1]] <- data.table(t = t, s = GU[day >= t & day <= t + 5L, mean(get(v))] - GU[day >= t - 6L & day <= t - 1L, mean(get(v))])
  }
  rr <- rbindlist(rr); a <- rr[t == as.integer(cc), s]
  for (pl in c("pre-cut dates", "all dates")) {
    x <- rr[t != as.integer(cc) & (pl == "all dates" | t + 5L < as.integer(cc) - 1L), s]
    U3[[length(U3) + 1]] <- data.table(series = v, placebo = pl, shift_6d = a, placebo_K = length(x), rank = 1L + sum(x >= a), placebo_pct = mean(x < a))
  }
}
U3 <- rbindlist(U3); cat("## U3. Log active addresses, 6-day shift at the cut: Base minus each donor, the donor mean and L1; L1 minus the donor mean; each chain alone\n"); print(U3)
fwrite(U1, file.path(DIR_TAB, "fee_path_march.csv")); fwrite(U2, file.path(DIR_TAB, "op_mainnet_vs_l1.csv")); fwrite(ESU, file.path(DIR_TAB, "op_mainnet_event_study.csv"))
fwrite(U3, file.path(DIR_TAB, "donor_pool_daa.csv"))

cat("\n## sessionInfo\n```\n"); print(sessionInfo()); cat("```\n"); sink()
