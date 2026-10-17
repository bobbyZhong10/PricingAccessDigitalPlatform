# 08_paper_exhibits.R: the paper's main tables, assembled from the outputs of 04-07 (results/tables) into results/paper/, and an index of every exhibit.
#   Writes table1-5.csv (Table 1 in two panels: table1a, table1b), tables.md (all with notes) and README.md (main tables and figures, appendix A1-A12, each
#   linked to the file written by 04-07). Estimates nothing new and copies no files; run after 04-07. Defines no functions.
source(here::here("code", "00_setup.R"))
sink(file.path(DIR_LOG, "08_paper_exhibits.md"), split = TRUE)
cat("# 08 paper exhibits\nRun ", format(Sys.time(), usetz = TRUE), "\n", sep = "")
ct <- yaml::read_yaml(CONTRACT_FILE)   # panel.rds must have passed 03_validate_panels.R and be unchanged since
stopifnot(isTRUE(ct$all_valid), unname(tools::md5sum(PANEL_FILE)) == ct$md5)
DIR_P <- here("results", "paper")
unlink(DIR_P, recursive = TRUE); dir.create(DIR_P)   # rebuilt from scratch on every run
TB <- list(); TT <- list(); TN <- list()   # main tables (character columns), titles, notes

# ---- inputs ----
FPM <- fread(file.path(DIR_TAB, "fee_path_march.csv")); IP <- fread(file.path(DIR_TAB, "inference_primary.csv")); ITP <- fread(file.path(DIR_TAB, "inference_top_placebos.csv"))
LRW <- fread(file.path(DIR_TAB, "entry_ratio_placebo_windows.csv")); HO <- fread(file.path(DIR_TAB, "headline_one_sample.csv")); EA <- fread(file.path(DIR_TAB, "entity_accounting.csv"))
EI <- fread(file.path(DIR_TAB, "entity_effect_implied.csv")); EC <- fread(file.path(DIR_TAB, "entrant_classes_6v6.csv")); CDH <- fread(file.path(DIR_TAB, "cut_day_hours.csv"))
CDP <- fread(file.path(DIR_TAB, "cut_day_hours_placebo_days.csv")); ERC <- fread(file.path(DIR_TAB, "entry_by_recipient_category.csv")); EFA <- fread(file.path(DIR_TAB, "entry_by_first_action.csv"))
EFS <- fread(file.path(DIR_TAB, "entrant_funding_source.csv")); TE <- fread(file.path(DIR_TAB, "timing_eth.csv")); OPL <- fread(file.path(DIR_TAB, "op_mainnet_vs_l1.csv"))
BOA <- fread(file.path(DIR_TAB, "base_minus_op_adjusted.csv")); DP <- fread(file.path(DIR_TAB, "donor_pool_daa.csv")); EDT <- fread(file.path(DIR_TAB, "entry_delay_test.csv"))
WF <- fread(file.path(DIR_TAB, "inference_wave_size_floors.csv")); EPC <- fread(file.path(DIR_TAB, "entrant_persistence_cut.csv"))
CAL <- readRDS(PANEL_FILE)$event_calendar

# ---- Table 1. Fees around the cut (panel A) and dated events (panel B) ----
LAB <- c(base = "Base", optimism = "OP Mainnet", arbitrum = "Arbitrum", ethereum = "Ethereum L1")
F1 <- FPM[period %in% c("before, 6 days: 03-08..13", "days 0-5: 03-14..19", "days 6-13: 03-20..27") & chain %in% names(LAB)][
  , cell := fifelse(log_change_from_before == 0, sprintf("$%.4f", median_fee_usd), sprintf("$%.4f (%+.2f)", median_fee_usd, log_change_from_before))]
