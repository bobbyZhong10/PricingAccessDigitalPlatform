# 01_download.R: public data -> data/raw. Each section is skipped if its files exist (set FORCE_DOWNLOAD = TRUE to redo).
# Sources (no keys): AWS Public Blockchain (s3://aws-public-blockchain, sonarx Base/Arbitrum, Ethereum/Bitcoin blocks), growthepie exports, Coinbase candles.
# Raw files are aggregates computed on the fly; the transaction-level tables are hundreds of GB. A full download takes 1-2 hours.
source(here::here("code", "00_setup.R"))
FORCE_DOWNLOAD <- FALSE
new_log("01 download")
need <- function(files) FORCE_DOWNLOAD || !all(file.exists(files))
tick <- function(t0, what) say(sprintf("%s: %.1f min", what, as.numeric(Sys.time() - t0, units = "mins")))
days_main <- format(seq(PULL_START, PULL_END, by = "day"))

# ---- S3 access with DuckDB (anonymous) ----
write_pq <- function(x, path) nanoparquet::write_parquet(as.data.frame(x), path)
sql_str <- function(x) paste0("'", gsub("'", "''", x), "'")   # local paths may contain an apostrophe
s3_con <- function(dbdir = ":memory:") { con <- DBI::dbConnect(duckdb::duckdb(), dbdir = dbdir)
  DBI::dbExecute(con, "INSTALL httpfs; LOAD httpfs; SET s3_region='us-east-2'; SET threads TO 8; SET memory_limit='10GB'; SET preserve_insertion_order = false; SET http_retries = 10; SET http_retry_wait_ms = 3000;")
  con }
s3_partitions <- function(chain, tbl, prefix = "v1.1/sonarx") {   # date partitions that exist
  out <- character(0); tok <- ""
  repeat { u <- sprintf("https://aws-public-blockchain.s3.us-east-2.amazonaws.com/?list-type=2&prefix=%s/%s/%s/&delimiter=/%s", prefix, chain, tbl,
                        if (nzchar(tok)) paste0("&continuation-token=", URLencode(tok, reserved = TRUE)) else "")
    x <- paste(readLines(u, warn = FALSE), collapse = ""); out <- c(out, regmatches(x, gregexpr("date=[0-9-]{10}", x))[[1]])
    if (!grepl("<NextContinuationToken>", x)) break; tok <- sub(".*<NextContinuationToken>(.*)</NextContinuationToken>.*", "\\1", x) }
  sub("date=", "", unique(out)) }
s3_files <- function(chain, tbl, days, prefix = "v1.1/sonarx", have = NULL) {
  d <- if (is.null(have)) days else intersect(days, have)
  paste0("[", paste0("'s3://aws-public-blockchain/", prefix, "/", chain, "/", tbl, "/date=", d, "/*.parquet'", collapse = ", "), "]") }
# Successful (transactions) and failed (transactions_failed) tables are disjoint and are stacked.

