# 03_validate_panels.R: checks every table in panel.rds and writes data/panel/contract.yaml, which 04-08 require.
# Cross-checks: daily L2 counts against growthepie, and the fee break at each documented event hour.
source(here::here("code", "00_setup.R"))
sink(file.path(DIR_LOG, "03_validate_panels.md"), split = TRUE)
cat("# 03 validate panels\nRun ", format(Sys.time(), usetz = TRUE), "\n", sep = "")
P <- readRDS(PANEL_FILE)
hours <- seq(as.POSIXct(PULL_START, tz = "UTC"), as.POSIXct(PULL_END, tz = "UTC") + 23 * 3600, by = 3600)
acts <- paste0("act_", gsub("-", "_", RETENTION_MONTHS))

# object, unique keys, other required columns, non-negative columns
S <- rbind(
  data.table(obj = "l2_hourly", keys = "chain hr hf failed", cols = "n fee n_senders", nonneg = "n fee n_senders"),
  data.table(obj = "l2_hourly_type", keys = "chain hr typ failed", cols = "n fee", nonneg = "n fee"),
  data.table(obj = "l2_newsenders", keys = "chain hr", cols = "new_senders", nonneg = "new_senders"),
  data.table(obj = "control_hourly", keys = "hr", cols = "n_eth n_btc", nonneg = "n_eth n_btc"),
  data.table(obj = "eth_usd_daily", keys = "day", cols = "close", nonneg = "close"),
  data.table(obj = "entrants", keys = "", cols = paste("chain day hr months_active any_later n_week1 single_tx_wk1 bot_wk1 wave batch wave_size wave_funded class3 first_to first_sel funder_any",
                                                       "f_eth_via funder2_seen lz funder_lz wave_funded2 sync cid200 cid500 cid2000 csize200 csize500 csize2000 csizeF500 in_largest500",
                                                       "other_chain_addr other_chain_funder tok_after eth_after",
                                                       paste(acts, collapse = " ")),
             nonneg = "months_active n_week1 csize200 csize500 csize2000 csizeF500"),
  data.table(obj = "sender_window", keys = "chain window id", cols = "n fee", nonneg = "n fee"),
  data.table(obj = "base_tx_by_class", keys = "cls day", cols = "txs", nonneg = "txs"),
  data.table(obj = "base_hourly_campaign", keys = "hr", cols = "n_campaign", nonneg = "n_campaign"),
  data.table(obj = "multichain_daily", keys = "chain date", cols = "txcount daa cost", nonneg = "txcount daa cost"),
  data.table(obj = "multichain_drops", keys = "chain date", cols = "drop local_max pre_level post_level", nonneg = ""),
  data.table(obj = "lz_meta", keys = "copy", cols = "lines evm share_of_archive share_in_archive", nonneg = "lines evm"),
  data.table(obj = "campaign_targets", keys = "addr", cols = "n_logs n_721 n_20 contract", nonneg = "n_logs n_721 n_20"),
  data.table(obj = "l2_economics_daily", keys = "chain date", cols = "fees_usd rent_usd profit_usd", nonneg = "fees_usd rent_usd"),
  data.table(obj = "gtrends_daily", keys = "request keyword date", cols = "value partial", nonneg = "value"),
  data.table(obj = "receipts_by_token", keys = "class3 tok", cols = "recipients senders top_sender", nonneg = "recipients senders"),
  data.table(obj = "fb_sent", keys = "tok", cols = "transfers recipients recipients_window_entrants", nonneg = "transfers recipients"),
  data.table(obj = "may_hourly", keys = "chain hr", cols = "n n_failed fee n_senders new_senders", nonneg = "n n_failed fee n_senders new_senders"),
  data.table(obj = "may_entrants", keys = "", cols = paste("chain day hr class3 wave n_week1 months4 csize500 cid500 march_operator f_eth_via first_to first_sel",
                                                           paste(paste0("act_", gsub("-", "_", RETENTION_MONTHS_MAY)), collapse = " ")), nonneg = "n_week1 months4 csize500"),
  data.table(obj = "may_ops", keys = "", cols = "march_burst_operators active_again_in_may", nonneg = "march_burst_operators active_again_in_may"),
  data.table(obj = "eth_usd_daily_may", keys = "day", cols = "close", nonneg = "close"),
  data.table(obj = "may_blocks", keys = "hr", cols = "gas_limit_min gas_limit_max base_fee_gwei gas_used blocks", nonneg = "gas_limit_min gas_limit_max base_fee_gwei gas_used blocks"),
  data.table(obj = "fee_quantiles_hourly", keys = "chain hr", cols = "n_paid p25 p50 p75", nonneg = "n_paid p25 p50 p75"))
