# 08_paper_exhibits.R: the paper's main tables, assembled from the outputs of 04-07 (results/tables) into results/paper/, and an index of every exhibit.
#   Writes table1-6.csv, tables.md (all six with notes) and README.md (main tables and figures, appendix A1-A13, each linked to the file written by 04-07).
#   Estimates nothing new and copies no files; run after 04-07. Defines no functions.
source(here::here("code", "00_setup.R"))
sink(file.path(DIR_LOG, "08_paper_exhibits.md"), split = TRUE)
cat("# 08 paper exhibits\nRun ", format(Sys.time(), usetz = TRUE), "\n", sep = "")
ct <- yaml::read_yaml(CONTRACT_FILE)   # panel.rds must have passed 03_validate_panels.R and be unchanged since
stopifnot(isTRUE(ct$all_valid), unname(tools::md5sum(PANEL_FILE)) == ct$md5)
DIR_P <- here("results", "paper")
unlink(DIR_P, recursive = TRUE); dir.create(DIR_P)   # rebuilt from scratch on every run
TB <- list(); TT <- list(); TN <- list()   # main tables (character columns), titles, notes

# ---- inputs ----
T1E <- fread(file.path(DIR_TAB, "table1_fee_cuts.csv")); RDA <- fread(file.path(DIR_TAB, "rd_all_events.csv")); RM <- fread(file.path(DIR_TAB, "may_events.csv"))
EL <- fread(file.path(DIR_TAB, "elasticities.csv")); MDD <- fread(file.path(DIR_TAB, "may_daily_did.csv")); MP <- fread(file.path(DIR_TAB, "multichain_pooled.csv"))
WSE <- fread(file.path(DIR_TAB, "within_sender_elasticity.csv"))
SC <- fread(file.path(DIR_TAB, "second_cut_entry_base.csv")); SCE <- fread(file.path(DIR_TAB, "second_cut_entrants_base.csv")); RB <- fread(file.path(DIR_TAB, "campaign_rule_bounds.csv"))
RB2 <- fread(file.path(DIR_TAB, "val_bound_corrected.csv")); VV <- fread(file.path(DIR_TAB, "val_lz_clusters.csv")); BO <- fread(file.path(DIR_TAB, "burst_operators_base.csv"))
CG <- fread(file.path(DIR_TAB, "val_campaign_targets_base.csv")); PC <- fread(file.path(DIR_TAB, "persistence_common_horizon_base.csv")); EG <- fread(file.path(DIR_TAB, "val_entity_growth.csv"))
TH <- fread(file.path(DIR_TAB, "threshold_stakes.csv")); ECO <- fread(file.path(DIR_TAB, "platform_economics.csv"))
FA <- fread(file.path(DIR_TAB, "first_actions_base.csv")); RW <- fread(file.path(DIR_TAB, "second_cut_vs_arbitrum.csv")); RK <- fread(file.path(DIR_TAB, "entry_rd_by_class.csv"))

# ---- Table 1. The fee cuts ----
TB$t1 <- T1E[, .(Cut = short, `Time (UTC)` = time_utc, `What changed` = origin, `Set by` = set_by, `Median fee per tx before (US$)` = sprintf("%.4f", median_fee_pre),
                 `After (US$)` = sprintf("%.4f", median_fee_post), `Change (log points)` = sprintf("%.2f", dlog_fee))]
TT$t1 <- "Table 1. The fee cuts"
TN$t1 <- "Median fee per transaction: median over the window's days of growthepie's daily median (US$). Windows: Base March 03-08..12 vs 03-14..21; Arbitrum step 1 03-10..13 vs 03-15..18; step 2 03-15..18 vs 03-20..21; Base May 05-21..27 vs 05-29..06-04."

