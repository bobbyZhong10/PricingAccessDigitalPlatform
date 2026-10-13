# 06_analysis_users.R: who responds. Entrants = addresses first active on 2024-03-01..27; campaign flags as in 00_setup.R.
#  A  entry and later activity around each drop: local randomization (W = 12/24/72 h), RI, marginal entrants; Base vs Arbitrum DiD
#  B  daily entrant cohorts
#  C  single-entity campaigns (burst rule, with size-only and funder-burst bounds); bot-like entrants as a separate class
#  D  campaign vs genuine entry; decomposition of Base's change in daily txs
#  E  response by the sender's own pre-drop fee level, net of a placebo window pair
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
# 03-01..03-28; p = share of fake |jump| >= |jump| (reported with at least 5 fakes). Row 1 of JUMP is the actual event, the rest are the fakes.
ys <- c(act_2024_04 = "active Apr 2024", act_2024_06 = "active Jun 2024", act_2024_09 = "active Sep 2024", act_2024_12 = "active Dec 2024", act_2025_03 = "active Mar 2025",
        any_later = "any activity in sampled months", months_active = "months active (of 10 sampled)", single_tx_wk1 = "single tx in first week", bot_wk1 = "bot-like (>= 100 txs in week 1)")
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
  ri <- rep(NA_real_, ncol(JUMP)); if (nrow(fk) >= 5) for (j in seq_len(ncol(JUMP))) ri[j] <- mean(abs(fk[, j]) >= abs(JUMP[1, j]))
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
# DiD at Base's drop (W = 12 h): did_v = jump_v(Base) - jump_v(Arbitrum), Arbitrum not yet treated; RI over grid times more than 36 h from any event
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
ri <- rep(NA_real_, ncol(DD)); for (j in seq_len(ncol(DD))) ri[j] <- mean(abs(fk[, j]) >= abs(DD[1, j]))
RD2 <- data.table(y = c("log entrants per hour", ys), base = J2_actual[1, ], arbitrum = J2_actual[2, ], did = DD[1, ], ri_p = ri)
cat(sprintf("## A. DiD at Base's drop (W = 12 h): Base change minus Arbitrum change; RI over %d fake times\n", nrow(fk))); print(RD2)
fwrite(RD2, file.path(DIR_TAB, "entry_retention_did_base_vs_arbitrum.csv"))

# ---- B. daily cohorts ----
DC <- E[, .(N = .N, single_tx_wk1 = mean(single_tx_wk1), active_apr24 = mean(act_2024_04), active_sep24 = mean(act_2024_09), active_mar25 = mean(act_2025_03), months_active_of5 = mean(months5)),
        by = .(chain, day)][day >= as.IDate("2024-03-04") & day <= as.IDate("2024-03-26")][order(chain, day)]
cat("## B. Daily entrant cohorts (UTC entry day)\n"); print(DC); fwrite(DC, file.path(DIR_TAB, "daily_cohorts.csv"))

# ---- C. campaigns on Base ----
X <- E[chain == "base" & !is.na(wave)][, campaign := as.integer(batch == 1 | wave == 1)]
cat(sprintf("C. Base entrants %s..%s: %d; in campaign bursts %d; funded by bursting funders %d\n", ENTRANT_WINDOW[1], ENTRANT_WINDOW[2], nrow(X), sum(X$wave), sum(X$batch)))
# concentration: share of the day's entrants whose first recipient / method / funder is the day's most common one (top1) or among the 10 most common (top10)
WD <- X[, .(N = .N, to_top1 = max(table(first_to)) / .N, to_top10 = sum(head(sort(table(first_to), decreasing = TRUE), 10)) / .N, sel_top1 = max(table(first_sel)) / .N,
            funder_top1 = max(table(funder_any)) / .N, funder_top10 = sum(head(sort(table(funder_any), decreasing = TRUE), 10)) / .N, no_funder_seen = mean(is.na(funder_any)),
            campaign = mean(wave), bursting_funder = mean(batch), months_active = mean(months5), months_active_noncampaign = mean(months5[wave == 0]), N_noncampaign = sum(wave == 0)), by = day][order(day)]
cat("## C. By entry day (Base): concentration of first recipient, method and funder\n"); print(WD)
cat("## C. Top first recipient x method and top funders on the largest campaign days\n")
for (d in as.IDate(c("2024-03-15", "2024-03-16", "2024-03-20"))) { y <- X[day == d]
  print(y[, .N, by = .(first_to, first_sel)][order(-N)][1:5][, share := round(N / nrow(y), 3)][]); print(y[!is.na(funder_any), .N, by = funder_any][order(-N)][1:5][, share := round(N / nrow(y), 3)][]) }