fails <- list(); objects <- list()
ok <- setequal(names(P), S$obj)
cat(sprintf("  [%s] panel.rds holds the %d expected tables\n", if (ok) "ok" else "FAIL", nrow(S)))
if (!ok) fails$panel <- "unexpected set of tables"

for (i in seq_len(nrow(S))) {
  o <- S$obj[i]; X <- P[[o]]; keys <- strsplit(S$keys[i], " ")[[1]]
  ck <- list()   # check description -> TRUE/FALSE
  ck[["required columns present"]] <- all(c(keys, strsplit(S$cols[i], " ")[[1]]) %in% names(X))
  if (length(keys)) ck[[sprintf("unique on (%s), %d rows", S$keys[i], nrow(X))]] <- !anyDuplicated(X, by = keys)
  for (v in strsplit(S$nonneg[i], " ")[[1]]) ck[[paste(v, "non-negative")]] <- !any(X[[v]] < 0, na.rm = TRUE)
  if (grepl("^l2_hourly", o)) ck[[sprintf("every UTC hour %s..%s present for both chains", PULL_START, PULL_END)]] <- X[, all(hours %in% hr), by = chain][, all(V1)]
  if (o == "l2_hourly_type") ck[["five transaction types"]] <- all(X$typ %in% c("native", "erc20_transfer", "approve", "swap", "other_call"))
  if (o == "entrants") {
    ck[["entry day in 03-01..27 and consistent with entry hour"]] <- X[, all(day >= as.IDate("2024-03-01") & day <= as.IDate("2024-03-27") & as.IDate(hr, tz = "UTC") == day)]
    ck[["campaign flags are 0/1 and classes bot/campaign/genuine inside the entrant window"]] <-
      X[!is.na(wave), all(day >= ENTRANT_WINDOW[1] & day <= ENTRANT_WINDOW[2]) && all(c(wave, batch, wave_size, wave_funded) %in% 0:1) && all(class3 %in% c("bot", "campaign", "genuine"))]
    ck[["validation flags are 0/1, defined for every window entrant, and component sizes >= 1"]] <-
      X[!is.na(wave), all(c(lz, funder2_seen, wave_funded2, sync) %in% 0:1) && all(funder_lz %in% c(0:1, NA)) && !anyNA(c(cid200, cid500, cid2000)) && min(c(csize200, csize500, csize2000)) >= 1]
    ck[["component sizes shrink weakly as the service threshold falls (fewer links)"]] <- X[!is.na(wave), all(csize200 <= csize500 & csize500 <= csize2000)] }
  if (o == "lz_meta") {
    ck[["official provisional list: 803,093 lines"]] <- X[copy == "lz_archive/initialList.txt", lines] == 803093
    ck[["a second copy agrees with the archive within 0.1% (V1 acceptance rule)"]] <- X[copy != "lz_archive/initialList.txt", any(share_of_archive >= 0.999 & share_in_archive >= 0.999)] }
  if (o == "may_blocks") ck[["gas limit steps up to 75M in the 05-28 19:00 hour and to 90M in the 05-30 20:00 hour (EVENTS_MAY)"]] <-
    X[hr == EVENTS_MAY$t0[1], gas_limit_min == 6e7 & gas_limit_max == 7.5e7] && X[hr == EVENTS_MAY$t0[2], gas_limit_min == 7.5e7 & gas_limit_max == 9e7]
  if (o == "may_hourly") ck[[sprintf("every UTC hour %s..%s present for both chains", MAY_PULL[1], MAY_PULL[2])]] <-
    X[, all(seq(as.POSIXct(MAY_PULL[1], tz = "UTC"), as.POSIXct(MAY_PULL[2], tz = "UTC") + 23 * 3600, by = 3600) %in% hr), by = chain][, .N == 2 && all(V1)]
  if (o == "may_entrants") ck[["both chains; entry day in MAY_WINDOW, classes bot/campaign/genuine, Base link flags 0/1"]] <- setequal(unique(X$chain), CHAINS) &&
    X[, all(day >= MAY_WINDOW[1] & day <= MAY_WINDOW[2]) && all(class3 %in% c("bot", "campaign", "genuine"))] && X[chain == "base", all(march_operator %in% 0:1)]
  if (o == "fee_quantiles_hourly") {
    may_hours <- seq(as.POSIXct(MAY_PULL[1], tz = "UTC"), as.POSIXct(MAY_PULL[2], tz = "UTC") + 23 * 3600, by = 3600)
    ck[["every UTC hour of the March and May pulls present for both chains"]] <- X[, all(c(hours, may_hours) %in% hr), by = chain][, .N == 2 && all(V1)]
    ck[["0 < p25 <= p50 <= p75"]] <- X[, all(p25 > 0 & p25 <= p50 & p50 <= p75)]
    # growthepie's daily median fee per tx (US$) against the median over the day's hours of the hourly median x ETH/USD (same price concept, different source)
    r <- merge(merge(X[, .(p = median(p50)), by = .(chain, date = as.IDate(hr, tz = "UTC"))], rbind(P$eth_usd_daily[, .(day, close)], P$eth_usd_daily_may[, .(day, close)])[, .(date = day, usd = close)], by = "date"),
               P$multichain_daily[, .(chain, date, cost)], by = c("chain", "date"))[, p * usd / cost]
    ck[[sprintf("growthepie median fee within a factor of 2 on >= 90%% of chain-days: %.0f%% of %d (median ratio %.2f)", 100 * mean(r > 0.5 & r < 2), length(r), median(r))]] <- mean(r > 0.5 & r < 2) >= 0.9
    # break hour of the median: largest fall in mean log p50, 6 h after vs 6 h before, searched over +-12 h; March as for l2_hourly, May within 3 h and > 0.3
    EVA <- rbind(EVENTS[, .(event, chain, t0, tol = 1, fall = 0.5)], EVENTS_MAY[, .(event, chain, t0, tol = 3, fall = 0.3)])
    for (j in seq_len(nrow(EVA))) {
      h <- X[chain == EVA$chain[j], .(hr, lp = log(p50))]; t0 <- EVA$t0[j]; cs <- t0 + seq(-12, 12) * 3600; b <- numeric(length(cs))
      for (k in seq_along(cs)) b[k] <- h[hr >= cs[k] & hr < cs[k] + 6 * 3600, mean(lp)] - h[hr >= cs[k] - 6 * 3600 & hr < cs[k], mean(lp)]
      ck[[sprintf("median fee, %s: break at %s UTC (documented %s), fall %.2f", EVA$event[j], format(cs[which.min(b)], "%m-%d %H:%M"), format(t0, "%m-%d %H:%M"), b[cs == t0])]] <-
        min(b) < -EVA$fall[j] && abs(as.numeric(cs[which.min(b)] - t0, units = "hours")) <= EVA$tol[j] } }
  if (o == "gtrends_daily") ck[["values in 0..100, every day 02-15..04-15 for each series"]] <- X[, all(value >= 0 & value <= 100)] && X[, .N, by = .(request, keyword)][, all(N == 61)]
  if (o == "sender_window") ck[["windows match FEE_WINDOWS"]] <- X[, all(window %in% FEE_WINDOWS[chain == .BY$chain, window]), by = chain][, all(V1)]
  if (o == "control_hourly") ck[["Ethereum every hour; Bitcoin > 95% of hours (no block = missing)"]] <- all(hours %in% X[!is.na(n_eth), hr]) && mean(hours %in% X[!is.na(n_btc), hr]) > 0.95
  if (o == "eth_usd_daily_may") ck[["every day 2024-05-01..06-30"]] <- all(seq(as.IDate("2024-05-01"), as.IDate("2024-06-30"), by = 1) %in% X$day)
  if (o == "eth_usd_daily") ck[["every day 2024-02-15..04-09"]] <- all(seq(as.IDate("2024-02-15"), as.IDate("2024-04-09"), by = 1) %in% X$day)
  if (o == "multichain_drops") ck[["every drop >= 50%"]] <- X[, all(drop >= log(2))]
  if (o == "l2_hourly") for (ch in CHAINS) {
    # growthepie counts all txs including failed ones and excluding system txs
    r <- merge(X[chain == ch, .(n = sum(n)), by = .(date = as.IDate(hr, tz = "UTC"))], P$multichain_daily[chain == ch, .(date, txcount)], by = "date")[date >= as.IDate("2024-03-01") & date <= as.IDate("2024-04-14"), n / txcount]
    ck[[sprintf("%s: daily txs / growthepie txcount in [0.99, 1.02]: %.4f-%.4f over %d days", ch, min(r), max(r), length(r))]] <- length(r) >= 40 && all(r > 0.99 & r < 1.02)
    # break hour: largest fall in mean log fee per tx, 6 h after vs 6 h before, searched over +-12 h around the documented hour
    h <- X[chain == ch, .(lfpt = log(sum(fee) / sum(n))), by = hr]
    for (j in which(EVENTS$chain == ch)) {
      t0 <- EVENTS$t0[j]; cs <- t0 + seq(-12, 12) * 3600; b <- numeric(length(cs))
      for (k in seq_along(cs)) b[k] <- h[hr >= cs[k] & hr < cs[k] + 6 * 3600, mean(lfpt)] - h[hr >= cs[k] - 6 * 3600 & hr < cs[k], mean(lfpt)]
      ck[[sprintf("%s: break at %s UTC (documented %s), fall %.2f", EVENTS$event[j], format(cs[which.min(b)], "%m-%d %H:%M"), format(t0, "%m-%d %H:%M"), b[cs == t0])]] <-
        min(b) < -0.5 && abs(as.numeric(cs[which.min(b)] - t0, units = "hours")) <= 1 } }
  pass <- vapply(ck, isTRUE, logical(1))
  cat("## ", o, "\n", sprintf("  [%s] %s\n", ifelse(pass, "ok", "FAIL"), names(ck)), sep = "")
  if (!all(pass)) fails[[o]] <- paste(names(ck)[!pass], collapse = "; ")
  objects[[o]] <- list(valid = all(pass), rows = nrow(X), keys = keys, columns = names(X))
}
yaml::write_yaml(list(created = format(Sys.time(), usetz = TRUE), file = basename(PANEL_FILE), md5 = unname(tools::md5sum(PANEL_FILE)), all_valid = length(fails) == 0,
                      failures = fails, objects = objects), CONTRACT_FILE)
cat(sprintf("Contract written: %d objects, %d with failed checks\n", length(objects), length(fails)))
cat("\n## sessionInfo\n```\n"); print(sessionInfo()); cat("```\n"); sink()
if (length(fails)) stop("Panel validation failed: ", paste(names(fails), unlist(fails), collapse = "; "))
