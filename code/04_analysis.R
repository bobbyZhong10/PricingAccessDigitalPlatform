# 04_analysis.R: the Base March 2024 entry effect and who responds. Entrants = addresses first active on 2024-03-01..27 (March) or in MAY_WINDOW (May); burst
# rule as in 00_setup.R. Classes: burst accounts (code: class3 == "campaign"), bot-like entrants ("bot") and the rest (non-burst, "genuine").
#  A  burst accounts on Base by entry day (concentration of first recipient, method and funder)
#  B  window entrants by period around the March cuts and the second Base fee cut (May gas-limit increases), used in D and E
#  C  four fee cuts: median fee and dollar stakes (Chetty 2012); Table 1; platform economics
#  D  composition under leave-one-out variants (largest burst day, target, component; size-only rule)
#  E  the 20 largest burst groups (March, May)
#  F  2024-01..06, one definition of a new address: new addresses in and outside waves on Base, Arbitrum and Ethereum L1 (figure)
#  G  the Base March entry effect against L1: daily event study, window ratios against pre-cut and all placebo dates, delay vs new entry, persistence
#  H  where the extra non-burst entrants' first ETH came from (exchanges, bridges, individuals); funding clusters and entities
#  I  both Base cuts with one estimator against L1 and Arbitrum (placebo sets, p floors, non-overlapping windows)
#  J  May waves day by day
#  K  hourly counts in the entrant windows (new senders, non-burst entrants, entrants at never-burst groups, funding entities)
#  L  funding entities behind non-burst entry: accounting variants and the composition deflator; the implied entity effect
#  M  headline numbers from one sample; inference for the primary statistic (6 low-fee days, 7 days, the 4-7-day path; largest placebos; wave and
#     burst size floors); entrant classes on equal 6-day windows
#  N  the cut hour with pre-cut fake hours; checks against a Base-specific demand shock (first recipients and their categories, Base minus OP adjusted,
#     the ETH rally, the cut day in blocks of hours, first actions)
#  O  the four cuts in one table (jump at the hour, entry minus L1 up to each chain's next cut)
#  P  the daily fee path on four chains; the March cut on OP Mainnet against L1; a donor pool of chains without a fee cut against the L1 comparison
#  Q  the primary statistic under alternative counterfactuals (longer, pre-announcement and trend baselines) and outcome definitions (a stricter wave
#     threshold; first actions established before the window); the pre-cut reference set
source(here::here("code", "00_setup.R"))
sink(file.path(DIR_LOG, "04_analysis.md"), split = TRUE)
cat("# 04 analysis\nRun ", format(Sys.time(), usetz = TRUE), "\n", sep = "")
ct <- yaml::read_yaml(CONTRACT_FILE)   # panel.rds must have passed 03_validate_panels.R and be unchanged since
stopifnot(isTRUE(ct$all_valid), unname(tools::md5sum(PANEL_FILE)) == ct$md5)
PNL <- readRDS(PANEL_FILE)
E <- PNL$entrants
acts <- paste0("act_", gsub("-", "_", RETENTION_MONTHS)); E[, months5 := rowSums(.SD), .SDcols = acts]   # months active of the five retention months
cat(sprintf("Entrants: %s\n", paste(E[, .N, by = chain][, sprintf("%s %d", chain, N)], collapse = "; ")))

# ---- A. burst accounts on Base by entry day ----
X <- E[chain == "base" & !is.na(wave)]
cat(sprintf("A. Base entrants %s..%s: %d; in campaign bursts %d; funded by bursting funders %d\n", ENTRANT_WINDOW[1], ENTRANT_WINDOW[2], nrow(X), sum(X$wave), sum(X$batch)))
# concentration: share of the day's entrants whose first recipient / method / funder is the day's most common one (top1) or among the 10 most common (top10)
WD <- X[, .(N = .N, to_top1 = max(table(first_to)) / .N, to_top10 = sum(head(sort(table(first_to), decreasing = TRUE), 10)) / .N, sel_top1 = max(table(first_sel)) / .N,
            funder_top1 = max(table(funder_any)) / .N, funder_top10 = sum(head(sort(table(funder_any), decreasing = TRUE), 10)) / .N, no_funder_seen = mean(is.na(funder_any)),
            campaign = mean(wave), bursting_funder = mean(batch), months_active = mean(months5), months_active_noncampaign = mean(months5[wave == 0]), N_noncampaign = sum(wave == 0)), by = day][order(day)]
cat("## A. By entry day (Base): concentration of first recipient, method and funder\n"); print(WD)
fwrite(WD, file.path(DIR_TAB, "campaigns_by_day_base.csv"))

# ---- B. window entrants by period: the March cuts and the second Base fee cut ----
# March (Base and Arbitrum): pre = 03-08..12; post = 03-14..21 (Base) or 03-15..21 (Arbitrum).
# Second Base fee cut (platform raised the gas limit 05-28 19:00 and 05-30 20:00): pre = 05-21..27, post = 05-29..06-04 (05-28 left out), 7 days each.
# New = entrants with no earlier activity (March: since chain launch; May: since 02-15); May entrants are classified with the same rules (02 section F).
EV <-E[!is.na(wave)][, period := fcase(day <= as.IDate("2024-03-12"), "pre", day >= as.IDate(fifelse(chain == "base", "2024-03-14", "2024-03-15")), "post", default = NA_character_)][!is.na(period)]
MY <- PNL$may_entrants[chain == "base"][, period := fcase(day <= MAY_PRE_END, "pre", day >= MAY_PRE_END + 2, "post", default = NA_character_)][!is.na(period)]

# ---- C. dollar stakes across four fee cuts (Base March and May; Arbitrum steps 1 and 2), Table 1 and platform economics ----
# Windows: Base March pre 03-08..12, post 03-14..21; Arbitrum step 1 pre 03-10..13, post 03-15..18; step 2 pre 03-15..18, post 03-20..21;
# Base May pre 05-21..27, post 05-29..06-04 (section B).
# p = the price a typical tx pays: median over the window's days of growthepie's daily median fee per tx (US$); dlp = log(p_pre) - log(p_post).
# Individual entrant: q = median first-week txs of non-burst entrants before the cut; dollar stake of the cut = (p_pre - p_post) x q (Chetty 2012, eq. 17 in dollars).
# Operator: m = median first-week txs of burst accounts after the cut; identities per burst entity-day after the cut (the entity of the average account
# = sum N^2 / sum N); stake = (p_pre - p_post) x m x identities.
EVT <- data.table(event = c("Base, March 2024 (L1 cost pass-through)", "Arbitrum step 1 (L1 cost pass-through)", "Arbitrum step 2 (fee floor cut by the platform)",
                            "Base, May 2024 (capacity raised by the platform)"), short = c("Base Mar", "Arb 1", "Arb 2", "Base May"),
                  chain = c("base", "arbitrum", "arbitrum", "base"), src = c("mar", "mar", "mar", "may"),
                  pre0 = as.IDate(c("2024-03-08", "2024-03-10", "2024-03-15", "2024-05-21")), pre1 = as.IDate(c("2024-03-12", "2024-03-13", "2024-03-18", "2024-05-27")),
                  post0 = as.IDate(c("2024-03-14", "2024-03-15", "2024-03-20", "2024-05-29")), post1 = as.IDate(c("2024-03-21", "2024-03-18", "2024-03-21", "2024-06-04")))
GD <- PNL$multichain_daily
TH <- list()
for (i in seq_len(nrow(EVT))) {
  w <- EVT[i]
  X <- if (w$src == "mar") E[chain == w$chain & !is.na(wave)] else PNL$may_entrants[chain == "base"]
  X <- X[(day >= w$pre0 & day <= w$pre1) | (day >= w$post0 & day <= w$post1)][, period := fifelse(day <= w$pre1, "pre", "post")]
  p0 <- GD[chain == w$chain & date >= w$pre0 & date <= w$pre1, median(cost)]; p1 <- GD[chain == w$chain & date >= w$post0 & date <= w$post1, median(cost)]
  q <- X[period == "pre" & class3 == "genuine", median(n_week1)]; m <- X[period == "post" & class3 == "campaign", median(n_week1)]
  IE <- X[period == "post" & class3 == "campaign", .N, by = .(day, cid500)]; aw <- sum(IE$N^2) / sum(IE$N)
  TH[[i]] <- data.table(event = w$event, short = w$short, p_pre = p0, p_post = p1, dlp = log(p0) - log(p1), q_nonburst = q, stake_individual = (p0 - p1) * q,
    m_burst = m, ids_per_entity_day_acct_weighted = aw, stake_operator_acct_weighted = (p0 - p1) * m * aw)
}
TH <- rbindlist(TH)
cat("## C. Median fee per tx and dollar stakes of each cut\n"); print(TH)
# Table 1 (paper): the fee cuts, their timing and origin, and the median fee per tx in the windows used for entry comparisons
T1E <- data.table(short = TH$short, time_utc = c(format(EVENTS$t0, "%Y-%m-%d %H:00"), paste(format(EVENTS_MAY$t0, "%Y-%m-%d %H:00"), collapse = " and ")),
                  origin = c("Ethereum Dencun (EIP-4844) passed through: Base Ecotone upgrade", "Ethereum Dencun passed through: Arbitrum ArbOS 20", "Arbitrum governance: minimum L2 base fee 0.1 to 0.01 gwei",
                             "Base raised the block gas limit 60M to 75M to 90M (capacity)"),
                  set_by = c("cost pass-through", "cost pass-through", "platform", "platform"))
