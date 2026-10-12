# 02_build_panels.R: data/raw -> data/panel/panel.rds, a named list with one table per panel (chains stacked).
# Address-level data stay in data/raw; the panel keeps only what 04-07 use, so it stays small enough for git.
source(here::here("code", "00_setup.R"))
new_log("02 build panels")
in_pull <- function(x) x[hr >= as.POSIXct(PULL_START, tz = "UTC") & hr < as.POSIXct(PULL_END + 1, tz = "UTC")]

# ---- A. hourly L2 series without protocol system txs ----
# System txs are fee-free, successful, sent by a high-frequency sender and typed 'other_call' (about 3% of Base and 22% of Arbitrum raw txs).
l2_hourly <- list(); l2_hourly_type <- list(); l2_newsenders <- list()
for (ch in CHAINS) {
  H <- read_pq(raw(sprintf("l2_hourly_%s.parquet", ch)))[, .(hr, hf, failed, n, fee, n_senders)]; Y <- read_pq(raw(sprintf("l2_hourly_type_%s.parquet", ch)))
  S <- read_pq(raw(sprintf("l2_hourly_system_%s.parquet", ch))); NS <- read_pq(raw(sprintf("l2_newsenders_%s.parquet", ch)))
  check_unique(H, c("hr", "hf", "failed"), "hourly"); check_unique(Y, c("hr", "typ", "failed"), "type"); check_unique(S, "hr", "system")
  H <- merge(H, S, by = "hr", all.x = TRUE)[is.na(n_sys), n_sys := 0]
  if (H[hf == 1 & failed == 0, any(n < n_sys)]) stop(ch, ": system txs exceed high-frequency successful txs")
  H[hf == 1 & failed == 0, `:=`(n = n - n_sys, n_senders = n_senders - as.integer(n_sys > 0))][, n_sys := NULL]
  Y <- merge(Y, S, by = "hr", all.x = TRUE)[is.na(n_sys), n_sys := 0]
  Y[typ == "other_call" & failed == 0, n := n - n_sys][, n_sys := NULL]
  stopifnot(H[, min(n)] >= 0, Y[, min(n)] >= 0)
  l2_hourly[[ch]] <- in_pull(H)[order(hr, hf, failed)][, chain := ch]; l2_hourly_type[[ch]] <- in_pull(Y)[order(hr, typ, failed)][, chain := ch]
  l2_newsenders[[ch]] <- NS[order(hr)][, chain := ch]
  say(sprintf("A %s: %d hours; system txs removed %d (%.1f%% of raw txs)", ch, uniqueN(H$hr), sum(S$n_sys), 100 * sum(S$n_sys) / (sum(H$n) + sum(S$n_sys))))
}
l2_hourly <- rbindlist(l2_hourly); l2_hourly_type <- rbindlist(l2_hourly_type); l2_newsenders <- rbindlist(l2_newsenders)

# ---- B. Ethereum L1 and Bitcoin hourly counts; ETH/USD ----
E <- read_pq(raw("l1_hourly_eth.parquet")); B <- read_pq(raw("btc_hourly.parquet")); check_unique(E, "hr", "eth"); check_unique(B, "hr", "btc")
control_hourly <- merge(E[, .(hr, n_eth = n)], B[, .(hr, n_btc = n)], by = "hr", all = TRUE)[order(hr)]
eth_usd_daily <- fread(raw("eth_usd_daily.csv"))[, .(day = as.IDate(day), close)]; check_unique(eth_usd_daily, "day", "eth_usd")
say(sprintf("B: control hours %d; ETH/USD days %d", nrow(control_hourly), nrow(eth_usd_daily)))