pre <- X[day >= as.IDate("2024-03-08") & day <= as.IDate("2024-03-12")]; post <- X[day >= as.IDate("2024-03-14") & day <= as.IDate("2024-03-21")]
SETS <- list("all entrants" = quote(TRUE), "genuine (main definition: not campaign, not bot-like)" = quote(class3 == "genuine"), "campaign bursts only" = quote(wave == 1),
             "bot-like only (>= 100 txs, week 1)" = quote(class3 == "bot"), "excluding campaign bursts (bots kept)" = quote(wave == 0), "excluding campaign bursts and bursting funders" = quote(campaign == 0))
WS <- list()
for (k in names(SETS)) WS[[k]] <- data.table(set = k, pre_per_day = pre[eval(SETS[[k]]), .N] / 5, post_per_day = post[eval(SETS[[k]]), .N] / 8,
                                             pre_months = pre[eval(SETS[[k]]), mean(months5)], post_months = post[eval(SETS[[k]]), mean(months5)])
WS <- rbindlist(WS)
WS[, `:=`(entry_ratio = post_per_day / pre_per_day, months_ratio = post_months / pre_months)]
cat(sprintf("Share of post-drop (03-14..21) Base entrants in campaign bursts: %.3f\n", post[, mean(wave)]))
cat("## C. Entry and retention, pre (Mar 8-12) vs post (Mar 14-21), with and without campaign addresses\n"); print(WS)
fwrite(WD, file.path(DIR_TAB, "campaigns_by_day_base.csv")); fwrite(WS, file.path(DIR_TAB, "campaigns_entry_retention_base.csv"))
# Campaign rule bounds: the main burst rule against a size-only rule and a rule that also requires bursting funders (00_setup.R); bot-like entrants
# are a separate class under every rule. Pre = 03-08..12; post = 03-14 (Base) or 03-15 (Arbitrum) to 03-21. Entry ratio = post / pre entrants per day.
rules <- c(wave = "main: burst vs own pre-shock level", wave_size = "bound: size only (>= 5,000 a day)", wave_funded = "bound: burst funded by bursting funders")
RB <- list()
for (ch in CHAINS) for (v in names(rules)) {
  Z <- E[chain == ch & !is.na(wave)][, cls := fcase(bot_wk1 == 1, "bot", get(v) == 1, "campaign", default = "genuine")]
  Zpre <- Z[day >= ENTRANT_WINDOW[1] & day <= as.IDate("2024-03-12")]; Zpost <- Z[day >= as.IDate(if (ch == "base") "2024-03-14" else "2024-03-15") & day <= ENTRANT_WINDOW[2]]
  RB[[length(RB) + 1]] <- data.table(chain = ch, rule = rules[[v]], campaign_share_pre = Zpre[, mean(cls == "campaign")], campaign_share_post = Zpost[, mean(cls == "campaign")],
    genuine_entry_ratio = (Zpost[cls == "genuine", .N] / uniqueN(Zpost$day)) / (Zpre[cls == "genuine", .N] / uniqueN(Zpre$day)),
    campaign_entry_ratio = (Zpost[cls == "campaign", .N] / uniqueN(Zpost$day)) / (Zpre[cls == "campaign", .N] / uniqueN(Zpre$day)),
    genuine_months_pre = Zpre[cls == "genuine", mean(months5)], genuine_months_post = Zpost[cls == "genuine", mean(months5)], campaign_months_post = Zpost[cls == "campaign", mean(months5)])
}
RB <- rbindlist(RB)
cat("## C. Campaign rule bounds (entry ratios = post / pre entrants per day; months active of the five retention months)\n"); print(RB)
fwrite(RB, file.path(DIR_TAB, "campaign_rule_bounds.csv"))

