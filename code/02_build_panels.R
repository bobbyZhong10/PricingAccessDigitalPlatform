# 02_build_panels.R: data/raw -> data/panel/panel.rds, a named list with one table per panel (chains stacked).
# Address-level data stay in data/raw; the panel keeps only what 04-07 use, so it stays small enough for git.
# Timestamps read from parquet are tagged UTC right after reading.
source(here::here("code", "00_setup.R"))
sink(file.path(DIR_LOG, "02_build_panels.md"), split = TRUE)
cat("# 02 build panels\nRun ", format(Sys.time(), usetz = TRUE), "\n", sep = "")
pull_from <- as.POSIXct(PULL_START, tz = "UTC"); pull_to <- as.POSIXct(PULL_END + 1, tz = "UTC")

# ---- A. hourly L2 series without protocol system txs ----
# System txs are fee-free, successful, sent by a high-frequency sender and typed 'other_call' (about 3% of Base and 22% of Arbitrum raw txs).
l2_hourly <- list(); l2_hourly_type <- list(); l2_newsenders <- list()
for (ch in CHAINS) {
  H <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, sprintf("l2_hourly_%s.parquet", ch))))[, .(hr, hf, failed, n, fee, n_senders)]
  Y <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, sprintf("l2_hourly_type_%s.parquet", ch))))
  S <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, sprintf("l2_hourly_system_%s.parquet", ch))))
  NS <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, sprintf("l2_newsenders_%s.parquet", ch))))
  setattr(H$hr, "tzone", "UTC"); setattr(Y$hr, "tzone", "UTC"); setattr(S$hr, "tzone", "UTC"); setattr(NS$hr, "tzone", "UTC")
  stopifnot(!anyDuplicated(H, by = c("hr", "hf", "failed")), !anyDuplicated(Y, by = c("hr", "typ", "failed")), !anyDuplicated(S$hr))
  H <- merge(H, S, by = "hr", all.x = TRUE)[is.na(n_sys), n_sys := 0]
  stopifnot(H[hf == 1 & failed == 0, all(n >= n_sys)])   # system txs sit in the high-frequency, successful cell
  H[hf == 1 & failed == 0, `:=`(n = n - n_sys, n_senders = n_senders - as.integer(n_sys > 0))][, n_sys := NULL]
  Y <- merge(Y, S, by = "hr", all.x = TRUE)[is.na(n_sys), n_sys := 0]
  Y[typ == "other_call" & failed == 0, n := n - n_sys][, n_sys := NULL]
  stopifnot(H[, min(n)] >= 0, Y[, min(n)] >= 0)
  l2_hourly[[ch]] <- H[hr >= pull_from & hr < pull_to][order(hr, hf, failed)][, chain := ch]
  l2_hourly_type[[ch]] <- Y[hr >= pull_from & hr < pull_to][order(hr, typ, failed)][, chain := ch]
  l2_newsenders[[ch]] <- NS[order(hr)][, chain := ch]
  cat(sprintf("A %s: %d hours; system txs removed %d (%.1f%% of raw txs)\n", ch, uniqueN(H$hr), sum(S$n_sys), 100 * sum(S$n_sys) / (sum(H$n) + sum(S$n_sys))))
}
l2_hourly <- rbindlist(l2_hourly); l2_hourly_type <- rbindlist(l2_hourly_type); l2_newsenders <- rbindlist(l2_newsenders)

# ---- B. Ethereum L1 and Bitcoin hourly counts; ETH/USD ----
E <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, "l1_hourly_eth.parquet"))); B <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, "btc_hourly.parquet")))
setattr(E$hr, "tzone", "UTC"); setattr(B$hr, "tzone", "UTC"); stopifnot(!anyDuplicated(E$hr), !anyDuplicated(B$hr))
control_hourly <- merge(E[, .(hr, n_eth = n)], B[, .(hr, n_btc = n)], by = "hr", all = TRUE)[order(hr)]
eth_usd_daily <- fread(file.path(DIR_RAW, "eth_usd_daily.csv"))[, .(day = as.IDate(day), close)]; stopifnot(!anyDuplicated(eth_usd_daily$day))
cat(sprintf("B: control hours %d; ETH/USD days %d\n", nrow(control_hourly), nrow(eth_usd_daily)))