# ---- C. entrants: first seen 03-01..27 with no earlier activity; later activity, first-week behaviour, campaign flags ----
entrants <- list()
for (ch in CHAINS) {
  Fi <- read_pq(raw(sprintf("cohort_first_%s.parquet", ch))); Pr <- read_pq(raw(sprintf("cohort_prior_%s.parquet", ch))); Po <- read_pq(raw(sprintf("cohort_post_%s.parquet", ch)))
  n_cohort <- nrow(Fi); X <- Fi[!(a %in% Pr$a)]
  A <- dcast(Po[a %in% X$a & ym %in% RETENTION_MONTHS, .(a, ym = paste0("act_", gsub("-", "_", ym)), v = 1L)], a ~ ym, value.var = "v", fill = 0L)
  X <- merge(X, A, by = "a", all.x = TRUE)
  for (m in paste0("act_", gsub("-", "_", RETENTION_MONTHS))) { if (!m %in% names(X)) X[, (m) := 0L]; X[is.na(get(m)), (m) := 0L] }
  X <- merge(X, Po[a %in% X$a, .(months_active = uniqueN(ym)), by = a], by = "a", all.x = TRUE)[is.na(months_active), months_active := 0L]
  X[, `:=`(chain = ch, day = as.IDate(first_dt, tz = "UTC"), hr = lubridate::floor_date(first_dt, "hour"), any_later = as.integer(months_active > 0),
           single_tx_wk1 = as.integer(n_week1 == 1), bot_wk1 = as.integer(n_week1 >= BOT_MIN_WEEK1))]
  W <- campaign_flags(read_pq(raw(sprintf("wave_first_out_%s.parquet", ch))), read_pq(raw(sprintf("wave_fund_eth_%s.parquet", ch))), read_pq(raw(sprintf("wave_fund_tok_%s.parquet", ch))))
  X <- merge(X, W[, .(a, first_to, first_sel, funder_any, wave, batch, wave_size, wave_funded)], by = "a", all.x = TRUE)
  X[!is.na(wave), class3 := fcase(bot_wk1 == 1, "bot", wave == 1, "campaign", default = "genuine")]   # bot > campaign > genuine
  say(sprintf("C %s: campaign bursts (>= %d entrants/day and >= %dx pre-shock median): campaign share pre %.3f, post %.3f", ch, SPIKE_MIN, SPIKE_K,
              X[!is.na(wave) & day <= PRE_END, mean(wave)], X[!is.na(wave) & day > PRE_END, mean(wave)]))
  check_unique(X, "a", "entrants"); stopifnot(!(SYSTEM_SENDERS[[ch]] %in% X$a)); entrants[[ch]] <- X
  say(sprintf("C %s: cohort %d; prior activity %.3f -> entrants %d; in window %s..%s: %d (campaign %.3f, bursting funder %.3f)", ch, n_cohort, 1 - nrow(X) / n_cohort, nrow(X),
              ENTRANT_WINDOW[1], ENTRANT_WINDOW[2], X[!is.na(wave), .N], X[!is.na(wave), mean(wave)], X[!is.na(batch), mean(batch)]))
}

# ---- D. sender-level aggregates from sender-days (system sender dropped) ----
# sender_window: txs and fees per sender and FEE_WINDOWS window, for senders with >= 2 txs and positive fees in some window (integer sender id).
# base_tx_by_class: Base daily txs 03-06..20 by sender class (incumbent = active 03-06..12; window entrants by campaign flag; other).
sender_window <- list()
for (ch in CHAINS) {
  SD <- read_pq(raw(sprintf("l2_senderday_%s.parquet", ch)))[a != SYSTEM_SENDERS[[ch]]][, day := as.IDate(day)]
  FW <- FEE_WINDOWS[chain == ch]
  X <- rbindlist(lapply(seq_len(nrow(FW)), function(k) SD[day >= FW$start[k] & day <= FW$end[k], .(window = FW$window[k], n = sum(n), fee = sum(fee)), by = a]))
  keep <- X[n >= 2 & fee > 0, unique(a)]
  sender_window[[ch]] <- X[a %in% keep][, `:=`(chain = ch, id = match(a, keep))][, .(chain, window, id, n, fee)]
  say(sprintf("D %s: %d sender-days; %d senders kept for the fee-level analysis", ch, nrow(SD), length(keep)))
  if (ch == "base") {
    EB <- entrants$base[!is.na(wave)]; inc <- SD[day >= as.IDate("2024-03-06") & day <= as.IDate("2024-03-12"), unique(a)]
    BD <- SD[day >= as.IDate("2024-03-06") & day <= as.IDate("2024-03-20") & day != as.IDate("2024-03-13")]
    BD[, cls := fcase(a %in% inc, "incumbent (active 03-06..12)", a %in% EB[class3 == "campaign", a], "entrant: campaign", a %in% EB[class3 == "bot", a], "entrant: bot-like",
                     a %in% EB[class3 == "genuine", a], "entrant: genuine",
                     default = "other (returning / pre-03-08 entrant)")]
    base_tx_by_class <- BD[, .(txs = sum(n)), by = .(cls, day)][order(cls, day)] }
  rm(SD, X); invisible(gc())
}
sender_window <- rbindlist(sender_window)
entrants <- rbindlist(entrants)[, .(chain, day, hr, act_2024_04, act_2024_06, act_2024_09, act_2024_12, act_2025_03, months_active, any_later, single_tx_wk1, bot_wk1,
                                     wave, batch, wave_size, wave_funded, class3, first_to, first_sel, funder_any)]   # entrant addresses are not needed downstream