TB$t1a <- dcast(F1[, .(Period = period, chain = LAB[chain], cell)], Period ~ chain, value.var = "cell")[order(match(Period, unique(F1$period)))][, c("Period", LAB), with = FALSE]
TT$t1a <- "Table 1A. Median fee per transaction around the cut (US$)"
TN$t1a <- "Median over the period's days of growthepie's daily median fee per transaction. In parentheses: log change from the six days before the cut. The upgrade took effect on Base and OP Mainnet at 00:00 UTC on 14 March; Arbitrum cut its fee at 15:00 on 14 March and again at 08:00 on 19 March; Ethereum L1 made no fee change. From 20 March congestion, not the upgrade, set Base's fee."
TB$t1b <- CAL[order(date, time_utc), .(Date = format(date, "%Y-%m-%d"), `Time (UTC)` = time_utc, Event = event, Source = sub("^https?://(www\\.)?([^/]+).*$", "\\2", source))]
TT$t1b <- "Table 1B. Dated events, March-June 2024"
TN$t1b <- "Each event with a public source (`data/external/event_calendar.csv`, which gives the full link). Time empty: only the day is known. Base-specific events (memecoin trading, record fees and deposits, congestion, the Onchain Summer campaign) are the main alternative explanation in Section 7."

# ---- Table 2. The effect on entry outside waves: estimate and inference ----
I2 <- merge(IP[placebo == "pre-cut dates"], IP[placebo == "all dates", .(window, all_K = placebo_K, all_rank = round(rank_p * (1 + placebo_K)))], by = "window")[
  order(match(window, c("6 v 6", "7 v 7", "4 v 4", "5 v 5", "6 v 5")))]
TB$t2 <- rbind(
  I2[, .(Window = fcase(window == "6 v 6", "6 v 6 days (primary)", window == "6 v 5", "6 v 5 days (19 March left out)", default = paste(window, "days")),
         Estimate = sprintf("%.3f", estimate), Ratio = sprintf("x%.2f", ratio), `Pre-cut placebos (non-overlapping)` = sprintf("%d (%d)", placebo_K, disjoint_K),
         `Rank p` = sprintf("%d/%d", round(rank_p * (1 + placebo_K)), 1L + placebo_K), `Placebo SDs` = sprintf("%.1f", z_placebo), `AR(1) z` = sprintf("%.1f", z_ar1),
         `All dates: rank of K + 1` = sprintf("%d of %d", all_rank, all_K + 1L), `Base alone` = sprintf("x%.2f", exp(base_alone)))],
  LRW[series == "Base minus Ethereum L1" & placebo == "pre-cut dates only" & window_days %in% c(14L, 28L), .(Window = sprintf("%d v %d days (path)", window_days, window_days), Estimate = sprintf("%.3f", log(ratio)),
         Ratio = sprintf("x%.2f", ratio), `Pre-cut placebos (non-overlapping)` = "", `Rank p` = "", `Placebo SDs` = "", `AR(1) z` = "", `All dates: rank of K + 1` = "", `Base alone` = "")])
tp <- ITP[window_days == 6L][order(-cut, -d)]
TT$t2 <- "Table 2. Entry of new addresses outside batch-creation waves, Base minus Ethereum L1"
TN$t2 <- sprintf("Estimate: change in mean daily log entry outside waves (new addresses neither in a wave nor heavy), Base minus Ethereum L1, from the days before the cut to the days from it (14 March); ratio = exp(estimate), a ratio of geometric means net of L1. Placebo dates: the same statistic at earlier dates whose windows end before the cut and hold no cut day (pre-cut), or at all dates of January-June 2024 (all dates). Rank p = (1 + placebos at least as large) / (1 + K); the smallest attainable is 1/(1 + K). Non-overlapping: the largest number of placebo windows that do not overlap. Placebo SDs: (estimate - placebo mean) / placebo SD. AR(1) z: estimate over its SD under an AR(1) fitted to pre-cut daily differences. Base alone: the same shift on Base without the L1 difference. 14 and 28 days are shown as a path, without tests. The two larger all-dates placebos at 6 days start on %s and %s; over the six days before each, the gap rose %.2f and %.2f log a day, against %.3f before the cut.",
                 format(tp$start[2], "%d %B"), format(tp$start[3], "%d %B"), tp$slope_before[2], tp$slope_before[3], tp$slope_before[1])