T1E <- merge(T1E, TH[, .(short, median_fee_pre = p_pre, median_fee_post = p_post, dlog_fee = -dlp, stake_individual, stake_operator_acct_weighted)], by = "short")[order(match(short, TH$short))]
cat("## C. Table 1: the fee cuts\n"); print(T1E); fwrite(T1E, file.path(DIR_TAB, "table1_fee_cuts.csv"))
# Platform economics of the four cuts (growthepie, US$ per day): fee revenue, L1 rent (data costs) and profit, mean over each window's days
#   dlog_x = log(mean x post) - log(mean x pre); margin = profit / fees
ECO <- list()
for (i in seq_len(nrow(EVT))) { w <- EVT[i]; e0 <- PNL$l2_economics_daily[chain == w$chain & date >= w$pre0 & date <= w$pre1]; e1 <- PNL$l2_economics_daily[chain == w$chain & date >= w$post0 & date <= w$post1]
  ECO[[i]] <- data.table(short = w$short, set_by = T1E[short == w$short, set_by], fees_pre = mean(e0$fees_usd), fees_post = mean(e1$fees_usd), rent_pre = mean(e0$rent_usd), rent_post = mean(e1$rent_usd),
                         profit_pre = mean(e0$profit_usd), profit_post = mean(e1$profit_usd)) }
ECO <- rbindlist(ECO)[, `:=`(dlog_fees = log(fees_post / fees_pre), dlog_rent = log(rent_post / rent_pre), dlog_profit = log(profit_post / profit_pre), margin_pre = profit_pre / fees_pre, margin_post = profit_post / fees_post)]
cat("## C. Platform economics of the four cuts (US$ per day)\n"); print(ECO); fwrite(ECO, file.path(DIR_TAB, "platform_economics.csv"))

# ---- D. composition under leave-one-out variants ----
# Key composition numbers under leave-one-out variants (Base, windows of section B): all entrants; without the largest post-cut burst day;
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
cat("## D. Composition under leave-one-out variants (Base)\n"); print(dcast(LO, event + metric ~ variant, value.var = "value")[order(event, match(metric, unique(LO$metric)))])
fwrite(LO, file.path(DIR_TAB, "composition_leave_one_out.csv"))

# ---- E. what the burst groups are ----
# The 20 largest post-cut burst groups (first recipient x method), March and May (Base): size, timing, single use, synchrony and Sybil-list overlap (March),
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
cat("## E. The 20 largest post-cut burst groups, March and May (Base)\n"); print(DS)
fwrite(DS, file.path(DIR_TAB, "campaign_dossier.csv"))

# ---- F. new addresses in and outside waves, 2024-01..06 (Base, Arbitrum and Ethereum L1; 02 section G) ----
# One definition at every date and on every chain: a new address has no outgoing tx in the previous LONG_LOOKBACK days; waves follow the trailing rule of
# 02 section G; entry outside waves excludes wave addresses and heavy new addresses (>= BOT_MIN_WEEK1 txs on the entry day).
# Figure: new addresses per day in waves and outside waves, with each chain's fee cuts (dashed) and Ethereum L1 (LONG_CONTROL), whose fees stayed at dollars,
# as the comparison chain; groups by recipient x method when L1 call data are read (LONG_CONTROL_SELECTOR), else by recipient only.
LD <- PNL$long_daily[, nonwave := new - wave_new - (heavy - wave_heavy)]
CUTS <- rbind(EVENTS[, .(chain, d = as.IDate(t0))], EVENTS_MAY[1, .(chain, d = as.IDate(t0))])
GPK3 <- unique(LD[chain == LONG_CONTROL, grouping])
LAB <- c(base = "Base", arbitrum = "Arbitrum", ethereum = "Ethereum L1 (comparison: fee fell far less)"); GPF <- if ("target x method" %in% GPK3) "target x method" else "target"
FL3 <- rbind(LD[grouping == GPF, .(chain, day, v = wave_new, series = "In waves")], LD[grouping == GPF, .(chain, day, v = nonwave, series = "Outside waves")])[, chain_lab := factor(LAB[chain], LAB)]
g <- ggplot(FL3, aes(day, v + 1, colour = series)) + geom_vline(data = CUTS[, .(d, chain_lab = factor(LAB[chain], LAB))], aes(xintercept = d), colour = COL[["ink2"]], linewidth = 0.3, linetype = "dashed") +
  geom_line(linewidth = 0.4) + facet_wrap(~ chain_lab, ncol = 1) + scale_y_log10(labels = scales::comma) + scale_colour_manual(values = c(COL[["main"]], COL[["ref"]])) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b %Y") + labs(x = NULL, y = "New addresses per day + 1 (log scale)") + THEME_FIG
ggsave(file.path(DIR_FIG, "waves_2024_with_l1.png"), g, width = 10, height = 7.6, dpi = 200, bg = "white")

# ---- G. The Base March entry effect: dynamics, placebo dates before the cut, delay, persistence ----
# Daily entry outside waves (long series: 60-day new-address definition, recipient x method groups): y_d = log(new addresses outside waves and not heavy);
# D_d = y_d(Base) - y_d(Ethereum L1), the chain without a fee change. Cut day c = 2024-03-14 (Ecotone at 00:00 UTC, so day c is after the cut).
# Days that no placebo window may contain (as section I): c - 1 (Dencun on L1), c, 03-19 (Arbitrum's floor cut) and the Base May steps 05-28..30.
# G1 event study: E_k = D_{c+k} - mean(D_{c-7..c-1}), k = -14..14; band = 5th-95th percentile of the same statistic at placebo dates t whose window t-14..t+14
#   ends before c - 1 (pre-cut dates only).
# G2 window ratio: r_w = mean(y over c..c+w-1) - mean(y over c-w..c-1), for Base and for D (Base minus L1), w = 6 (the low-fee days), 7, 14, 28; against all placebo dates in
#   2024-01..06 and against pre-cut dates only (window ends before c - 1). Percentile = share of placebo r below r_w; p = (1 + #{placebo r >= r_w}) / (1 + K).
# G3 delay or new entry: baseline B = c-42..c-15, run-up A = c-14..c-1, after P = c..c+13, on D. dip = mean(A) - mean(B) (negative if people waited for the
#   announced cut); after = mean(P) - mean(B); net = mean(A and P) - mean(B), the excess over the 28 days around the cut (zero if entry was only retimed).
# G4 persistence: share of non-burst window entrants active on days 1-10 of 2024-09, 2024-12 or 2025-03, entrants in the 6 days before vs the 6 days after
#   each chain's first cut hour (Base: 03-08..13 vs 03-14..19); ratio after / before with a 95% interval from BOOT_REPS draws of entry days within each period.
LDT <- PNL$long_daily[grouping == "target x method"][, y := log(new - wave_new - (heavy - wave_heavy))]
DL <- merge(LDT[chain == "base", .(day, yb = y)], LDT[chain == LONG_CONTROL, .(day, yl = y)], by = "day")[, d := yb - yl][order(day)]
cc <- as.IDate(EVENTS$t0[1]); BAD <- unique(c(as.IDate(L1_FORK), as.IDate(EVENTS$t0), as.IDate(EVENTS_MAY$t0[1]) + 0:2))
# G1: event study with a band from pre-cut placebo dates
ES <- list()
for (t in c(as.integer(cc), as.integer(DL[day - 14L >= LONG_FROM & day + 14L < cc - 1L, day]))) {
  ref <- DL[day >= t - 7L & day <= t - 1L, mean(d)]
  ES[[length(ES) + 1]] <- DL[day >= t - 14L & day <= t + 14L, .(placebo = t != as.integer(cc), k = as.integer(day) - t, e = d - ref)]
}
ES <- rbindlist(ES)
EST <- merge(ES[placebo == FALSE, .(k, e)], ES[placebo == TRUE, .(placebo_K = .N, lo = quantile(e, 0.05, names = FALSE), hi = quantile(e, 0.95, names = FALSE)), by = k], by = "k")
cat("## G1. Event study: log entry outside waves, Base minus Ethereum L1, relative to the week before the cut (band: 5th-95th percentile, pre-cut placebo dates)\n"); print(EST)
# shaded: the 6 low-fee days (k = 0..5); dotted: the day deposits on Base reached a record (event_calendar) and the first day after the low-fee days, labelled
#   with Base's median fee that day as a multiple of its median over the 6 low-fee days (growthepie daily medians), to one significant digit
FB <- PNL$multichain_daily[chain == "base"]; d5 <- PNL$event_calendar[event %like% "^Base deposits reach a record", date]
MK <- data.table(k = as.integer(c(d5, cc + 6L) - cc), lab = c(sprintf("%s: record deposits", sub("^0", "", format(d5, "%d %b"))),
                 sprintf("%s: fee x%g", sub("^0", "", format(cc + 6L, "%d %b")), signif(FB[date == cc + 6L, cost] / FB[date >= cc & date <= cc + 5L, median(cost)], 1))))
