# 01_download.R: public data -> data/raw. Each section is skipped if its files exist (set FORCE_DOWNLOAD = TRUE to redo).
# Sources (no keys): AWS Public Blockchain (s3://aws-public-blockchain, sonarx Base/Arbitrum, Ethereum/Bitcoin blocks), growthepie exports, Coinbase candles.
# Raw files are aggregates computed on the fly with DuckDB; the transaction-level tables are hundreds of GB. A full download takes 1-2 hours.
# Successful (transactions) and failed (transactions_failed) tables are disjoint and are stacked.
source(here::here("code", "00_setup.R"))
sink(file.path(DIR_LOG, "01_download.md"), split = TRUE)
cat("# 01 download\nRun ", format(Sys.time(), usetz = TRUE), "\n", sep = "")
FORCE_DOWNLOAD <- FALSE
S3_INIT <- "INSTALL httpfs; LOAD httpfs; SET s3_region='us-east-2'; SET threads TO 8; SET memory_limit='10GB'; SET preserve_insertion_order = false; SET http_retries = 10; SET http_retry_wait_ms = 3000;"
SONARX <- "s3://aws-public-blockchain/v1.1/sonarx/"
days_main <- format(seq(PULL_START, PULL_END, by = "day"))

# ---- A. hourly activity, new senders, sender-days (2024-02-15..04-15) ----
for (ch in CHAINS) {
  outs <- file.path(DIR_RAW, sprintf(c("l2_hourly_%s.parquet", "l2_newsenders_%s.parquet", "l2_senderday_%s.parquet"), ch))
  if (!FORCE_DOWNLOAD && all(file.exists(outs))) { cat("A ", ch, ": exists, skipped\n", sep = ""); next }
  q_out <- paste0("'", gsub("'", "''", outs), "'")   # local paths may contain an apostrophe
  f_ok <- paste0("[", paste0("'", SONARX, ch, "/transactions/date=", days_main, "/*.parquet'", collapse = ", "), "]")
  f_fail <- paste0("[", paste0("'", SONARX, ch, "/transactions_failed/date=", days_main, "/*.parquet'", collapse = ", "), "]")
  t_start <- Sys.time(); dbf <- tempfile(fileext = ".duckdb"); con <- DBI::dbConnect(duckdb::duckdb(), dbdir = dbf); DBI::dbExecute(con, S3_INIT)
  DBI::dbExecute(con, sprintf("CREATE TABLE tx AS SELECT lower(FROM_ADDRESS) AS a, DATETIME AS dt, TRANSACTION_FEE AS fee, 0 AS failed FROM read_parquet(%s)
    UNION ALL SELECT lower(FROM_ADDRESS), DATETIME, TRANSACTION_FEE, 1 FROM read_parquet(%s)", f_ok, f_fail))
  DBI::dbExecute(con, sprintf("CREATE TABLE hf AS SELECT a FROM tx WHERE dt >= TIMESTAMP '2024-02-15' AND dt < TIMESTAMP '2024-02-22' GROUP BY a HAVING count(*) >= %d", HF_MIN_WEEKLY))
  DBI::dbExecute(con, sprintf("COPY (SELECT date_trunc('hour', dt) AS hr, CAST(a IN (SELECT a FROM hf) AS INTEGER) AS hf, failed, count(*) AS n, sum(fee) AS fee,
    count(DISTINCT a) AS n_senders FROM tx GROUP BY 1, 2, 3) TO %s (FORMAT PARQUET)", q_out[1]))
  DBI::dbExecute(con, sprintf("COPY (SELECT date_trunc('hour', first_dt) AS hr, count(*) AS new_senders FROM (SELECT a, min(dt) AS first_dt FROM tx GROUP BY a) GROUP BY 1) TO %s (FORMAT PARQUET)", q_out[2]))
  DBI::dbExecute(con, sprintf("COPY (SELECT a, CAST(dt AS DATE) AS day, count(*) AS n, sum(fee) AS fee FROM tx GROUP BY 1, 2) TO %s (FORMAT PARQUET)", q_out[3]))
  DBI::dbDisconnect(con, shutdown = TRUE); unlink(dbf)
  cat(sprintf("A %s: %.1f min\n", ch, as.numeric(Sys.time() - t_start, units = "mins")))
}

# ---- B. Ethereum L1 and Bitcoin hourly txs (market-wide comparison series) ----
outs <- file.path(DIR_RAW, c("l1_hourly_eth.parquet", "btc_hourly.parquet"))
if (FORCE_DOWNLOAD || !all(file.exists(outs))) {
  t_start <- Sys.time(); con <- DBI::dbConnect(duckdb::duckdb()); DBI::dbExecute(con, S3_INIT)
  d <- format(seq(as.Date("2024-02-14"), as.Date("2024-04-16"), by = "day"))
  E <- as.data.table(DBI::dbGetQuery(con, sprintf("SELECT date_trunc('hour', timestamp) AS hr, sum(transaction_count) AS n FROM read_parquet([%s]) GROUP BY 1 ORDER BY 1",
    paste0("'s3://aws-public-blockchain/v1.0/eth/blocks/date=", d, "/*.parquet'", collapse = ", "))))
  B <- as.data.table(DBI::dbGetQuery(con, sprintf("SELECT date_trunc('hour', timestamp) AS hr, sum(transaction_count) AS n FROM read_parquet([%s]) GROUP BY 1 ORDER BY 1",
    paste0("'s3://aws-public-blockchain/v1.0/btc/blocks/date=", d, "/*.parquet'", collapse = ", "))))
  DBI::dbDisconnect(con, shutdown = TRUE)
  nanoparquet::write_parquet(as.data.frame(E), outs[1]); nanoparquet::write_parquet(as.data.frame(B), outs[2])
  cat(sprintf("B Ethereum/Bitcoin: %.1f min\n", as.numeric(Sys.time() - t_start, units = "mins")))
} else cat("B: exists, skipped\n")

# ---- C. protocol system txs per hour (removed in 02) ----
for (ch in CHAINS) {
  out <- file.path(DIR_RAW, sprintf("l2_hourly_system_%s.parquet", ch))
  if (!FORCE_DOWNLOAD && file.exists(out)) { cat("C ", ch, ": exists, skipped\n", sep = ""); next }
  t_start <- Sys.time(); con <- DBI::dbConnect(duckdb::duckdb()); DBI::dbExecute(con, S3_INIT)
  S <- as.data.table(DBI::dbGetQuery(con, sprintf("SELECT date_trunc('hour', DATETIME) AS hr, count(*) AS n_sys FROM read_parquet([%s]) WHERE lower(FROM_ADDRESS) = '%s' GROUP BY 1 ORDER BY 1",
    paste0("'", SONARX, ch, "/transactions/date=", days_main, "/*.parquet'", collapse = ", "), SYSTEM_SENDERS[[ch]])))
  DBI::dbDisconnect(con, shutdown = TRUE); nanoparquet::write_parquet(as.data.frame(S), out)
  cat(sprintf("C %s: %.1f min\n", ch, as.numeric(Sys.time() - t_start, units = "mins")))
}

# ---- D. hourly txs by type (4-byte method selector) ----
swap <- c("0x3593564c", "0x24856bc3", "0x7ff36ab5", "0x18cbafe5", "0x38ed1739", "0xb6f9de95", "0x791ac947", "0x5c11d795", "0xfb3bdb41", "0x8803dbee", "0x4a25d94a",
          "0x414bf389", "0x04e45aaf", "0xc04b8d59", "0xb858183f", "0xdb3e2198", "0x5ae401dc", "0xac9650d8", "0x12aa3caf", "0xe449022e", "0x0502b1c5", "0x2e95b6c8",
          "0x415565b0", "0xcac88ea9", "0xf41766d8", "0x83bd37f9", "0x90411a32")   # Uniswap V2/V3/Universal Router, Aerodrome, 1inch, 0x, ParaSwap, Odos
cls <- sprintf("CASE WHEN INPUT IS NULL OR length(INPUT) <= 2 THEN 'native' WHEN substr(INPUT,1,10) = '0xa9059cbb' THEN 'erc20_transfer' WHEN substr(INPUT,1,10) = '0x095ea7b3' THEN 'approve'
  WHEN substr(INPUT,1,10) IN (%s) THEN 'swap' ELSE 'other_call' END", paste0("'", swap, "'", collapse = ","))
for (ch in CHAINS) {
  out <- file.path(DIR_RAW, sprintf("l2_hourly_type_%s.parquet", ch))
  if (!FORCE_DOWNLOAD && file.exists(out)) { cat("D ", ch, ": exists, skipped\n", sep = ""); next }
  f_ok <- paste0("[", paste0("'", SONARX, ch, "/transactions/date=", days_main, "/*.parquet'", collapse = ", "), "]")
  f_fail <- paste0("[", paste0("'", SONARX, ch, "/transactions_failed/date=", days_main, "/*.parquet'", collapse = ", "), "]")
  t_start <- Sys.time(); con <- DBI::dbConnect(duckdb::duckdb()); DBI::dbExecute(con, S3_INIT)
  DBI::dbExecute(con, sprintf("COPY (SELECT date_trunc('hour', DATETIME) AS hr, typ, failed, count(*) AS n, sum(fee) AS fee FROM (
      SELECT DATETIME, %s AS typ, 0 AS failed, TRANSACTION_FEE AS fee FROM read_parquet(%s) UNION ALL SELECT DATETIME, %s, 1, TRANSACTION_FEE FROM read_parquet(%s))
    GROUP BY 1, 2, 3) TO %s (FORMAT PARQUET)", cls, f_ok, cls, f_fail, paste0("'", gsub("'", "''", out), "'")))
  DBI::dbDisconnect(con, shutdown = TRUE)
  cat(sprintf("D %s: %.1f min\n", ch, as.numeric(Sys.time() - t_start, units = "mins")))
}

# ---- E. entrant cohorts: senders first seen on 03-01..27 ----
# prior: senders active before 2024-02-15 (Base since genesis 2023-06-15, Arbitrum since 2023-03-01); post: months with activity on days 1-10 of
# 2024-04..12 and 2025-03; first: first timestamp and first-week txs. Failed txs count as activity.
post_days <- character(0)
for (m in c(format(seq(as.Date("2024-04-01"), as.Date("2024-12-01"), by = "month")), "2025-03-01")) post_days <- c(post_days, format(seq(as.Date(m), as.Date(m) + 9, by = "day")))
first_days <- format(seq(as.Date("2024-02-29"), as.Date("2024-04-04"), by = "day"))
for (ch in CHAINS) {
  outs <- file.path(DIR_RAW, sprintf(c("cohort_prior_%s.parquet", "cohort_post_%s.parquet", "cohort_first_%s.parquet"), ch))
  if (!FORCE_DOWNLOAD && all(file.exists(outs))) { cat("E ", ch, ": exists, skipped\n", sep = ""); next }
  q_out <- paste0("'", gsub("'", "''", outs), "'")
  # date partitions that exist in each table (S3 ListObjectsV2, anonymous; history before a chain's launch has no partitions)
  have <- list()
  for (tbl in c("transactions", "transactions_failed")) {
    found <- character(0); tok <- ""
    repeat {
      u <- sprintf("https://aws-public-blockchain.s3.us-east-2.amazonaws.com/?list-type=2&prefix=v1.1/sonarx/%s/%s/&delimiter=/%s", ch, tbl,
                   if (nzchar(tok)) paste0("&continuation-token=", URLencode(tok, reserved = TRUE)) else "")
      x <- paste(readLines(u, warn = FALSE), collapse = ""); found <- c(found, regmatches(x, gregexpr("date=[0-9-]{10}", x))[[1]])
      if (!grepl("<NextContinuationToken>", x)) break
      tok <- sub(".*<NextContinuationToken>(.*)</NextContinuationToken>.*", "\\1", x)
    }
    have[[tbl]] <- sub("date=", "", unique(found))
  }
  hist_days <- format(seq(as.Date(if (ch == "base") "2023-06-15" else "2023-03-01"), as.Date("2024-02-14"), by = "day"))
  src <- list()   # successful + failed txs on a set of days
  for (k in c("hist", "post", "first")) {
    d <- switch(k, hist = hist_days, post = post_days, first = first_days)
    src[[k]] <- sprintf("(SELECT FROM_ADDRESS, DATETIME FROM read_parquet([%s]) UNION ALL SELECT FROM_ADDRESS, DATETIME FROM read_parquet([%s]))",
                        paste0("'", SONARX, ch, "/transactions/date=", intersect(d, have$transactions), "/*.parquet'", collapse = ", "),
                        paste0("'", SONARX, ch, "/transactions_failed/date=", intersect(d, have$transactions_failed), "/*.parquet'", collapse = ", "))
  }
  t_start <- Sys.time(); dbf <- tempfile(fileext = ".duckdb"); con <- DBI::dbConnect(duckdb::duckdb(), dbdir = dbf); DBI::dbExecute(con, S3_INIT)
  DBI::dbExecute(con, sprintf("CREATE TABLE coh AS SELECT a, min(day) AS first_day FROM read_parquet('%s') GROUP BY a HAVING min(day) >= DATE '2024-03-01' AND min(day) <= DATE '2024-03-27'",
    gsub("'", "''", file.path(DIR_RAW, sprintf("l2_senderday_%s.parquet", ch)))))
  DBI::dbExecute(con, sprintf("COPY (SELECT DISTINCT lower(FROM_ADDRESS) AS a FROM %s WHERE lower(FROM_ADDRESS) IN (SELECT a FROM coh))
    TO %s (FORMAT PARQUET)", src$hist, q_out[1]))
  DBI::dbExecute(con, sprintf("COPY (SELECT DISTINCT lower(FROM_ADDRESS) AS a, strftime(DATETIME, '%%Y-%%m') AS ym FROM %s WHERE lower(FROM_ADDRESS) IN (SELECT a FROM coh))
    TO %s (FORMAT PARQUET)", src$post, q_out[2]))
  DBI::dbExecute(con, sprintf("COPY (SELECT a, min(dt) AS first_dt, count(*) FILTER (WHERE dt < first_dt0 + INTERVAL 7 DAY) AS n_week1
    FROM (SELECT t.*, min(dt) OVER (PARTITION BY a) AS first_dt0 FROM (SELECT lower(FROM_ADDRESS) AS a, DATETIME AS dt FROM %s) t WHERE a IN (SELECT a FROM coh)) GROUP BY a)
    TO %s (FORMAT PARQUET)", src$first, q_out[3]))
  DBI::dbDisconnect(con, shutdown = TRUE); unlink(dbf)
  cat(sprintf("E %s: %.1f min\n", ch, as.numeric(Sys.time() - t_start, units = "mins")))
}

# ---- F. entrants' first outgoing tx and first funder (entrants first seen from 03-08) ----
# "First" follows chain order (block number, then position in the block), so ties within a block are resolved the same way on every run.
win_end <- c(base = "2024-03-22", arbitrum = "2024-03-25")
for (ch in CHAINS) {
  outs <- file.path(DIR_RAW, sprintf(c("wave_first_out_%s.parquet", "wave_fund_eth_%s.parquet", "wave_fund_tok_%s.parquet"), ch))
  if (!FORCE_DOWNLOAD && all(file.exists(outs))) { cat("F ", ch, ": exists, skipped\n", sep = ""); next }
  q_out <- paste0("'", gsub("'", "''", outs), "'")
  d <- format(seq(as.Date("2024-03-06"), as.Date(win_end[[ch]]) + 1, by = "day"))
  t_start <- Sys.time(); dbf <- tempfile(fileext = ".duckdb"); con <- DBI::dbConnect(duckdb::duckdb(), dbdir = dbf); DBI::dbExecute(con, S3_INIT)
  DBI::dbExecute(con, sprintf("CREATE TABLE ent AS SELECT f.a, f.first_dt FROM read_parquet('%s') f ANTI JOIN read_parquet('%s') p USING (a) WHERE f.first_dt >= TIMESTAMP '2024-03-08' AND f.first_dt < TIMESTAMP '%s'",
    gsub("'", "''", file.path(DIR_RAW, sprintf("cohort_first_%s.parquet", ch))), gsub("'", "''", file.path(DIR_RAW, sprintf("cohort_prior_%s.parquet", ch))), win_end[[ch]]))
  DBI::dbExecute(con, sprintf("CREATE TABLE tx AS SELECT lower(FROM_ADDRESS) AS fr, lower(TO_ADDRESS) AS t, DATETIME AS dt, BLOCK_NUMBER * 100000 + TRANSACTION_INDEX AS ord, VALUE AS v,
    substr(INPUT, 1, 10) AS sel FROM read_parquet([%s])
    WHERE lower(FROM_ADDRESS) IN (SELECT a FROM ent) OR (lower(TO_ADDRESS) IN (SELECT a FROM ent) AND VALUE > 0)",
    paste0("'", SONARX, ch, "/transactions/date=", d, "/*.parquet'", collapse = ", ")))
  DBI::dbExecute(con, sprintf("COPY (SELECT e.a, e.first_dt, arg_min(o.t, o.ord) AS first_to, arg_min(o.sel, o.ord) AS first_sel FROM ent e LEFT JOIN tx o ON o.fr = e.a GROUP BY 1, 2) TO %s (FORMAT PARQUET)", q_out[1]))
  DBI::dbExecute(con, sprintf("COPY (SELECT i.t AS a, arg_min(i.fr, i.ord) AS funder FROM tx i WHERE i.t IN (SELECT a FROM ent) AND i.v > 0 GROUP BY 1) TO %s (FORMAT PARQUET)", q_out[2]))
  DBI::dbExecute(con, sprintf("COPY (SELECT lower(TO_ADDRESS) AS a, arg_min(lower(FROM_ADDRESS), BLOCK_NUMBER * 100000 + LOG_INDEX) AS tfunder
    FROM read_parquet([%s]) WHERE lower(TO_ADDRESS) IN (SELECT a FROM ent) GROUP BY 1) TO %s (FORMAT PARQUET)",
    paste0("'", SONARX, ch, "/transfers/date=", d, "/*.parquet'", collapse = ", "), q_out[3]))
  DBI::dbDisconnect(con, shutdown = TRUE); unlink(dbf)
  cat(sprintf("F %s: %.1f min\n", ch, as.numeric(Sys.time() - t_start, units = "mins")))
}

# ---- G. Base hourly txs of campaign wallets (entrants in campaign bursts) and their collectors (recipients of their plain ETH transfers) ----
out <- file.path(DIR_RAW, "base_hourly_campaign.parquet")
if (FORCE_DOWNLOAD || !file.exists(out)) {
  t_start <- Sys.time()
  X <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, "wave_first_out_base.parquet"))); setattr(X$first_dt, "tzone", "UTC")
  # campaign rule (the wave flag of 02 section C): a first-action group (recipient x method) is a burst on a day if it has >= SPIKE_MIN entrants
  # and >= SPIKE_K times its median daily count over the pre-shock days ENTRANT_WINDOW[1]..PRE_END (days without entrants count as zero)
  X[, `:=`(day = as.IDate(first_dt, tz = "UTC"), pair = paste(first_to, first_sel))]
  X <- X[day >= ENTRANT_WINDOW[1] & day <= ENTRANT_WINDOW[2]]
  n_pre <- as.integer(PRE_END - ENTRANT_WINDOW[1]) + 1L
  PR <- X[, .N, by = .(day, pair)]
  PR[, base := 0][PR[day <= PRE_END, .(b = median(c(N, rep(0L, n_pre - .N)))), by = pair], base := i.b, on = "pair"]
  X[, wave := as.integer(paste(day, pair) %in% PR[N >= SPIKE_MIN & N >= SPIKE_K * base, paste(day, pair)])]
  wallets <- X[wave == 1, .(a)]; collectors <- X[wave == 1 & first_sel == "0x", unique(first_to)]
  cat(sprintf("G: %d campaign wallets, %d collectors (%s)\n", nrow(wallets), length(collectors), paste(collectors, collapse = ", ")))
  con <- DBI::dbConnect(duckdb::duckdb()); DBI::dbExecute(con, S3_INIT); duckdb::duckdb_register(con, "wave", wallets)
  d <- format(seq(as.Date("2024-02-29"), as.Date("2024-04-16"), by = "day"))
  DBI::dbExecute(con, sprintf("COPY (SELECT date_trunc('hour', DATETIME) AS hr, count(*) AS n_campaign FROM read_parquet([%s]) WHERE lower(FROM_ADDRESS) IN (SELECT a FROM wave) OR lower(TO_ADDRESS) IN (%s)
    GROUP BY 1) TO %s (FORMAT PARQUET)", paste0("'", SONARX, "base/transactions/date=", d, "/*.parquet'", collapse = ", "), paste0("'", collectors, "'", collapse = ","),
    paste0("'", gsub("'", "''", out), "'")))
  DBI::dbDisconnect(con, shutdown = TRUE)
  cat(sprintf("G campaign activity: %.1f min\n", as.numeric(Sys.time() - t_start, units = "mins")))
} else cat("G: exists, skipped\n")

# ---- H. growthepie daily exports (all L2s) ----
dir.create(file.path(DIR_RAW, "growthepie"), showWarnings = FALSE)
for (m in c("txcount", "daa", "txcosts")) {
  f <- file.path(DIR_RAW, "growthepie", sprintf("export_%s.json", m))
  if (!FORCE_DOWNLOAD && file.exists(f)) next
  download.file(sprintf("https://api.growthepie.xyz/v1/export/%s.json", m), f, mode = "wb", quiet = TRUE, headers = c(`User-Agent` = "Mozilla/5.0")); Sys.sleep(1)
}
cat("H: growthepie exports:", paste(basename(list.files(file.path(DIR_RAW, "growthepie"))), collapse = ", "), "\n")

# ---- I. ETH/USD daily (Coinbase) ----
out <- file.path(DIR_RAW, "eth_usd_daily.csv")
if (FORCE_DOWNLOAD || !file.exists(out)) {
  j <- fromJSON("https://api.exchange.coinbase.com/products/ETH-USD/candles?granularity=86400&start=2024-02-15T00:00:00Z&end=2024-04-10T00:00:00Z")
  P <- data.table(day = as.IDate(as.POSIXct(j[, 1], origin = "1970-01-01", tz = "UTC")), low = j[, 2], high = j[, 3], open = j[, 4], close = j[, 5])[order(day)]
  stopifnot(!anyDuplicated(P$day)); fwrite(P, out); cat(sprintf("I: %d days of ETH/USD\n", nrow(P)))
} else cat("I: exists, skipped\n")

cat("\n## sessionInfo\n```\n"); print(sessionInfo()); cat("```\n"); sink()
