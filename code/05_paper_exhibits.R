# 05_paper_exhibits.R: the paper's exhibits, assembled from the outputs of 04_analysis.R (results/tables, results/figures) into results/paper/.
#   Writes tables.md (Tables 1-3 and A.7 laid out as in the paper, with one CSV each) and README.md (an index of every table and figure of the paper, main
#   text and appendix, with the files it is built from, and the numbers the text derives from those files). Estimates nothing new and copies no files.
#   Run after 04. Defines no functions.
source(here::here("code", "00_setup.R"))
sink(file.path(DIR_LOG, "05_paper_exhibits.md"), split = TRUE)
cat("# 05 paper exhibits\nRun ", format(Sys.time(), usetz = TRUE), "\n", sep = "")
ct <- yaml::read_yaml(CONTRACT_FILE)   # panel.rds must have passed 03_validate_panels.R and be unchanged since
stopifnot(isTRUE(ct$all_valid), unname(tools::md5sum(PANEL_FILE)) == ct$md5)
DIR_P <- here("results", "paper")
unlink(DIR_P, recursive = TRUE); dir.create(DIR_P)   # rebuilt from scratch on every run
TB <- list(); TT <- list(); TN <- list()   # laid-out tables (character columns), titles, notes
f2 <- "%.2f"   # two-decimal format used below

# ---- inputs ----
HO <- fread(file.path(DIR_TAB, "headline_one_sample.csv")); IP <- fread(file.path(DIR_TAB, "inference_primary.csv")); ITP <- fread(file.path(DIR_TAB, "inference_top_placebos.csv"))
LRW <- fread(file.path(DIR_TAB, "entry_ratio_placebo_windows.csv")); EI <- fread(file.path(DIR_TAB, "entity_effect_implied.csv")); EC <- fread(file.path(DIR_TAB, "entrant_classes_6v6.csv"))
EPC <- fread(file.path(DIR_TAB, "entrant_persistence_cut.csv")); IC <- fread(file.path(DIR_TAB, "inference_counterfactuals.csv")); IRS <- fread(file.path(DIR_TAB, "inference_reference_set.csv"))
ENB <- fread(file.path(DIR_TAB, "entrant_entities_nonburst.csv")); ETR <- fread(file.path(DIR_TAB, "entry_top_recipients.csv")); TE <- fread(file.path(DIR_TAB, "timing_eth.csv"))

# ---- Table 1. Counted new addresses and entry outside batch waves on Base ----
t1 <- rbind(HO[sample %like% "^long" & window %in% c("6 v 6 days", "7 v 7 days")][, lab := sprintf("Long series, %s%s", sub(" days", "", window), fifelse(window == "6 v 6 days", " days (primary)", " days"))],
            HO[sample %like% "^window" & rule == "main burst rule"][, lab := "Window entrants, 6 v 6 days"])
TB$t1 <- t1[, .(`Sample and window` = lab, `Per day, before -> after` = sprintf("%s -> %s", format(round(all_before), big.mark = ",", trim = TRUE), format(round(all_after), big.mark = ",", trim = TRUE)),
                `Ratio, all` = sprintf(f2, all_ratio), `Ratio, outside waves or bursts` = sprintf(f2, outside_ratio), `Share of increase in waves or bursts` = sprintf("%.0f%%", 100 * batch_share_of_added))]
TT$t1 <- "Table 1. Counted New Addresses and Entry Outside Batch Waves on Base, Before and After the Cut"
TN$t1 <- "Base alone; ratios of daily means. Source: headline_one_sample.csv (all rows, including longer windows and the alternative burst rules, are Appendix Table A.4)."

# ---- Table 2. Entry outside batch waves, Base relative to Ethereum L1 ----
I2 <- merge(IP[placebo == "pre-cut dates", .(window, estimate, ratio, K = placebo_K, r = round(rank_p * (1 + placebo_K)), base_alone)],
            IP[placebo == "all dates", .(window, Ka = placebo_K, ra = round(rank_p * (1 + placebo_K)))], by = "window")[order(match(window, c("6 v 6", "7 v 7", "5 v 5", "4 v 4", "6 v 5")))]