g <- ggplot(EST, aes(k, e)) + annotate("rect", xmin = -0.5, xmax = 5.5, ymin = -Inf, ymax = Inf, fill = COL[["grid"]], alpha = 0.6) +
  geom_ribbon(aes(ymin = lo, ymax = hi), fill = COL[["band"]]) + geom_hline(yintercept = 0, colour = COL[["ref"]], linewidth = 0.3) +
  geom_vline(xintercept = -0.5, colour = COL[["ink2"]], linewidth = 0.3, linetype = "dashed") + geom_vline(data = MK, aes(xintercept = k), colour = COL[["ink2"]], linewidth = 0.3, linetype = "dotted") +
  geom_text(data = MK, aes(x = k, y = Inf, label = lab), vjust = 1.3, hjust = -0.05, size = 2.6, colour = COL[["ink2"]]) +
  geom_line(colour = COL[["main"]], linewidth = 0.5) + geom_point(colour = COL[["main"]], size = 1.2) +
  labs(x = "Days from the Base fee cut (14 Mar 2024; shaded: the six low-fee days)", y = "Log entry outside waves, Base minus Ethereum L1\n(relative to the week before)") + THEME_FIG
ggsave(file.path(DIR_FIG, "entry_event_study_base_l1.png"), g, width = 7, height = 4, dpi = 200, bg = "white")
# G2: window ratios against all placebo dates and against pre-cut dates only
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
LR <- rbindlist(LR); cat("## G2. Entry outside waves after vs before the Base cut (ratio), against placebo dates\n"); print(LR)
# G3: delay or new entry
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
LT3 <- rbindlist(LT3); cat("## G3. Delay or new entry: Base minus L1, run-up (dip), after, and the 28 days together (net), relative to days c-42..c-15\n"); print(LT3)
# G4: persistence of non-burst entrants before and after each chain's first cut
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
L4 <- rbindlist(L4); cat("## G4. Non-burst window entrants active later (Sep 2024, Dec 2024 or Mar 2025, days 1-10): 6 days before vs 6 days after the chain's first cut hour\n"); print(L4)
fwrite(EST, file.path(DIR_TAB, "entry_event_study_base_l1.csv")); fwrite(LR, file.path(DIR_TAB, "entry_ratio_placebo_windows.csv"))
fwrite(LT3, file.path(DIR_TAB, "entry_delay_test.csv")); fwrite(L4, file.path(DIR_TAB, "entrant_persistence_cut.csv"))

# ---- H. Where the extra non-burst entrants came from: how their first ETH arrived ----
# Source of a non-burst window entrant's first ETH (the ETH funder before its first outgoing tx, 01 section F), by the funder's role:
#   a service funder (>= 500 distinct ETH recipients on 02-15..03-07), named in panel funder_labels: an exchange hot wallet (a withdrawal from an exchange),
#   an exchange's deposit funder (gas sent to a customer's deposit address), a bridge or relayer (funds moved from another chain), or untagged;
#   an individual funder (fewer recipients): a direct transfer, or on Base a contract transfer attributed to the account that started the tx;
#   no ETH funder: a token funder only, or none (ETH bridged from Ethereum to the same address does not count as funding by another account).
# Entrants per day in the 6 days before and the 6 days after the chain's first cut hour t0 (Base: 03-08..13 vs 03-14..19, the days of low fees; Arbitrum:
# 03-08 15:00 .. 03-20 15:00); ratio after / before; share of the increase = change per day in the source / change per day in all non-burst entrants (H1).
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
cat("## H1. Non-burst window entrants per day by source of their first ETH, 6 days before vs 6 days after the chain's first cut hour\n"); print(M5)
# H2. Funding clusters behind non-burst entrants (same 6 v 6 days): entrants per day by the size of their funder-entrant-sweep component (h = 500): alone,
# 2 to CLUSTER_MIN - 1, CLUSTER_MIN or more; and the funding entities (components) behind them per day, all and in components below CLUSTER_MIN entrants.
# Entities are counted within each 24-hour block from the cut hour and averaged over the six blocks on each side (as section L counts them per day).
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
M7 <- rbindlist(M7); cat("## H2. Non-burst window entrants per day by funding cluster, and the funding entities behind them, 6 days before vs 6 days after the chain's first cut hour\n"); print(M7)
fwrite(M5, file.path(DIR_TAB, "entrant_funding_source.csv")); fwrite(M7, file.path(DIR_TAB, "entrant_entities_nonburst.csv"))

# ---- I. Both Base cuts with one estimator: waves and entry outside waves against Ethereum L1 and Arbitrum ----
# Long series (recipient x method groups). Cut day c with g step days left out: March c = 03-14, g = 0 (Ecotone at 00:00, day c is after the cut);
#   May c = 05-28, g = 3 (gas-limit steps 05-28 19:00 and 05-30 20:00). Window length w = 6 (Base's low-fee days in March), 7, 14, 28: before = c-w..c-1,
#   after = c+g..c+g+w-1.
#   Outcomes per chain-day: y1 = log(1 + new addresses in waves); y2 = the same without the chain's largest wave group of the window; y3 = waves per day;
#   y4 = log(new addresses outside waves and not heavy). Shift = mean after - mean before; S = shift on Base - shift on the comparison chain: Ethereum L1
#   (no fee change), or Arbitrum (no change in May; in March it was cut too, at 03-14 15:00 and 03-19, so S compares Base with another treated chain).
#   Placebo dates t: windows t-w..t+g+w-1 inside LONG_FROM..LONG_END holding none of the cut days (03-13 L1 Dencun, 03-14, 03-19, 05-28..30). Placebo sets:
#   all such dates; pre-cut (windows end before the cut; for May they also start after 03-19); the cents regime (windows start after 03-19, for May); the
#   cents regime without Base's gas-target steps of 03-26 and 04-01 (event_calendar). Percentile = share of placebo S below S; p = (1 + #{placebo S >= S}) /
#   (1 + K), floor 1 / (1 + K); disjoint_K = the largest number of placebo windows that do not overlap.
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
cat("## I. Both Base cuts, one estimator: shift on Base minus the comparison chain, against placebo dates (May: step days 05-28..30 left out)\n"); print(NT)
fwrite(NT, file.path(DIR_TAB, "base_cuts_test.csv"))

# ---- J. May waves day by day ----
# Waves per day around the May steps (long series): E_k = D_{c+k} - mean(D over the reference days), D = waves per day on Base minus the comparison chain
#   (none, Ethereum L1 or Arbitrum), k = -14..21, c = 05-28 (steps on c and c+2). Reference days: c-14..c-1, or c-28..c-8, which leaves out the week before.
#   Band: 5th-95th percentile of E_k over placebo dates t whose span (first reference day .. t+21) starts after 03-19 and holds no cut day.
#   Step 1 was announced after it took effect, step 2 two days ahead.
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
cat("## J. Base May: waves per day relative to the reference days (Base alone, minus L1, minus Arbitrum), with a band from cents-regime placebo dates\n"); print(OT)
cat("## J. Waves per day on the three chains, 05-14..06-11 (step days 05-28 and 05-30)\n")
print(dcast(LDN[day >= as.IDate(EVENTS_MAY$t0[1]) - 14L & day <= as.IDate(EVENTS_MAY$t0[1]) + 14L, .(day, chain, waves)], day ~ chain, value.var = "waves"))
FO <- rbind(OT[reference == "c-14..c-1" & comparison %in% c("none", LONG_CONTROL)])[, panel := factor(fifelse(comparison == "none", "A. Base alone", "B. Base minus Ethereum L1"), c("A. Base alone", "B. Base minus Ethereum L1"))]
g <- ggplot(FO, aes(k, e)) + geom_ribbon(aes(ymin = lo, ymax = hi), fill = COL[["band"]]) + geom_hline(yintercept = 0, colour = COL[["ref"]], linewidth = 0.3) +
  geom_vline(xintercept = c(-0.5, 1.5), colour = COL[["ink2"]], linewidth = 0.3, linetype = "dashed") + geom_line(colour = COL[["main"]], linewidth = 0.5) + geom_point(colour = COL[["main"]], size = 1.1) +
  facet_wrap(~ panel, ncol = 2) + labs(x = "Days from the first gas-limit step (28 May 2024; second step on day 2)", y = "Waves per day, relative to the two weeks before") + THEME_FIG
ggsave(file.path(DIR_FIG, "may_waves_event_study.png"), g, width = 9, height = 3.8, dpi = 200, bg = "white")
fwrite(OT, file.path(DIR_TAB, "may_waves_event_study.csv"))