# ---- Table 3. Where the rise in counted new addresses came from (Base alone) ----
TB$t3 <- rbind(
  HO[sample %like% "^long", .(Sample = "Long series: new addresses (no tx in 60 days)", `Window or rule` = window, `Before -> after (per day)` = sprintf("%s -> %s", format(round(all_before), big.mark = ",", trim = TRUE), format(round(all_after), big.mark = ",", trim = TRUE)),
       All = sprintf("x%.2f", all_ratio), `Outside waves or bursts` = sprintf("x%.2f", outside_ratio), `Share of the added in waves or bursts` = sprintf("%.0f%%", 100 * batch_share_of_added))][
    order(as.integer(sub(" v.*", "", `Window or rule`)))],
  HO[sample %like% "^window", .(Sample = "Window entrants (never active on Base), 6 v 6 days", `Window or rule` = rule, `Before -> after (per day)` = sprintf("%s -> %s", format(round(all_before), big.mark = ",", trim = TRUE), format(round(all_after), big.mark = ",", trim = TRUE)),
       All = sprintf("x%.2f", all_ratio), `Outside waves or bursts` = sprintf("x%.2f", outside_ratio), `Share of the added in waves or bursts` = sprintf("%.0f%%", 100 * batch_share_of_added))],
  EI[cut == "Base March", .(Sample = "Funding entities behind non-burst entrants", `Window or rule` = sprintf("implied, %d days (net of L1)", window_days), `Before -> after (per day)` = "",
       All = "", `Outside waves or bursts` = sprintf("x%.2f [%.2f, %.2f]", implied_entity_effect, implied_lo, implied_hi), `Share of the added in waves or bursts` = "")],
  EA[cut == "Base March" & days == "all days" & measure == "entities", .(Sample = "Funding entities behind non-burst entrants", `Window or rule` = "direct count, 6 v 6 days (Base alone)",
       `Before -> after (per day)` = sprintf("%s -> %s", format(round(before), big.mark = ",", trim = TRUE), format(round(after), big.mark = ",", trim = TRUE)), All = "", `Outside waves or bursts` = sprintf("x%.2f [%.2f, %.2f]", ratio, lo, hi),
       `Share of the added in waves or bursts` = "")])
wf <- WF[window_days == 6L & placebo == "pre-cut dates"]
TT$t3 <- "Table 3. Counted new addresses against entry outside batch-creation waves, Base, March 2024"
TN$t3 <- sprintf("Ratios of daily means after / before on Base alone, except the implied entity effect (the L1-differenced address effect of Table 2 times the change in funding entities per address; interval from that change only, 2,000 day-bootstrap draws). Long series: waves are recipient x method groups with >= 1,000 new addresses a day and >= 3 times their trailing 28-day median. Window entrants: bursts are recipient x method groups with >= 1,000 entrants a day and >= 3 times their own median over 8-13 March; bot-like entrants (>= 100 txs in week 1) are a separate class; the main rule is the strictest of the four shown. Funding entities: funder-entrant-sweep components (service threshold 500), counted per day. Across wave and burst floors from %s to %s new addresses a day, the 6-day estimate runs from x%.2f to x%.2f, the share of the added in waves from %.0f%% to %.0f%%, and the implied entity effect from x%.2f to x%.2f (appendix A2).",
                 format(min(wf$wave_size_floor), big.mark = ",", trim = TRUE), format(max(wf$wave_size_floor), big.mark = ",", trim = TRUE), min(wf$ratio), max(wf$ratio), 100 * max(wf$wave_share_of_added_6v6), 100 * min(wf$wave_share_of_added_6v6),
                 min(wf$implied_entity_effect), max(wf$implied_entity_effect))

