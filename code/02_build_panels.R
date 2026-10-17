# 02_build_panels.R: data/raw -> data/panel/panel.rds, a named list with one table per panel (chains stacked).
# Address-level data stay in data/raw; the panel keeps only what 04-08 use, so it stays small enough for git.
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

# ---- C0. LayerZero provisional Sybil list (validation V1) ----
# The official initialList.txt (Internet Archive capture, 2024-05-23) is the list used; every other copy in DIR_RAW/lz_*/ is compared with it.
# Lines that are not EVM addresses (the list also covers non-EVM chains) are dropped.
# Read as plain text: fread's type detection turns some addresses into numbers when the file has no header.
LZ_A <- unique(tolower(trimws(readLines(file.path(DIR_RAW, "lz_archive", "initialList.txt"), warn = FALSE))))
lz_meta <- data.table(copy = "lz_archive/initialList.txt", lines = length(LZ_A), evm = sum(grepl("^0x[0-9a-f]{40}$", LZ_A)), share_of_archive = 1, share_in_archive = 1)
LZ_A <- LZ_A[grepl("^0x[0-9a-f]{40}$", LZ_A)]
lz_files <- list.files(DIR_RAW, recursive = TRUE, full.names = TRUE)
lz_files <- setdiff(lz_files[grepl("/lz_[a-z]+/", lz_files)], file.path(DIR_RAW, "lz_archive", "initialList.txt"))
for (f in lz_files) {
  L2 <- unique(tolower(trimws(readLines(f, warn = FALSE)))); L2 <- L2[grepl("^0x[0-9a-f]{40}$", L2)]
  lz_meta <- rbind(lz_meta, data.table(copy = sub(paste0(DIR_RAW, "/"), "", f, fixed = TRUE), lines = length(L2), evm = length(L2), share_of_archive = mean(LZ_A %in% L2), share_in_archive = mean(L2 %in% LZ_A)))
}
cat("C0: LayerZero list copies (share_of_archive = share of the archive's EVM addresses found in the copy)\n"); print(lz_meta)

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

  # validation V1 (LayerZero list) and V2 (funder-entrant-sweep components), from 01 sections J and K
  V <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, sprintf("val_entrant_%s.parquet", ch))))
  DG <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, sprintf("val_degree_%s.parquet", ch))))
  W <- merge(W, V[, .(a, blk0, f_eth, f_eth_via, f_tok, sweep_to)], by = "a", all.x = TRUE)
  # pre-entry funder: first ETH funder before the first outgoing tx, else first token funder before it (funder_any above can postdate entry)
  W[, `:=`(funder2 = fifelse(!is.na(f_eth), f_eth, f_tok), lz = as.integer(a %in% LZ_A))]
  W[, funder_lz := fifelse(is.na(funder2), NA_integer_, as.integer(funder2 %in% LZ_A))]
  FD2 <- W[!is.na(funder2), .N, by = .(day, funder2)]
  FD2[, base := 0][FD2[day <= PRE_END, .(b = median(c(N, rep(0L, n_pre - .N)))), by = funder2], base := i.b, on = "funder2"]
  W[, fburst2 := paste(day, funder2) %in% FD2[N >= FUNDER_BURST_MIN & N >= SPIKE_K * base, paste(day, funder2)]]
  W[, wave_funded2 := as.integer(wave == 1 & mean(fburst2) >= 0.5), by = .(day, pair)]   # bound 2 with the pre-entry funder
  # synchronized entry: >= SYNC_MIN other entrants whose first tx is in the same block with the same recipient x method
  W[, sync := as.integer(!is.na(first_to) & .N > SYNC_MIN), by = .(blk0, pair)]
  # Multi-identity entities: components of the graph with edges entrant - ETH funder and entrant - sweep target (01 section J). Services are dropped:
  # funders with >= h distinct ETH recipients and sweep targets with >= h distinct ETH senders on 02-15..03-07. csize = entrants in the component.
  for (h in HUB_MIN) {
    svc <- DG[deg_pre >= h, paste(role, addr)]
    ED <- rbind(W[!is.na(f_eth) & !(paste("funder", f_eth) %in% svc), .(u = a, v = f_eth)], W[!is.na(sweep_to) & !(paste("sweep", sweep_to) %in% svc), .(u = a, v = sweep_to)])
    G <- igraph::graph_from_data_frame(ED, directed = FALSE, vertices = data.frame(name = unique(c(W$a, ED$u, ED$v))))
    cm <- igraph::components(G)$membership
    W[, (paste0("cid", h)) := unname(cm[a])][, (paste0("csize", h)) := .N, by = c(paste0("cid", h))]
    cat(sprintf("C %s: services at h = %d: %d funders, %d sweep targets; entrants in components of >= %d: %.3f\n", ch, h, DG[deg_pre >= h & role == "funder", .N],
                DG[deg_pre >= h & role == "sweep", .N], CLUSTER_MIN, W[, mean(get(paste0("csize", h)) >= CLUSTER_MIN)]))
  }
  # the same components at lower service thresholds (more addresses treated as services, fewer links), for the linkage range in section C3 only
  for (h in HUB_MIN_EXTRA) {
    svc <- DG[deg_pre >= h, paste(role, addr)]
    ED <- rbind(W[!is.na(f_eth) & !(paste("funder", f_eth) %in% svc), .(u = a, v = f_eth)], W[!is.na(sweep_to) & !(paste("sweep", sweep_to) %in% svc), .(u = a, v = sweep_to)])
    G <- igraph::graph_from_data_frame(ED, directed = FALSE, vertices = data.frame(name = unique(c(W$a, ED$u, ED$v))))
    cm <- igraph::components(G)$membership
    W[, (paste0("cid", h)) := unname(cm[a])]
    cat(sprintf("C %s: services at h = %d: %d funders, %d sweep targets; largest component %d entrants\n", ch, h, DG[deg_pre >= h & role == "funder", .N],
                DG[deg_pre >= h & role == "sweep", .N], W[, max(table(get(paste0("cid", h))))]))
  }
  # sensitivity: funder edges only (h = 500); entrants in the largest h = 500 component
  svc <- DG[deg_pre >= 500 & role == "funder", addr]
  ED <- W[!is.na(f_eth) & !(f_eth %in% svc), .(u = a, v = f_eth)]
  G <- igraph::graph_from_data_frame(ED, directed = FALSE, vertices = data.frame(name = unique(c(W$a, ED$u, ED$v))))
  cm <- igraph::components(G)$membership
  W[, cidF500 := unname(cm[a])][, csizeF500 := .N, by = cidF500][, in_largest500 := as.integer(csize500 == max(csize500))]
  W[, fn := fifelse(!is.na(f_eth) & !(f_eth %in% svc), f_eth, NA_character_)]   # non-service ETH funder (h = 500), used for the cross-chain flags below
  W[, f_service := fifelse(!is.na(f_eth) & f_eth %in% svc, f_eth, NA_character_)]   # service ETH funder (h = 500): an exchange, bridge or app address, kept to label funders (06 section M)

  X <- merge(X, W[, .(a, first_to, first_sel, funder_any, wave, batch, wave_size, wave_funded, f_eth_via, funder2_seen = as.integer(!is.na(funder2)), lz, funder_lz,
                      wave_funded2, sync, cid200, cid500, cid2000, csize200, csize500, csize2000, csizeF500, in_largest500, fn, f_eth, f_service, sweep_to, blk0)], by = "a", all.x = TRUE)
  X <- merge(X, W[, c("a", paste0("cid", HUB_MIN_EXTRA)), with = FALSE], by = "a", all.x = TRUE)   # section C3 only; not kept in the panel
  X[!is.na(wave), class3 := fcase(bot_wk1 == 1, "bot", wave == 1, "campaign", default = "genuine")]   # bot > campaign > genuine
  stopifnot(!anyDuplicated(X$a), !(SYSTEM_SENDERS[[ch]] %in% X$a)); entrants[[ch]] <- X
  cat(sprintf("C %s: campaign bursts (>= %d entrants/day and >= %dx pre-shock median): campaign share pre %.3f, post %.3f\n", ch, SPIKE_MIN, SPIKE_K,
              X[!is.na(wave) & day <= PRE_END, mean(wave)], X[!is.na(wave) & day > PRE_END, mean(wave)]))
  cat(sprintf("C %s: cohort %d; prior activity %.3f -> entrants %d; in window %s..%s: %d (campaign %.3f, bursting funder %.3f)\n", ch, n_cohort, 1 - nrow(X) / n_cohort, nrow(X),
              ENTRANT_WINDOW[1], ENTRANT_WINDOW[2], X[!is.na(wave), .N], X[!is.na(wave), mean(wave)], X[!is.na(batch), mean(batch)]))
}