# ---- K. Hourly counts in the entrant windows ----
# Hourly counts in the entrant windows (03-08..21 on both chains; 05-21..06-04 on Base): non-burst entrants (classes by UTC day); entrants at groups that
# never burst in the window (classes fixed in time); distinct funding entities (components, h = 500) among non-burst entrants; new senders (no outgoing tx
# since 02-15). Classes fixed in time: the burst rule labels whole UTC days and Base's March cut is at 00:00 UTC, so a group's entrants before midnight can be
# labelled non-burst and those after it burst. Here a first-action group (recipient x method) is a burst group if it bursts on any day of its window, and the
# entrants (bot-like excluded) of the other groups count as entrants at never-burst groups in every hour.
GI <- rbind(E[!is.na(wave) & class3 != "bot", .(win = "march", chain, hr, pair = paste(first_to, first_sel), wave)],
            PNL$may_entrants[chain == "base" & class3 != "bot", .(win = "may", chain, hr, pair = paste(first_to, first_sel), wave)])
GI[, grp := fifelse(any(wave == 1), "burst group", "other"), by = .(win, chain, pair)]
LIM <- list(march = as.POSIXct(c(ENTRANT_WINDOW[1], ENTRANT_WINDOW[2] + 1), tz = "UTC"), may = as.POSIXct(c(MAY_WINDOW[1], MAY_WINDOW[2] + 1), tz = "UTC"))
HI <- GI[grp == "other", .N, by = .(win, chain, hr)][rbind(CJ(win = "march", chain = CHAINS, hr = seq(LIM$march[1], LIM$march[2] - 3600, by = 3600)),
                                                           CJ(win = "may", chain = "base", hr = seq(LIM$may[1], LIM$may[2] - 3600, by = 3600))), on = .(win, chain, hr)][is.na(N), N := 0]
EV5w <- rbind(EVENTS[, .(event, chain, t0, win = "march")], EVENTS_MAY[, .(event, chain, t0, win = "may")])
HP <- rbind(PNL$entrants[!is.na(wave), .(win = "march", chain, hr, class3, cid500)], PNL$may_entrants[chain == "base", .(win = "may", chain, hr, class3, cid500)])[
  , .(nonburst = sum(class3 == "genuine"), entities = uniqueN(cid500[class3 == "genuine"])), by = .(win, chain, hr)]
HP <- merge(HP, HI[, .(win, chain, hr, never_burst_groups = N)], by = c("win", "chain", "hr"), all = TRUE)
HP <- merge(HP, rbind(PNL$l2_newsenders[, .(win = "march", chain, hr, new_senders)], PNL$may_hourly[chain == "base", .(win = "may", chain, hr, new_senders)]), by = c("win", "chain", "hr"), all.x = TRUE)
HP <- merge(rbind(CJ(win = "march", chain = CHAINS, hr = seq(LIM$march[1], LIM$march[2] - 3600, by = 3600)), CJ(win = "may", chain = "base", hr = seq(LIM$may[1], LIM$may[2] - 3600, by = 3600))),
            HP, by = c("win", "chain", "hr"), all.x = TRUE)
YP <- c(new_senders = "new senders", never_burst_groups = "entrants at never-burst groups", entities = "funding entities (non-burst)")   # outcomes of the RD at the cut hour (N1)
for (v in c(names(YP), "nonburst")) HP[is.na(get(v)), (v) := 0]
HP[, hod := hour(hr)]

# ---- L. Funding entities behind non-burst entry at both Base cuts: accounting variants and the composition deflator ----
# Non-burst window entrants on Base. Days: March c-6..c-1 vs c..c+5 (6 v 6, c = 03-14); May c-5..c-1 vs c+3..c+7 (5 v 5, c = 05-28, step days left out).
# Per day: addresses; distinct funding entities (components, h = 500); entities with an entrant not funded by a service (exchange, bridge or other service);
# entities with an entrant active later (days 1-10 of 2024-09, 2024-12 or 2025-03); addresses alone in their component. Ratio after / before of daily means,
# all days and weekdays only, 95% interval from BOOT_REPS draws of days within each side. Deflator = log(entities / addresses), after minus before (daily
# means); implied entity effect = exp(L1-differenced address effect outside waves over 6 days, the primary window, or 7 days; section I) x exp(deflator), assuming
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
cat("## L. Non-burst entry on Base, daily means after vs before each cut (equal windows), 95% day-bootstrap intervals; the last row is the composition deflator\n"); print(QA)
cat("## L. Implied entity effect = L1-differenced 6- or 7-day address effect outside waves x exp(deflator) (interval from the deflator only)\n"); print(QI)
fwrite(QA, file.path(DIR_TAB, "entity_accounting.csv")); fwrite(QI, file.path(DIR_TAB, "entity_effect_implied.csv"))

# ---- M. Headline numbers from one sample, and the inference table for the Base March effect ----
# M1. Base March, equal windows; every ratio is a ratio of daily means on Base alone (not net of L1). Long series (60-day new addresses, recipient x method
#   waves): days c-w..c-1 vs c..c+w-1, w = 6 (the days of low fees), 7, 14, 28; counted new addresses, new addresses outside waves, and the share of the added
#   new addresses that came in waves = change in waves per day / change in new addresses per day. Window entrants (never active on Base before; days c-6..c-1
#   vs c..c+5): all entrants, and under each burst rule of 00_setup.R (main burst rule; size only; burst funded by bursting funders; the same with the pre-entry
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
  EB[, cls := fcase(bot_wk1 == 1, "bot", get(r) %in% 1, "batch", default = "nonburst")]   # classes: bot > batch > non-burst
  s <- EB[, .(all = .N / 6, batch = sum(cls == "batch") / 6, nonburst = sum(cls == "nonburst") / 6), by = post][order(post)]
  R1[[length(R1) + 1]] <- data.table(sample = "window entrants (never active on Base)", window = "6 v 6 days", rule = c(wave = "main burst rule", wave_size = "size only (>= 5,000 a day)",
    wave_funded = "burst funded by bursting funders", wave_funded2 = "same, pre-entry funder")[[r]], all_before = s$all[1], all_after = s$all[2], all_ratio = s$all[2] / s$all[1],
    outside_ratio = s$nonburst[2] / s$nonburst[1], batch_share_of_added = (s$batch[2] - s$batch[1]) / (s$all[2] - s$all[1]))
}
R1 <- rbindlist(R1); cat("## M1. Base March headline numbers from one sample at a time (counted new accounts, entry outside batches, batch share of the added accounts)\n"); print(R1)
# M2. Inference for the primary statistic: the shift in log entry outside waves, Base minus L1 (as section I), over the 6 days of low fees (w = 6: c..c+5 vs
#   c-6..c-1; Base's median fee rose thirtyfold on c+6, section P), and over 7 days (c..c+6 vs c-7..c-1) alongside; against pre-cut placebo dates and all
#   dates: estimate, rank, K, non-overlapping K and their values, placebo mean and SD, and z = (estimate - placebo mean) / placebo SD. The placebo rank is in
#   the spirit of Andrews's (2003) end-of-sample instability test: under the null the cut window is one more draw from the process behind the pre-cut windows.
#   Placebo dates as section I: windows holding none of the cut days BADN. Window path: wb days before vs wa days from c, (wb, wa) = (4, 4), (5, 5), (6, 6),
#   (7, 7), and (6, 5), which leaves out 03-19 (record fee revenue). The largest all-dates placebos (6 v 6 and 7 v 7) are listed with Base's and L1's own
#   shifts, the slope of d = y(Base) - y(L1) over their before-window (per day; OLS on day), and the dated events (event_calendar) inside their windows; the
#   cut's own row comes first.
D2 <- merge(LDN[chain == "base", .(day, yb = log(nonwave))], LDN[chain == LONG_CONTROL, .(day, yl = log(nonwave))], by = "day")[, d := yb - yl][order(day)]
R2 <- list(); RT <- list()
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
  for (pl in c("pre-cut dates", "all dates")) {
    x <- X2[t != as.integer(cc) & (pl == "all dates" | t + w - 1L < as.integer(cc) - 1L)][order(t)]; sel <- integer(0); le <- -Inf
    for (u in x$t) if (u - wb > le) { sel <- c(sel, u); le <- u + w - 1L }   # greedy count of non-overlapping windows
    R2[[length(R2) + 1]] <- data.table(statistic = sprintf("%d v %d days%s, log entry outside waves, Base minus L1", wb, w, if (wb != w) " (03-19 left out)" else ""), window = sprintf("%d v %d", wb, w),
                         window_days = w, placebo = pl, estimate = a2, ratio = exp(a2),
                         placebo_K = nrow(x), rank_p = (1 + sum(x$d >= a2)) / (1 + nrow(x)), disjoint_K = length(sel), disjoint_values = paste(sprintf("%.2f", x[t %in% sel, d]), collapse = ", "),
                         placebo_max = max(x$d), placebo_mean = mean(x$d), placebo_sd = sd(x$d), z_placebo = (a2 - mean(x$d)) / sd(x$d),
                         base_alone = X2[t == as.integer(cc), base_alone], base_alone_rank_p = (1 + sum(x$base_alone >= X2[t == as.integer(cc), base_alone])) / (1 + nrow(x)))
  }
  top <- rbind(X2[t == as.integer(cc)], X2[t != as.integer(cc)][order(-d)][1:6])
  if (i <= 2L) for (k in seq_len(nrow(top))) RT[[length(RT) + 1]] <- top[k, .(window_days = w, start = as.IDate(t), cut = t == as.integer(cc), d, base_alone, l1_alone, slope_before,
    events_in_window = paste(PNL$event_calendar[as.integer(date) >= t - w & as.integer(date) <= t + w - 1L, sprintf("%s %s", format(date, "%m-%d"), substr(event, 1, 60))], collapse = " | "))]
}
R2 <- rbindlist(R2); RT <- rbindlist(RT)
cat("## M2. Inference for the primary statistic (shift outside waves, Base minus L1, over the 6 low-fee days), 7 days, the 4- and 5-day path, and without 03-19\n"); print(R2)
cat("## M2. The cut and the largest all-dates placebos: Base minus L1, Base alone, L1 alone, before-window slope, and the dated events inside their windows\n"); print(RT)
# M2b. The primary statistic across wave size floors F (WAVE_FLOORS, panel long_floor_daily; F = SPIKE_MIN is the rule): entry outside waves = new - wave
#   addresses at F - (heavy - heavy wave addresses at F), on Base and L1 alike; 6- and 7-day shifts, placebo sets and rank as M2; Base alone, 6 v 6 days, the
#   share of the added new addresses in waves at F. Window entrants (Base, 6 v 6 days) under the burst rule of 02 section C with F in place of SPIKE_MIN (group =
#   first recipient x method; burst day if N >= F and N >= SPIKE_K x the group's median daily count over ENTRANT_WINDOW[1]..PRE_END, zeros included): non-burst
#   entrants and funding entities per day after / before, the deflator as section L, and the implied entity effect = exp(6-day estimate at F + deflator at F).
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
RW <- rbindlist(RW); cat("## M2b. The primary statistic, the breakdown and the implied entity effect across wave and burst size floors (Base minus L1)\n"); print(RW)
# M3. Who the new accounts are, on the same 6 v 6 days (03-08..13 vs 03-14..19): Base window entrants by class (main burst rule; bot-like separate): entrants
#   and funding entities (components, h = 500) per day before and after, ratio; share of all entrants after the cut and of the added entrants; after the cut:
#   share in a funding cluster of >= CLUSTER_MIN, first tx in a same-block group (sync), share of the class held by its largest 10 / 100 components, share
#   whose first recipient is the class's most common first recipient after the cut, months
#   active of Sep 2024, Dec 2024, Mar 2025 (0-3), on the LayerZero provisional Sybil list, address or funder also entering Arbitrum, tokens / ETH received after entry.
R4 <- EB[, .(entrants_before = sum(!post) / 6, entrants_after = sum(post) / 6,
             in_cluster_20 = mean(csize500[post] >= CLUSTER_MIN), same_block_group = mean(sync[post] == 1, na.rm = TRUE),
             months_active_of3 = mean((act_2024_09 + act_2024_12 + act_2025_03)[post]), layerzero_list = mean(lz[post], na.rm = TRUE),
             other_l2_address = mean(other_chain_addr[post], na.rm = TRUE), other_l2_funder = mean(other_chain_funder[post], na.rm = TRUE),
             tokens_after = mean(tok_after[post], na.rm = TRUE), eth_after = mean(eth_after[post], na.rm = TRUE)), by = class3]