# ---- Table 4. Who the new accounts are ----
EC[, cls := c(bot = "Bot-like", campaign = "Burst", genuine = "Non-burst")[class3]]
T4 <- EC[, .(cls, `Entrants per day, before -> after` = sprintf("%s -> %s (x%.1f)", format(round(entrants_before), big.mark = ",", trim = TRUE), format(round(entrants_after), big.mark = ",", trim = TRUE), entrant_ratio),
             `Funding entities per day, before -> after` = sprintf("%s -> %s (x%.1f)", format(round(entities_before), big.mark = ",", trim = TRUE), format(round(entities_after), big.mark = ",", trim = TRUE), entity_ratio),
             `Share of entrants after the cut` = sprintf("%.0f%%", 100 * share_after), `Share of the added entrants` = sprintf("%.0f%%", 100 * share_of_added),
             `In a funding cluster of 20+` = sprintf("%.0f%%", 100 * in_cluster_20), `First tx in a same-block group of 10+` = sprintf("%.0f%%", 100 * same_block_group),
             `Held by the 10 / 100 largest components` = sprintf("%.0f%% / %.0f%%", 100 * top10_share, 100 * top100_share), `Months active of Sep 2024, Dec 2024, Mar 2025 (0-3)` = sprintf("%.2f", months_active_of3),
             `On the LayerZero provisional Sybil list` = sprintf("%.1f%%", 100 * layerzero_list), `Address / funder also enters Arbitrum` = sprintf("%.1f%% / %.1f%%", 100 * other_l2_address, 100 * other_l2_funder),
             `Received tokens / ETH after entry` = sprintf("%.0f%% / %.0f%%", 100 * tokens_after, 100 * eth_after))]
T4 <- melt(T4, id.vars = "cls", variable.name = "Characteristic", value.name = "v", variable.factor = FALSE)
TB$t4 <- dcast(T4, Characteristic ~ cls, value.var = "v")[order(match(Characteristic, unique(T4$Characteristic)))][, .(Characteristic, Burst, `Non-burst`, `Bot-like`)]
TT$t4 <- "Table 4. Who the new accounts are: Base window entrants, 6 days before vs 6 days after the cut"
TN$t4 <- "Window entrants: addresses never active on Base before, first active on 8-13 March (before) or 14-19 March (after). Classes under the main burst rule of Table 3; bot-like: >= 100 txs in the first week. Shares after the cut unless stated. Same-block group: the first tx shares a block with >= 10 other entrants with the same recipient and method. Months active: days 1-10 of each month."