# ---- C2. cross-chain flags and what Base entrants received after entry ----
# other_chain_addr: the entrant's address is also a window entrant on the other chain; other_chain_funder: its non-service ETH funder (h = 500) also
# funds window entrants on the other chain (any class there).
for (ch in CHAINS) {
  o <- setdiff(CHAINS, ch); Xo <- entrants[[o]][!is.na(wave)]
  entrants[[ch]][!is.na(wave), `:=`(other_chain_addr = as.integer(a %in% Xo$a), other_chain_funder = fifelse(is.na(fn), NA_integer_, as.integer(fn %in% Xo[!is.na(f_eth), f_eth])))]
}
# Base: token and ETH transfers received after the first outgoing tx, up to 04-15 (01 section O; native ETH has token address 0xeee...e)
ETH_TOK <- "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
RC <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, "val_received_base.parquet")))
XB <- entrants$base[!is.na(wave), .(a, blk0, class3)]
RA <- merge(RC, XB, by = "a")[blk > blk0]
entrants$base[, `:=`(tok_after = as.integer(a %in% RA[tok != ETH_TOK, a]), eth_after = as.integer(a %in% RA[tok == ETH_TOK, a]))][is.na(wave), `:=`(tok_after = NA_integer_, eth_after = NA_integer_)]
entrants$arbitrum[, `:=`(tok_after = NA_integer_, eth_after = NA_integer_)]
receipts_by_token <- RA[tok != ETH_TOK, .(recipients = uniqueN(a), senders = uniqueN(fr), top_sender = names(which.max(table(fr)))), by = .(class3, tok)][recipients >= 1000][order(class3, -recipients)]
fb_sent <- RC[fr == "0xfb10c144539af9a7b905a28f8ad07fb0cf85ae50", .(transfers = .N, recipients = uniqueN(a), recipients_window_entrants = uniqueN(a[a %in% XB$a])), by = tok][order(-transfers)]
mar_base <- entrants$base[!is.na(wave), .(a, class3, f_eth, sweep_to)]   # March Base window entrants, for the link to the May event (section H)
cat(sprintf("C2: Base entrants receiving tokens after entry: %.3f; ETH: %.3f; %d token x class cells with >= 1,000 recipients\n",
            entrants$base[!is.na(wave), mean(tok_after)], entrants$base[!is.na(wave), mean(eth_after)], nrow(receipts_by_token)))