TB$t2 <- rbind(
  I2[, .(Window = fcase(window == "6 v 6", "6 v 6 days (primary)", window == "6 v 5", "6 v 5 days (19 March out)", default = paste(window, "days")), `Estimate (log)` = sprintf("%.3f", estimate),
         Ratio = sprintf(f2, ratio), `Rank, pre-cut` = sprintf("%d of %d", r, K + 1L), `Rank, all dates` = sprintf("%d of %d", ra, Ka + 1L), `Ratio, Base alone` = sprintf(f2, exp(base_alone)))],
  LRW[series == "Base minus Ethereum L1" & placebo == "pre-cut dates only" & window_days %in% c(14L, 28L), .(Window = sprintf("%d v %d days (path only)", window_days, window_days),
         `Estimate (log)` = sprintf("%.3f", log(ratio)), Ratio = sprintf(f2, ratio), `Rank, pre-cut` = "", `Rank, all dates` = "", `Ratio, Base alone` = "")],
  EI[cut == "Base March", .(Window = sprintf("Panel B. Funding entities, %d v %d days", window_days, window_days), `Estimate (log)` = "", Ratio = sprintf(f2, implied_entity_effect),
         `Rank, pre-cut` = sprintf("95%% interval, delta only: %.2f-%.2f", implied_lo, implied_hi), `Rank, all dates` = "", `Ratio, Base alone` = "")])
TT$t2 <- "Table 2. Entry Outside Batch Waves, Base Relative to Ethereum L1"
TN$t2 <- "Panel A: inference_primary.csv (ranks = rank_p x (K + 1)) and entry_ratio_placebo_windows.csv (14 and 28 days, a path only). Panel B: entity_effect_implied.csv, an assumption-dependent composition adjustment, not a separately estimated effect."

# ---- Table 3. Characteristics of window entrants on Base ----
EC[, cls := c(campaign = "Burst", genuine = "Non-burst", bot = "Heavy")[class3]]
T3 <- EC[, .(cls, `Entrants per day, before -> after` = sprintf("%s -> %s", format(round(entrants_before), big.mark = ",", trim = TRUE), format(round(entrants_after), big.mark = ",", trim = TRUE)),
             `  Ratio` = fifelse(entrant_ratio >= 10, sprintf("%.1f", entrant_ratio), sprintf(f2, entrant_ratio)),
             `Funding entities per day, before -> after` = sprintf("%s -> %s", format(round(entities_before), big.mark = ",", trim = TRUE), format(round(entities_after), big.mark = ",", trim = TRUE)),
             `  Ratio ` = fifelse(entity_ratio >= 10, sprintf("%.1f", entity_ratio), sprintf(f2, entity_ratio)),
             `Share of the added entrants` = fifelse(share_of_added < 0.01, sprintf("%.1f%%", 100 * share_of_added), sprintf("%.0f%%", 100 * share_of_added)),
             `After the cut: in a funding cluster of 20 or more` = sprintf("%.0f%%", 100 * in_cluster_20), `First transaction in a same-block group of 10 or more` = sprintf("%.0f%%", 100 * same_block_group),
             `Held by the 10 / 100 largest funding entities` = sprintf("%.0f%% / %.0f%%", 100 * top10_share, 100 * top100_share),
             `First transaction to the class's most common recipient` = sprintf("%.0f%%", 100 * top_recipient_share), `Later months active (of 3)` = sprintf(f2, months_active_of3),
             `On the LayerZero provisional Sybil list` = sprintf("%.1f%%", 100 * layerzero_list))]
T3 <- melt(T3, id.vars = "cls", variable.name = "Characteristic", value.name = "v", variable.factor = FALSE)
TB$t3 <- dcast(T3, Characteristic ~ cls, value.var = "v")[order(match(Characteristic, unique(T3$Characteristic)))][, .(Characteristic, Burst, `Non-burst`, Heavy)]
TT$t3 <- "Table 3. Characteristics of Window Entrants on Base, Six Days Before and After the Cut"
TN$t3 <- sprintf("entrant_classes_6v6.csv. Non-burst entrants active in any later month (entrant_persistence_cut.csv): %.1f%% before, %.1f%% after (ratio %.2f, 95%% interval %.2f to %.2f; Arbitrum %.2f, %.2f to %.2f).",
                 100 * EPC[chain == "base", active_before], 100 * EPC[chain == "base", active_after], EPC[chain == "base", ratio], EPC[chain == "base", lo], EPC[chain == "base", hi],
                 EPC[chain == "arbitrum", ratio], EPC[chain == "arbitrum", lo], EPC[chain == "arbitrum", hi])