# ---- Table 5. Threats and the evidence on each ----
bb <- CDH[chain == "base"]; pd <- CDP[measure == "entrants"]; pe <- CDP[measure == "entities"]
boom <- ERC[category == "boom-type recipients"]; nob <- ERC[category == "all but boom-type recipients"]; nbx <- ERC[category == "all but bridge and exchange recipients"]
swp <- EFA[type %like% "^swap-like"]; nsw <- EFA[type == "all but swap-like first actions"]
op6 <- OPL[window_days == 6L & placebo == "pre-cut dates"]; ba6 <- BOA[window_days == 6L]
dp <- DP[placebo == "pre-cut dates"]; wf6 <- WF[window_days == 6L & placebo == "pre-cut dates"]
TB$t5 <- data.table(Threat = c("A Base-specific shock: the cut day hour by hour", "A Base-specific shock: the memecoin boom (first recipients)", "A Base-specific shock: swap-like first actions",
                               "A Base-specific shock: exchange inflows", "A Base-specific shock: the ETH rally", "A shock common to OP-stack chains (OP Mainnet, same cut, same second)",
                               "Ethereum L1 as the comparison", "Delay, not new entry", "Batch accounts the rules miss; the choice of floor", "Returners counted as new", "Entrant quality"),
  Evidence = c(
    sprintf("Base non-burst entrants on 14 March against the same hours of 8-13 March: %+.2f log in hours 00-05 (median fee %.2f cents), %+.2f in 06-11, %+.2f in 12-14, %+.2f in 15-23. Base minus not-yet-cut Arbitrum: %+.2f in 06-11 (placebo days %.2f to %.2f), %+.2f in 12-14; entities %+.2f in 06-11 (placebo days %.2f to %.2f). Arbitrum rose %+.2f in 12-14, before its own 15:00 cut.",
            bb[blk == "00-05", log_change], 100 * bb[blk == "00-05", cut_day_fee_usd], bb[blk == "06-11", log_change], bb[blk == "12-14", log_change], bb[blk == "15-23", log_change],
            pd[blk == "06-11", cut_day], pd[blk == "06-11", placebo_min], pd[blk == "06-11", placebo_max], pd[blk == "12-14", cut_day], pe[blk == "06-11", cut_day], pe[blk == "06-11", placebo_min], pe[blk == "06-11", placebo_max],
            CDH[chain == "arbitrum" & blk == "12-14", log_change]),
    sprintf("NFT mints and claims, other tokens and a trading-bot contract: x%.1f, %.0f%% of the rise in non-burst entrants and %.0f%% of the rise in funding entities. Without them: x%.2f (entities x%.2f).",
            boom$ratio, 100 * boom$share_of_increase, 100 * boom$share_of_entity_increase, nob$ratio, nob$entity_ratio),
    sprintf("A DEX-swap selector or a first recipient named as a DEX router, aggregator or trading bot: x%.2f, %.0f%% of the rise; without them x%.2f.", swp$ratio, 100 * swp$share_of_rise, nsw$ratio),
    sprintf("Non-burst entrants by source of their first ETH: exchange withdrawals x%.2f, direct transfers from other addresses x%.2f, all x%.2f. Without bridge and exchange first recipients: x%.2f.",
            EFS[chain == "base" & source == "exchange withdrawal", ratio], EFS[chain == "base" & source == "individual, direct transfer", ratio], EC[class3 == "genuine", entrant_ratio], nbx$ratio),
    sprintf("Mean daily gap (Base minus L1 entry outside waves, relative to the week before the cut) while ETH rose to its 11 March peak: %+.2f.", TE[day <= TE[which.max(eth_usd), day], mean(gap)]),
    sprintf("OP Mainnet minus L1, 6 days: transactions %+.2f (above %d of %d pre-cut placebos), active addresses %+.2f (%.0fth percentile). Base minus OP Mainnet, active addresses: %+.2f; without 16 March and Base's new addresses in waves %+.2f (%.0fth percentile).",
            op6[pair %like% "^OP" & outcome == "log transactions", shift], round(op6[pair %like% "^OP" & outcome == "log transactions", placebo_pct * placebo_K]), op6[pair %like% "^OP" & outcome == "log transactions", placebo_K],
            op6[pair %like% "^OP" & outcome == "log active addresses", shift], 100 * op6[pair %like% "^OP" & outcome == "log active addresses", placebo_pct],
            op6[pair == "Base minus OP Mainnet" & outcome == "log active addresses", shift], ba6[base_count %like% "without" & without_03_16 == TRUE, base_minus_op], 100 * ba6[base_count %like% "without" & without_03_16 == TRUE, placebo_pct]),
    sprintf("L1's fee fell %.0f%% (Base's %.0f%%); L1's own entry outside waves rose %.2f. Active addresses, donor pool of %d chains whose fees fell less than 1 log: L1 minus the donor mean %+.2f (%.0fth percentile); Base minus the donor mean %+.2f against %+.2f minus L1; Base minus each donor %.2f to %.2f, each above all pre-cut placebos.",
            100 * (1 - exp(FPM[chain == "ethereum" & period == "days 0-5: 03-14..19", log_change_from_before])), 100 * (1 - exp(FPM[chain == "base" & period == "days 0-5: 03-14..19", log_change_from_before])),
            I2[window == "6 v 6", base_alone - estimate], uniqueN(dp[series %like% "^base minus" & !(series %in% c("base minus ethereum", "base minus donor_mean")), series]),
            dp[series == "L1 minus donor_mean", shift_6d], 100 * dp[series == "L1 minus donor_mean", placebo_pct], dp[series == "base minus donor_mean", shift_6d], dp[series == "base minus ethereum", shift_6d],
            dp[series %like% "^base minus" & !(series %in% c("base minus ethereum", "base minus donor_mean")), min(shift_6d)], dp[series %like% "^base minus" & !(series %in% c("base minus ethereum", "base minus donor_mean")), max(shift_6d)]),
    sprintf("Base minus L1 against 28 days before (c-42..c-15): run-up %+.2f, after %+.2f, net %+.2f over the 28 days around the cut (a path, without tests).",
            EDT[statistic == "dip" & placebo == "all dates", value], EDT[statistic == "after" & placebo == "all dates", value], EDT[statistic == "net" & placebo == "all dates", value]),
    sprintf("Wave and burst floors from %s to %s a day: estimate x%.2f to x%.2f, each above all %d pre-cut placebos; implied entity effect x%.2f to x%.2f. Clusters of 20+ hold %s of the non-burst rise.",
            format(min(wf6$wave_size_floor), big.mark = ",", trim = TRUE), format(max(wf6$wave_size_floor), big.mark = ",", trim = TRUE), min(wf6$ratio), max(wf6$ratio), wf6$placebo_K[1], min(wf6$implied_entity_effect), max(wf6$implied_entity_effect),
            sprintf("%.0f%%", 100 * fread(file.path(DIR_TAB, "entrant_entities_nonburst.csv"))[chain == "base", (after[measure == "addresses, cluster of 20+"] - before[measure == "addresses, cluster of 20+"]) / (after[measure == "addresses, all"] - before[measure == "addresses, all"])])),
    sprintf("Window entrants never active on Base, outside bursts: x%.2f.", HO[sample %like% "^window" & rule == "main burst rule", outside_ratio]),
    sprintf("Share of non-burst entrants active later (Sep 2024, Dec 2024 or Mar 2025): %.1f%% before, %.1f%% after (x%.2f [%.2f, %.2f]).", 100 * EPC[chain == "base", active_before], 100 * EPC[chain == "base", active_after],
            EPC[chain == "base", ratio], EPC[chain == "base", lo], EPC[chain == "base", hi])),
  Source = c("cut_day_hours.csv, cut_day_hours_placebo_days.csv", "entry_by_recipient_category.csv", "entry_by_first_action.csv", "entrant_funding_source.csv, entry_by_recipient_category.csv", "timing_eth.csv",
             "op_mainnet_vs_l1.csv, base_minus_op_adjusted.csv", "fee_path_march.csv, inference_primary.csv, donor_pool_daa.csv", "entry_delay_test.csv", "inference_wave_size_floors.csv, entrant_entities_nonburst.csv",
             "headline_one_sample.csv", "entrant_persistence_cut.csv"))