# ---- C3. robustness inputs for the composition results: entity counts under alternative linkage rules, funding of Base entrants, look-alike addresses ----
# entity_daily: window entrants (n_addr) and distinct entities (n_ent) per entry day and class (all, campaign, genuine, bot) under each linkage rule, for all
# entrants and without the largest post-cut burst target (largest_target) or the largest component (h = 500). Entities are counted per day, as in 06 section F.
#   h<k>: funder-entrant-sweep components with services at threshold k (section C); campaign: burst entrants grouped by first-action group (recipient x method),
#   the others by component (h = 500); singleton: every non-burst entrant is its own entity, the others by component (h = 500); campaign+singleton: both.
# The May window is added in section H.
RULES <- c(paste0("h", sort(c(HUB_MIN_EXTRA, HUB_MIN))), "campaign", "singleton", "campaign+singleton")
SUBSETS <- c("all", "without largest target", "without largest component")
entity_daily <- list(); lookalike <- list()
for (ch in CHAINS) {
  X <- entrants[[ch]][!is.na(wave)][, pair := paste(first_to, first_sel)]
  tt <- X[day >= as.IDate(fifelse(ch == "base", "2024-03-14", "2024-03-15")) & class3 == "campaign", .N, by = first_to][which.max(N), first_to]
  for (r in RULES) {
    X[, id := switch(r, campaign = fifelse(class3 == "campaign", paste("c", pair), paste("k", cid500)), singleton = fifelse(class3 == "genuine", paste("s", a), paste("k", cid500)),
                     `campaign+singleton` = fcase(class3 == "campaign", paste("c", pair), class3 == "genuine", paste("s", a), default = paste("k", cid500)),
                     as.character(get(paste0("cid", sub("^h", "", r)))))]
    for (s in SUBSETS) {
      Z <- switch(s, all = X, `without largest target` = X[!(first_to %in% tt)], `without largest component` = X[in_largest500 == 0])
      entity_daily[[length(entity_daily) + 1]] <- rbind(Z[, .(class = "all", n_addr = .N, n_ent = uniqueN(id)), by = day], Z[, .(n_addr = .N, n_ent = uniqueN(id)), by = .(day, class = class3)])[
        , `:=`(event = "march", chain = ch, rule = r, subset = s, largest_target = tt)]
    }
  }
  # lookalike: entrants whose first action is a plain transfer (empty calldata); share sent to themselves (self), and among transfers to another address the
  # share whose address matches the recipient's in its first and last four hex digits, as address-poisoning senders' addresses do (chance match 16^-4 on each
  # side); pre 03-08..12, post 03-14..21 (03-13 left out)
  lookalike[[ch]] <- X[first_sel %in% "0x" & !is.na(first_to)][, period := fcase(day <= as.IDate("2024-03-12"), "pre", day >= as.IDate("2024-03-14"), "post", default = NA_character_)][!is.na(period),
    .(n_plain = .N, self = mean(a == first_to), prefix4 = mean((substr(a, 3, 6) == substr(first_to, 3, 6))[a != first_to]), suffix4 = mean((substr(a, 39, 42) == substr(first_to, 39, 42))[a != first_to]),
      both4 = mean((substr(a, 3, 6) == substr(first_to, 3, 6) & substr(a, 39, 42) == substr(first_to, 39, 42))[a != first_to])), by = .(period, class3)][, `:=`(event = "march", chain = ch)]
}
# entrant_funding (Base): ETH an entrant received before its first outgoing tx (top-level transfers from 03-08, 01 section O; internal transfers from 03-06,
# 01 section S), the fee of the internal funding txs divided over the window entrants each paid (ETH), and whether the entrant ever sent ETH out (sweep, to 04-15).
# Summarized by period (pre 03-08..12, post 03-14..21), class, first-action group (the 20 largest post-cut burst groups by name, the rest pooled by class) and
# how the first ETH funder was found (top-level, internal, none). init: the account that initiated an entrant's first internal funding tx.
IN <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, "val_internal_base.parquet")))
XB <- entrants$base[!is.na(wave)][, `:=`(period = fcase(day <= as.IDate("2024-03-12"), "pre", day >= as.IDate("2024-03-14"), "post", default = NA_character_), pair = paste(first_to, first_sel))][!is.na(period)]
FT <- merge(RC[tok == ETH_TOK, .(a, blk = as.numeric(blk), v = as.numeric(v))], XB[, .(a, blk0)], by = "a")[blk <= blk0, .(eth_top = sum(v), n_top = .N), by = a]
FI <- merge(IN[, .(a, ord = as.numeric(ord), init, v = as.numeric(v) / 1e18, fee_share = as.numeric(tx_fee) / n_paid)], XB[, .(a, blk0)], by = "a")[floor(ord / 1e5) <= blk0][order(ord),
  .(eth_int = sum(v), fee_int = sum(fee_share, na.rm = TRUE), n_int = .N, init = init[1]), by = a]   # traces report wei, transfers and fees ETH; fee missing for 1% of funding txs