R4 <- merge(EB[, .(e = uniqueN(cid500)), by = .(class3, post, day)][, .(entities_before = sum(e[!post]) / 6, entities_after = sum(e[post]) / 6), by = class3], R4, by = "class3")   # entities per day
R4 <- merge(R4, EB[post == TRUE, .N, by = .(class3, cid500)][order(-N), .(top10_share = sum(head(N, 10)) / sum(N), top100_share = sum(head(N, 100)) / sum(N)), by = class3], by = "class3")
R4 <- merge(R4, EB[post == TRUE, .(top_recipient_share = max(table(first_to)) / .N), by = class3], by = "class3")
R4[, `:=`(entrant_ratio = entrants_after / entrants_before, entity_ratio = entities_after / entities_before, share_after = entrants_after / sum(entrants_after),
          share_of_added = (entrants_after - entrants_before) / sum(entrants_after - entrants_before))]
cat("## M3. Base window entrants by class, 6 days before vs 6 days after the cut (03-08..13 vs 03-14..19)\n"); print(R4)
fwrite(R1, file.path(DIR_TAB, "headline_one_sample.csv")); fwrite(R2, file.path(DIR_TAB, "inference_primary.csv")); fwrite(RT, file.path(DIR_TAB, "inference_top_placebos.csv"))
fwrite(RW, file.path(DIR_TAB, "inference_wave_size_floors.csv"))
fwrite(R4, file.path(DIR_TAB, "entrant_classes_6v6.csv"))

# ---- N. The cut hour with pre-cut fake hours, and checks against a Base-specific demand shock ----
# N1. RD in time at each cut hour t0 for the hourly outcomes YP (section K), +-36 h, 1-hour donut (t0 - 1 and t0 dropped), Newey-West SEs (6 lags):
#   log(1 + y_t) = a + b Post_t + c1 (t - t0) + c2 (t - t0) Post_t + hour-of-day FE + e_t
#   RI over fake hours that all lie before the cut: a 6-hour grid whose +-36 h window ends at least 1 hour before the cut and lies inside the series (new
#   senders: the whole hourly series from 02-15, or from 05-14 in May; other outcomes: the entrant window); p = (1 + #{fake |b| >= |b|}) / (1 + K).
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
S1 <- rbindlist(S1); cat("## N1. The cut hour: RD with RI over fake hours before the cut only\n"); print(S1)
# N2. Is the March rise one app's boom? Base non-burst window entrants, days c-6..c-1 vs c..c+5, by their first recipient.
E6 <- PNL$entrants[!is.na(wave) & chain == "base" & class3 == "genuine" & day >= cc - 6L & day <= cc + 5L][, post := day >= cc]
TOPR <- E6[post == TRUE & !is.na(first_to), .N, by = first_to][order(-N)]
# The 50 most common first recipients, named in panel recipient_labels, with their entrants per day before and after; and non-burst entry by the category of
#   the first recipient (the fifty named ones; all other recipients as one group)
TOPL <- merge(TOPR[1:50, .(first_to, rank = .I)], PNL$recipient_labels[, .(first_to = address, name_tag, category, first_call)], by = "first_to", all.x = TRUE)
TOPL <- merge(TOPL, E6[first_to %in% TOPL$first_to, .(before = sum(!post) / 6, after = sum(post) / 6), by = first_to], by = "first_to")[, ratio := after / before][order(rank)]
cat(sprintf("## N2. The 50 most common first recipients of non-burst entrants after the cut (%.0f%% of them): entrants per day, 6 days before vs after\n", 100 * sum(TOPR$N[1:50]) / E6[post == TRUE, .N]))
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
cat("## N2. Non-burst entrants per day by the category of their first recipient (the 50 named; boom-type recipients together), 6 days before vs after\n"); print(S2C)
# N3. Base minus OP Mainnet, which got the same Ecotone cut at the same second (growthepie daily log active addresses), with Base's batch accounts removed:
#   Base active addresses minus its new addresses in waves that day (most batch accounts are active only on their entry day), OP raw; also without 03-16 (the
#   largest batch day). Shift = mean over c..c+w-1 minus mean over c-w..c-1, w = 6 (primary) and 7, against pre-cut placebo dates (windows end before c - 1)
#   holding no cut day (BADN, section I); rank_p = (1 + #{placebo >= shift}) / (1 + K).
GD <- dcast(PNL$multichain_daily[chain %in% c("base", "optimism") & date >= LONG_FROM & date <= as.IDate(LONG_END), .(chain = paste0("daa_", chain), day = as.integer(date), daa = log(daa))],
            day ~ chain, value.var = "daa")