# ---- Table 2. Usage at the five cuts (hourly RD in time) ----
bf <- RM[y %like% "base fee", sprintf("%.2f (%.2f) [%.2f]", est, se, ri_p)]
T2 <- copy(RDA); setnames(T2, c("Outcome", "Base, 14 Mar", "Arbitrum, 14 Mar", "Arbitrum, 19 Mar", "Base, 28 May", "Base, 30 May"))
T2 <- rbind(T2[1:2], data.table(Outcome = "log L2 base fee per gas", `Base, 14 Mar` = "", `Arbitrum, 14 Mar` = "", `Arbitrum, 19 Mar` = "", `Base, 28 May` = bf[1], `Base, 30 May` = bf[2]), T2[-(1:2)])
for (v in names(T2)[-1]) T2[is.na(get(v)), (v) := ""]
TB$t2 <- T2
TT$t2 <- "Table 2. Usage at the five fee cuts: hourly regression discontinuity in time"
TN$t2 <- "Estimate (Newey-West SE) [randomization-inference p = (1 + number of fake event hours with an estimate at least as large in absolute value) / (1 + number of fake hours)]. +-36 h, hour-of-day FE, side-specific trends, 1-hour donut. Price: hourly median fee per successful tx with a positive fee (the fee a typical tx pays); the hourly mean fee per tx is shown as a check and, once fees are cents, is dominated by a few high-priority txs. Base fee per gas: May only (block median). New senders: no outgoing tx since 2024-02-15. Elasticity: fuzzy RD, Post instrumenting the log median fee (= jump in log txs / jump in log median fee), Newey-West SE."

# ---- Table 3. Aggregate vs intensive margin ----
mp <- MP[set %like% "^documented" & term == "2SLS elasticity txs"]; mdt <- MP[set %like% "^detected blob" & term == "2SLS elasticity txs"]; md <- MDD[outcome == "log txs"]
TB$t3 <- rbind(
  EL[price == "median", .(Margin = "Aggregate (all txs)", Design = "Hourly fuzzy RD in time", Sample = c("Base, 14 Mar", "Arbitrum, 14 Mar", "Arbitrum, 19 Mar", "Base, 28 May", "Base, 30 May", "Base, both May steps"),
                           Elasticity = sprintf("%.2f", elasticity_txs), SE = sprintf("(%.2f)", se_txs), Note = sprintf("first-stage Wald %.1f", first_stage_wald))],
  data.table(Margin = "Aggregate (all txs)", Design = c(sprintf("Daily 2SLS vs %d chains", md$n_perm), "Stacked 2SLS across rollups", "Stacked 2SLS across rollups"),
             Sample = c("Base, May", sprintf("%d events, documented dates", mp$n_events), sprintf("%d events, detected dates", mdt$n_events)),
             Elasticity = sprintf("%.2f", c(md$elasticity, mp$est, mdt$est)), SE = sprintf("(%.2f)", c(md$se_elasticity, mp$se, mdt$se)),
             Note = c(sprintf("permutation p of the DiD %.2f", md$perm_p), sprintf("first-stage F %.0f", c(mp$first_stage_F, mdt$first_stage_F)))),
  WSE[, .(Margin = "Intensive (txs per existing sender)", Design = "Within sender, net of a placebo window pair",
          Sample = sprintf("%s (%s senders)", c("Base (Ecotone)" = "Base, 14 Mar", "Arbitrum step 1" = "Arbitrum, 14 Mar", "Arbitrum step 2" = "Arbitrum, 19 Mar")[event], format(senders, big.mark = ",")),
          Elasticity = sprintf("%.3f", elasticity), SE = sprintf("(%.3f)", se), Note = sprintf("%d fee-level bins, %.3f to %.3f", bins, bin_min, bin_max))])
TT$t3 <- "Table 3. Usage responds through entry: aggregate vs intensive-margin elasticities"
TN$t3 <- "Fuzzy RD: the Table 2 RD with Post instrumenting the log hourly median fee per tx; Newey-West SEs (6 lags). Both May steps: one RD over 05-27 07:00..06-01 08:00 with a trend that may kink at each step and both steps as instruments. With the median price the first stage is strong at the first May step and weaker at the second (Wald statistics in the table); with the hourly mean fee it is weak at both (elasticities.csv). Daily 2SLS: Base vs the other chains without a fee drop nearby (growthepie), log median fee instrumented by Base x post, SEs clustered by date; with one treated chain, the permutation p over control chains is the more conservative guide. Stacked 2SLS: blob adoption across rollups, SEs clustered by rollup. Intensive margin: senders active before the cut, by pre-cut fee-level bin (bins with >= 500 senders); sender-weighted mean of the bin elasticities, SE from the independent bins. Anchuri & Mamageishvili (2026) estimate -0.036 on Arbitrum for heavy users (>= 500 txs), conditional on the number of txs, Oct 2025-Apr 2026."