XB <- merge(merge(XB, FT, by = "a", all.x = TRUE), FI, by = "a", all.x = TRUE)
for (v in c("eth_top", "n_top", "eth_int", "fee_int", "n_int")) XB[is.na(get(v)), (v) := 0]
XB[, eth_in := eth_top + eth_int]
TOP20 <- XB[period == "post" & class3 == "campaign", .N, by = pair][order(-N)][1:min(20, .N), pair]
XB[, grp := fifelse(class3 == "campaign" & pair %in% TOP20, pair, paste("other", class3))]
entrant_funding <- XB[, .(n = .N, funded = mean(eth_in > 0), eth_p10 = quantile(eth_in[eth_in > 0], 0.1, names = FALSE), eth_p50 = quantile(eth_in[eth_in > 0], 0.5, names = FALSE),
                          eth_p90 = quantile(eth_in[eth_in > 0], 0.9, names = FALSE), eth_mean = mean(eth_in), eth_sum = sum(eth_in), eth_unswept = sum(eth_in[is.na(sweep_to)]),
                          fee_int_sum = sum(fee_int), n_top_sum = sum(n_top),
                          n_int_sum = sum(n_int), swept = mean(!is.na(sweep_to)), initiators = uniqueN(init[!is.na(init)]),
                          top_initiator_share = if (any(!is.na(init))) max(table(init)) / sum(!is.na(init)) else NA_real_, top_level_funders = uniqueN(f_eth[f_eth_via %in% "top-level"])),
                      by = .(period, class3, grp, via = fifelse(is.na(f_eth_via), "none", f_eth_via))][order(period, class3, -n)]
cat(sprintf("C3: entity counts for %d rules x %d subsets; Base entrants funded before entry: %.3f (top-level %.3f, internal %.3f); internal funding transfers %d\n",
            length(RULES), length(SUBSETS), XB[, mean(eth_in > 0)], XB[, mean(eth_top > 0)], XB[, mean(eth_int > 0)], nrow(IN)))
rm(RC, RA, IN, FT, FI, XB, X, Z); invisible(gc())

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
entrants <- rbindlist(entrants, use.names = TRUE)[, .(chain, day, hr, act_2024_04, act_2024_06, act_2024_09, act_2024_12, act_2025_03, months_active, any_later, n_week1, single_tx_wk1, bot_wk1,
                                     wave, batch, wave_size, wave_funded, class3, first_to, first_sel, funder_any,
                                     f_eth_via, funder2_seen, lz, funder_lz, wave_funded2, sync, cid200, cid500, cid2000, csize200, csize500, csize2000, csizeF500, in_largest500,
                                     other_chain_addr, other_chain_funder, tok_after, eth_after, f_service)]   # entrant addresses are not needed downstream; service funders are public addresses

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