TT$t5 <- "Table 5. Threats to the estimate and the evidence on each"
TN$t5 <- "All numbers are for Base's March cut over the 6 days from it against the 6 days before unless stated. Log changes; x = ratio after / before. A first recipient or first action does not reveal intent. The stated limit: a Base-specific shock that began on the cut day cannot be excluded; the estimate is the effect of the cut on Base as it was."

# ---- write the main tables: one CSV each and tables.md ----
md <- c("# Main tables", "", "Generated by `code/08_paper_exhibits.R` from `results/tables`. Do not edit by hand.", "")
for (k in names(TB)) {
  fwrite(TB[[k]], file.path(DIR_P, sprintf("table%s.csv", sub("t", "", k))))
  md <- c(md, paste0("## ", TT[[k]]), "", paste0("| ", paste(names(TB[[k]]), collapse = " | "), " |"), paste0("|", paste(rep("---", ncol(TB[[k]])), collapse = "|"), "|"),
          paste0("| ", do.call(paste, c(lapply(TB[[k]], as.character), sep = " | ")), " |"), "", paste0("*Notes.* ", TN[[k]]), "")
  cat("\n## ", TT[[k]], "\n", sep = ""); print(TB[[k]])
}
writeLines(md, file.path(DIR_P, "tables.md"))