# ---- Table A.7. The primary statistic under alternative counterfactuals and outcome definitions ----
# The paper shows a representative subset of panel A (rows marked shown); its note summarizes the other rows.
SHOWN <- c("mean over the 6 days 2024-03-08..2024-03-13", "mean over the 30 days 2024-02-13..2024-03-13", "mean over the 6 days 2024-03-01..2024-03-06", "mean over the 24 days 2024-02-12..2024-03-06",
           "linear trend over the 12 days 2024-03-02..2024-03-13", "linear trend over the 28 days 2024-02-15..2024-03-13", "linear trend over the 73 days 2024-01-01..2024-03-13")
TB$ta7 <- IC[, .(Panel = panel, `Counterfactual or outcome` = variant, `Estimate (log)` = sprintf("%.3f", estimate), Ratio = sprintf(f2, ratio),
                 `Rank among placebo dates` = fifelse(is.na(rank), "--", sprintf("%d of %d", rank, placebo_K + 1L)), `In the paper` = fifelse(panel %like% "^B" | variant %in% SHOWN, "shown", "note"))]
TB$ta7 <- TB$ta7[!(`Counterfactual or outcome` %like% "established-action placebo origins")]   # the primary statistic on those origins is reported in the note
pa <- IC[panel %like% "^A" & !(variant %in% SHOWN)]
TT$ta7 <- "Table A.7. The Primary Statistic Under Alternative Counterfactuals and Outcome Definitions"
TN$ta7 <- sprintf("inference_counterfactuals.csv. Rows marked note: estimates %.2f-%.2f, ranks %s. On the %d placebo origins of the established-first-action outcomes, the primary statistic ranks %d of %d.",
                  min(pa$estimate), max(pa$estimate), paste(unique(sprintf("%d of %d", pa$rank, pa$placebo_K + 1L)), collapse = ", "),
                  IC[variant %like% "established-action placebo origins", placebo_K], IC[variant %like% "established-action placebo origins", rank], IC[variant %like% "established-action placebo origins", placebo_K] + 1L)

# ---- write the laid-out tables: one CSV each and tables.md ----
md <- c("# Tables", "", "Generated by `code/05_paper_exhibits.R` from `results/tables`. Do not edit by hand.", "")
for (k in names(TB)) {
  fwrite(TB[[k]], file.path(DIR_P, sprintf("table%s.csv", sub("^t", "", k))))
  md <- c(md, paste0("## ", TT[[k]]), "", paste0("| ", paste(trimws(names(TB[[k]])), collapse = " | "), " |"), paste0("|", paste(rep("---", ncol(TB[[k]])), collapse = "|"), "|"),
          paste0("| ", do.call(paste, c(lapply(TB[[k]], as.character), sep = " | ")), " |"), "", paste0("*Notes.* ", TN[[k]]), "")
  cat("\n## ", TT[[k]], "\n", sep = ""); print(TB[[k]])
}
writeLines(md, file.path(DIR_P, "tables.md"))