# ---- C. entrants: first seen 03-01..27 with no earlier activity; later activity, first-week behaviour, campaign flags ----
entrants <- list()
for (ch in CHAINS) {
  Fi <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, sprintf("cohort_first_%s.parquet", ch)))); setattr(Fi$first_dt, "tzone", "UTC")
  Pr <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, sprintf("cohort_prior_%s.parquet", ch))))
  Po <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, sprintf("cohort_post_%s.parquet", ch))))
  n_cohort <- nrow(Fi); X <- Fi[!(a %in% Pr$a)]
  A <- dcast(Po[a %in% X$a & ym %in% RETENTION_MONTHS, .(a, ym = paste0("act_", gsub("-", "_", ym)), v = 1L)], a ~ ym, value.var = "v", fill = 0L)
  X <- merge(X, A, by = "a", all.x = TRUE)
  for (m in paste0("act_", gsub("-", "_", RETENTION_MONTHS))) { if (!m %in% names(X)) X[, (m) := 0L]; X[is.na(get(m)), (m) := 0L] }
  X <- merge(X, Po[a %in% X$a, .(months_active = uniqueN(ym)), by = a], by = "a", all.x = TRUE)[is.na(months_active), months_active := 0L]
  X[, `:=`(chain = ch, day = as.IDate(first_dt, tz = "UTC"), hr = lubridate::floor_date(first_dt, "hour"), any_later = as.integer(months_active > 0),
           single_tx_wk1 = as.integer(n_week1 == 1), bot_wk1 = as.integer(n_week1 >= BOT_MIN_WEEK1))]

  # campaign rule for entrants in ENTRANT_WINDOW (01 section G uses the same wave flag to pick campaign wallets)
  W <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, sprintf("wave_first_out_%s.parquet", ch)))); setattr(W$first_dt, "tzone", "UTC")
  FE <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, sprintf("wave_fund_eth_%s.parquet", ch))))
  FT <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, sprintf("wave_fund_tok_%s.parquet", ch))))
  W <- merge(W, FE[, .(a, funder)], by = "a", all.x = TRUE)
  W <- merge(W, FT[, .(a, tfunder)], by = "a", all.x = TRUE)
  W[, `:=`(day = as.IDate(first_dt, tz = "UTC"), funder_any = fifelse(!is.na(funder), funder, tfunder), pair = paste(first_to, first_sel))]
  W <- W[day >= ENTRANT_WINDOW[1] & day <= ENTRANT_WINDOW[2]]
  n_pre <- as.integer(PRE_END - ENTRANT_WINDOW[1]) + 1L
  # burst: a group's daily count N_gd >= SPIKE_MIN and N_gd >= SPIKE_K * median of its daily counts on ENTRANT_WINDOW[1]..PRE_END (zeros for days without entrants)
  PR <- W[, .N, by = .(day, pair)]
  PR[, base := 0][PR[day <= PRE_END, .(b = median(c(N, rep(0L, n_pre - .N)))), by = pair], base := i.b, on = "pair"]
  FD <- W[!is.na(funder_any), .N, by = .(day, funder_any)]
  FD[, base := 0][FD[day <= PRE_END, .(b = median(c(N, rep(0L, n_pre - .N)))), by = funder_any], base := i.b, on = "funder_any"]
  W[, `:=`(wave = as.integer(paste(day, pair) %in% PR[N >= SPIKE_MIN & N >= SPIKE_K * base, paste(day, pair)]),                                   # main rule
           batch = as.integer(!is.na(funder_any) & paste(day, funder_any) %in% FD[N >= SPIKE_MIN & N >= SPIKE_K * base, paste(day, funder_any)]),  # bursting funder
           fburst = paste(day, funder_any) %in% FD[N >= FUNDER_BURST_MIN & N >= SPIKE_K * base, paste(day, funder_any)])]
  W[, `:=`(wave_size = as.integer(.N >= WAVE_SIZE_ALT),                      # bound 1: size only
           wave_funded = as.integer(wave == 1 & mean(fburst) >= 0.5)),        # bound 2: burst mostly funded by bursting funders
    by = .(day, pair)]

  X <- merge(X, W[, .(a, first_to, first_sel, funder_any, wave, batch, wave_size, wave_funded)], by = "a", all.x = TRUE)
  X[!is.na(wave), class3 := fcase(bot_wk1 == 1, "bot", wave == 1, "campaign", default = "genuine")]   # bot > campaign > genuine
  stopifnot(!anyDuplicated(X$a), !(SYSTEM_SENDERS[[ch]] %in% X$a)); entrants[[ch]] <- X
  cat(sprintf("C %s: campaign bursts (>= %d entrants/day and >= %dx pre-shock median): campaign share pre %.3f, post %.3f\n", ch, SPIKE_MIN, SPIKE_K,
              X[!is.na(wave) & day <= PRE_END, mean(wave)], X[!is.na(wave) & day > PRE_END, mean(wave)]))
  cat(sprintf("C %s: cohort %d; prior activity %.3f -> entrants %d; in window %s..%s: %d (campaign %.3f, bursting funder %.3f)\n", ch, n_cohort, 1 - nrow(X) / n_cohort, nrow(X),
              ENTRANT_WINDOW[1], ENTRANT_WINDOW[2], X[!is.na(wave), .N], X[!is.na(wave), mean(wave)], X[!is.na(batch), mean(batch)]))
}