# ---- A. hourly activity, new senders, sender-days (2024-02-15..04-15) ----
for (chain in CHAINS) {
  outs <- raw(sprintf(c("l2_hourly_%s.parquet", "l2_newsenders_%s.parquet", "l2_senderday_%s.parquet"), chain))
  if (!need(outs)) { say("A ", chain, ": exists, skipped"); next }
  t0 <- Sys.time(); dbf <- tempfile(fileext = ".duckdb"); con <- s3_con(dbf)
  DBI::dbExecute(con, sprintf("CREATE TABLE tx AS SELECT lower(FROM_ADDRESS) AS a, DATETIME AS dt, TRANSACTION_FEE AS fee, 0 AS failed FROM read_parquet(%s)
    UNION ALL SELECT lower(FROM_ADDRESS), DATETIME, TRANSACTION_FEE, 1 FROM read_parquet(%s)", s3_files(chain, "transactions", days_main), s3_files(chain, "transactions_failed", days_main)))
  DBI::dbExecute(con, sprintf("CREATE TABLE hf AS SELECT a FROM tx WHERE dt >= TIMESTAMP '2024-02-15' AND dt < TIMESTAMP '2024-02-22' GROUP BY a HAVING count(*) >= %d", HF_MIN_WEEKLY))
  DBI::dbExecute(con, sprintf("COPY (SELECT date_trunc('hour', dt) AS hr, CAST(a IN (SELECT a FROM hf) AS INTEGER) AS hf, failed, count(*) AS n, sum(fee) AS fee,
    count(DISTINCT a) AS n_senders FROM tx GROUP BY 1, 2, 3) TO %s (FORMAT PARQUET)", sql_str(outs[1])))
  DBI::dbExecute(con, sprintf("COPY (SELECT date_trunc('hour', first_dt) AS hr, count(*) AS new_senders FROM (SELECT a, min(dt) AS first_dt FROM tx GROUP BY a) GROUP BY 1) TO %s (FORMAT PARQUET)", sql_str(outs[2])))
  DBI::dbExecute(con, sprintf("COPY (SELECT a, CAST(dt AS DATE) AS day, count(*) AS n, sum(fee) AS fee FROM tx GROUP BY 1, 2) TO %s (FORMAT PARQUET)", sql_str(outs[3])))
  DBI::dbDisconnect(con, shutdown = TRUE); unlink(dbf); tick(t0, paste("A", chain))
}

# ---- B. Ethereum L1 and Bitcoin hourly txs (untreated comparison series) ----
outs <- raw(c("l1_hourly_eth.parquet", "btc_hourly.parquet"))
if (need(outs)) { t0 <- Sys.time(); con <- s3_con(); d <- format(seq(as.Date("2024-02-14"), as.Date("2024-04-16"), by = "day"))
  E <- as.data.table(DBI::dbGetQuery(con, sprintf("SELECT date_trunc('hour', timestamp) AS hr, sum(transaction_count) AS n FROM read_parquet(%s) GROUP BY 1 ORDER BY 1",
    s3_files("eth", "blocks", d, prefix = "v1.0"))))
  B <- as.data.table(DBI::dbGetQuery(con, sprintf("SELECT date_trunc('hour', timestamp) AS hr, sum(transaction_count) AS n FROM read_parquet(%s) GROUP BY 1 ORDER BY 1", s3_files("btc", "blocks", d, prefix = "v1.0"))))
  DBI::dbDisconnect(con, shutdown = TRUE); write_pq(E, outs[1]); write_pq(B, outs[2]); tick(t0, "B Ethereum/Bitcoin")
} else say("B: exists, skipped")

# ---- C. protocol system txs per hour (removed in 02) ----
for (chain in CHAINS) { out <- raw(sprintf("l2_hourly_system_%s.parquet", chain)); if (!need(out)) { say("C ", chain, ": exists, skipped"); next }
  t0 <- Sys.time(); con <- s3_con()
  S <- as.data.table(DBI::dbGetQuery(con, sprintf("SELECT date_trunc('hour', DATETIME) AS hr, count(*) AS n_sys FROM read_parquet(%s) WHERE lower(FROM_ADDRESS) = '%s' GROUP BY 1 ORDER BY 1",
    s3_files(chain, "transactions", days_main), SYSTEM_SENDERS[[chain]])))
  DBI::dbDisconnect(con, shutdown = TRUE); write_pq(S, out); tick(t0, paste("C", chain)) }

# ---- D. hourly txs by type (4-byte method selector) ----
swap <- c("0x3593564c", "0x24856bc3", "0x7ff36ab5", "0x18cbafe5", "0x38ed1739", "0xb6f9de95", "0x791ac947", "0x5c11d795", "0xfb3bdb41", "0x8803dbee", "0x4a25d94a",
          "0x414bf389", "0x04e45aaf", "0xc04b8d59", "0xb858183f", "0xdb3e2198", "0x5ae401dc", "0xac9650d8", "0x12aa3caf", "0xe449022e", "0x0502b1c5", "0x2e95b6c8",
          "0x415565b0", "0xcac88ea9", "0xf41766d8", "0x83bd37f9", "0x90411a32")   # Uniswap V2/V3/Universal Router, Aerodrome, 1inch, 0x, ParaSwap, Odos
cls <- sprintf("CASE WHEN INPUT IS NULL OR length(INPUT) <= 2 THEN 'native' WHEN substr(INPUT,1,10) = '0xa9059cbb' THEN 'erc20_transfer' WHEN substr(INPUT,1,10) = '0x095ea7b3' THEN 'approve'
  WHEN substr(INPUT,1,10) IN (%s) THEN 'swap' ELSE 'other_call' END", paste0("'", swap, "'", collapse = ","))
for (chain in CHAINS) { out <- raw(sprintf("l2_hourly_type_%s.parquet", chain)); if (!need(out)) { say("D ", chain, ": exists, skipped"); next }
  t0 <- Sys.time(); con <- s3_con()
  DBI::dbExecute(con, sprintf("COPY (SELECT date_trunc('hour', DATETIME) AS hr, typ, failed, count(*) AS n, sum(fee) AS fee FROM (
      SELECT DATETIME, %s AS typ, 0 AS failed, TRANSACTION_FEE AS fee FROM read_parquet(%s) UNION ALL SELECT DATETIME, %s, 1, TRANSACTION_FEE FROM read_parquet(%s))
    GROUP BY 1, 2, 3) TO %s (FORMAT PARQUET)", cls, s3_files(chain, "transactions", days_main), cls, s3_files(chain, "transactions_failed", days_main), sql_str(out)))
  DBI::dbDisconnect(con, shutdown = TRUE); tick(t0, paste("D", chain)) }

# ---- E. entrant cohorts: senders first seen on 03-01..27 ----
# prior: senders active before 2024-02-15 (Base since genesis 2023-06-15, Arbitrum since 2023-03-01); post: months with activity on days 1-10 of
# 2024-04..12 and 2025-03; first: first timestamp and first-week txs. Failed txs count as activity.
post_months <- c(format(seq(as.Date("2024-04-01"), as.Date("2024-12-01"), by = "month")), "2025-03-01")
post_days <- unlist(lapply(post_months, function(m) format(seq(as.Date(m), as.Date(m) + 9, by = "day"))))
first_days <- format(seq(as.Date("2024-02-29"), as.Date("2024-04-04"), by = "day"))
for (chain in CHAINS) {
  outs <- raw(sprintf(c("cohort_prior_%s.parquet", "cohort_post_%s.parquet", "cohort_first_%s.parquet"), chain))
  if (!need(outs)) { say("E ", chain, ": exists, skipped"); next }
  t0 <- Sys.time(); dbf <- tempfile(fileext = ".duckdb"); con <- s3_con(dbf)
  DBI::dbExecute(con, sprintf("CREATE TABLE coh AS SELECT a, min(day) AS first_day FROM read_parquet(%s) GROUP BY a HAVING min(day) >= DATE '2024-03-01' AND min(day) <= DATE '2024-03-27'",
    sql_str(raw(sprintf("l2_senderday_%s.parquet", chain)))))
  have_tx <- s3_partitions(chain, "transactions"); have_fail <- s3_partitions(chain, "transactions_failed")
  src <- function(days) sprintf("(SELECT FROM_ADDRESS, DATETIME FROM read_parquet(%s) UNION ALL SELECT FROM_ADDRESS, DATETIME FROM read_parquet(%s))",
                                s3_files(chain, "transactions", days, have = have_tx), s3_files(chain, "transactions_failed", days, have = have_fail))
  hist_days <- format(seq(as.Date(if (chain == "base") "2023-06-15" else "2023-03-01"), as.Date("2024-02-14"), by = "day"))
  DBI::dbExecute(con, sprintf("COPY (SELECT DISTINCT lower(FROM_ADDRESS) AS a FROM %s WHERE lower(FROM_ADDRESS) IN (SELECT a FROM coh))
    TO %s (FORMAT PARQUET)", src(hist_days), sql_str(outs[1])))
  DBI::dbExecute(con, sprintf("COPY (SELECT DISTINCT lower(FROM_ADDRESS) AS a, strftime(DATETIME, '%%Y-%%m') AS ym FROM %s WHERE lower(FROM_ADDRESS) IN (SELECT a FROM coh))
    TO %s (FORMAT PARQUET)", src(post_days), sql_str(outs[2])))
  DBI::dbExecute(con, sprintf("COPY (SELECT a, min(dt) AS first_dt, count(*) FILTER (WHERE dt < first_dt0 + INTERVAL 7 DAY) AS n_week1
    FROM (SELECT t.*, min(dt) OVER (PARTITION BY a) AS first_dt0 FROM (SELECT lower(FROM_ADDRESS) AS a, DATETIME AS dt FROM %s) t WHERE a IN (SELECT a FROM coh)) GROUP BY a)
    TO %s (FORMAT PARQUET)", src(first_days), sql_str(outs[3])))
  DBI::dbDisconnect(con, shutdown = TRUE); unlink(dbf); tick(t0, paste("E", chain))
}

# ---- F. entrants' first outgoing tx and first funder (entrants first seen from 03-08) ----
# "First" follows chain order (block number, then position in the block), so ties within a block are resolved the same way on every run.
win_end <- c(base = "2024-03-22", arbitrum = "2024-03-25")
for (chain in CHAINS) {
  outs <- raw(sprintf(c("wave_first_out_%s.parquet", "wave_fund_eth_%s.parquet", "wave_fund_tok_%s.parquet"), chain))
  if (!need(outs)) { say("F ", chain, ": exists, skipped"); next }
  t0 <- Sys.time(); dbf <- tempfile(fileext = ".duckdb"); con <- s3_con(dbf)
  DBI::dbExecute(con, sprintf("CREATE TABLE ent AS SELECT f.a, f.first_dt FROM read_parquet(%s) f ANTI JOIN read_parquet(%s) p USING (a) WHERE f.first_dt >= TIMESTAMP '2024-03-08' AND f.first_dt < TIMESTAMP '%s'",
    sql_str(raw(sprintf("cohort_first_%s.parquet", chain))), sql_str(raw(sprintf("cohort_prior_%s.parquet", chain))), win_end[[chain]]))
  d <- format(seq(as.Date("2024-03-06"), as.Date(win_end[[chain]]) + 1, by = "day"))
  DBI::dbExecute(con, sprintf("CREATE TABLE tx AS SELECT lower(FROM_ADDRESS) AS fr, lower(TO_ADDRESS) AS t, DATETIME AS dt, BLOCK_NUMBER * 100000 + TRANSACTION_INDEX AS ord, VALUE AS v,
    substr(INPUT, 1, 10) AS sel FROM read_parquet(%s)
    WHERE lower(FROM_ADDRESS) IN (SELECT a FROM ent) OR (lower(TO_ADDRESS) IN (SELECT a FROM ent) AND VALUE > 0)", s3_files(chain, "transactions", d)))
  DBI::dbExecute(con, sprintf("COPY (SELECT e.a, e.first_dt, arg_min(o.t, o.ord) AS first_to, arg_min(o.sel, o.ord) AS first_sel FROM ent e LEFT JOIN tx o ON o.fr = e.a GROUP BY 1, 2) TO %s (FORMAT PARQUET)", sql_str(outs[1])))
  DBI::dbExecute(con, sprintf("COPY (SELECT i.t AS a, arg_min(i.fr, i.ord) AS funder FROM tx i WHERE i.t IN (SELECT a FROM ent) AND i.v > 0 GROUP BY 1) TO %s (FORMAT PARQUET)", sql_str(outs[2])))
  DBI::dbExecute(con, sprintf("COPY (SELECT lower(TO_ADDRESS) AS a, arg_min(lower(FROM_ADDRESS), BLOCK_NUMBER * 100000 + LOG_INDEX) AS tfunder
    FROM read_parquet(%s) WHERE lower(TO_ADDRESS) IN (SELECT a FROM ent) GROUP BY 1) TO %s (FORMAT PARQUET)", s3_files(chain, "transfers", d), sql_str(outs[3])))
  DBI::dbDisconnect(con, shutdown = TRUE); unlink(dbf); tick(t0, paste("F", chain))
}

# ---- G. Base hourly txs of campaign wallets (entrants in campaign bursts) and their collectors (recipients of their plain ETH transfers) ----
out <- raw("base_hourly_campaign.parquet")
if (need(out)) { t0 <- Sys.time()
  X <- campaign_flags(read_pq(raw("wave_first_out_base.parquet")), read_pq(raw("wave_fund_eth_base.parquet")), read_pq(raw("wave_fund_tok_base.parquet")))
  wallets <- X[wave == 1, .(a)]; collectors <- X[wave == 1 & first_sel == "0x", unique(first_to)]
  say(sprintf("G: %d campaign wallets, %d collectors (%s)", nrow(wallets), length(collectors), paste(collectors, collapse = ", ")))
  con <- s3_con(); duckdb::duckdb_register(con, "wave", wallets)
  d <- format(seq(as.Date("2024-02-29"), as.Date("2024-04-16"), by = "day"))
  DBI::dbExecute(con, sprintf("COPY (SELECT date_trunc('hour', DATETIME) AS hr, count(*) AS n_campaign FROM read_parquet(%s) WHERE lower(FROM_ADDRESS) IN (SELECT a FROM wave) OR lower(TO_ADDRESS) IN (%s)
    GROUP BY 1) TO %s (FORMAT PARQUET)", s3_files("base", "transactions", d), paste0("'", collectors, "'", collapse = ","), sql_str(out)))
  DBI::dbDisconnect(con, shutdown = TRUE); tick(t0, "G campaign activity")
} else say("G: exists, skipped")

# ---- H. growthepie daily exports (all L2s) ----
dir.create(raw("growthepie"), showWarnings = FALSE)
for (m in c("txcount", "daa", "txcosts")) { f <- raw("growthepie", sprintf("export_%s.json", m)); if (!need(f)) next
  download.file(sprintf("https://api.growthepie.xyz/v1/export/%s.json", m), f, mode = "wb", quiet = TRUE, headers = c(`User-Agent` = "Mozilla/5.0")); Sys.sleep(1) }
say("H: growthepie exports: ", paste(basename(list.files(raw("growthepie"))), collapse = ", "))

# ---- I. ETH/USD daily (Coinbase) ----
out <- raw("eth_usd_daily.csv")
if (need(out)) { j <- fromJSON("https://api.exchange.coinbase.com/products/ETH-USD/candles?granularity=86400&start=2024-02-15T00:00:00Z&end=2024-04-10T00:00:00Z")
  P <- data.table(day = as.IDate(as.POSIXct(j[, 1], origin = "1970-01-01", tz = "UTC")), low = j[, 2], high = j[, 3], open = j[, 4], close = j[, 5])[order(day)]
  check_unique(P, "day", "eth_usd"); fwrite(P, out); say(sprintf("I: %d days of ETH/USD", nrow(P)))
} else say("I: exists, skipped")
save_log("01_download")