# ---- index (results/paper/README.md): every exhibit, the question it answers, and its files (links relative to results/paper; figures and appendix stay where 04-07 write them) ----
p6 <- I2[window == "6 v 6"]
MAIN <- data.table(exhibit = c("Table 1", "Figure 1", "Table 2", "Figure 2", "Table 3", "Figure 3", "Table 4", "Table 5", "Figure 4"),
  question = c("What changed at the cut, and how did fees move?", "How did fees move, hourly at the cut and daily on four chains?", "How much did entry outside batch waves rise, and how sure are we?",
               "When did the gap open, and did the same cut move OP Mainnet?", "Where did the rise in counted new addresses come from?", "Do batch waves happen on every chain?",
               "Who are the new accounts?", "Could a Base-specific shock explain the rise?", "When on the cut day did entry move?"),
  answer = c(sprintf("Base's median fee fell %.0f%% for six days, then congestion set it; L1's fell %.0f%%", 100 * (1 - exp(FPM[chain == "base" & period == "days 0-5: 03-14..19", log_change_from_before])),
                     100 * (1 - exp(FPM[chain == "ethereum" & period == "days 0-5: 03-14..19", log_change_from_before]))),
             "The fee broke at 00:00 on Base and OP Mainnet; Base's rose again from 20 March",
             sprintf("x%.2f over the six low-fee days relative to L1, above all %d pre-cut placebos; x%.2f over seven days", p6$ratio, p6$placebo_K, I2[window == "7 v 7", ratio]),
             "The gap grew day by day from the cut; OP Mainnet's transactions rose but not its active addresses",
             sprintf("Counted new addresses x%.2f; %.0f%% of the rise came in batch waves; entry outside waves x%.2f (Base alone)", HO[sample %like% "^long" & window == "6 v 6 days", all_ratio],
                     100 * HO[sample %like% "^long" & window == "6 v 6 days", batch_share_of_added], HO[sample %like% "^long" & window == "6 v 6 days", outside_ratio]),
             "Yes, on Base and L1 alike; their volume swings widely, so the design cannot attribute them to the cut",
             "Burst accounts: same-block, clustered, concentrated and short-lived; non-burst entrants spread out and stay longer",
             "Timing, recipients, funding, OP Mainnet and a donor pool narrow it; a shock that began on the cut day cannot be excluded",
             "Normal for six hours, then above every earlier day from 06:00, while not-yet-cut Arbitrum was flat until noon"),
  file = c("table1a.csv", "../figures/fee_daily_march.png", "table2.csv", "../figures/entry_event_study_base_l1.png", "table3.csv", "../figures/waves_2024_with_l1.png", "table4.csv", "table5.csv", "../figures/cut_day_hours.png"),
  script = c("06 U1; event calendar", "04 A; 06 U1", "06 L, R2", "06 L1, U2", "06 Q, R1, R2b", "06 K3", "06 R4", "06 S, U2, U3", "06 S6"))
APX <- data.table(exhibit = paste0("A", 1:12),
  content = c("The four cuts in one table, and the hourly fee and transactions at the March cuts on both chains", "Wave and burst size floors: estimate, breakdown and implied entity effect",
              "Window path, the largest placebos with their before-window slopes and dated events", "First actions by method selector, and the 50 named first recipients",
              "Donor pool of chains without a fee cut against the L1 comparison", "Daily non-burst entrants and funding entities; entity accounting and the composition deflator",
              "The cut hour: RD with pre-cut fake hours, local randomization, matched hours against Arbitrum, cut-day placebo days", "OP Mainnet: Base minus OP, batch-adjusted, and OP minus L1",
              "Base's May cut: one estimator against L1 and Arbitrum, funding entities, waves day by day", "Where non-burst entrants' first ETH came from; funding clusters; cross-chain entry",
              "Delay or new entry, persistence, and the daily event study", "Long-series waves by chain and against L1"))