# ---- Table 4. Who the burst accounts are (Base, first cut) ----
v <- VV[chain == "base" & rule %like% "^main" & period == "post"]; sm <- SC[event %like% "^1"]
rules_ratio <- rbind(RB[chain == "base" & !(rule %like% "funded"), .(campaign_entry_ratio, genuine_entry_ratio, campaign_share_post)], RB2[chain == "base" & rule == "wave_funded2", .(campaign_entry_ratio, genuine_entry_ratio, campaign_share_post)])
cc <- BO[table == "concentration"]; xc <- BO[table == "cross_chain base"]; rc <- BO[table == "received_after_entry"]; pm <- PC[event %like% "March" & period == "post"]
eg <- EG[chain == "base" & service_threshold == 500 & class == "all"]
egc <- EG[chain == "base" & service_threshold == 500 & class == "campaign"]; egg <- EG[chain == "base" & service_threshold == 500 & class == "genuine"]
TB$t4 <- data.table(Characteristic = c("Entrants per day, before -> after the cut", "Entities per day, before -> after the cut", "Entry ratio across the three classification rules",
  "Share of all entrants after the cut (range across rules)",
  "In a funding cluster of >= 20 entrants", "First tx in the same block as >= 10 others with the same target and method", "Share held by the largest 10 / 100 entities",
  "First action: zero-value or native transfer to an account without code", "Months active of Sep 2024, Dec 2024, Mar 2025 (mean, 0-3)", "On the LayerZero provisional Sybil list",
  "Address also enters on Arbitrum / funder also funds Arbitrum entrants", "Received tokens / ETH after entry (to 15 Apr)"),
  `Burst accounts` = c(sprintf("%s -> %s (x%.1f)", format(round(sm[class3 == "campaign", pre]), big.mark = ","), format(round(sm[class3 == "campaign", post]), big.mark = ","), sm[class3 == "campaign", ratio]),
    sprintf("%s -> %s (x%.1f)", format(round(egc$ent_per_day_pre), big.mark = ","), format(round(egc$ent_per_day_post), big.mark = ","), egc$entity_ratio),
    sprintf("x%.0f to x%.0f", min(rules_ratio$campaign_entry_ratio), max(rules_ratio$campaign_entry_ratio)), sprintf("%.0f%% to %.0f%%", 100 * min(rules_ratio$campaign_share_post), 100 * max(rules_ratio$campaign_share_post)),
    sprintf("%.1f%%", 100 * v$clu500_campaign), sprintf("%.1f%%", 100 * v$sync_campaign), sprintf("%.0f%% / %.0f%%", 100 * cc[key == "campaign", v2], 100 * cc[key == "campaign", v3]),
    sprintf("%.0f%%", 100 * CG[type %like% "^native", sum(N)] / CG[, sum(N)]), sprintf("%.2f", pm[class3 == "campaign", months_active_of3]), sprintf("%.2f%%", 100 * v$lz_campaign),
    sprintf("%.1f%% / %.1f%%", 100 * xc[key == "campaign", v2], 100 * xc[key == "campaign", v3]), sprintf("%.0f%% / %.0f%%", 100 * rc[key == "campaign", v2], 100 * rc[key == "campaign", v3])),
  `Non-burst entrants` = c(sprintf("%s -> %s (x%.2f)", format(round(sm[class3 == "genuine", pre]), big.mark = ","), format(round(sm[class3 == "genuine", post]), big.mark = ","), sm[class3 == "genuine", ratio]),
    sprintf("%s -> %s (x%.2f)", format(round(egg$ent_per_day_pre), big.mark = ","), format(round(egg$ent_per_day_post), big.mark = ","), egg$entity_ratio),
    sprintf("x%.2f to x%.2f", min(rules_ratio$genuine_entry_ratio), max(rules_ratio$genuine_entry_ratio)), "",
    sprintf("%.1f%%", 100 * v$clu500_genuine), sprintf("%.1f%%", 100 * v$sync_genuine), sprintf("%.0f%% / %.0f%%", 100 * cc[key == "genuine", v2], 100 * cc[key == "genuine", v3]), "",
    sprintf("%.2f", pm[class3 == "genuine", months_active_of3]), sprintf("%.2f%%", 100 * v$lz_genuine),
    sprintf("%.1f%% / %.1f%%", 100 * xc[key == "genuine", v2], 100 * xc[key == "genuine", v3]), sprintf("%.0f%% / %.0f%%", 100 * rc[key == "genuine", v2], 100 * rc[key == "genuine", v3])))