# ---- D. campaign vs genuine entry ----
EW <- E[!is.na(wave)][, grp2 := fcase(class3 == "campaign", "campaign", class3 == "bot", "bot-like (>= 100 txs, week 1)", default = "genuine")]
EW[, grp := fcase(class3 != "genuine", grp2, batch == 1, "genuine: bursting funder", default = "genuine: other")]
cat("## D. Entrants by group and chain (03-08..21)\n"); print(EW[, .N, by = .(chain, grp)][, share := round(N / sum(N), 3), by = chain][order(chain, grp)])
ev <- copy(EVENTS)[, `:=`(pre0 = as.IDate(c("2024-03-08", "2024-03-10", "2024-03-15")), pre1 = as.IDate(c("2024-03-12", "2024-03-13", "2024-03-18")),
                          post0 = as.IDate(c("2024-03-14", "2024-03-15", "2024-03-20")), post1 = as.IDate(c("2024-03-21", "2024-03-18", "2024-03-21")))]
# fee change over the daily windows: log(pooled fee per tx, post days) - log(pooled fee per tx, pre days)
HF <- l2_hourly[, .(n = sum(n), fee = sum(fee)), by = .(day = as.IDate(hr, tz = "UTC"), chain)]
dlf <- numeric(nrow(ev))
for (i in seq_len(nrow(ev))) { h <- HF[chain == ev$chain[i]]; dlf[i] <- log(h[day >= ev$post0[i] & day <= ev$post1[i], sum(fee) / sum(n)]) - log(h[day >= ev$pre0[i] & day <= ev$pre1[i], sum(fee) / sum(n)]) }
ev[, dlf := dlf]
cat("## D. Fee change over the daily windows (log, pooled fee per tx)\n"); print(ev[, .(event, pre = paste(pre0, pre1), post = paste(post0, post1), dlf = round(dlf, 3))])
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
# g = genuine, campaign, and their difference; RI over fake times on a 6-hour grid (03-09 12:00..03-24 12:00) more than 48 h from any event.
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
  R2[[i]] <- data.table(event = ev$event[i], genuine_dlog = S2[1, 1], campaign_dlog = S2[1, 2], diff = S2[1, 3], ri_p_genuine = mean(abs(fk[, 1]) >= abs(S2[1, 1])),
                        ri_p_campaign = mean(abs(fk[, 2]) >= abs(S2[1, 2])), ri_p_diff = mean(abs(fk[, 3]) >= abs(S2[1, 3])), n_fake = nrow(fk))
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
bins <- c(0, 0.005, 0.01, 0.02, 0.05, 0.10, 0.25, 0.50, Inf); labs <- c("<0.5c", "0.5-1c", "1-2c", "2-5c", "5-10c", "10-25c", "25-50c", ">50c")
evl <- data.table(name = EVENTS$event, chain = EVENTS$chain, pre = c("pre", "pre1", "post1"), post = c("post", "post1", "post2"))   # windows in FEE_WINDOWS
WP <- rbind(evl[, .(chain, pre, post)], data.table(chain = CHAINS, pre = "placebo_pre", post = "placebo_post"))   # every window pair needed
XW <- list(); SW <- list()   # sender-level changes and their per-bin summary, by "chain pre post"
for (k in seq_len(nrow(WP))) {
  ch <- WP$chain[k]; w0 <- FEE_WINDOWS[chain == ch & window == WP$pre[k]]; w1 <- FEE_WINDOWS[chain == ch & window == WP$post[k]]
  X <- merge(sender_window[chain == ch & window == WP$pre[k] & n >= 2, .(id, n0 = n, f0 = fee)], sender_window[chain == ch & window == WP$post[k], .(id, n1 = n, f1 = fee)],
             by = "id", all.x = TRUE)[is.na(n1), `:=`(n1 = 0, f1 = 0)]
  X <- X[f0 > 0]   # sponsored senders have no fee level
  X[, `:=`(lvl_usd = f0 / n0 * px[day >= w0$start & day <= w0$end, mean(usd)], dy = log1p(n1 / (as.integer(w1$end - w1$start) + 1L)) - log1p(n0 / (as.integer(w0$end - w0$start) + 1L)),
           dlf = fifelse(n1 > 0 & f1 > 0, log(f1 / n1) - log(f0 / n0), NA_real_))]
  X[, bin := cut(lvl_usd, bins, labels = labs, right = FALSE)]
  nm <- paste(ch, WP$pre[k], WP$post[k]); XW[[nm]] <- X
  SW[[nm]] <- X[, .(N = .N, dy = mean(dy), se_dy = sd(dy) / sqrt(.N), dlf = mean(dlf, na.rm = TRUE), se_dlf = sd(dlf, na.rm = TRUE) / sqrt(sum(!is.na(dlf))), lvl = median(lvl_usd)), by = bin]
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
# Meta-regression over cells (event x bin, N >= 500), weights 1 / se_el^2, heteroskedasticity-robust SEs:
#   elasticity_eb = a + d * log(fee level_eb) [+ event FE] + u_eb      (d < 0: more elastic at higher fee levels)
Rp <- RL[N >= 500 & is.finite(elasticity) & se_el > 0]
f1 <- feols(elasticity ~ log(lvl), data = Rp, weights = ~ 1 / se_el^2, vcov = "hetero"); f2 <- feols(elasticity ~ log(lvl) | event, data = Rp, weights = ~ 1 / se_el^2, vcov = "hetero")
cat("## E. Elasticity on log fee level (cells with N >= 500, inverse-variance weights); slope < 0 = more elastic at higher fees\n"); print(etable(f1, f2, se.below = TRUE))
# Within sender on Arbitrum: senders active before both steps; dy net of the placebo pair's mean change mr
X1 <- XW[["arbitrum pre1 post1"]]; X2 <- XW[["arbitrum post1 post2"]]
WS2 <- merge(X1[, .(id, lvl1 = lvl_usd, dy1 = dy, dlf1 = dlf)], X2[, .(id, lvl2 = lvl_usd, dy2 = dy, dlf2 = dlf)], by = "id")
mr <- SW[["arbitrum placebo_pre placebo_post"]][, weighted.mean(dy, N)]
WS2[, grp := cut(lvl2, c(0, 0.01, 0.02, 0.05, Inf), labels = c("step-2 level <1c", "1-2c", "2-5c", ">=5c"), right = FALSE)]
cat(sprintf("## E. Within-sender, Arbitrum (%d senders active before both steps); placebo mean dy %.3f\n", nrow(WS2), mr))
print(WS2[, .(N = .N, lvl_step1 = signif(median(lvl1), 2), lvl_step2 = signif(median(lvl2), 2), dy_step1 = round(mean(dy1) - mr, 3), dy_step2 = round(mean(dy2) - mr, 3),
              dlf_step1 = round(mean(dlf1, na.rm = TRUE), 2), dlf_step2 = round(mean(dlf2, na.rm = TRUE), 2)), by = grp][order(grp)])
fwrite(RL[, c(list(event = event, bin = bin, N = N, fee_level_usd = lvl), .SD), .SDcols = c("did_y", "se_y", "did_f", "se_f", "elasticity", "se_el", "dy", "se_dy", "dlf", "se_dlf", "N_pl", "dy_pl", "se_dy_pl", "dlf_pl", "se_dlf_pl")],
       file.path(DIR_TAB, "response_by_fee_level.csv"))
# Figure 4: elasticity by the sender's pre-drop fee level (bins with >= 500 senders)
# Confidence intervals beyond +-0.12 are cut at the panel edge and marked with an arrow.
lim <- 0.12
F4 <- RL[N >= 500][, `:=`(label = factor(EVENTS$label[match(event, EVENTS$event)], EVENTS$label), lo = pmax(elasticity - 1.96 * se_el, -lim), hi = pmin(elasticity + 1.96 * se_el, lim))]
g <- ggplot(F4, aes(lvl, elasticity)) + geom_hline(yintercept = 0, colour = COL[["ink2"]], linewidth = 0.3) +
  geom_linerange(aes(ymin = lo, ymax = hi), colour = COL[["main"]], linewidth = 0.6) + geom_point(colour = COL[["main"]], size = 2.2) +
  geom_segment(data = F4[elasticity + 1.96 * se_el > lim], aes(x = lvl, xend = lvl, y = lim - 0.01, yend = lim), colour = COL[["main"]], linewidth = 0.6, arrow = arrow(length = unit(5, "pt"))) +
  facet_wrap(~ label, nrow = 1) + scale_x_log10(labels = scales::dollar, breaks = c(0.03, 0.1, 0.3, 1)) + coord_cartesian(ylim = c(-lim, lim)) +
  labs(x = "Sender's fee per transaction before the drop (US$, log scale; bin median)", y = "Elasticity of the sender's transactions\nwith respect to the fee (95% CI)") + THEME_FIG
ggsave(file.path(DIR_FIG, "fig4_elasticity_by_fee_level.png"), g, width = 10, height = 3.6, dpi = 200, bg = "white")
cat("\n## sessionInfo\n```\n"); print(sessionInfo()); cat("```\n"); sink()