# ---- index (results/paper/README.md): every exhibit of the paper and the files it is built from (links relative to results/paper) ----
EX <- rbind(
  data.table(exhibit = "Table 1", title = sub("^Table 1\\. ", "", TT$t1), file = c("tables.md", "../tables/headline_one_sample.csv")),
  data.table(exhibit = "Table 2", title = sub("^Table 2\\. ", "", TT$t2), file = c("tables.md", "../tables/inference_primary.csv", "../tables/entry_ratio_placebo_windows.csv", "../tables/entity_effect_implied.csv")),
  data.table(exhibit = "Table 3", title = sub("^Table 3\\. ", "", TT$t3), file = c("tables.md", "../tables/entrant_classes_6v6.csv", "../tables/entrant_persistence_cut.csv")),
  data.table(exhibit = "Figure 1", title = "Daily Median Fee per Transaction, 15 February to 15 April 2024", file = "../figures/fee_daily_march.png"),
  data.table(exhibit = "Figure 2", title = "New Addresses in and Outside Batch Waves, January to June 2024", file = "../figures/waves_2024_with_l1.png"),
  data.table(exhibit = "Figure 3", title = "Daily Entry Outside Waves, Base Relative to Ethereum L1", file = c("../figures/entry_event_study_base_l1.png", "../tables/entry_event_study_base_l1.csv")),
  data.table(exhibit = "Figure 4", title = "The Cut Day Hour by Hour: Non-Burst Entrants and the Median Fee", file = c("../figures/cut_day_hours.png", "../tables/cut_day_hours.csv")),
  data.table(exhibit = "Table A.1", title = "Definitions and Parameters", file = "../../code/00_setup.R"),
  data.table(exhibit = "Table A.2", title = "Median Fee per Transaction Around the Base Fee Cut", file = "../tables/fee_path_march.csv"),
  data.table(exhibit = "Table A.3", title = "Dated Events, March-June 2024", file = "../../data/external/event_calendar.csv"),
  data.table(exhibit = "Table A.4", title = "Counted New Addresses and Entry Outside Waves or Bursts, by Window and Burst Rule", file = "../tables/headline_one_sample.csv"),
  data.table(exhibit = "Table A.5", title = "Inference for Entry Outside Waves, by Window", file = c("../tables/inference_primary.csv", "../tables/inference_reference_set.csv")),
  data.table(exhibit = "Table A.6", title = "The Cut and the Largest Placebo Statistics", file = "../tables/inference_top_placebos.csv"),
  data.table(exhibit = "Table A.7", title = sub("^Table A\\.7\\. ", "", TT$ta7), file = c("tables.md", "../tables/inference_counterfactuals.csv")),
  data.table(exhibit = "Table A.8", title = "The Primary Statistic, the Breakdown, and the Entity Adjustment Across Size Floors", file = "../tables/inference_wave_size_floors.csv"),
  data.table(exhibit = "Table A.9", title = "Non-Burst Entrants on Base by Category of First Recipient", file = c("../tables/entry_by_recipient_category.csv", "../tables/entry_by_first_action.csv", "../tables/entry_top_recipients.csv")),
  data.table(exhibit = "Table A.10", title = "Non-Burst Entrants on Base by Source of Their First ETH", file = c("../tables/entrant_funding_source.csv", "../tables/entrant_classes_6v6.csv")),
  data.table(exhibit = "Table A.11", title = "Six-Day Shift in Log Active Addresses: Base, Ethereum L1, and a Donor Pool", file = "../tables/donor_pool_daa.csv"),
  data.table(exhibit = "Table A.12", title = "Four Fee Cuts: Fees, Dollar Savings, and Entry Outside Waves", file = "../tables/four_cuts_summary.csv"),
  data.table(exhibit = "Figure A.1", title = "Batch Waves per Day Around Base's May 2024 Fee Cut", file = c("../figures/may_waves_event_study.png", "../tables/may_waves_event_study.csv")),
  data.table(exhibit = "Figure A.2", title = "Log Active Addresses Around the Ecotone Cut: OP Mainnet, Base, and Ethereum L1", file = c("../figures/op_mainnet_event_study.png", "../tables/op_mainnet_event_study.csv")))
# the files behind the numbers in the text that are not in a table or figure
TX <- data.table(where = c("Sections 3.2, 6.6", "Section 3.2", "Section 6.1", "Section 6.2, Appendix A.2", "Appendix A.2", "Appendix A.2", "Appendix A.2", "Section 6.5, Appendix A.4",
                           "Section 6.5, Appendix A.4", "Section 6.6, Appendix A.4", "Section 6.6, Appendix A.5", "Appendix A.5"),
  content = c("Base's L1 data cost and fee revenue around the cut; who set each fee cut", "Arbitrum's hourly fee breaks", "Base's transactions and active addresses against L1",
              "The largest wave day and burst group", "Waves and the cut (wave volume against placebo dates)", "Leaving out the largest wave day", "Funding entities and clusters behind non-burst entry",
              "The cut day by hour against the preceding days and Arbitrum", "Prior trends, the price of ETH, and delay", "OP Mainnet against L1 and Base", "Base's May cut against Arbitrum", "Funding entities behind May entry"),
  file = c("../tables/platform_economics.csv, ../tables/table1_fee_cuts.csv", "../tables/table1_fee_cuts.csv", "../tables/op_mainnet_vs_l1.csv",
           "../tables/campaigns_by_day_base.csv, ../tables/campaign_dossier.csv", "../tables/base_cuts_test.csv", "../tables/composition_leave_one_out.csv",
           "../tables/entity_accounting.csv, ../tables/entrant_entities_nonburst.csv", "../tables/cut_day_hours.csv, ../tables/cut_day_hours_placebo_days.csv",
           "../tables/inference_top_placebos.csv, ../tables/timing_eth.csv, ../tables/entry_delay_test.csv", "../tables/op_mainnet_vs_l1.csv, ../tables/base_minus_op_adjusted.csv",
           "../tables/base_cuts_test.csv", "../tables/entity_accounting.csv"))