# ---- D. sender-level aggregates from sender-days (system sender dropped) ----
# sender_window: txs and fees per sender and FEE_WINDOWS window, for senders with >= 2 txs and positive fees in some window (integer sender id).
# base_tx_by_class: Base daily txs 03-06..20 by sender class (incumbent = active 03-06..12; window entrants by class; other).
sender_window <- list()
for (ch in CHAINS) {
  SD <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, sprintf("l2_senderday_%s.parquet", ch))))[a != SYSTEM_SENDERS[[ch]]][, day := as.IDate(day)]
  FW <- FEE_WINDOWS[chain == ch]
  X <- list()
  for (k in seq_len(nrow(FW))) X[[k]] <- SD[day >= FW$start[k] & day <= FW$end[k], .(window = FW$window[k], n = sum(n), fee = sum(fee)), by = a]
  X <- rbindlist(X)
  keep <- X[n >= 2 & fee > 0, unique(a)]
  sender_window[[ch]] <- X[a %in% keep][, `:=`(chain = ch, id = match(a, keep))][, .(chain, window, id, n, fee)]
  cat(sprintf("D %s: %d sender-days; %d senders kept for the fee-level analysis\n", ch, nrow(SD), length(keep)))
  if (ch == "base") {
    EB <- entrants$base[!is.na(wave)]; inc <- SD[day >= as.IDate("2024-03-06") & day <= as.IDate("2024-03-12"), unique(a)]
    BD <- SD[day >= as.IDate("2024-03-06") & day <= as.IDate("2024-03-20") & day != as.IDate("2024-03-13")]
    BD[, cls := fcase(a %in% inc, "incumbent (active 03-06..12)", a %in% EB[class3 == "campaign", a], "entrant: campaign", a %in% EB[class3 == "bot", a], "entrant: bot-like",
                     a %in% EB[class3 == "genuine", a], "entrant: genuine",
                     default = "other (returning / pre-03-08 entrant)")]
    base_tx_by_class <- BD[, .(txs = sum(n)), by = .(cls, day)][order(cls, day)]
  }
  rm(SD, X); invisible(gc())
}
sender_window <- rbindlist(sender_window)
entrants <- rbindlist(entrants)[, .(chain, day, hr, act_2024_04, act_2024_06, act_2024_09, act_2024_12, act_2025_03, months_active, any_later, single_tx_wk1, bot_wk1,
                                     wave, batch, wave_size, wave_funded, class3, first_to, first_sel, funder_any)]   # entrant addresses are not needed downstream