# ---- G. validation inputs: Base first-action targets (V4); L2 fee revenue, L1 rent and profit (V6) ----
campaign_targets <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, "val_targets_base.parquet")))[, `:=`(chain = "base", contract = as.integer(n_logs > 0))]
stopifnot(!anyDuplicated(campaign_targets$addr))
EC <- list()
for (m in c("fees", "rent_paid", "profit")) EC[[m]] <- as.data.table(fromJSON(file.path(DIR_RAW, "growthepie", sprintf("export_%s.json", m))))
EC <- rbindlist(EC)[metric_key %in% c("fees_paid_usd", "rent_paid_usd", "profit_usd") & origin_key %in% CHAINS]
l2_economics_daily <- dcast(EC[, .(chain = origin_key, date = as.IDate(date), metric_key, value)], chain + date ~ metric_key, value.var = "value", fun.aggregate = mean)
l2_economics_daily <- l2_economics_daily[date >= as.IDate(PULL_START) & date <= as.IDate(MAY_PULL[2])][order(chain, date)]   # through the May event window
setnames(l2_economics_daily, c("fees_paid_usd", "rent_paid_usd"), c("fees_usd", "rent_usd"))
gtrends_daily <- fread(here("data", "external", "gtrends_daily.csv"))[, date := as.IDate(date)]   # validation V5: browser capture in data/external (01 section M)
funder_labels <- fread(here("data", "external", "funder_labels.csv"))[, address := tolower(address)]   # names of the service funders of window entrants (block-explorer tags; see data/external/README.md)
recipient_labels <- fread(here("data", "external", "recipient_labels.csv"))[, address := tolower(address)]   # names of the most common first recipients of Base's non-burst entrants (data/external/README.md)
event_calendar <- fread(here("data", "external", "event_calendar.csv"), colClasses = list(character = "time_utc"))[, date := as.IDate(date)]   # dated events around the cuts, with sources (data/external/README.md)
cat(sprintf("G: %d first-action targets (%d contracts); %d chain-days of fees, rent and profit; %d Google Trends rows\n", nrow(campaign_targets), sum(campaign_targets$contract),
            nrow(l2_economics_daily), nrow(gtrends_daily)))

# ---- H. second Base event: gas limit raised 05-28 19:00 and 05-30 20:00 UTC (01 section N); Arbitrum, with no fee change then, as the comparison chain ----
# may_hourly: txs, fees, senders, new senders (no outgoing tx since 02-15) per chain and hour. may_entrants: new senders with a first outgoing tx in MAY_WINDOW,
# classified per chain with the March rules (bot-like: >= BOT_MIN_WEEK1 txs in week 1; burst: first-action group with >= SPIKE_MIN entrants a day and >= SPIKE_K x
# its median over MAY_WINDOW[1]..MAY_PRE_END). Base only: later activity, components as in section C (h = 500, May service degrees), link to March operators.
n_pre <- as.integer(MAY_PRE_END - MAY_WINDOW[1]) + 1L
MH <- list(); MS <- list()
for (ch in CHAINS) {
  MH[[ch]] <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, sprintf("may_hourly_%s.parquet", ch))))[, chain := ch]
  X <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, sprintf("may_entrant_%s.parquet", ch)))); setattr(X$first_dt, "tzone", "UTC")
  X[, `:=`(chain = ch, day = as.IDate(first_dt, tz = "UTC"), hr = lubridate::floor_date(first_dt, "hour"), pair = paste(first_to, first_sel))]
  X <- X[day >= MAY_WINDOW[1] & day <= MAY_WINDOW[2]]
  PR <- X[, .N, by = .(day, pair)]
  PR[, base := 0][PR[day <= MAY_PRE_END, .(b = median(c(N, rep(0L, n_pre - .N)))), by = pair], base := i.b, on = "pair"]
  X[, wave := as.integer(paste(day, pair) %in% PR[N >= SPIKE_MIN & N >= SPIKE_K * base, paste(day, pair)])]
  MS[[ch]] <- X[, class3 := fcase(n_week1 >= BOT_MIN_WEEK1, "bot", wave == 1, "campaign", default = "genuine")]
}
may_hourly <- rbindlist(MH, use.names = TRUE)[order(chain, hr)]; setattr(may_hourly$hr, "tzone", "UTC")
stopifnot(!anyDuplicated(may_hourly, by = c("chain", "hr")))
M <- MS$base
DGm <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, "may_degree_base.parquet")))
Pm <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, "may_post_base.parquet")))
acts_may <- paste0("act_", gsub("-", "_", RETENTION_MONTHS_MAY))
A <- dcast(Pm[a %in% M$a & ym %in% RETENTION_MONTHS_MAY, .(a, ym = paste0("act_", gsub("-", "_", ym)), v = 1L)], a ~ ym, value.var = "v", fill = 0L)
M <- merge(M, A, by = "a", all.x = TRUE)
for (m in acts_may) { if (!m %in% names(M)) M[, (m) := 0L]; M[is.na(get(m)), (m) := 0L] }
M[, months4 := rowSums(.SD), .SDcols = acts_may]
svf <- DGm[deg_pre >= 500 & role == "funder", addr]; svs <- DGm[deg_pre >= 500 & role == "sweep", addr]
ED <- rbind(M[!is.na(f_eth) & !(f_eth %in% svf), .(u = a, v = f_eth)], M[!is.na(sweep_to) & !(sweep_to %in% svs), .(u = a, v = sweep_to)])
G <- igraph::graph_from_data_frame(ED, directed = FALSE, vertices = data.frame(name = unique(c(M$a, ED$u, ED$v))))
cm <- igraph::components(G)$membership
M[, cid500 := unname(cm[a])][, csize500 := .N, by = cid500]
M[, f_service := fifelse(!is.na(f_eth) & f_eth %in% svf, f_eth, NA_character_)]   # service ETH funder (May degrees, h = 500), as for March (06 section Q)
# entity_daily and lookalike for the May window (section C3), with May service degrees; post = from 05-29 (05-28, the first step's day, is left out)
for (h in setdiff(c(HUB_MIN_EXTRA, HUB_MIN), 500)) {
  ED <- rbind(M[!is.na(f_eth) & !(f_eth %in% DGm[deg_pre >= h & role == "funder", addr]), .(u = a, v = f_eth)], M[!is.na(sweep_to) & !(sweep_to %in% DGm[deg_pre >= h & role == "sweep", addr]), .(u = a, v = sweep_to)])
  G <- igraph::graph_from_data_frame(ED, directed = FALSE, vertices = data.frame(name = unique(c(M$a, ED$u, ED$v))))
  cm <- igraph::components(G)$membership
  M[, (paste0("cid", h)) := unname(cm[a])]
}
M[, `:=`(pair = paste(first_to, first_sel), in_largest500 = as.integer(csize500 == max(csize500)))]
tt <- M[day >= MAY_PRE_END + 2 & class3 == "campaign", .N, by = first_to][which.max(N), first_to]
for (r in RULES) {
  M[, id := switch(r, campaign = fifelse(class3 == "campaign", paste("c", pair), paste("k", cid500)), singleton = fifelse(class3 == "genuine", paste("s", a), paste("k", cid500)),
                   `campaign+singleton` = fcase(class3 == "campaign", paste("c", pair), class3 == "genuine", paste("s", a), default = paste("k", cid500)),
                   as.character(get(paste0("cid", sub("^h", "", r)))))]
  for (s in SUBSETS) {
    Z <- switch(s, all = M, `without largest target` = M[!(first_to %in% tt)], `without largest component` = M[in_largest500 == 0])
    entity_daily[[length(entity_daily) + 1]] <- rbind(Z[, .(class = "all", n_addr = .N, n_ent = uniqueN(id)), by = day], Z[, .(n_addr = .N, n_ent = uniqueN(id)), by = .(day, class = class3)])[
      , `:=`(event = "may", chain = "base", rule = r, subset = s, largest_target = tt)]
  }
}
for (ch in CHAINS) lookalike[[paste("may", ch)]] <- (if (ch == "base") M else MS$arbitrum)[first_sel %in% "0x" & !is.na(first_to)][
  , period := fcase(day <= MAY_PRE_END, "pre", day >= MAY_PRE_END + 2, "post", default = NA_character_)][!is.na(period),
  .(n_plain = .N, self = mean(a == first_to), prefix4 = mean((substr(a, 3, 6) == substr(first_to, 3, 6))[a != first_to]), suffix4 = mean((substr(a, 39, 42) == substr(first_to, 39, 42))[a != first_to]),
    both4 = mean((substr(a, 3, 6) == substr(first_to, 3, 6) & substr(a, 39, 42) == substr(first_to, 39, 42))[a != first_to])), by = .(period, class3)][, `:=`(event = "may", chain = ch)]