GA <- merge(GD[, .(day, daa_base, daa_optimism)], LDN[chain == "base", .(day = as.integer(day), wave_new)], by = "day")[, d_adj := log(pmax(exp(daa_base) - wave_new, 1)) - daa_optimism][, d_raw := daa_base - daa_optimism]
S4 <- list()
for (w in c(6L, 7L)) for (v in c("d_raw", "d_adj")) for (drop316 in c(FALSE, TRUE)) {
  rr <- list()
  for (t in GA[day - w >= as.integer(as.IDate(LONG_FROM)) & day + w - 1L <= as.integer(as.IDate(LONG_END)), day]) {
    if (t != as.integer(cc) && any(((t - w):(t + w - 1L)) %in% BADN)) next
    Z <- GA[day >= t - w & day <= t + w - 1L & !(drop316 & day == as.integer(cc) + 2L)][, post := day >= t]; rr[[length(rr) + 1]] <- data.table(t = t, s = Z[post == TRUE, mean(get(v))] - Z[post == FALSE, mean(get(v))])
  }
  rr <- rbindlist(rr); a <- rr[t == as.integer(cc), s]; x <- rr[t != as.integer(cc) & t + w - 1L < as.integer(cc) - 1L, s]
  S4[[length(S4) + 1]] <- data.table(window_days = w, base_count = fifelse(v == "d_raw", "all active addresses", "without new addresses in waves"), without_03_16 = drop316, base_minus_op = a,
                                     placebo_K = length(x), placebo_pct = mean(x < a), rank_p = (1 + sum(x >= a)) / (1 + length(x)))
}
S4 <- rbindlist(S4); cat("## N3. Base minus OP Mainnet, 6 and 7 days, with Base's batch accounts removed and without 03-16 (pre-cut placebos)\n"); print(S4)
# N4. Timing against the ETH price: daily Base-minus-L1 entry outside waves (relative to the week before the cut) and the ETH/USD close, 03-01..03-21; mean of
#   the entry gap over ETH's rise to its peak (all before the cut). An inflow driven by the rally predicts a rising gap then.
S5 <- merge(D2[day >= as.IDate("2024-03-01") & day <= as.IDate("2024-03-21"), .(day, gap = d - D2[day >= cc - 7L & day <= cc - 1L, mean(d)])], PNL$eth_usd_daily[, .(day, eth_usd = close)], by = "day", all.x = TRUE)
cat("## N4. Base minus L1 entry outside waves (relative to the week before the cut) and ETH/USD, 03-01..03-21\n"); print(S5)
cat(sprintf("N4: ETH peak %s at %.0f; mean entry gap on ETH's rise (03-01 to the peak) %.3f\n", S5[which.max(eth_usd), day], S5[, max(eth_usd, na.rm = TRUE)], S5[day <= S5[which.max(eth_usd), day], mean(gap)]))
cat("## N4. Funding sources of the extra non-burst entrants (from H1): exchange withdrawals vs all\n"); print(M5[chain == "base" & source %in% c("exchange withdrawal", "individual, direct transfer", "bridge or relayer"), .(source, ratio, share_of_increase)])
fwrite(TOPL, file.path(DIR_TAB, "entry_top_recipients.csv"))
fwrite(S2C, file.path(DIR_TAB, "entry_by_recipient_category.csv"))
# N5. The cut day hour by hour: non-burst window entrants and the funding entities behind them on 03-14 in blocks of hours (00-05, 06-11, 12-14, 15-23;
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
cat("## N5. The cut day in blocks of hours: non-burst entrants and funding entities on 03-14 against the same hours of 03-08..13, and the hourly median fee\n"); print(S6)
PD <- list()
for (dd in seq(as.integer(cc) - 6L, as.integer(cc))) for (v in c("entrants", "entities")) {
  oth <- setdiff(seq(as.integer(cc) - 6L, as.integer(cc) - 1L), dd)
  X <- HB[blk != "15-23", .(own = log(get(v)[as.integer(day) == dd]) - log(mean(get(v)[as.integer(day) %in% oth]))), by = .(chain, blk)]
  PD[[length(PD) + 1]] <- X[, .(day = dd, measure = v, d = own[chain == "base"] - own[chain == "arbitrum"]), by = blk]
}
S6P <- rbindlist(PD)[, .(cut_day = d[day == as.integer(cc)], placebo_days = sum(day < as.integer(cc)), placebo_min = min(d[day < as.integer(cc)]), placebo_max = max(d[day < as.integer(cc)])), by = .(measure, blk)][
  , above_all_placebo_days := cut_day > placebo_max]
cat("## N5. Base minus Arbitrum in blocks of hours before Arbitrum's cut: the cut day against each pre-cut day (against the other five)\n"); print(S6P)
HH <- HP[win == "march" & as.IDate(hr) >= cc - 6L & as.IDate(hr) <= cc + 1L, .(chain, hr, nonburst, hod = hour(hr), day = as.IDate(hr))]
HH <- merge(HH[day >= cc - 1L], HH[day < cc, .(lo = min(nonburst), hi = max(nonburst), mid = mean(nonburst)), by = .(chain, hod)], by = c("chain", "hod"))[
  , chain_lab := factor(fifelse(chain == "base", "Base (cut 14 Mar 00:00)", "Arbitrum (cut 14 Mar 15:00)"), c("Base (cut 14 Mar 00:00)", "Arbitrum (cut 14 Mar 15:00)"))]
g <- ggplot(HH, aes(hr)) + geom_ribbon(aes(ymin = lo, ymax = hi), fill = COL[["band"]]) + geom_line(aes(y = mid, colour = "Mean of the same hour, 8-13 Mar"), linewidth = 0.3) +
  geom_vline(data = EVENTS[t0 < as.POSIXct(cc + 1L, tz = "UTC"), .(t0, chain_lab = factor(fifelse(chain == "base", "Base (cut 14 Mar 00:00)", "Arbitrum (cut 14 Mar 15:00)"),
             c("Base (cut 14 Mar 00:00)", "Arbitrum (cut 14 Mar 15:00)")))], aes(xintercept = t0), colour = COL[["ink2"]], linewidth = 0.3, linetype = "dashed") +
  geom_line(aes(y = nonburst, colour = "Each hour, 13-15 Mar"), linewidth = 0.5) + facet_wrap(~ chain_lab, ncol = 1, scales = "free_y") + scale_y_continuous(labels = scales::comma) +
  scale_colour_manual(values = c("Each hour, 13-15 Mar" = COL[["main"]], "Mean of the same hour, 8-13 Mar" = COL[["ref"]])) +
  scale_x_datetime(date_breaks = "12 hours", date_labels = "%d %b\n%H:00") + labs(x = "Hour (UTC)", y = "Non-burst entrants per hour\n(band: range of the same hour, 8-13 Mar)") + THEME_FIG
FF <- FQ6[day >= cc - 1L & day <= cc + 1L, .(hr, fee_usd, chain_lab = factor(fifelse(chain == "base", "Base", "Arbitrum"), c("Base", "Arbitrum")))]
g2 <- ggplot(FF, aes(hr, fee_usd, colour = chain_lab)) + geom_vline(xintercept = EVENTS[t0 < as.POSIXct(cc + 1L, tz = "UTC"), t0], colour = COL[["ink2"]], linewidth = 0.3, linetype = "dashed") +
  geom_line(linewidth = 0.5) + scale_y_log10(breaks = c(0.001, 0.01, 0.1, 1), labels = c("$0.001", "$0.01", "$0.10", "$1")) + scale_colour_manual(values = c(COL[["main"]], COL[["ref"]])) +
  scale_x_datetime(date_breaks = "12 hours", date_labels = "%d %b\n%H:00") + labs(x = "Hour (UTC)", y = "Median fee per tx\n(US$, log scale)", colour = NULL) + THEME_FIG +
  theme(legend.position = "inside", legend.position.inside = c(0.01, 0.03), legend.justification = c(0, 0), legend.background = element_rect(fill = "white", colour = NA))
ggsave(file.path(DIR_FIG, "cut_day_hours.png"), gridExtra::arrangeGrob(g + labs(x = NULL), g2, ncol = 1, heights = c(2, 1)), width = 9, height = 6.8, dpi = 200, bg = "white")
# N6. First action of Base non-burst window entrants, 6 days before vs after the cut (03-08..13 vs 03-14..19), by 4-byte selector: native or
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
cat("## N6. Base non-burst window entrants by first action, 6 days before vs after the cut\n"); print(S7)
fwrite(S4, file.path(DIR_TAB, "base_minus_op_adjusted.csv")); fwrite(S5, file.path(DIR_TAB, "timing_eth.csv")); fwrite(S6, file.path(DIR_TAB, "cut_day_hours.csv"))
fwrite(S7, file.path(DIR_TAB, "entry_by_first_action.csv")); fwrite(S6P, file.path(DIR_TAB, "cut_day_hours_placebo_days.csv"))

# ---- O. The four cuts in one table: the jump at the cut hour (pre-cut fake hours) and the entry shift up to the chain's next cut ----
# Per cut, on the cutting chain: (1) the RD jump at the cut hour in new senders, entrants at never-burst groups and funding entities, each with RI over fake
# hours before the cut (section N1). (2) The shift in log entry outside waves (long series), cutting chain minus Ethereum L1, as section I with equal windows of w
# days: pre = c-w..c-1, post = c+g..c+g+w-1, c = the day of the cut, g = days left out (Base March 0, cut at 00:00; Arbitrum steps 1 and 2: 1, the cut day;
# Base May 3, the step days 05-28..30); the post window ends before the chain's next cut and the pre window starts after its previous cut, w <= 7 (Arbitrum
# step 1: 03-15..18; step 2: 03-15..18 vs 03-20..23). Placebo dates: windows of the same shape holding no cut day (BADN); pre-cut = ending before 03-13 (for
# May, also starting after 03-19). (3) The median fee per tx (growthepie daily median, US$) over the same pre and post days, its log change, and the dollars
# a typical non-burst entrant saves in its first week = (fee pre - fee post) x median first-week txs of non-burst entrants before the cut (section C).
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
cat("## O. The four cuts: fee change over the comparison days, jump at the hour (RI over pre-cut fake hours), entry outside waves minus L1 up to the next cut\n"); print(T1)
fwrite(T1, file.path(DIR_TAB, "four_cuts_summary.csv"))