TT$t4 <- "Table 4. Who the new accounts are: burst accounts vs non-burst entrants, Base, first cut"
TN$t4 <- sprintf("After the cut = entrants on 03-14..21 (before: 03-08..12). Burst accounts: first action in a same-day burst on one target (>= 1,000 entrants, >= 3x its own pre-cut median); rules: main, size-only (>= 5,000 a day), burst funded by bursting funders (funder before the first tx). Entities: funder-entrant-sweep components without service addresses (>= 500 distinct ETH counterparties before 03-08). All entrants: addresses x%.2f, entities x%.2f per day. The most common tokens received include a bulk memecoin drop (PEN) and phishing claim tokens (burst_tokens_received_base.csv).", eg$address_ratio, eg$entity_ratio)

# ---- Table 5. The second cut ----
cm <- BO[table == "concentration_may"]; mo <- BO[table == "march_operators_in_may"]; fa <- FA[class3 == "campaign"]
fe <- T1E[short %in% c("Base Mar", "Base May")]; s1 <- SC[event %like% "^1"]; s2 <- SC[event %like% "^2"]
p1 <- PC[event %like% "March" & period == "post"]; p2 <- PC[event %like% "May" & period == "post"]
h1 <- TH[short == "Base Mar"]; h2 <- TH[short == "Base May"]
TB$t5 <- data.table(` ` = c("Median fee per tx, before -> after (US$)", "Burst accounts per day, before -> after", "Burst entities per day, before -> after",
  "Non-burst entrants per day, before -> after", "All entrants per day, ratio",
  "Overstatement of participation growth (all / non-burst ratio)", "Burst share of entrants after the cut", "Share held by the largest 10 / 100 burst entities",
  "Burst accounts in a funding cluster of >= 20", "Months active of Sep 2024, Dec 2024, Mar 2025 (mean, 0-3): burst / non-burst",
  "March burst operators active again in May", "May burst accounts funded or swept by a March burst operator",
  "Burst accounts' first action: transfer / DEX swap / mint or claim / other", "Non-burst entry jump in the cut hour (hourly RD, log points)",
  "Relative to Arbitrum: burst accounts (95% CI)", "Relative to Arbitrum: non-burst entrants (95% CI)"),
  `First cut: March 2024 (L1 data cost)` = c(sprintf("%.3f -> %.4f", fe[short == "Base Mar", median_fee_pre], fe[short == "Base Mar", median_fee_post]),
    sprintf("%s -> %s (x%.1f)", format(round(s1[class3 == "campaign", pre]), big.mark = ","), format(round(s1[class3 == "campaign", post]), big.mark = ","), s1[class3 == "campaign", ratio]),
    sprintf("%s -> %s (x%.2f)", format(round(h1$burst_entities_per_day_pre), big.mark = ","), format(round(h1$burst_entities_per_day_post), big.mark = ","), h1$burst_entities_per_day_post / h1$burst_entities_per_day_pre),
    sprintf("%s -> %s (x%.2f)", format(round(s1[class3 == "genuine", pre]), big.mark = ","), format(round(s1[class3 == "genuine", post]), big.mark = ","), s1[class3 == "genuine", ratio]),
    sprintf("x%.2f", s1[class3 == "all", ratio]), sprintf("%.2f", s1$wedge[1]), sprintf("%.0f%%", 100 * s1[class3 == "campaign", post] / s1[class3 == "all", post]),
    sprintf("%.0f%% / %.0f%%", 100 * cc[key == "campaign", v2], 100 * cc[key == "campaign", v3]), sprintf("%.1f%%", 100 * v$clu500_campaign),
    sprintf("%.2f / %.2f", p1[class3 == "campaign", months_active_of3], p1[class3 == "genuine", months_active_of3]), "", "",
    fa[event == "1. March", sprintf("%.0f%% / %.0f%% / %.0f%% / %.0f%%", 100 * sum(share[type %like% "transfer"]), 100 * sum(share[type == "DEX swap"]), 100 * sum(share[type == "mint or claim"]), 100 * sum(share[type == "other contract call"]))],
    RK[event == EVENTS$event[1] & class3 == "genuine", sprintf("%.2f (%.2f)", jump, se)], "", ""),
  `Second cut: May 2024 (capacity raised by Base)` = c(sprintf("%.3f -> %.4f", fe[short == "Base May", median_fee_pre], fe[short == "Base May", median_fee_post]),
    sprintf("%s -> %s (x%.1f)", format(round(s2[class3 == "campaign", pre]), big.mark = ","), format(round(s2[class3 == "campaign", post]), big.mark = ","), s2[class3 == "campaign", ratio]),
    sprintf("%s -> %s (x%.2f)", format(round(h2$burst_entities_per_day_pre), big.mark = ","), format(round(h2$burst_entities_per_day_post), big.mark = ","), h2$burst_entities_per_day_post / h2$burst_entities_per_day_pre),
    sprintf("%s -> %s (x%.2f)", format(round(s2[class3 == "genuine", pre]), big.mark = ","), format(round(s2[class3 == "genuine", post]), big.mark = ","), s2[class3 == "genuine", ratio]),
    sprintf("x%.2f", s2[class3 == "all", ratio]), sprintf("%.2f", s2$wedge[1]), sprintf("%.0f%%", 100 * s2[class3 == "campaign", post] / s2[class3 == "all", post]),
    sprintf("%.0f%% / %.0f%%", 100 * cm$v2, 100 * cm$v3), sprintf("%.1f%%", 100 * SCE[period == "post" & class3 == "campaign", clu500]),
    sprintf("%.2f / %.2f", p2[class3 == "campaign", months_active_of3], p2[class3 == "genuine", months_active_of3]),
    sprintf("%d of %s (%.1f%%)", mo$v2, format(mo$v1, big.mark = ","), 100 * mo$v3),
    sprintf("%.3f%%", 100 * SCE[period == "post" & class3 == "campaign", march_operator]),
    fa[event == "2. May", sprintf("%.0f%% / %.0f%% / %.0f%% / %.0f%%", 100 * sum(share[type %like% "transfer"]), 100 * sum(share[type == "DEX swap"]), 100 * sum(share[type == "mint or claim"]), 100 * sum(share[type == "other contract call"]))],
    paste(RK[event %in% EVENTS_MAY$event & class3 == "genuine", sprintf("%.2f (%.2f)", jump, se)], collapse = " / "),
    RW[variant == "main" & class3 == "campaign", sprintf("x%.2f [%.2f, %.2f]", relative, rel_lo, rel_hi)], RW[variant == "main" & class3 == "genuine", sprintf("x%.2f [%.2f, %.2f]", relative, rel_lo, rel_hi)]))