entity_daily <- rbindlist(entity_daily, use.names = TRUE)[order(event, chain, rule, subset, class, day)]
lookalike <- rbindlist(lookalike, use.names = TRUE)[order(event, chain, period, class3)]
cat(sprintf("H: entity_daily %d rows; lookalike %d rows\n", nrow(entity_daily), nrow(lookalike)))
# Link to March operators, one hop: a March burst operator is a non-service funder or sweep target of >= CLUSTER_MIN March burst entrants; a May entrant
# links to one if its own non-service funder or sweep target is such an operator. (Components of a joint March + May graph are not used: one giant
# component, glued by thousands of incidental shared funders and sweep targets, absorbs most entrants of both periods.)
DGb <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, "val_degree_base.parquet")))
svf2 <- union(svf, DGb[deg_pre >= 500 & role == "funder", addr]); svs2 <- union(svs, DGb[deg_pre >= 500 & role == "sweep", addr])
MB <- mar_base[class3 == "campaign"]
OPS <- rbind(MB[!is.na(f_eth) & !(f_eth %in% svf2), .(v = f_eth)], MB[!is.na(sweep_to) & !(sweep_to %in% svs2), .(v = sweep_to)])[, .N, by = v][N >= CLUSTER_MIN, v]
M[, `:=`(fn = fifelse(!is.na(f_eth) & !(f_eth %in% svf2), f_eth, NA_character_), sn = fifelse(!is.na(sweep_to) & !(sweep_to %in% svs2), sweep_to, NA_character_))]
M[, march_operator := as.integer(fn %in% OPS | sn %in% OPS)]
ops_back <- sum(OPS %in% c(M$fn, M$sn))
may_entrants <- rbind(M[, c("chain", "day", "hr", "class3", "wave", "n_week1", "months4", acts_may, "csize500", "cid500", "march_operator", "f_eth_via", "f_service", "first_to", "first_sel"), with = FALSE],
                      MS$arbitrum[, .(chain, day, hr, class3)], fill = TRUE)[order(chain, hr)]   # Arbitrum, the comparison chain: entry time and class only (the other columns are NA)