# ---- P. How long the March fee stayed low, whether the same cut moved OP Mainnet, and how Ethereum L1 compares with other chains ----
# P1. Daily median fee per tx (growthepie, US$) on Base, OP Mainnet, Arbitrum and Ethereum L1, 2024-03-01..04-07; medians over the 6 and 7 days before the
#   cut (03-08..13, 03-07..13), the 6 low-fee days (03-14..19), days 6-13 (03-20..27) and the Table 1 windows for Base (03-08..12 vs 03-14..21), with the log
#   change from the 6 days before. Figure: the daily fee on the four chains, 02-15..04-15 (log scale), cut days dashed.
FP <- PNL$multichain_daily[chain %in% c("base", "optimism", "arbitrum", LONG_CONTROL) & date >= as.IDate("2024-02-15") & date <= as.IDate("2024-04-15")]
cat("## P1. Daily median fee per tx (US$), 03-01..04-07\n"); print(dcast(FP[date >= as.IDate("2024-03-01") & date <= as.IDate("2024-04-07")], date ~ chain, value.var = "cost"), nrows = 50)
PER <- data.table(period = c("before, 6 days: 03-08..13", "before, 7 days: 03-07..13", "days 0-5: 03-14..19", "days 6-13: 03-20..27", "Table 1 before: 03-08..12", "Table 1 after: 03-14..21"),
                  d0 = as.IDate(c("2024-03-08", "2024-03-07", "2024-03-14", "2024-03-20", "2024-03-08", "2024-03-14")), d1 = as.IDate(c("2024-03-13", "2024-03-13", "2024-03-19", "2024-03-27", "2024-03-12", "2024-03-21")))
U1 <- FP[PER, on = .(date >= d0, date <= d1), .(period, chain, cost), allow.cartesian = TRUE][, .(median_fee_usd = median(cost)), by = .(period, chain)]
U1 <- merge(U1, U1[period == "before, 6 days: 03-08..13", .(chain, ref = median_fee_usd)], by = "chain")[, log_change_from_before := log(median_fee_usd) - log(ref)][, ref := NULL][order(match(period, PER$period), chain)]
cat("## P1. Median fee per tx by period (median of daily medians, US$) and the log change from the 6 days before the cut\n"); print(U1)
LABU <- c(base = "Base", optimism = "OP Mainnet", arbitrum = "Arbitrum", ethereum = "Ethereum L1")
g <- ggplot(FP[, .(date, cost, chain_lab = factor(LABU[chain], LABU))], aes(date, cost, colour = chain_lab, linetype = chain_lab)) +
  geom_vline(xintercept = as.Date(c(EVENTS$t0[1], EVENTS$t0[3])), colour = COL[["ink2"]], linewidth = 0.3, linetype = "dashed") + geom_line(linewidth = 0.5) +
  scale_y_log10(labels = scales::dollar) + scale_colour_manual(values = c(COL[["main"]], COL[["ref"]], COL[["ink2"]], COL[["ink"]])) + scale_linetype_manual(values = c("solid", "solid", "dashed", "dotted")) +
  labs(x = NULL, y = "Median fee per transaction (US$, log scale)", colour = NULL, linetype = NULL) + THEME_FIG
ggsave(file.path(DIR_FIG, "fee_daily_march.png"), g, width = 8, height = 4, dpi = 200, bg = "white")
# P2. Did the same cut move OP Mainnet? growthepie daily log active addresses, log transactions and log median fee: OP Mainnet minus Ethereum L1, Base minus
#   L1 and Base minus OP Mainnet; shift over w = 7 and 6 days (c..c+w-1 vs c-w..c-1, c = 03-14) against placebo dates holding no cut day (BADN), pre-cut
#   (windows end before 03-13) and all dates. Event study of log active addresses for the three pairs as in section G (relative to c-7..c-1; band from pre-cut
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
cat("## P2. The March cut on OP Mainnet: shifts of growthepie series, OP Mainnet minus L1, Base minus L1, Base minus OP Mainnet, against placebo dates\n"); print(U2)
cat("## P2. Event study: log active addresses for the three pairs, relative to the week before the cut (band: 5th-95th percentile, pre-cut placebo dates)\n"); print(dcast(ESU, k ~ pair, value.var = c("e", "lo", "hi")))
g <- ggplot(ESU[, panel := factor(pair, PAIRS$pair)], aes(k, e)) + geom_ribbon(aes(ymin = lo, ymax = hi), fill = COL[["band"]]) + geom_hline(yintercept = 0, colour = COL[["ref"]], linewidth = 0.3) +
  geom_vline(xintercept = -0.5, colour = COL[["ink2"]], linewidth = 0.3, linetype = "dashed") + geom_line(colour = COL[["main"]], linewidth = 0.5) + geom_point(colour = COL[["main"]], size = 1.1) +
  facet_wrap(~ panel, ncol = 3) + labs(x = "Days from the Ecotone cut on Base and OP Mainnet (14 Mar 2024)", y = "Log active addresses, difference\n(relative to the week before)") + THEME_FIG
ggsave(file.path(DIR_FIG, "op_mainnet_event_study.png"), g, width = 10, height = 3.6, dpi = 200, bg = "white")
# P3. Is Ethereum L1 a flattering comparison? Donor chains: growthepie chains with daily active addresses and fees on every day of LONG_FROM..LONG_END whose
#   median fee over the 6 low-fee days (03-14..19) fell less than 1 log against the 6 days before, other than Base, OP Mainnet, Arbitrum and L1. Outcome: log
#   daily active addresses (aggregate, batch accounts included, so this checks the comparison chain, not the primary outcome). 6-day shift at 03-14 (as M2) of
#   Base minus each donor, minus the donors' mean log, and minus L1; of L1 minus the donor mean; and of each chain alone; against pre-cut and all-dates placebo
#   dates holding no cut day (BADN).
FC <- PNL$multichain_daily[date >= LONG_FROM & date <= as.IDate(LONG_END), .(full = sum(!is.na(daa) & daa > 0 & !is.na(cost) & cost > 0) == as.integer(as.IDate(LONG_END) - LONG_FROM) + 1L,
                                                                             dfee = log(median(cost[date >= cc & date <= cc + 5L])) - log(median(cost[date >= cc - 6L & date < cc]))), by = chain]
DON <- FC[full == TRUE & !is.na(dfee) & dfee > -1 & !(chain %in% c("base", "optimism", "arbitrum", LONG_CONTROL)), chain]
cat(sprintf("## P3. Donor chains (fee fell less than 1 log over the low-fee days): %s\n", paste(DON, collapse = ", "))); print(FC[order(dfee)])
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
U3 <- rbindlist(U3); cat("## P3. Log active addresses, 6-day shift at the cut: Base minus each donor, the donor mean and L1; L1 minus the donor mean; each chain alone\n"); print(U3)
fwrite(U1, file.path(DIR_TAB, "fee_path_march.csv")); fwrite(U2, file.path(DIR_TAB, "op_mainnet_vs_l1.csv")); fwrite(ESU, file.path(DIR_TAB, "op_mainnet_event_study.csv"))
fwrite(U3, file.path(DIR_TAB, "donor_pool_daa.csv"))