# numbers the text derives from those files
p6 <- IP[window == "6 v 6" & placebo == "pre-cut dates"]; h6 <- HO[sample %like% "^long" & window == "6 v 6 days"]; cl <- ENB[chain == "base"]
DV <- data.table(where = c("Section 6.3, Appendix A.3", "Section 6.2", "Appendix A.4", "Appendix A.2", "Appendix A.4"),
  number = c(sprintf("%.2f", p6$estimate / p6$placebo_max), sprintf("%.1f", h6$all_ratio / h6$outside_ratio), sprintf("%+.2f", TE[day <= TE[which.max(eth_usd), day], mean(gap)]),
             sprintf("%.0f%%", 100 * cl[, (after[measure == "addresses, cluster of 20+"] - before[measure == "addresses, cluster of 20+"]) / (after[measure == "addresses, all"] - before[measure == "addresses, all"])]),
             sprintf("%.0f%%", 100 * ETR[, sum(after)] / EC[class3 == "genuine", entrants_after])),
  meaning = c("the estimate over the largest of the 61 pre-cut placebo statistics (inference_primary.csv: estimate / placebo_max)",
              "growth of counted new addresses over growth of entry outside waves, 6 v 6 days (headline_one_sample.csv: all_ratio / outside_ratio)",
              "mean Base-minus-L1 gap, relative to the week before the cut, while ETH rose to its peak (timing_eth.csv)",
              "share of the rise in non-burst entry in funding clusters of 20 or more (entrant_entities_nonburst.csv)",
              "share of post-cut non-burst entrants whose first recipient is one of the 50 named recipients (entry_top_recipients.csv over entrant_classes_6v6.csv)"))
stopifnot(all(file.exists(file.path(DIR_P, EX$file))), all(file.exists(file.path(DIR_P, unlist(strsplit(TX$file, ", "))))))   # every linked file exists
used <- unique(basename(c(EX$file[EX$file %like% "^\\.\\./(tables|figures)/"], unlist(strsplit(TX$file, ", ")))))
stopifnot(setequal(used, c(list.files(DIR_TAB), list.files(DIR_FIG))))   # every file 04 writes is used by the paper, and every file used exists
IDX <- c("# Paper exhibits", "", "Generated by `code/05_paper_exhibits.R`. Tables 1-3 and A.7 are laid out in [`tables.md`](tables.md) (one CSV each); every other exhibit is the file written by `04_analysis.R`.", "",
         "| Exhibit | Title | Files |", "|---|---|---|",
         EX[, .(files = paste(sprintf("[%s](%s)", basename(file), file), collapse = ", ")), by = .(exhibit, title)][, sprintf("| %s | %s | %s |", exhibit, title, files)],
         "", "## Numbers in the text", "", "| Where | Content | Files |", "|---|---|---|",
         TX[, sprintf("| %s | %s | %s |", where, content, paste(sprintf("[%s](%s)", basename(strsplit(file, ", ")[[1]]), strsplit(file, ", ")[[1]]), collapse = ", ")), by = seq_len(nrow(TX))]$V1,
         "", "## Numbers the text derives", "", "| Where | Number | How |", "|---|---|---|", DV[, sprintf("| %s | %s | %s |", where, number, meaning)])
writeLines(IDX, file.path(DIR_P, "README.md"))
cat(sprintf("\nWrote %d laid-out tables, tables.md and README.md (%d exhibits, %d result files) to results/paper\n", length(TB), uniqueN(EX$exhibit), length(used)))
print(DV)
cat("\n## sessionInfo\n```\n"); print(sessionInfo()); cat("```\n"); sink()