may_ops <- data.table(march_burst_operators = length(OPS), active_again_in_may = ops_back)
eth_usd_daily_may <- fread(file.path(DIR_RAW, "eth_usd_daily_may.csv"))[, .(day = as.IDate(day), close)]; stopifnot(!anyDuplicated(eth_usd_daily_may$day))   # 01 section P
may_blocks <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, "may_blocks_base.parquet")))[order(hr)]; setattr(may_blocks$hr, "tzone", "UTC")   # 01 section Q
for (v in c("gas_limit_min", "gas_limit_max", "gas_used")) may_blocks[, (v) := as.numeric(get(v))]
stopifnot(!anyDuplicated(may_blocks$hr))
cat(sprintf("H: May chain-hours %d; entrants %s; Base burst share pre %.3f, post %.3f; March burst operators %d, of which active again in May %d; May entrants linked to one %.4f\n",
            nrow(may_hourly), paste(may_entrants[, .N, by = chain][, sprintf("%s %d", chain, N)], collapse = ", "), may_entrants[chain == "base" & day <= MAY_PRE_END, mean(class3 == "campaign")],
            may_entrants[chain == "base" & day > MAY_PRE_END + 1, mean(class3 == "campaign")], length(OPS), ops_back, may_entrants[chain == "base", mean(march_operator)]))
rm(M, MS, MB, Pm); invisible(gc())
# Hourly fee quantiles (01 section R): fee in ETH paid by the 25th, 50th and 75th percentile successful tx with a positive fee, both chains, March and May pulls.
# The median is the price of a typical tx; the hourly mean (l2_hourly, may_hourly) is dominated by a few high-priority txs once fees are cents.
fee_quantiles_hourly <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, "fee_quantiles_hourly.parquet")))[, n_paid := as.numeric(n_paid)][order(chain, hr)]
setattr(fee_quantiles_hourly$hr, "tzone", "UTC"); stopifnot(!anyDuplicated(fee_quantiles_hourly, by = c("chain", "hr")))
cat(sprintf("H: fee quantiles for %d chain-hours\n", nrow(fee_quantiles_hourly)))