# ---- Q. The primary statistic under alternative counterfactuals and outcome definitions; the pre-cut reference set ----
# Notation as in the inference section: y_ct = log daily entry outside waves on chain c, d_t = y_Base,t - y_L1,t, c = the cut day, placebo origins t whose
#   windows hold no excluded day (BADN) and end before 03-13 (pre-cut). Each variant is ranked among the same construction at the pre-cut origins where it can
#   be formed; rank = 1 + #(placebo values >= estimate). The variants rest on different assumptions and are not an interval.
cX <- as.integer(as.IDate(EVENTS$t0[1])); dX0 <- as.integer(as.IDate(LONG_FROM)); gA <- cX - as.integer(BASE_ANNOUNCE)
LDX <- PNL$long_daily[grouping == "target x method" & chain %in% c("base", LONG_CONTROL)][, nonwave := new - wave_new - (heavy - wave_heavy)]
DX <- dcast(LDX[, .(chain, day = as.integer(day), y = log(nonwave))], day ~ chain, value.var = "y"); setnames(DX, c("base", LONG_CONTROL), c("yb", "yl")); DX[, d := yb - yl]
SX <- list()
# Panel A, level baselines: estimate = mean(d over c..c+5) - mean(d over the L days ending g days before c); g = 0 (window ends 03-13) or g = c - BASE_ANNOUNCE
#   (window ends the day before Base announced the cut).
for (cfg in list(c(6L, 0L), c(12L, 0L), c(18L, 0L), c(24L, 0L), c(30L, 0L), c(6L, gA), c(12L, gA), c(24L, gA))) {
  L <- cfg[1]; g <- cfg[2]; xs <- c()
  for (t in (dX0 + L + g):cX) {
    if (t != cX && (t + 5L >= cX - 1L || any(((t - g - L):(t + 5L)) %in% BADN))) next
    v <- DX[day >= t & day <= t + 5L, mean(d)] - DX[day >= t - g - L & day <= t - g - 1L, mean(d)]
    if (t == cX) a <- v else xs <- c(xs, v)
  }
  SX[[length(SX) + 1]] <- data.table(panel = "A. counterfactual", variant = sprintf("mean over the %d days %s..%s", L, as.IDate(cX - g - L), as.IDate(cX - g - 1L)),
                                     estimate = a, placebo_K = length(xs), rank = 1L + sum(xs >= a))
}
# Panel A, linear trends: d_t = a + s (t - c) + e_t (OLS on c-H..c-1), counterfactual for c..c+5 = a + s (t - c); estimate = mean(d - counterfactual) over c..c+5.
#   H = c - LONG_FROM uses every pre-cut day of the series, so no earlier placebo origin exists.
for (H in c(12L, 21L, 28L, 42L, cX - dX0)) {
  xs <- c()
  for (t in (dX0 + H):cX) {
    if (t != cX && (t + 5L >= cX - 1L || any(((t - H):(t + 5L)) %in% BADN))) next
    Z <- DX[day >= t - H & day <= t + 5L][, `:=`(k = day - t, post = day >= t)]
    f <- lm(d ~ k, data = Z[post == FALSE]); v <- Z[post == TRUE, mean(d - predict(f, newdata = Z[post == TRUE]))]
    if (t == cX) a <- v else xs <- c(xs, v)
  }
  SX[[length(SX) + 1]] <- data.table(panel = "A. counterfactual", variant = sprintf("linear trend over the %d days %s..%s", H, as.IDate(cX - H), as.IDate(cX - 1L)),
                                     estimate = a, placebo_K = length(xs), rank = if (length(xs)) 1L + sum(xs >= a) else NA_integer_)
}
# Panel B, a stricter wave threshold: wave group-days (long_waves) with n < 6 x their trailing median are put back into entry outside waves on both chains
#   (a wave rule with SPIKE_K = 6 for these groups); same 6 v 6 statistic and pre-cut origins.
LWX <- PNL$long_waves[grouping == "target x method" & chain %in% c("base", LONG_CONTROL)]
DX6 <- merge(LDX[, .(chain, day, nonwave)], LWX[n < 6 * pmax(base, 1 / SPIKE_K), .(back = sum(n)), by = .(chain, day)], by = c("chain", "day"), all.x = TRUE)[is.na(back), back := 0]
DX6 <- dcast(DX6[, .(chain, day = as.integer(day), y = log(nonwave + back))], day ~ chain, value.var = "y"); setnames(DX6, c("base", LONG_CONTROL), c("yb", "yl")); DX6[, d := yb - yl]
xs <- c()
for (t in (dX0 + 6L):cX) {
  if (t != cX && (t + 5L >= cX - 1L || any(((t - 6L):(t + 5L)) %in% BADN))) next
  v <- DX6[day >= t & day <= t + 5L, mean(d)] - DX6[day >= t - 6L & day <= t - 1L, mean(d)]
  if (t == cX) a <- v else xs <- c(xs, v)
}
SX[[length(SX) + 1]] <- data.table(panel = "B. outcome", variant = "wave threshold six times the group's baseline instead of three", estimate = a, placebo_K = length(xs), rank = 1L + sum(xs >= a))
# Panel B, established first actions: at origin t, E_t = recipient x method groups (long_groups, not pooled) present on >= 14 of the 28 days t-35..t-8, i.e.
#   fixed before the window (for the cut: 02-08..03-06, before Base's announcement). Outcomes per chain-day: new addresses at E_t groups outside the day's
#   waves (daily wave rule kept); all new addresses at E_t groups (no wave rule); the same without groups that had a wave in t-35..t-8 (exclusion fixed in
#   advance). Heavy addresses are kept; pooled first actions (< 10 a day) cannot be assigned to a group. Origins need 35 earlier days, so the reference set
#   is smaller; the primary statistic is ranked on the same origins for comparison.
GX <- copy(PNL$long_groups)[, `:=`(day = as.integer(day), pooled = is.na(first_to) & is.na(first_sel), g = paste(first_to, first_sel))]
GX <- merge(GX, LWX[, .(chain, day = as.integer(day), g = paste(first_to, first_sel), wave = 1L)], by = c("chain", "day", "g"), all.x = TRUE)[is.na(wave), wave := 0L]
RX <- list()
for (t in (dX0 + 35L):cX) {
  if (t != cX && (t + 5L >= cX - 1L || any(((t - 6L):(t + 5L)) %in% BADN))) next
  EG <- GX[pooled == FALSE & day >= t - 35L & day <= t - 8L, .(days = uniqueN(day), ref_wave = max(wave)), by = .(chain, g)][days >= 14L]
  Z <- merge(GX[day >= t - 6L & day <= t + 5L], EG[, .(chain, g, est = 1L, ref_wave)], by = c("chain", "g"), all.x = TRUE)[is.na(est), `:=`(est = 0L, ref_wave = 0L)]
  ZO <- Z[, .(daily = sum(n[est == 1L & wave == 0L]), none = sum(n[est == 1L]), fixed = sum(n[est == 1L & ref_wave == 0L])), by = .(chain, day)]
  for (o in c("daily", "none", "fixed")) RX[[length(RX) + 1]] <- data.table(t = t, outcome = o, d = (ZO[chain == "base" & day >= t, mean(log(get(o)))] - ZO[chain == "base" & day < t, mean(log(get(o)))]) -
                                                                            (ZO[chain == LONG_CONTROL & day >= t, mean(log(get(o)))] - ZO[chain == LONG_CONTROL & day < t, mean(log(get(o)))]))
  RX[[length(RX) + 1]] <- data.table(t = t, outcome = "primary", d = DX[day >= t & day <= t + 5L, mean(d)] - DX[day >= t - 6L & day <= t - 1L, mean(d)])
}
RX <- rbindlist(RX)
for (o in c("primary", "daily", "none", "fixed")) {
  a <- RX[t == cX & outcome == o, d]; xs <- RX[t != cX & outcome == o, d]
  SX[[length(SX) + 1]] <- data.table(panel = "B. outcome", variant = c(primary = "entry outside waves (primary), established-action placebo origins", daily = "established first actions, daily wave rule",
                                     none = "established first actions, no wave rule", fixed = "established first actions, excluding groups with a wave in the reference period")[[o]],
                                     estimate = a, placebo_K = length(xs), rank = 1L + sum(xs >= a))
}
SX <- rbindlist(SX)[, ratio := exp(estimate)]
cat("## Q. The primary statistic under alternative counterfactuals (panel A) and outcome definitions (panel B), Base minus L1, 6 low-fee days\n"); print(SX)
# The pre-cut reference set of the 6 v 6 statistic: its size, the spread of the same statistic for Base alone, the three largest placebo windows, and the
#   pooled first actions on Base (groups of < 10 new addresses a day, never a wave) on the day of the largest, against the day before.
PX <- list()
for (t in (dX0 + 6L):(cX - 7L)) {
  if (any(((t - 6L):(t + 5L)) %in% BADN)) next
  PX[[length(PX) + 1]] <- data.table(t = t, d = DX[day >= t & day <= t + 5L, mean(d)] - DX[day >= t - 6L & day <= t - 1L, mean(d)], b = DX[day >= t & day <= t + 5L, mean(yb)] - DX[day >= t - 6L & day <= t - 1L, mean(yb)])
}
PX <- rbindlist(PX)[order(-d)]; t1 <- PX$t[1]; POX <- GX[chain == "base" & pooled == TRUE]
SXR <- data.table(placebo_K = nrow(PX), gap_max = PX$d[1], gap_sd = sd(PX$d), base_alone_sd = sd(PX$b), largest_three_start = paste(as.IDate(PX$t[1:3]), collapse = ", "),
                  pooled_base_on_largest_after_day = as.character(as.IDate(t1)), pooled_base = POX[day == t1, n], pooled_base_day_before = POX[day == t1 - 1L, n],
                  pooled_ratio = POX[day == t1, n] / POX[day == t1 - 1L, n])
cat("## Q. The pre-cut reference set\n"); print(SXR)
fwrite(SX, file.path(DIR_TAB, "inference_counterfactuals.csv")); fwrite(SXR, file.path(DIR_TAB, "inference_reference_set.csv"))

cat("\n## sessionInfo\n```\n"); print(sessionInfo()); cat("```\n"); sink()
