# 03_validate_panels.R: checks every table in panel.rds and writes data/panel/contract.yaml, which 04-07 require.
# Cross-checks: daily L2 counts against growthepie, and the fee break at each documented event hour.
source(here::here("code", "00_setup.R"))
new_log("03 validate panels")
P <- readRDS(PANEL_FILE)
fails <- list()
check <- function(o, ok, what) { say(sprintf("  [%s] %s", if (isTRUE(ok)) "ok" else "FAIL", what)); if (!isTRUE(ok)) fails[[o]] <<- paste(fails[[o]], what) }
hours <- seq(as.POSIXct(PULL_START, tz = "UTC"), as.POSIXct(PULL_END, tz = "UTC") + 23 * 3600, by = 3600)
acts <- paste0("act_", gsub("-", "_", RETENTION_MONTHS))

# object, unique keys, other required columns, non-negative columns
S <- rbind(
  data.table(obj = "l2_hourly", keys = "chain hr hf failed", cols = "n fee n_senders", nonneg = "n fee n_senders"),
  data.table(obj = "l2_hourly_type", keys = "chain hr typ failed", cols = "n fee", nonneg = "n fee"),
  data.table(obj = "l2_newsenders", keys = "chain hr", cols = "new_senders", nonneg = "new_senders"),
  data.table(obj = "control_hourly", keys = "hr", cols = "n_eth n_btc", nonneg = "n_eth n_btc"),
  data.table(obj = "eth_usd_daily", keys = "day", cols = "close", nonneg = "close"),
  data.table(obj = "entrants", keys = "", cols = paste("chain day hr months_active any_later single_tx_wk1 bot_wk1 wave batch wave_size wave_funded class3 first_to first_sel funder_any", paste(acts, collapse = " ")),
             nonneg = "months_active"),
  data.table(obj = "sender_window", keys = "chain window id", cols = "n fee", nonneg = "n fee"),
  data.table(obj = "base_tx_by_class", keys = "cls day", cols = "txs", nonneg = "txs"),
  data.table(obj = "base_hourly_campaign", keys = "hr", cols = "n_campaign", nonneg = "n_campaign"),
  data.table(obj = "multichain_daily", keys = "chain date", cols = "txcount daa cost", nonneg = "txcount daa cost"),
  data.table(obj = "multichain_drops", keys = "chain date", cols = "drop local_max pre_level post_level", nonneg = ""))
check("panel", setequal(names(P), S$obj), sprintf("panel.rds holds the %d expected tables", nrow(S)))
objects <- list()
for (i in seq_len(nrow(S))) {
  o <- S$obj[i]; X <- P[[o]]; keys <- strsplit(S$keys[i], " ")[[1]]
  say("## ", o)
  check(o, all(c(keys, strsplit(S$cols[i], " ")[[1]]) %in% names(X)), "required columns present")
  if (length(keys)) check(o, !anyDuplicated(X, by = keys), sprintf("unique on (%s), %d rows", S$keys[i], nrow(X)))
  for (v in strsplit(S$nonneg[i], " ")[[1]]) check(o, !any(X[[v]] < 0, na.rm = TRUE), paste(v, "non-negative"))
  if (grepl("^l2_hourly", o)) check(o, X[, all(hours %in% hr), by = chain][, all(V1)], sprintf("every UTC hour %s..%s present for both chains", PULL_START, PULL_END))
  if (o == "l2_hourly_type") check(o, all(X$typ %in% c("native", "erc20_transfer", "approve", "swap", "other_call")), "five transaction types")
  if (o == "entrants") {
    check(o, X[, all(day >= as.IDate("2024-03-01") & day <= as.IDate("2024-03-27") & as.IDate(hr, tz = "UTC") == day)], "entry day in 03-01..27 and consistent with entry hour")
    check(o, X[!is.na(wave), all(day >= ENTRANT_WINDOW[1] & day <= ENTRANT_WINDOW[2]) && all(c(wave, batch, wave_size, wave_funded) %in% 0:1) && all(class3 %in% c("bot", "campaign", "genuine"))],
          "campaign flags are 0/1 and classes bot/campaign/genuine inside the entrant window") }
  if (o == "sender_window") check(o, X[, all(window %in% FEE_WINDOWS[chain == .BY$chain, window]), by = chain][, all(V1)], "windows match FEE_WINDOWS")
  if (o == "control_hourly") check(o, all(hours %in% X[!is.na(n_eth), hr]) && mean(hours %in% X[!is.na(n_btc), hr]) > 0.95, "Ethereum every hour; Bitcoin > 95% of hours (no block = missing)")
  if (o == "eth_usd_daily") check(o, all(seq(as.IDate("2024-02-15"), as.IDate("2024-04-09"), by = 1) %in% X$day), "every day 2024-02-15..04-09")
  if (o == "multichain_drops") check(o, X[, all(drop >= log(2))], "every drop >= 50%")
  if (o == "l2_hourly") for (ch in CHAINS) {
    # growthepie counts all txs including failed ones and excluding system txs
    r <- merge(X[chain == ch, .(n = sum(n)), by = .(date = as.IDate(hr, tz = "UTC"))], P$multichain_daily[chain == ch, .(date, txcount)], by = "date")[date >= as.IDate("2024-03-01") & date <= as.IDate("2024-04-14"), n / txcount]
    check(o, length(r) >= 40 && all(r > 0.99 & r < 1.02), sprintf("%s: daily txs / growthepie txcount in [0.99, 1.02]: %.4f-%.4f over %d days", ch, min(r), max(r), length(r)))
    # break hour: largest fall in mean log fee per tx, 6 h after vs 6 h before, searched over +-12 h around the documented hour
    h <- X[chain == ch, .(lfpt = log(sum(fee) / sum(n))), by = hr]
    for (j in which(EVENTS$chain == ch)) { t0 <- EVENTS$t0[j]; cs <- t0 + seq(-12, 12) * 3600
      b <- sapply(cs, function(c) h[hr >= c & hr < c + 6 * 3600, mean(lfpt)] - h[hr >= c - 6 * 3600 & hr < c, mean(lfpt)])
      check(o, min(b) < -0.5 && abs(as.numeric(cs[which.min(b)] - t0, units = "hours")) <= 1,
            sprintf("%s: break at %s UTC (documented %s), fall %.2f", EVENTS$event[j], format(cs[which.min(b)], "%m-%d %H:%M"), format(t0, "%m-%d %H:%M"), b[cs == t0])) } }
  objects[[o]] <- list(valid = is.null(fails[[o]]), rows = nrow(X), keys = keys, columns = names(X))
}
yaml::write_yaml(list(created = format(Sys.time(), usetz = TRUE), file = basename(PANEL_FILE), md5 = unname(tools::md5sum(PANEL_FILE)), all_valid = length(fails) == 0,
                      failures = fails, objects = objects), panel("contract.yaml"))
say(sprintf("Contract written: %d objects, %d with failed checks", length(objects), length(fails)))
save_log("03_validate_panels")
if (length(fails)) stop("Panel validation failed: ", paste(names(fails), unlist(fails), collapse = "; "))