TT$t5 <- "Table 5. The second cut: Base, March vs May 2024"
TN$t5 <- sprintf("Before / after: March 03-08..12 vs 03-14..21; May 05-21..27 vs 05-29..06-04 (05-28, the day of the first gas-limit step, left out). New entrants: no earlier activity since chain launch (March) or since 2024-02-15 (May); on the common definition (no tx since 2024-02-15) all new senders grew x%.1f in March and x%.1f in May. A March burst operator is a non-service funder or sweep target of >= 20 March burst accounts. First action by 4-byte method selector (native or zero-value transfers and token transfers or approvals counted as transfers). Non-burst jump: May step 1 / step 2. Relative to Arbitrum: Base post / pre entry ratio divided by Arbitrum's (no fee change in May; same rules), day-bootstrap CI; in March Arbitrum cut its own fees 15 hours after Base, so it is no comparison chain. Window variants (second_cut_vs_arbitrum.csv; post window ending before Base's Onchain Summer opened on 06-03 or before its buildathon on 05-31, pre window starting after the spot ETH ETF approval on 05-23): burst accounts relative to Arbitrum x%.2f to x%.2f; non-burst entrants x%.2f to x%.2f over post windows of five days or more, but x%.2f [%.2f, %.2f] over the first two days (05-29..30) alone, the one-day bump of the hourly RD.",
                 s1[class3 %like% "since 02-15", ratio], s2[class3 %like% "since 02-15", ratio], RW[class3 == "campaign", min(relative)], RW[class3 == "campaign", max(relative)],
                 RW[class3 == "genuine" & variant != "post to 05-30", min(relative)], RW[class3 == "genuine" & variant != "post to 05-30", max(relative)],
                 RW[class3 == "genuine" & variant == "post to 05-30", relative], RW[class3 == "genuine" & variant == "post to 05-30", rel_lo], RW[class3 == "genuine" & variant == "post to 05-30", rel_hi])