APF <- rbind(
  data.table(exhibit = "A1", file = c("four_cuts_summary.csv", "fee_cuts_hourly_march.png")), data.table(exhibit = "A2", file = c("inference_wave_size_floors.csv", "wave_floors.png")),
  data.table(exhibit = "A3", file = c("inference_primary.csv", "inference_top_placebos.csv", "entry_ratio_placebo_windows.csv")),
  data.table(exhibit = "A4", file = c("entry_by_first_action.csv", "entry_top_recipients.csv", "entry_by_recipient_category.csv", "entry_without_top_recipients.csv")),
  data.table(exhibit = "A5", file = "donor_pool_daa.csv"), data.table(exhibit = "A6", file = c("entities_daily_march.csv", "entities_daily_march.png", "entity_accounting.csv", "entity_effect_implied.csv")),
  data.table(exhibit = "A7", file = c("hour_rd_precut_ri.csv", "hour_rd_outcomes.csv", "hour_matched_base_arbitrum.csv", "cut_day_hours.csv", "cut_day_hours_placebo_days.csv")),
  data.table(exhibit = "A8", file = c("base_minus_op_mainnet.csv", "base_minus_op_adjusted.csv", "op_mainnet_vs_l1.csv", "op_mainnet_event_study.csv", "op_mainnet_event_study.png")),
  data.table(exhibit = "A9", file = c("base_cuts_test.csv", "base_cuts_reading.csv", "may_entities_nonburst.csv", "may_waves_event_study.csv", "may_waves_first_week.csv", "may_waves_event_study.png")),
  data.table(exhibit = "A10", file = c("entrant_funding_source.csv", "entrant_entities_nonburst.csv", "entrant_cross_chain.csv")),
  data.table(exhibit = "A11", file = c("entry_delay_test.csv", "entrant_persistence_cut.csv", "entry_event_study_base_l1.csv", "timing_eth.csv")),
  data.table(exhibit = "A12", file = c("long_control_test.csv", "waves_2024_by_chain.png")))
APF[, file := paste0(fifelse(file %like% "\\.png$", "../figures/", "../tables/"), file)]
# the results/tables files each main exhibit is built from, and second figure panels
SRC <- rbind(data.table(exhibit = "Table 1", file = c("../tables/fee_path_march.csv", "table1b.csv")), data.table(exhibit = "Figure 1", file = "../figures/fee_cuts_hourly_march.png"),
  data.table(exhibit = "Table 2", file = c("../tables/inference_primary.csv", "../tables/entry_ratio_placebo_windows.csv", "../tables/inference_top_placebos.csv")),
  data.table(exhibit = "Figure 2", file = c("../tables/entry_event_study_base_l1.csv", "../figures/op_mainnet_event_study.png")),
  data.table(exhibit = "Table 3", file = c("../tables/headline_one_sample.csv", "../tables/entity_effect_implied.csv", "../tables/entity_accounting.csv", "../tables/inference_wave_size_floors.csv")),
  data.table(exhibit = "Table 4", file = "../tables/entrant_classes_6v6.csv"), data.table(exhibit = "Table 5", file = paste0("../tables/", unique(unlist(strsplit(TB$t5$Source, ", "))))),
  data.table(exhibit = "Figure 4", file = "../tables/cut_day_hours.csv"))
stopifnot(all(file.exists(file.path(DIR_P, c(MAIN$file, APF$file, SRC$file)))))   # every linked file exists
MAIN <- merge(MAIN[, ord := .I], SRC[, .(sources = paste(sprintf("[%s](%s)", basename(file), file), collapse = ", ")), by = exhibit], by = "exhibit", all.x = TRUE)[order(ord)][is.na(sources), sources := ""]
APX <- merge(APX, APF[, .(files = paste(sprintf("[%s](%s)", basename(file), file), collapse = ", ")), by = exhibit], by = "exhibit")[order(as.integer(sub("A", "", exhibit)))]
IDX <- c("# Paper exhibits", "", "Generated by `code/08_paper_exhibits.R`. The five main tables are in [`tables.md`](tables.md) (and one CSV each; Table 1 in two panels); figures and appendix exhibits are the files written by `04`-`07`.", "",
         "## Main text", "", "| Exhibit | Question | Answer | File | Built from, other panels | Script, section |", "|---|---|---|---|---|---|",
         MAIN[, sprintf("| %s | %s | %s | [%s](%s) | %s | %s |", exhibit, question, answer, basename(file), file, sources, script)],
         "", "## Appendix", "", "| No. | Content | Files |", "|---|---|---|", APX[, sprintf("| %s | %s | %s |", exhibit, content, files)])
writeLines(IDX, file.path(DIR_P, "README.md"))
cat(sprintf("\nWrote %d main tables, tables.md and README.md (%d main exhibits, %d appendix files indexed) to results/paper\n", length(TB), nrow(MAIN), nrow(APF)))
cat("\n## sessionInfo\n```\n"); print(sessionInfo()); cat("```\n"); sink()