# ---- E. Base campaign-wallet activity ----
base_hourly_campaign <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, "base_hourly_campaign.parquet")))[order(hr)]
setattr(base_hourly_campaign$hr, "tzone", "UTC"); stopifnot(!anyDuplicated(base_hourly_campaign$hr))
cat(sprintf("E: campaign-wallet txs %d over %d hours\n", sum(base_hourly_campaign$n_campaign), nrow(base_hourly_campaign)))

# ---- F. multi-chain daily panel and fee drops ----
G <- list()
for (m in c("txcount", "daa", "txcosts")) G[[m]] <- as.data.table(fromJSON(file.path(DIR_RAW, "growthepie", sprintf("export_%s.json", m))))
G <- rbindlist(G)[metric_key %in% c("txcount", "daa", "txcosts_median_usd")]
G <- dcast(G[, .(chain = origin_key, date = as.IDate(date), metric_key, value)], chain + date ~ metric_key, value.var = "value", fun.aggregate = mean)
setnames(G, "txcosts_median_usd", "cost")
multichain_daily <- G[date >= as.IDate("2023-12-01") & date <= as.IDate("2025-01-31") & !(chain %in% c("all_l2s", "multiple"))][order(chain, date)]
stopifnot(!anyDuplicated(multichain_daily, by = c("chain", "date")))
# Drop day t: median log cost over t-3..t-1 minus median over t+1..t+3 >= log(2). All such days are kept (they exclude a chain as a control);
# local_max marks the largest within a 10-day cluster (the event date).
G <- copy(multichain_daily)[, lc := log(cost)]
G[, `:=`(pre3 = frollapply(lc, 3, median, align = "right"), post3 = shift(frollapply(lc, 3, median, align = "left"), -1)), by = chain]
G[, drop := shift(pre3, 1) - post3, by = chain]
D <- G[date >= as.IDate("2024-02-15") & date <= as.IDate("2024-12-31") & is.finite(drop) & drop >= log(2) & chain != "ethereum"]
D[, local_max := as.integer(drop == max(drop)), by = .(chain, grp = cumsum(c(1, diff(as.integer(date)) > 10)))]
D <- D[, .(chain, date, drop, local_max)]
D[, `:=`(pre_level = NA_real_, post_level = NA_real_)]   # median fee in the 7 days before and after the drop day
for (i in seq_len(nrow(D))) {
  D[i, pre_level := G[chain == D$chain[i] & date >= D$date[i] - 7 & date < D$date[i], median(cost, na.rm = TRUE)]]
  D[i, post_level := G[chain == D$chain[i] & date > D$date[i] & date <= D$date[i] + 7, median(cost, na.rm = TRUE)]]
}
multichain_drops <- D
cat(sprintf("F: %d chain-days, %d chains; %d drop days, %d events\n", nrow(multichain_daily), uniqueN(multichain_daily$chain), nrow(D), sum(D$local_max)))

# ---- save ----
PANELS <- c("l2_hourly", "l2_hourly_type", "l2_newsenders", "control_hourly", "eth_usd_daily", "entrants", "sender_window", "base_tx_by_class", "base_hourly_campaign",
            "multichain_daily", "multichain_drops")
saveRDS(mget(PANELS), PANEL_FILE, compress = "xz")
cat(sprintf("Saved %s (%.1f MB): %s\n", basename(PANEL_FILE), file.size(PANEL_FILE) / 1e6, paste(PANELS, collapse = ", ")))
cat("\n## sessionInfo\n```\n"); print(sessionInfo()); cat("```\n"); sink()