# ---- Table 6. What the cuts mean for platforms and for identity operators ----
EC6 <- merge(ECO, TH[, .(short, stake_individual, stake_operator_acct_weighted, cost_identity_pre, cost_identity_post, q_nonburst, m_burst, ids_per_entity_day_acct_weighted, p_post)], by = "short")[order(match(short, TH$short))]
TB$t6 <- EC6[, .(Cut = short, `Set by` = set_by, `Fee revenue, before -> after (US$ k/day)` = sprintf("%.0f -> %.0f", fees_pre / 1e3, fees_post / 1e3),
                 `L1 data cost (US$ k/day)` = sprintf("%.1f -> %.1f", rent_pre / 1e3, rent_post / 1e3), `Profit (US$ k/day)` = sprintf("%.0f -> %.0f", profit_pre / 1e3, profit_post / 1e3),
                 `Profit change (log)` = sprintf("%+.2f", dlog_profit), `Stake: individual entrant (US$)` = sprintf("%.2f", stake_individual),
                 `Stake: operator of the average burst account (US$)` = format(round(stake_operator_acct_weighted), big.mark = ",", trim = TRUE),
                 `Cost of an identity, before -> after (US$)` = sprintf("%.3f -> %.4f", cost_identity_pre, cost_identity_post))]
fl <- EC6[short == "Base May"]; floor_fee <- 0.03
TT$t6 <- "Table 6. Dollar stakes, the cost of an identity, and platform profit at each cut"
TN$t6 <- sprintf("Fees, L1 data cost and profit: growthepie, mean US$ per day over the Table 1 windows. Stakes: first-week savings (fee change x txs) for an individual non-burst entrant (median first-week txs) and for the operator of the average burst account (entity size weighted by accounts x median txs per account). Cost of an identity = median txs per burst account x median fee. Fee-floor illustration at Base's post-May fee (US$%.4f): a floor of US$%.2f would cost an individual entrant US$%.3f more in the first week, and an operator of %s accounts US$%s more per batch.",
                 fl$p_post, floor_fee, (floor_fee - fl$p_post) * fl$q_nonburst, format(round(fl$ids_per_entity_day_acct_weighted), big.mark = ","), format(round((floor_fee - fl$p_post) * fl$m_burst * fl$ids_per_entity_day_acct_weighted), big.mark = ","))

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
em <- EL[price == "median"]; ws <- WSE[event %in% c("Base (Ecotone)", "Arbitrum step 1")]   # numbers quoted in the index
MAIN <- data.table(exhibit = c("Table 1", "Figure 1a", "Figure 1b", "Table 2", "Table 3", "Figure 2", "Table 4", "Table 5", "Table 6"),
  question = c("Which cuts, when, set by whom, how large?", "Did fees and usage break at the March cut hours?", "Did fees and usage break at the May steps?", "How much does usage respond?",
               "Through which margin?", "Who enters, hour by hour?", "Who are the new accounts?", "Does a second cut repeat the first?", "Why, and what does it mean for platforms?"),
  answer = c("Four cuts (Base's May cut in two steps): two passed through from Ethereum's Dencun upgrade, two chosen by the platform", "Fees break at the cut hour; usage rises at Base and Arbitrum step 1",
             "The median fee breaks at both steps; usage rises less than in March",
             sprintf("Inelastic: %.2f to %.2f at the March pass-through cuts, %.2f for both May steps together, %.2f at Arbitrum's floor cut",
                     em[event == "Base (Ecotone)", elasticity_txs], em[event == "Arbitrum step 1", elasticity_txs], em[event %like% "both steps", elasticity_txs], em[event == "Arbitrum step 2", elasticity_txs]),
             sprintf("Aggregate %.2f to %.2f against %.3f to %.3f within existing senders: usage grows through entry", max(em[1:2, elasticity_txs]), min(em[1:2, elasticity_txs]), max(ws$elasticity), min(ws$elasticity)),
             "In March burst accounts build up over two days after the cut; in May their rise is far smaller",
             "Multi-identity operators: batch-created, synchronized, concentrated in few operators, short-lived, Base-specific; external Sybil lists miss them",
             "No, for either group relative to Arbitrum, which cut no fees: individuals move for a day; burst accounts, now swapping through DEX routers and claiming drops, rise on both chains; almost no March operators return",
             sprintf("An individual's stake falls from about a dollar to cents; after March an identity costs cents (US$%.3f right after, US$%.3f before the May cut), so operators follow campaigns, not cuts; pass-through cuts raised platform profit, platform-chosen cuts lowered it",
                     TH[short == "Base Mar", cost_identity_post], TH[short == "Base May", cost_identity_pre])),
  file = c("table1.csv", "../figures/fee_cuts_hourly_march.png", "../figures/fee_cuts_hourly_may.png", "table2.csv", "table3.csv", "../figures/entrants_by_class_two_cuts.png",
           "table4.csv", "table5.csv", "table6.csv"),
  script = c("06 H", "04 A", "04 D", "04 A, D", "04 A, D; 06 E; 07 B, E", "06 G", "06 C, F, G", "06 G, H", "06 H"))
