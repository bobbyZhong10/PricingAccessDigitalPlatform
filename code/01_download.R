# 01_download.R: public data -> data/raw. Each section is skipped if its files exist (set FORCE_DOWNLOAD = TRUE to redo).
# Sources (no keys): AWS Public Blockchain (s3://aws-public-blockchain: sonarx Base/Arbitrum, Ethereum/Bitcoin blocks), growthepie exports, Coinbase candles,
# copies of the LayerZero provisional Sybil list (Internet Archive, GitHub mirrors). The Google Trends capture is in data/external (section M).
# Raw files are aggregates computed on the fly with DuckDB; the transaction-level tables are hundreds of GB. A full download takes 4-5 hours (section T alone about 3).
# Successful (transactions) and failed (transactions_failed) tables are disjoint and are stacked.
source(here::here("code", "00_setup.R"))
sink(file.path(DIR_LOG, "01_download.md"), split = TRUE)
cat("# 01 download\nRun ", format(Sys.time(), usetz = TRUE), "\n", sep = "")
FORCE_DOWNLOAD <- FALSE
S3_INIT <- "INSTALL httpfs; LOAD httpfs; SET s3_region='us-east-2'; SET threads TO 8; SET memory_limit='10GB'; SET preserve_insertion_order = false; SET http_retries = 10; SET http_retry_wait_ms = 3000; SET http_retry_backoff = 1; SET http_timeout = 600; SET enable_progress_bar = false;"   # a request may take 10 min (large column chunks on a slow link timed out at the default 30 s); constant 3 s between retries (the default backoff x4 slept for hours); the progress bar polled S3 file lists in a loop
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
cls <- sprintf("CASE WHEN INPUT IS NULL OR length(INPUT) <= 2 THEN 'native' WHEN substr(INPUT,1,10) = '0xa9059cbb' THEN 'erc20_transfer' WHEN substr(INPUT,1,10) = '0x095ea7b3' THEN 'approve'
  WHEN substr(INPUT,1,10) IN (%s) THEN 'swap' ELSE 'other_call' END", paste0("'", SWAP_SELECTORS, "'", collapse = ","))
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
for (m in c("txcount", "daa", "txcosts", "fees", "rent_paid", "profit")) {   # fees, rent_paid (L1 costs), profit: validation V6
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

# ---- J. validation V2: entrants' first block, funders before the first outgoing tx, last ETH sweep, service degrees ----
# Entrants = wave_first_out (first outgoing tx from 03-08). First outgoing tx: successful or failed (as in cohort_first), ordered by block, then position.
# ETH funder: earliest incoming top-level ETH transfer (from 02-15) or, on Base, internal ETH transfer (traces 03-01..22; the funder is the account that
# initiated the tx), strictly before the first outgoing tx. Token funder: earliest ERC-20 transfer in an earlier block (from 02-15; mints excluded).
# Sweep: last outgoing top-level ETH transfer up to 04-15. Service degrees on 02-15..03-07, before any fee drop: distinct ETH recipients of each funder
# (internal transfers: 03-01..07) and distinct ETH senders of each sweep target. Traces are read for Base only (about 8.5 GB a day on Arbitrum).
d_ent <- format(seq(as.Date("2024-03-06"), as.Date("2024-03-26"), by = "day")); d_pre <- format(seq(PULL_START, as.Date("2024-03-07"), by = "day"))
d_tr <- format(seq(as.Date("2024-03-01"), as.Date("2024-03-22"), by = "day")); d_tok <- format(seq(PULL_START, as.Date("2024-03-26"), by = "day"))
for (ch in CHAINS) {
  outs <- file.path(DIR_RAW, sprintf(c("val_entrant_%s.parquet", "val_degree_%s.parquet"), ch))
  if (!FORCE_DOWNLOAD && all(file.exists(outs))) { cat("J ", ch, ": exists, skipped\n", sep = ""); next }
  q_out <- paste0("'", gsub("'", "''", outs), "'")
  pq <- list()   # parquet file lists: tx, failed tx, transfers, pre-period tx, traces, pre-period traces
  pq$tx <- paste0("[", paste0("'", SONARX, ch, "/transactions/date=", days_main, "/*.parquet'", collapse = ", "), "]")
  pq$txf <- paste0("[", paste0("'", SONARX, ch, "/transactions_failed/date=", d_ent, "/*.parquet'", collapse = ", "), "]")
  pq$tok <- paste0("[", paste0("'", SONARX, ch, "/transfers/date=", d_tok, "/*.parquet'", collapse = ", "), "]")
  pq$pre <- paste0("[", paste0("'", SONARX, ch, "/transactions/date=", d_pre, "/*.parquet'", collapse = ", "), "]")
  pq$tr <- paste0("[", paste0("'", SONARX, ch, "/traces/date=", d_tr, "/*.parquet'", collapse = ", "), "]")
  pq$trpre <- paste0("[", paste0("'", SONARX, ch, "/traces/date=", d_tr[1:7], "/*.parquet'", collapse = ", "), "]")
  t_start <- Sys.time(); dbf <- tempfile(fileext = ".duckdb"); con <- DBI::dbConnect(duckdb::duckdb(), dbdir = dbf); DBI::dbExecute(con, S3_INIT)
  DBI::dbExecute(con, sprintf("CREATE TABLE ent AS SELECT a FROM read_parquet('%s')", gsub("'", "''", file.path(DIR_RAW, sprintf("wave_first_out_%s.parquet", ch)))))
  DBI::dbExecute(con, sprintf("CREATE TABLE tx AS SELECT lower(FROM_ADDRESS) AS fr, lower(TO_ADDRESS) AS t, BLOCK_NUMBER * 100000 + TRANSACTION_INDEX AS ord, VALUE AS v
    FROM read_parquet(%s) WHERE lower(FROM_ADDRESS) IN (SELECT a FROM ent) OR (VALUE > 0 AND lower(TO_ADDRESS) IN (SELECT a FROM ent))", pq$tx))
  DBI::dbExecute(con, sprintf("CREATE TABLE fo AS SELECT a, min(ord) AS ord0 FROM (SELECT fr AS a, ord FROM tx WHERE fr IN (SELECT a FROM ent) UNION ALL
    SELECT lower(FROM_ADDRESS), BLOCK_NUMBER * 100000 + TRANSACTION_INDEX FROM read_parquet(%s) WHERE lower(FROM_ADDRESS) IN (SELECT a FROM ent)) GROUP BY a", pq$txf))
  DBI::dbExecute(con, "CREATE TABLE ftx AS SELECT i.t AS a, arg_min(i.fr, i.ord) AS f_tx, min(i.ord) AS ord_tx FROM tx i JOIN fo ON i.t = fo.a WHERE i.v > 0 AND i.ord < fo.ord0 AND i.fr <> i.t GROUP BY 1")
  DBI::dbExecute(con, sprintf("CREATE TABLE tk AS SELECT lower(TO_ADDRESS) AS t, lower(FROM_ADDRESS) AS fr, BLOCK_NUMBER * 100000 + LOG_INDEX AS ord FROM read_parquet(%s)
    WHERE lower(TO_ADDRESS) IN (SELECT a FROM ent) AND lower(FROM_ADDRESS) <> '0x0000000000000000000000000000000000000000'", pq$tok))
  DBI::dbExecute(con, "CREATE TABLE ftk AS SELECT k.t AS a, arg_min(k.fr, k.ord) AS f_tok FROM tk k JOIN fo ON k.t = fo.a WHERE floor(k.ord / 100000) < floor(fo.ord0 / 100000) AND k.fr <> k.t GROUP BY 1")
  DBI::dbExecute(con, "CREATE TABLE sw AS SELECT fr AS a, arg_max(t, ord) AS sweep_to FROM tx WHERE fr IN (SELECT a FROM ent) AND v > 0 AND t IS NOT NULL AND t <> fr GROUP BY 1")
  if (ch == "base") {
    DBI::dbExecute(con, sprintf("CREATE TABLE tr AS SELECT lower(TO_ADDRESS) AS t, lower(TRANSACTION_FROM) AS fr, BLOCK_NUMBER * 100000 + TRANSACTION_INDEX AS ord FROM read_parquet(%s)
      WHERE coalesce(PATH, '') <> '' AND VALUE > 0 AND lower(TO_ADDRESS) IN (SELECT a FROM ent)", pq$tr))
    DBI::dbExecute(con, "CREATE TABLE ftr AS SELECT r.t AS a, arg_min(r.fr, r.ord) AS f_tr, min(r.ord) AS ord_tr FROM tr r JOIN fo ON r.t = fo.a WHERE r.ord < fo.ord0 AND r.fr <> r.t GROUP BY 1")
  } else DBI::dbExecute(con, "CREATE TABLE ftr AS SELECT NULL::VARCHAR AS a, NULL::VARCHAR AS f_tr, NULL::DECIMAL(38,0) AS ord_tr WHERE false")
  # ETH funder = the earlier of the top-level and the internal funder
  DBI::dbExecute(con, sprintf("COPY (SELECT fo.a, floor(fo.ord0 / 100000) AS blk0, CASE WHEN ftr.f_tr IS NOT NULL AND (ftx.ord_tx IS NULL OR ftr.ord_tr < ftx.ord_tx) THEN ftr.f_tr ELSE ftx.f_tx END AS f_eth,
    CASE WHEN ftr.f_tr IS NOT NULL AND (ftx.ord_tx IS NULL OR ftr.ord_tr < ftx.ord_tx) THEN 'internal' WHEN ftx.f_tx IS NOT NULL THEN 'top-level' END AS f_eth_via, ftk.f_tok, sw.sweep_to
    FROM fo LEFT JOIN ftx USING (a) LEFT JOIN ftr USING (a) LEFT JOIN ftk USING (a) LEFT JOIN sw USING (a)) TO %s (FORMAT PARQUET)", q_out[1]))
  # service degrees before any fee drop
  DBI::dbExecute(con, sprintf("CREATE TABLE cand AS SELECT DISTINCT f_eth AS addr, 'funder' AS role FROM read_parquet(%s) WHERE f_eth IS NOT NULL
    UNION SELECT DISTINCT sweep_to, 'sweep' FROM read_parquet(%s) WHERE sweep_to IS NOT NULL", q_out[1], q_out[1]))
  DBI::dbExecute(con, sprintf("CREATE TABLE pre AS SELECT lower(FROM_ADDRESS) AS fr, lower(TO_ADDRESS) AS t FROM read_parquet(%s) WHERE VALUE > 0 AND
    (lower(FROM_ADDRESS) IN (SELECT addr FROM cand WHERE role = 'funder') OR lower(TO_ADDRESS) IN (SELECT addr FROM cand WHERE role = 'sweep'))", pq$pre))
  if (ch == "base") DBI::dbExecute(con, sprintf("INSERT INTO pre SELECT lower(TRANSACTION_FROM), lower(TO_ADDRESS) FROM read_parquet(%s) WHERE coalesce(PATH, '') <> '' AND VALUE > 0 AND
    lower(TRANSACTION_FROM) IN (SELECT addr FROM cand WHERE role = 'funder')", pq$trpre))
  DBI::dbExecute(con, sprintf("COPY (SELECT c.addr, c.role, coalesce(CASE WHEN c.role = 'funder' THEN o.n ELSE i.n END, 0) AS deg_pre FROM cand c
    LEFT JOIN (SELECT fr AS addr, count(DISTINCT t) AS n FROM pre GROUP BY 1) o ON c.addr = o.addr LEFT JOIN (SELECT t AS addr, count(DISTINCT fr) AS n FROM pre GROUP BY 1) i ON c.addr = i.addr)
    TO %s (FORMAT PARQUET)", q_out[2]))
  DBI::dbDisconnect(con, shutdown = TRUE); unlink(dbf)
  cat(sprintf("J %s: %.1f min\n", ch, as.numeric(Sys.time() - t_start, units = "mins")))
}

# ---- K. validation V1: LayerZero provisional Sybil list (May 2024), two copies ----
# The official repository (LayerZero-Labs/sybil-report) has been removed. Copies: the Internet Archive capture of its initialList.txt (2024-05-23) and two
# GitHub mirrors. The ibuyshite mirror (lz_copy) matches the archive; the Compich mirror (lz_mirror) turned out to hold a different, larger list (reported, not used).
# Each file goes to its own directory and is only read as text (addresses are extracted in 02).
LZ <- data.table(dir = c("lz_archive", "lz_mirror", "lz_copy"),
                 url = c("https://web.archive.org/web/20240523230204id_/https://raw.githubusercontent.com/LayerZero-Labs/sybil-report/main/initialList.txt",
                         "https://raw.githubusercontent.com/Compich/LayerZero-Sybil-List/main/LayerZeroSybilList.txt",
                         "https://raw.githubusercontent.com/ibuyshite/LayerZero-Sybil/main/LO%20Report"))
for (i in seq_len(nrow(LZ))) {
  dir.create(file.path(DIR_RAW, LZ$dir[i]), showWarnings = FALSE); f <- file.path(DIR_RAW, LZ$dir[i], URLdecode(basename(LZ$url[i])))
  if (!FORCE_DOWNLOAD && file.exists(f)) { cat("K ", LZ$dir[i], ": exists, skipped\n", sep = ""); next }
  options(timeout = 1200); download.file(LZ$url[i], f, mode = "wb", quiet = TRUE); Sys.sleep(5)
  cat(sprintf("K %s: %s, %.1f MB, md5 %s\n", LZ$dir[i], basename(f), file.size(f) / 1e6, tools::md5sum(f)))
}

# ---- L. validation V4: Base first-action targets with >= SPIKE_MIN entrants on some day: contract or not, token standard (logs 03-13..22) ----
# A target that emitted logs is a contract; Transfer events with a fourth topic (token id) mark ERC-721, without it ERC-20.
out <- file.path(DIR_RAW, "val_targets_base.parquet")
if (FORCE_DOWNLOAD || !file.exists(out)) {
  t_start <- Sys.time()
  X <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, "wave_first_out_base.parquet"))); setattr(X$first_dt, "tzone", "UTC")
  tg <- X[!is.na(first_to), .N, by = .(day = as.IDate(first_dt, tz = "UTC"), first_to)][N >= SPIKE_MIN, unique(first_to)]
  con <- DBI::dbConnect(duckdb::duckdb()); DBI::dbExecute(con, S3_INIT)
  d <- format(seq(as.Date("2024-03-13"), as.Date("2024-03-22"), by = "day"))
  DBI::dbExecute(con, sprintf("COPY (SELECT t.addr, coalesce(l.n_logs, 0) AS n_logs, coalesce(l.n_721, 0) AS n_721, coalesce(l.n_20, 0) AS n_20 FROM (SELECT unnest([%s]) AS addr) t LEFT JOIN
    (SELECT lower(ADDRESS) AS addr, count(*) AS n_logs, count(*) FILTER (WHERE TOPIC1 = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef' AND coalesce(TOPIC4, '') <> '') AS n_721,
      count(*) FILTER (WHERE TOPIC1 = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef' AND coalesce(TOPIC4, '') = '') AS n_20
     FROM read_parquet([%s]) WHERE lower(ADDRESS) IN (%s) GROUP BY 1) l USING (addr)) TO %s (FORMAT PARQUET)",
    paste0("'", tg, "'", collapse = ", "), paste0("'", SONARX, "base/logs/date=", d, "/*.parquet'", collapse = ", "), paste0("'", tg, "'", collapse = ", "), paste0("'", gsub("'", "''", out), "'")))
  DBI::dbDisconnect(con, shutdown = TRUE)
  cat(sprintf("L: %d targets, %.1f min\n", length(tg), as.numeric(Sys.time() - t_start, units = "mins")))
} else cat("L: exists, skipped\n")

# ---- M. validation V5: Google Trends, daily 2024-02-15..04-15 (browser capture on 2026-10-12) ----
# Google Trends has no keyless API and rate-limits scripted requests, so the series were read in a browser session from trends.google.com (explore and
# widgetdata/multiline responses; hl = en-US, tz = 0, worldwide, all categories, web search) and saved as data/external/gtrends_daily.csv (tracked in git; see data/external/README.md) with columns
# request, keyword, date, value, partial. request = "shared": one request with "Base airdrop", "Arbitrum airdrop", "Dencun", "EIP-4844" on a common 0-100
# scale; request = "single": one request per term (own scale; "EIP-4844" alone returned no series). Values are sampled and rounded by Google, so a
# new capture can differ slightly.
cat(sprintf("M: Google Trends capture %s\n", if (file.exists(here("data", "external", "gtrends_daily.csv"))) "present" else "MISSING (capture it as described above)"))

# ---- N. second Base event: the block gas limit was raised 60M -> 75M (05-28 19:00 UTC) and 75M -> 90M (05-30 20:00 UTC); Arbitrum as the comparison chain ----
# New sender = no outgoing tx (successful or failed) on the chain since 2024-02-15 (section A sender-days, then transactions from 04-16).
# Hourly window MAY_PULL: txs, fees, distinct senders, new senders. Entrants = new senders whose first outgoing tx is in MAY_WINDOW; first-week txs.
# Base only: funders, sweeps and service degrees as in section J, moved to May: ETH funder from 05-01 (internal transfers 05-15..06-05), sweep up to 06-30,
# service degrees on 05-01..05-20 (internal: 05-15..05-20); later activity on days 1-10 of RETENTION_MONTHS_MAY.
for (ch in CHAINS) {
  outs <- file.path(DIR_RAW, sprintf(c("may_hourly_%s.parquet", "may_entrant_%s.parquet", "may_degree_%s.parquet", "may_post_%s.parquet"), ch))
  if (ch == "arbitrum") outs <- outs[1:2]   # comparison chain: activity and entrants only
  if (!FORCE_DOWNLOAD && all(file.exists(outs))) { cat("N ", ch, ": exists, skipped\n", sep = ""); next }
  q_out <- paste0("'", gsub("'", "''", outs), "'")
  post_d <- character(0); for (m in RETENTION_MONTHS_MAY) post_d <- c(post_d, format(seq(as.Date(paste0(m, "-01")), as.Date(paste0(m, "-10")), by = "day")))
  fl <- list()   # parquet file lists by purpose
  for (k in c("seen", "seenf", "hour", "hourf", "fund", "tr", "sweep", "pre", "trpre", "post", "postf")) {
    d <- switch(k, seen = , seenf = format(seq(as.Date("2024-04-16"), MAY_PULL[1] - 1, by = "day")), hour = , hourf = format(seq(MAY_PULL[1], MAY_PULL[2], by = "day")),
                fund = format(seq(as.Date("2024-05-01"), as.Date(MAY_WINDOW[2]) + 1, by = "day")), tr = format(seq(as.Date("2024-05-15"), as.Date(MAY_WINDOW[2]) + 1, by = "day")),
                sweep = format(seq(as.Date(MAY_WINDOW[1]), as.Date("2024-06-30"), by = "day")), pre = format(seq(as.Date("2024-05-01"), as.Date("2024-05-20"), by = "day")),
                trpre = format(seq(as.Date("2024-05-15"), as.Date("2024-05-20"), by = "day")), post = , postf = post_d)
    tbl <- switch(k, seenf = , hourf = , postf = "transactions_failed", tr = , trpre = "traces", "transactions")
    fl[[k]] <- paste0("[", paste0("'", SONARX, ch, "/", tbl, "/date=", d, "/*.parquet'", collapse = ", "), "]")
  }
  t_start <- Sys.time(); dbf <- tempfile(fileext = ".duckdb"); con <- DBI::dbConnect(duckdb::duckdb(), dbdir = dbf); DBI::dbExecute(con, S3_INIT)
  DBI::dbExecute(con, sprintf("CREATE TABLE seen AS SELECT DISTINCT a FROM read_parquet('%s') UNION SELECT DISTINCT lower(FROM_ADDRESS) FROM read_parquet(%s)
    UNION SELECT DISTINCT lower(FROM_ADDRESS) FROM read_parquet(%s)", gsub("'", "''", file.path(DIR_RAW, sprintf("l2_senderday_%s.parquet", ch))), fl$seen, fl$seenf))
  DBI::dbExecute(con, sprintf("CREATE TABLE tx AS SELECT lower(FROM_ADDRESS) AS a, lower(TO_ADDRESS) AS t, substr(INPUT, 1, 10) AS sel, DATETIME AS dt, BLOCK_NUMBER * 100000 + TRANSACTION_INDEX AS ord,
    TRANSACTION_FEE AS fee, 0 AS failed FROM read_parquet(%s) WHERE lower(FROM_ADDRESS) <> '%s' UNION ALL SELECT lower(FROM_ADDRESS), lower(TO_ADDRESS), substr(INPUT, 1, 10), DATETIME,
    BLOCK_NUMBER * 100000 + TRANSACTION_INDEX, TRANSACTION_FEE, 1 FROM read_parquet(%s) WHERE lower(FROM_ADDRESS) <> '%s'", fl$hour, SYSTEM_SENDERS[[ch]], fl$hourf, SYSTEM_SENDERS[[ch]]))
  DBI::dbExecute(con, "CREATE TABLE fs AS SELECT a, min(ord) AS ord0, arg_min(t, ord) AS first_to, arg_min(sel, ord) AS first_sel, min(dt) AS first_dt FROM tx WHERE a NOT IN (SELECT a FROM seen) GROUP BY a")
  DBI::dbExecute(con, sprintf("COPY (SELECT h.hr, h.n, h.n_failed, h.fee, h.n_senders, coalesce(s.new_senders, 0) AS new_senders FROM
    (SELECT date_trunc('hour', dt) AS hr, count(*) AS n, sum(failed) AS n_failed, sum(fee) AS fee, count(DISTINCT a) AS n_senders FROM tx GROUP BY 1) h
    LEFT JOIN (SELECT date_trunc('hour', first_dt) AS hr, count(*) AS new_senders FROM fs GROUP BY 1) s USING (hr) ORDER BY h.hr) TO %s (FORMAT PARQUET)", q_out[1]))
  DBI::dbExecute(con, sprintf("CREATE TABLE ent AS SELECT * FROM fs WHERE first_dt >= TIMESTAMP '%s' AND first_dt < TIMESTAMP '%s'", MAY_WINDOW[1], MAY_WINDOW[2] + 1))
  DBI::dbExecute(con, "CREATE TABLE wk AS SELECT x.a, count(*) AS n_week1 FROM tx x JOIN ent e ON x.a = e.a WHERE x.dt < e.first_dt + INTERVAL 7 DAY GROUP BY 1")
  if (ch == "arbitrum") {
    DBI::dbExecute(con, sprintf("COPY (SELECT e.a, e.first_dt, floor(e.ord0 / 100000) AS blk0, e.first_to, e.first_sel, coalesce(w.n_week1, 0) AS n_week1 FROM ent e LEFT JOIN wk w USING (a))
      TO %s (FORMAT PARQUET)", q_out[2]))
    DBI::dbDisconnect(con, shutdown = TRUE); unlink(dbf); cat(sprintf("N %s: %.1f min\n", ch, as.numeric(Sys.time() - t_start, units = "mins"))); next
  }
  DBI::dbExecute(con, sprintf("CREATE TABLE fin AS SELECT lower(FROM_ADDRESS) AS fr, lower(TO_ADDRESS) AS t, BLOCK_NUMBER * 100000 + TRANSACTION_INDEX AS ord FROM read_parquet(%s)
    WHERE VALUE > 0 AND lower(TO_ADDRESS) IN (SELECT a FROM ent)", fl$fund))
  DBI::dbExecute(con, "CREATE TABLE ftx AS SELECT i.t AS a, arg_min(i.fr, i.ord) AS f_tx, min(i.ord) AS ord_tx FROM fin i JOIN ent e ON i.t = e.a WHERE i.ord < e.ord0 AND i.fr <> i.t GROUP BY 1")
  DBI::dbExecute(con, sprintf("CREATE TABLE tr AS SELECT lower(TO_ADDRESS) AS t, lower(TRANSACTION_FROM) AS fr, BLOCK_NUMBER * 100000 + TRANSACTION_INDEX AS ord FROM read_parquet(%s)
    WHERE coalesce(PATH, '') <> '' AND VALUE > 0 AND lower(TO_ADDRESS) IN (SELECT a FROM ent)", fl$tr))
  DBI::dbExecute(con, "CREATE TABLE ftr AS SELECT r.t AS a, arg_min(r.fr, r.ord) AS f_tr, min(r.ord) AS ord_tr FROM tr r JOIN ent e ON r.t = e.a WHERE r.ord < e.ord0 AND r.fr <> r.t GROUP BY 1")
  DBI::dbExecute(con, sprintf("CREATE TABLE sw AS SELECT lower(FROM_ADDRESS) AS a, arg_max(lower(TO_ADDRESS), BLOCK_NUMBER * 100000 + TRANSACTION_INDEX) AS sweep_to FROM read_parquet(%s)
    WHERE VALUE > 0 AND lower(FROM_ADDRESS) IN (SELECT a FROM ent) AND TO_ADDRESS IS NOT NULL AND lower(TO_ADDRESS) <> lower(FROM_ADDRESS) GROUP BY 1", fl$sweep))
  DBI::dbExecute(con, sprintf("COPY (SELECT e.a, e.first_dt, floor(e.ord0 / 100000) AS blk0, e.first_to, e.first_sel, coalesce(w.n_week1, 0) AS n_week1,
    CASE WHEN ftr.f_tr IS NOT NULL AND (ftx.ord_tx IS NULL OR ftr.ord_tr < ftx.ord_tx) THEN ftr.f_tr ELSE ftx.f_tx END AS f_eth,
    CASE WHEN ftr.f_tr IS NOT NULL AND (ftx.ord_tx IS NULL OR ftr.ord_tr < ftx.ord_tx) THEN 'internal' WHEN ftx.f_tx IS NOT NULL THEN 'top-level' END AS f_eth_via, sw.sweep_to
    FROM ent e LEFT JOIN wk w USING (a) LEFT JOIN ftx USING (a) LEFT JOIN ftr USING (a) LEFT JOIN sw USING (a)) TO %s (FORMAT PARQUET)", q_out[2]))
  DBI::dbExecute(con, sprintf("CREATE TABLE cand AS SELECT DISTINCT f_eth AS addr, 'funder' AS role FROM read_parquet(%s) WHERE f_eth IS NOT NULL
    UNION SELECT DISTINCT sweep_to, 'sweep' FROM read_parquet(%s) WHERE sweep_to IS NOT NULL", q_out[2], q_out[2]))
  DBI::dbExecute(con, sprintf("CREATE TABLE pre AS SELECT lower(FROM_ADDRESS) AS fr, lower(TO_ADDRESS) AS t FROM read_parquet(%s) WHERE VALUE > 0 AND
    (lower(FROM_ADDRESS) IN (SELECT addr FROM cand WHERE role = 'funder') OR lower(TO_ADDRESS) IN (SELECT addr FROM cand WHERE role = 'sweep'))", fl$pre))
  DBI::dbExecute(con, sprintf("INSERT INTO pre SELECT lower(TRANSACTION_FROM), lower(TO_ADDRESS) FROM read_parquet(%s) WHERE coalesce(PATH, '') <> '' AND VALUE > 0 AND
    lower(TRANSACTION_FROM) IN (SELECT addr FROM cand WHERE role = 'funder')", fl$trpre))
  DBI::dbExecute(con, sprintf("COPY (SELECT c.addr, c.role, coalesce(CASE WHEN c.role = 'funder' THEN o.n ELSE i.n END, 0) AS deg_pre FROM cand c
    LEFT JOIN (SELECT fr AS addr, count(DISTINCT t) AS n FROM pre GROUP BY 1) o ON c.addr = o.addr LEFT JOIN (SELECT t AS addr, count(DISTINCT fr) AS n FROM pre GROUP BY 1) i ON c.addr = i.addr)
    TO %s (FORMAT PARQUET)", q_out[3]))
  DBI::dbExecute(con, sprintf("COPY (SELECT DISTINCT lower(FROM_ADDRESS) AS a, strftime(DATETIME, '%%Y-%%m') AS ym FROM read_parquet(%s) WHERE lower(FROM_ADDRESS) IN (SELECT a FROM ent)
    UNION SELECT DISTINCT lower(FROM_ADDRESS), strftime(DATETIME, '%%Y-%%m') FROM read_parquet(%s) WHERE lower(FROM_ADDRESS) IN (SELECT a FROM ent)) TO %s (FORMAT PARQUET)", fl$post, fl$postf, q_out[4]))
  DBI::dbDisconnect(con, shutdown = TRUE); unlink(dbf)
  cat(sprintf("N %s: %.1f min\n", ch, as.numeric(Sys.time() - t_start, units = "mins")))
}

# ---- O. tokens and ETH received by Base window entrants after entry (transfers 03-08..04-15), and transfers sent by the largest burst target ----
# Native ETH appears with token address 0xeee...e. The filter on the entrant's first block is applied in 02.
out <- file.path(DIR_RAW, "val_received_base.parquet")
if (FORCE_DOWNLOAD || !file.exists(out)) {
  t_start <- Sys.time(); dbf <- tempfile(fileext = ".duckdb"); con <- DBI::dbConnect(duckdb::duckdb(), dbdir = dbf); DBI::dbExecute(con, S3_INIT)
  DBI::dbExecute(con, sprintf("CREATE TABLE ent AS SELECT a, blk0 FROM read_parquet('%s')", gsub("'", "''", file.path(DIR_RAW, "val_entrant_base.parquet"))))
  DBI::dbExecute(con, sprintf("COPY (SELECT lower(TO_ADDRESS) AS a, lower(FROM_ADDRESS) AS fr, lower(TOKEN_ADDRESS) AS tok, BLOCK_NUMBER AS blk, VALUE AS v FROM read_parquet([%s])
    WHERE lower(TO_ADDRESS) IN (SELECT a FROM ent) OR lower(FROM_ADDRESS) = '0xfb10c144539af9a7b905a28f8ad07fb0cf85ae50') TO '%s' (FORMAT PARQUET)",
    paste0("'", SONARX, "base/transfers/date=", format(seq(as.Date("2024-03-08"), as.Date("2024-04-15"), by = "day")), "/*.parquet'", collapse = ", "), gsub("'", "''", out)))
  DBI::dbDisconnect(con, shutdown = TRUE); unlink(dbf)
  cat(sprintf("O: %.1f min\n", as.numeric(Sys.time() - t_start, units = "mins")))
} else cat("O: exists, skipped\n")

# ---- Q. Base blocks in the May window: hourly block gas limit and median L2 base fee per gas (the price lever the gas-limit increase moved) ----
out <- file.path(DIR_RAW, "may_blocks_base.parquet")
if (FORCE_DOWNLOAD || !file.exists(out)) {
  t_start <- Sys.time(); con <- DBI::dbConnect(duckdb::duckdb()); DBI::dbExecute(con, S3_INIT)
  DBI::dbExecute(con, sprintf("COPY (SELECT date_trunc('hour', DATETIME) AS hr, min(GAS_LIMIT) AS gas_limit_min, max(GAS_LIMIT) AS gas_limit_max, median(BASE_FEE_PER_GAS) / 1e9 AS base_fee_gwei,
    avg(GAS_USED) AS gas_used, count(*) AS blocks FROM read_parquet([%s]) GROUP BY 1 ORDER BY 1) TO '%s' (FORMAT PARQUET)",
    paste0("'", SONARX, "base/blocks/date=", format(seq(MAY_PULL[1], MAY_PULL[2], by = "day")), "/*.parquet'", collapse = ", "), gsub("'", "''", out)))
  DBI::dbDisconnect(con, shutdown = TRUE)
  cat(sprintf("Q: %.1f min\n", as.numeric(Sys.time() - t_start, units = "mins")))
} else cat("Q: exists, skipped\n")

# ---- R. hourly fee quantiles: the fee a typical transaction pays (successful txs with a positive fee, system sender excluded), both chains, ----
# March pull (PULL_START..PULL_END) and May pull (MAY_PULL). Fees in ETH. The hourly mean (section A) is dominated by a few high-priority txs once fees are cents.
out <- file.path(DIR_RAW, "fee_quantiles_hourly.parquet")
if (FORCE_DOWNLOAD || !file.exists(out)) {
  t_start <- Sys.time(); con <- DBI::dbConnect(duckdb::duckdb()); DBI::dbExecute(con, S3_INIT)
  FQ <- list()
  for (ch in CHAINS) {
    d <- format(c(seq(PULL_START, PULL_END, by = "day"), seq(MAY_PULL[1], MAY_PULL[2], by = "day")))
    FQ[[ch]] <- as.data.table(DBI::dbGetQuery(con, sprintf("SELECT date_trunc('hour', DATETIME) AS hr, count(*) AS n_paid, quantile_cont(TRANSACTION_FEE, 0.25) AS p25,
      median(TRANSACTION_FEE) AS p50, quantile_cont(TRANSACTION_FEE, 0.75) AS p75 FROM read_parquet([%s]) WHERE TRANSACTION_FEE > 0 AND lower(FROM_ADDRESS) <> '%s' GROUP BY 1 ORDER BY 1",
      paste0("'", SONARX, ch, "/transactions/date=", d, "/*.parquet'", collapse = ", "), SYSTEM_SENDERS[[ch]])))[, chain := ch]
  }
  DBI::dbDisconnect(con, shutdown = TRUE)
  nanoparquet::write_parquet(as.data.frame(rbindlist(FQ)), out)
  cat(sprintf("R: %.1f min\n", as.numeric(Sys.time() - t_start, units = "mins")))
} else cat("R: exists, skipped\n")

# ---- P. ETH/USD daily (Coinbase) for the second Base event, 2024-05-01..06-30 ----
out <- file.path(DIR_RAW, "eth_usd_daily_may.csv")
if (FORCE_DOWNLOAD || !file.exists(out)) {
  j <- fromJSON("https://api.exchange.coinbase.com/products/ETH-USD/candles?granularity=86400&start=2024-05-01T00:00:00Z&end=2024-06-30T00:00:00Z")
  P <- data.table(day = as.IDate(as.POSIXct(j[, 1], origin = "1970-01-01", tz = "UTC")), low = j[, 2], high = j[, 3], open = j[, 4], close = j[, 5])[order(day)]
  stopifnot(!anyDuplicated(P$day)); fwrite(P, out); cat(sprintf("P: %d days of ETH/USD\n", nrow(P)))
} else cat("P: exists, skipped\n")

# ---- S. what it cost to fund a Base window entrant: internal ETH transfers received, with the fee of the funding tx (traces and transactions 03-06..21) ----
# Section J keeps only who funded each entrant, and the transfers table (section O) holds top-level transfers only. Here: every internal ETH transfer
# (trace with a non-empty PATH and VALUE > 0) to a Base window entrant (wave_first_out), with the initiating account, the contract that sent it, the amount
# (ETH), the fee of its transaction (ETH) and the number of window entrants that transaction paid. The filter on the entrant's first block is applied in 02.
out <- file.path(DIR_RAW, "val_internal_base.parquet")
if (FORCE_DOWNLOAD || !file.exists(out)) {
  t_start <- Sys.time(); dbf <- tempfile(fileext = ".duckdb"); con <- DBI::dbConnect(duckdb::duckdb(), dbdir = dbf); DBI::dbExecute(con, S3_INIT)
  d <- format(seq(as.Date("2024-03-06"), as.Date("2024-03-21"), by = "day"))
  DBI::dbExecute(con, sprintf("CREATE TABLE ent AS SELECT a FROM read_parquet('%s')", gsub("'", "''", file.path(DIR_RAW, "wave_first_out_base.parquet"))))
  DBI::dbExecute(con, sprintf("CREATE TABLE tr AS SELECT lower(TO_ADDRESS) AS a, lower(TRANSACTION_FROM) AS init, lower(FROM_ADDRESS) AS src, TRANSACTION_HASH AS h,
    BLOCK_NUMBER * 100000 + TRANSACTION_INDEX AS ord, VALUE AS v FROM read_parquet([%s]) WHERE coalesce(PATH, '') <> '' AND VALUE > 0 AND lower(TO_ADDRESS) IN (SELECT a FROM ent)",
    paste0("'", SONARX, "base/traces/date=", d, "/*.parquet'", collapse = ", ")))
  DBI::dbExecute(con, sprintf("CREATE TABLE fx AS SELECT TRANSACTION_HASH AS h, TRANSACTION_FEE AS tx_fee FROM read_parquet([%s]) WHERE TRANSACTION_HASH IN (SELECT DISTINCT h FROM tr)",
    paste0("'", SONARX, "base/transactions/date=", d, "/*.parquet'", collapse = ", ")))
  DBI::dbExecute(con, sprintf("COPY (SELECT tr.a, tr.init, tr.src, tr.ord, tr.v, fx.tx_fee, n.n_paid FROM tr LEFT JOIN fx USING (h)
    LEFT JOIN (SELECT h, count(DISTINCT a) AS n_paid FROM tr GROUP BY 1) n USING (h)) TO '%s' (FORMAT PARQUET)", gsub("'", "''", out)))
  DBI::dbDisconnect(con, shutdown = TRUE); unlink(dbf)
  cat(sprintf("S: %.1f min\n", as.numeric(Sys.time() - t_start, units = "mins")))
} else cat("S: exists, skipped\n")

# ---- T. long series of new addresses, both chains, LONG_START..LONG_END (fee regimes and placebo dates, 06 section K) ----
# A sender is new on day d if its first outgoing tx on d (successful or failed; system sender excluded) follows LONG_LOOKBACK days without one on the chain
# (the lookback reads from LONG_START - LONG_LOOKBACK). Kept per day: new addresses by first-action group (recipient x 4-byte selector of the day's first tx,
# ordered by block and position), groups with fewer than 10 new addresses pooled (first_to and first_sel NA); n_heavy = new addresses with >= BOT_MIN_WEEK1
# txs that day; and the day's senders. Senders are tracked by a 64-bit hash of the address, one day at a time, in a file-backed DuckDB that keeps each
# sender's last active day within the lookback; lookback days before LONG_START read the sender column only. About 4-40 s a day.
# The DuckDB file (data/raw/long_state_<chain>.duckdb) is kept until the chain is done: an interrupted run resumes after the last day it completed.
# Comparison chain LONG_CONTROL (Ethereum L1, v1.0 eth tables): one table with successful and failed txs, no system sender; its method selector is read only
# if LONG_CONTROL_SELECTOR (otherwise first_sel is NA and groups are recipients).
for (ch in c(CHAINS, LONG_CONTROL)) {
  outs <- file.path(DIR_RAW, sprintf(c("long_entrants_%s.parquet", "long_senders_%s.parquet"), ch))
  if (!FORCE_DOWNLOAD && all(file.exists(outs))) { cat("T ", ch, ": exists, skipped\n", sep = ""); next }
  t_start <- Sys.time(); dbf <- file.path(DIR_RAW, sprintf("long_state_%s.duckdb", ch)); con <- DBI::dbConnect(duckdb::duckdb(), dbdir = dbf); DBI::dbExecute(con, S3_INIT)
  d0 <- LONG_START - LONG_LOOKBACK
  if ("recent" %in% DBI::dbListTables(con)) {   # resume: drop rows of a day that was not finished, continue after the last finished day
    last <- as.Date(DBI::dbGetQuery(con, "SELECT max(day) AS d FROM recent")$d)
    if (!is.na(last)) { d0 <- last + 1; DBI::dbExecute(con, sprintf("DELETE FROM grp WHERE day > DATE '%s'", last)); DBI::dbExecute(con, sprintf("DELETE FROM snd WHERE day > DATE '%s'", last)) }
    cat(sprintf("T %s: resuming at %s\n", ch, d0))
  } else {
    DBI::dbExecute(con, "CREATE TABLE recent (h UBIGINT, day DATE)")
    DBI::dbExecute(con, "CREATE TABLE grp (day DATE, first_to VARCHAR, first_sel VARCHAR, n BIGINT, n_heavy BIGINT)")
    DBI::dbExecute(con, "CREATE TABLE snd (day DATE, senders BIGINT, new_senders BIGINT)")
  }
  for (d in format(seq(d0, LONG_END, by = "day"))) {
    if (ch == LONG_CONTROL) {
      src <- sprintf("read_parquet('s3://aws-public-blockchain/v1.0/eth/transactions/date=%s/*.parquet')", d)
      if (as.Date(d) < LONG_START) {
        DBI::dbExecute(con, sprintf("CREATE OR REPLACE TABLE ds AS SELECT DISTINCT hash(lower(from_address)) AS h FROM %s", src))
      } else DBI::dbExecute(con, sprintf("CREATE OR REPLACE TABLE ds AS SELECT hash(lower(from_address)) AS h, arg_min(lower(to_address), block_number * 100000 + transaction_index) AS first_to,
        arg_min(%s, block_number * 100000 + transaction_index) AS first_sel, count(*) AS n FROM %s GROUP BY 1", if (LONG_CONTROL_SELECTOR) "substr(input, 1, 10)" else "NULL::VARCHAR", src))
    } else if (as.Date(d) < LONG_START) {   # lookback only: who sent a tx that day
      DBI::dbExecute(con, sprintf("CREATE OR REPLACE TABLE ds AS SELECT DISTINCT hash(lower(FROM_ADDRESS)) AS h FROM read_parquet(['%s%s/transactions/date=%s/*.parquet',
        '%s%s/transactions_failed/date=%s/*.parquet'], union_by_name = true) WHERE lower(FROM_ADDRESS) <> '%s'", SONARX, ch, d, SONARX, ch, d, SYSTEM_SENDERS[[ch]]))
    } else DBI::dbExecute(con, sprintf("CREATE OR REPLACE TABLE ds AS SELECT h, arg_min(t, ord) AS first_to, arg_min(sel, ord) AS first_sel, count(*) AS n FROM (
      SELECT hash(lower(FROM_ADDRESS)) AS h, lower(TO_ADDRESS) AS t, substr(INPUT, 1, 10) AS sel, BLOCK_NUMBER * 100000 + TRANSACTION_INDEX AS ord FROM read_parquet('%s%s/transactions/date=%s/*.parquet')
      WHERE lower(FROM_ADDRESS) <> '%s' UNION ALL SELECT hash(lower(FROM_ADDRESS)), lower(TO_ADDRESS), substr(INPUT, 1, 10), BLOCK_NUMBER * 100000 + TRANSACTION_INDEX
      FROM read_parquet('%s%s/transactions_failed/date=%s/*.parquet') WHERE lower(FROM_ADDRESS) <> '%s') GROUP BY h", SONARX, ch, d, SYSTEM_SENDERS[[ch]], SONARX, ch, d, SYSTEM_SENDERS[[ch]]))
    if (as.Date(d) >= LONG_START) {
      DBI::dbExecute(con, "CREATE OR REPLACE TABLE nw AS SELECT ds.* FROM ds ANTI JOIN recent USING (h)")   # recent: senders active in the previous LONG_LOOKBACK days
      DBI::dbExecute(con, sprintf("INSERT INTO grp SELECT DATE '%s', CASE WHEN k >= 10 THEN first_to END AS ft, CASE WHEN k >= 10 THEN first_sel END AS fs, sum(k), sum(heavy) FROM
        (SELECT first_to, first_sel, count(*) AS k, sum(CASE WHEN n >= %d THEN 1 ELSE 0 END) AS heavy FROM nw GROUP BY 1, 2) GROUP BY 2, 3", d, BOT_MIN_WEEK1))
      DBI::dbExecute(con, sprintf("INSERT INTO snd SELECT DATE '%s', (SELECT count(*) FROM ds), (SELECT count(*) FROM nw)", d))
    }
    DBI::dbExecute(con, sprintf("CREATE OR REPLACE TABLE recent AS SELECT h, max(day) AS day FROM (SELECT h, day FROM recent WHERE day > DATE '%s' - INTERVAL %d DAY
      UNION ALL SELECT h, DATE '%s' FROM ds) GROUP BY h", d, LONG_LOOKBACK, d))
    if (format(as.Date(d), "%d") == "01") cat(sprintf("T %s: through %s, %.0f min\n", ch, d, as.numeric(Sys.time() - t_start, units = "mins")))
  }
  DBI::dbExecute(con, sprintf("COPY (SELECT * FROM grp ORDER BY day, n DESC) TO '%s' (FORMAT PARQUET)", gsub("'", "''", outs[1])))
  DBI::dbExecute(con, sprintf("COPY (SELECT * FROM snd ORDER BY day) TO '%s' (FORMAT PARQUET)", gsub("'", "''", outs[2])))
  DBI::dbDisconnect(con, shutdown = TRUE); unlink(c(dbf, paste0(dbf, ".wal")))
  cat(sprintf("T %s: %.1f min\n", ch, as.numeric(Sys.time() - t_start, units = "mins")))
}

cat("\n## sessionInfo\n```\n"); print(sessionInfo()); cat("```\n"); sink()