# ---- I. long series of new addresses (01 section T): one wave rule at every date ----
# Wave: a first-action group with >= SPIKE_MIN new addresses on day d and >= SPIKE_K x its median over d - WAVE_TRAIL .. d - 1 (days without the group, or with
# the group pooled for having fewer than 10 new addresses, count as zero). The baseline trails every date in the same way, so it is not anchored to any cut.
# Size-only variant: groups with >= WAVE_SIZE_ALT new addresses a day. Two groupings:
#   "target x method": recipient x method selector (as the burst rule), Base and Arbitrum (and Ethereum L1 if LONG_CONTROL_SELECTOR);
#   "target": recipient only, Base, Arbitrum and Ethereum L1 (the comparison chain); recipient sums leave out groups pooled by section T and contract creations.
# long_daily (grouping x chain x day, LONG_FROM..LONG_END): senders; new addresses; heavy new addresses (>= BOT_MIN_WEEK1 txs that day); new and heavy new
# addresses in waves; number of waves and the largest; new addresses in size-only waves. long_waves: every wave group-day (main rule), for leave-one-out in 06 section K.
# long_floor_daily (floor x chain x day; recipient x method groups; Base and the comparison chain): new and heavy new addresses in waves when the size floor
# SPIKE_MIN is replaced by each of WAVE_FLOORS (the SPIKE_MIN row reproduces long_daily). The trailing median is taken by a non-equi join of each candidate
# group-day with the same group's previous WAVE_TRAIL days (days without the group count as zero, as above).
long_daily <- list(); long_waves <- list()
for (gp in c("target x method", "target")) for (ch in if (gp == "target") c(CHAINS, LONG_CONTROL) else c(CHAINS, if (LONG_CONTROL_SELECTOR) LONG_CONTROL)) {
  LG <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, sprintf("long_entrants_%s.parquet", ch))))[, `:=`(day = as.IDate(day), n = as.numeric(n), n_heavy = as.numeric(n_heavy))]
  LS <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, sprintf("long_senders_%s.parquet", ch))))[, `:=`(day = as.IDate(day), senders = as.numeric(senders), new_senders = as.numeric(new_senders))]
  HV <- LG[day >= LONG_FROM & day <= LONG_END, .(heavy = sum(n_heavy)), by = day]
  LG <- if (gp == "target") LG[!is.na(first_to), .(n = sum(n), n_heavy = sum(n_heavy), first_sel = NA_character_), by = .(day, first_to)][, g := first_to] else
          LG[!is.na(first_to) | !is.na(first_sel)][, g := paste(first_to, first_sel)]
  setkey(LG, g)
  CAN <- LG[n >= SPIKE_MIN & day >= LONG_FROM & day <= LONG_END][, base := NA_real_]   # candidate group-days
  for (i in seq_len(nrow(CAN))) {
    h <- LG[.(CAN$g[i])][day >= CAN$day[i] - WAVE_TRAIL & day < CAN$day[i], n]
    set(CAN, i, "base", median(c(h, rep(0, WAVE_TRAIL - length(h)))))
  }
  W <- CAN[n >= SPIKE_K * base]
  long_waves[[paste(gp, ch)]] <- W[, .(grouping = gp, chain = ch, day, first_to, first_sel, n, n_heavy, base)]
  D <- merge(LS[day >= LONG_FROM & day <= LONG_END, .(day, senders, new = new_senders)], HV, by = "day", all.x = TRUE)
  D <- merge(D, W[, .(wave_new = sum(n), wave_heavy = sum(n_heavy), waves = .N, largest_wave = max(n)), by = day], by = "day", all.x = TRUE)
  D <- merge(D, LG[n >= WAVE_SIZE_ALT & day >= LONG_FROM & day <= LONG_END, .(size_new = sum(n)), by = day], by = "day", all.x = TRUE)
  for (v in c("heavy", "wave_new", "wave_heavy", "waves", "largest_wave", "size_new")) D[is.na(get(v)), (v) := 0]
  long_daily[[paste(gp, ch)]] <- D[, `:=`(grouping = gp, chain = ch)]
  cat(sprintf("I %s, %s: %d days; new addresses per day %.0f; in waves %.3f (size-only %.3f); %d wave group-days\n", gp, ch, nrow(D), D[, mean(new)], D[, sum(wave_new) / sum(new)],
              D[, sum(size_new) / sum(new)], nrow(W)))
}
long_daily <- rbindlist(long_daily, use.names = TRUE)[order(grouping, chain, day)]; long_waves <- rbindlist(long_waves, use.names = TRUE)[order(grouping, chain, day, -n)]
long_floor_daily <- list()
for (ch in c("base", LONG_CONTROL)) {
  LG <- as.data.table(nanoparquet::read_parquet(file.path(DIR_RAW, sprintf("long_entrants_%s.parquet", ch))))[, `:=`(day = as.IDate(day), n = as.numeric(n), n_heavy = as.numeric(n_heavy))]
  LG <- LG[!is.na(first_to) | !is.na(first_sel)][, g := paste(first_to, first_sel)]
  for (fl in WAVE_FLOORS) {
    CAN <- LG[n >= fl & day >= LONG_FROM & day <= LONG_END, .(g, d0 = day, n, n_heavy)][, `:=`(id = .I, lo = d0 - WAVE_TRAIL)]
    H <- LG[CAN, on = .(g, day >= lo, day < d0), .(id = i.id, h = x.n), nomatch = NULL]   # the group's counts on d0 - WAVE_TRAIL .. d0 - 1
    CAN <- merge(CAN, H[, .(base = median(c(h, rep(0, WAVE_TRAIL - .N)))), by = id], by = "id", all.x = TRUE)[is.na(base), base := 0]
    long_floor_daily[[paste(ch, fl)]] <- CAN[n >= SPIKE_K * base, .(floor = fl, chain = ch, wave_new = sum(n), wave_heavy = sum(n_heavy)), by = .(day = d0)]
  }
}
long_floor_daily <- rbindlist(long_floor_daily)
long_floor_daily <- merge(CJ(floor = WAVE_FLOORS, chain = c("base", LONG_CONTROL), day = seq(LONG_FROM, as.IDate(LONG_END), by = 1)), long_floor_daily, by = c("floor", "chain", "day"), all.x = TRUE)
for (v in c("wave_new", "wave_heavy")) long_floor_daily[is.na(get(v)), (v) := 0]
cat(sprintf("I: wave volume at %d size floors, Base and %s: %d rows\n", length(WAVE_FLOORS), LONG_CONTROL, nrow(long_floor_daily)))
rm(LG, LS, HV, CAN, W, D, H); invisible(gc())

# ---- save ----
PANELS <- c("l2_hourly", "l2_hourly_type", "l2_newsenders", "control_hourly", "eth_usd_daily", "entrants", "sender_window", "base_tx_by_class", "base_hourly_campaign",
            "multichain_daily", "multichain_drops", "lz_meta", "campaign_targets", "l2_economics_daily", "gtrends_daily", "receipts_by_token", "fb_sent", "may_hourly", "may_entrants", "may_ops", "eth_usd_daily_may", "may_blocks", "fee_quantiles_hourly",
            "entity_daily", "entrant_funding", "lookalike", "long_daily", "long_waves", "long_floor_daily", "funder_labels", "recipient_labels", "event_calendar")
saveRDS(mget(PANELS), PANEL_FILE, compress = "xz")
cat(sprintf("Saved %s (%.1f MB): %s\n", basename(PANEL_FILE), file.size(PANEL_FILE) / 1e6, paste(PANELS, collapse = ", ")))
cat("\n## sessionInfo\n```\n"); print(sessionInfo()); cat("```\n"); sink()