APX <- data.table(exhibit = c("A1", "A2", "A3", "A4", "A5", "A6", "A7", "A8", "A9", "A10", "A11", "A12", "A13"),
  content = c("Hourly summary statistics before and after each cut (median fee per tx)", "All RD outcomes, L1 and Bitcoin placebos, market controls; specification grid; other checks; placebo at the L1 fork hour",
              "Base vs not-yet-treated Arbitrum: DiD and daily event study", "RD by transaction type", "Within-sender response by pre-cut fee level",
              "Multi-rollup replication: per-event DiD, stacked 2SLS, Callaway-Sant'Anna, level test, second drops by rollup",
              "Entry and retention at the cut hour (local randomization), Base vs Arbitrum at the hour, daily cohorts, hourly entry by class at all five cuts",
              "Burst rule, bounds and corrected funder rule; bursts by day; decomposition of Base's added txs; burst vs non-burst entry, daily and hourly",
              "Validation: LayerZero list and funding clusters (all rules, thresholds, sensitivity), entity growth, burst target types, operators, tokens received",
              "Second cut: RD with median, mean and base fee, daily DiD and event study vs rollups, May entrants by class, Arbitrum comparison and window variants, first actions, largest May burst groups", "Stakes and friction bounds; value-of-identity bands; platform economics on 7-day windows (V6)",
              "Entrants per hour by class over the full windows: Base and Arbitrum (March), Base (May)", "Google Trends: monthly sums and peaks"))