# ---- E. Base campaign-wallet activity ----
base_hourly_campaign <- read_pq(raw("base_hourly_campaign.parquet"))[order(hr)]; check_unique(base_hourly_campaign, "hr", "campaign")
say(sprintf("E: campaign-wallet txs %d over %d hours", sum(base_hourly_campaign$n_campaign), nrow(base_hourly_campaign)))

# ---- F. multi-chain daily panel and fee drops ----
G <- rbindlist(lapply(c("txcount", "daa", "txcosts"), function(m) as.data.table(fromJSON(raw("growthepie", sprintf("export_%s.json", m))))))
G <- G[metric_key %in% c("txcount", "daa", "txcosts_median_usd")]
G <- dcast(G[, .(chain = origin_key, date = as.IDate(date), metric_key, value)], chain + date ~ metric_key, value.var = "value", fun.aggregate = mean)
setnames(G, "txcosts_median_usd", "cost"); multichain_daily <- G[date >= as.IDate("2023-12-01") & date <= as.IDate("2025-01-31") & !(chain %in% c("all_l2s", "multiple"))][order(chain, date)]
check_unique(multichain_daily, c("chain", "date"), "multichain")
# Drop day: median log cost over t+1..t+3 at least log(2) below t-3..t-1. All such days are kept (they exclude a chain as a control);
# local_max marks the largest within a 10-day cluster (the event date).
G <- copy(multichain_daily)[, lc := log(cost)]
G[, `:=`(pre3 = frollapply(lc, 3, median, align = "right"), post3 = shift(frollapply(lc, 3, median, align = "left"), -1)), by = chain]
G[, drop := shift(pre3, 1) - post3, by = chain]
D <- G[date >= as.IDate("2024-02-15") & date <= as.IDate("2024-12-31") & is.finite(drop) & drop >= log(2) & chain != "ethereum"]
D[, local_max := as.integer(drop == max(drop)), by = .(chain, grp = cumsum(c(1, diff(as.integer(date)) > 10)))]
D <- D[, .(chain, date, drop, local_max)]
D[, pre_level := sapply(seq_len(.N), function(i) G[chain == D$chain[i] & date >= D$date[i] - 7 & date < D$date[i], median(cost, na.rm = TRUE)])]
D[, post_level := sapply(seq_len(.N), function(i) G[chain == D$chain[i] & date > D$date[i] & date <= D$date[i] + 7, median(cost, na.rm = TRUE)])]
multichain_drops <- D
say(sprintf("F: %d chain-days, %d chains; %d drop days, %d events", nrow(multichain_daily), uniqueN(multichain_daily$chain), nrow(D), sum(D$local_max)))

# ---- save ----
PANELS <- c("l2_hourly", "l2_hourly_type", "l2_newsenders", "control_hourly", "eth_usd_daily", "entrants", "sender_window", "base_tx_by_class", "base_hourly_campaign",
            "multichain_daily", "multichain_drops")
saveRDS(mget(PANELS), PANEL_FILE, compress = "xz")
say(sprintf("Saved %s (%.1f MB): %s", basename(PANEL_FILE), file.size(PANEL_FILE) / 1e6, paste(PANELS, collapse = ", ")))
save_log("02_build_panels")