APF <- rbind(
  data.table(exhibit = "A1", file = "summary_hourly.csv"), data.table(exhibit = "A2", file = c("events.csv", "robust_grid.csv", "robust_checks.csv", "placebo_l1_fork.csv")),
  data.table(exhibit = "A3", file = c("did_base_vs_arbitrum.csv", "event_study_base_vs_arbitrum.csv", "event_study_base_vs_arbitrum.png")), data.table(exhibit = "A4", file = "type_rd.csv"),
  data.table(exhibit = "A5", file = c("response_by_fee_level.csv", "within_sender_elasticity.csv", "elasticity_by_fee_level.png")),
  data.table(exhibit = "A6", file = c("multichain_events.csv", "multichain_pooled.csv", "multichain_callaway_santanna.csv", "multichain_second_drops.csv", "multichain_elasticities.png")),
  data.table(exhibit = "A7", file = c("entry_retention_local_randomization.csv", "entry_retention_did_base_vs_arbitrum.csv", "daily_cohorts.csv", "entry_rd_by_class.csv")),
  data.table(exhibit = "A8", file = c("campaign_rule_bounds.csv", "val_bound_corrected.csv", "campaigns_by_day_base.csv", "tx_decomposition_base.csv", "campaign_vs_genuine_daily.csv", "campaign_vs_genuine_hourly_ri.csv")),
  data.table(exhibit = "A9", file = c("val_lz_clusters.csv", "val_entity_growth.csv", "val_campaign_targets_base.csv", "burst_operators_base.csv", "burst_tokens_received_base.csv")),
  data.table(exhibit = "A10", file = c("may_events.csv", "elasticities.csv", "may_daily_did.csv", "may_daily_event_study.csv", "second_cut_entrants_base.csv", "second_cut_vs_arbitrum.csv",
                                     "first_actions_base.csv", "burst_targets_may_base.csv", "may_event_study.png")),
  data.table(exhibit = "A11", file = c("threshold_stakes.csv", "identity_value_bands.csv", "val_economics.csv")),
  data.table(exhibit = "A12", file = c("entrants_by_class_hourly_march.png", "entrants_by_class_hourly_may.png")), data.table(exhibit = "A13", file = "val_google_trends.csv"))
APF[, file := paste0(fifelse(file %like% "\\.png$", "../figures/", "../tables/"), file)]
# the results/tables files each main table is built from
SRC <- rbind(data.table(exhibit = "Table 1", file = "table1_fee_cuts.csv"), data.table(exhibit = "Table 2", file = c("rd_all_events.csv", "may_events.csv")),
  data.table(exhibit = "Table 3", file = c("elasticities.csv", "may_daily_did.csv", "multichain_pooled.csv", "within_sender_elasticity.csv")),
  data.table(exhibit = "Table 4", file = c("second_cut_entry_base.csv", "campaign_rule_bounds.csv", "val_bound_corrected.csv", "val_lz_clusters.csv", "burst_operators_base.csv",
                                           "val_campaign_targets_base.csv", "persistence_common_horizon_base.csv", "val_entity_growth.csv")),
  data.table(exhibit = "Table 5", file = c("table1_fee_cuts.csv", "second_cut_entry_base.csv", "second_cut_entrants_base.csv", "threshold_stakes.csv", "persistence_common_horizon_base.csv",
                                           "burst_operators_base.csv", "val_lz_clusters.csv", "first_actions_base.csv", "entry_rd_by_class.csv", "second_cut_vs_arbitrum.csv")),
  data.table(exhibit = "Table 6", file = c("platform_economics.csv", "threshold_stakes.csv")))[, file := paste0("../tables/", file)]
stopifnot(all(file.exists(file.path(DIR_P, c(MAIN$file, APF$file, SRC$file)))))   # every linked file exists
MAIN <- merge(MAIN[, ord := .I], SRC[, .(sources = paste(sprintf("[%s](%s)", basename(file), file), collapse = ", ")), by = exhibit], by = "exhibit", all.x = TRUE)[order(ord)][is.na(sources), sources := ""]
APX <- merge(APX, APF[, .(files = paste(sprintf("[%s](%s)", basename(file), file), collapse = ", ")), by = exhibit], by = "exhibit")[order(as.integer(sub("A", "", exhibit)))]
IDX <- c("# Paper exhibits", "", "Generated by `code/08_paper_exhibits.R`. The six main tables are in [`tables.md`](tables.md) (and one CSV each); figures and appendix exhibits are the files written by `04`-`07`.", "",
         "## Main text", "", "| Exhibit | Question | Answer | File | Built from | Script, section |", "|---|---|---|---|---|---|",
         MAIN[, sprintf("| %s | %s | %s | [%s](%s) | %s | %s |", exhibit, question, answer, basename(file), file, sources, script)],
         "", "## Appendix", "", "| No. | Content | Files |", "|---|---|---|", APX[, sprintf("| %s | %s | %s |", exhibit, content, files)])
writeLines(IDX, file.path(DIR_P, "README.md"))
cat(sprintf("\nWrote %d main tables, tables.md and README.md (%d main exhibits, %d appendix files indexed) to results/paper\n", length(TB), nrow(MAIN), nrow(APF)))
cat("\n## sessionInfo\n```\n"); print(sessionInfo()); cat("```\n"); sink()
