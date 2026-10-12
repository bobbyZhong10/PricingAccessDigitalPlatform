# 00_setup.R: packages, paths, constants and helpers; sourced by every script.
# Open PricingAccessDigitalPlatform.Rproj and run 01-07 in order. All times are UTC.
#   01_download             public data -> data/raw (not in git)
#   02_build_panels         data/raw -> data/panel/panel.rds (named list of panels)
#   03_validate_panels      checks panel.rds -> data/panel/contract.yaml
#   04_analysis_main        hourly RD in time and DiD at the three fee drops
#   05_analysis_robustness  specification grid, alternative controls, placebo
#   06_analysis_users       entry, retention, campaigns and bots, fee-level heterogeneity
#   07_analysis_multichain  multi-rollup replication (growthepie)

PKGS <- c("here", "data.table", "fixest", "did", "ggplot2", "nanoparquet", "jsonlite", "yaml", "lubridate", "scales", "DBI", "duckdb")
miss <- PKGS[!vapply(PKGS, requireNamespace, logical(1), quietly = TRUE)]
if (length(miss)) stop("Install missing packages first: install.packages(c(", paste0('"', miss, '"', collapse = ", "), "))")
suppressPackageStartupMessages({
  library(here); library(data.table); library(fixest); library(ggplot2); library(jsonlite)
})
Sys.setenv(TZ = "UTC")
options(scipen = 6, warn = 1, width = 250, datatable.print.nrows = 200, datatable.print.class = FALSE, datatable.print.keys = FALSE)
set.seed(20240314)

DIR_RAW <- here("data", "raw"); DIR_PANEL <- here("data", "panel"); DIR_RES <- here("results")
for (d in c(DIR_RAW, DIR_PANEL, file.path(DIR_RES, c("tables", "figures", "logs")))) dir.create(d, recursive = TRUE, showWarnings = FALSE)
raw <- function(...) file.path(DIR_RAW, ...)
panel <- function(...) file.path(DIR_PANEL, ...)
res <- function(...) file.path(DIR_RES, ...)
PANEL_FILE <- panel("panel.rds")

# ---- constants ----
CHAINS <- c("base", "arbitrum")
PULL_START <- as.Date("2024-02-15"); PULL_END <- as.Date("2024-04-15")
# Base: Ecotone (unix 1710374401); Arbitrum: ArbOS 20 (blobs), then minimum base fee 0.1 -> 0.01 gwei
EVENTS <- data.table(event = c("Base (Ecotone)", "Arbitrum step 1", "Arbitrum step 2"), chain = c("base", "arbitrum", "arbitrum"),
                     t0 = as.POSIXct(c("2024-03-14 00:00:00", "2024-03-14 15:00:00", "2024-03-19 08:00:00"), tz = "UTC"),
                     label = c("Base: Ecotone upgrade\n14 Mar 2024, 00:00 UTC", "Arbitrum: blob pricing (ArbOS 20)\n14 Mar 2024, 15:00 UTC",
                               "Arbitrum: lower fee floor\n19 Mar 2024, 08:00 UTC"))   # label: figure panels
L1_FORK <- as.POSIXct("2024-03-13 13:00:00", tz = "UTC")   # Dencun on Ethereum L1 (13:55 UTC)
SYSTEM_SENDERS <- c(base = "0xdeaddeaddeaddeaddeaddeaddeaddeaddead0001",      # one L1-attributes deposit per block
                    arbitrum = "0x00000000000000000000000000000000000a4b05")  # one ArbOS internal tx per block
HF_MIN_WEEKLY <- 700        # high-frequency sender: >= 700 txs in 2024-02-15..21
ENTRANT_WINDOW <- as.IDate(c("2024-03-08", "2024-03-21"))
PRE_END <- as.IDate("2024-03-13")   # last full day before any L2 fee drop; campaign baselines use only entrants up to this day
SPIKE_MIN <- 1000; SPIKE_K <- 3     # campaign burst: >= 1,000 entrants in a day and >= 3x the group's pre-shock median daily count
WAVE_SIZE_ALT <- 5000               # bound 1 (size only): first-action group of >= 5,000 entrants in a day
FUNDER_BURST_MIN <- 100             # bound 2: burst group mostly funded by addresses that fund >= 100 entrants that day and >= 3x their pre-shock median
BOT_MIN_WEEK1 <- 100        # bot-like entrant: >= 100 txs in its first week
RETENTION_MONTHS <- c("2024-04", "2024-06", "2024-09", "2024-12", "2025-03")   # activity measured on days 1-10
# sender windows for the fee-level analysis: before/after each drop, plus a placebo pair without a fee change (Arbitrum step 2: post1 -> post2)
FEE_WINDOWS <- data.table(chain = rep(c("base", "arbitrum"), c(4, 5)), window = c("pre", "post", "placebo_pre", "placebo_post", "pre1", "post1", "post2", "placebo_pre", "placebo_post"),
  start = as.IDate(c("2024-03-06", "2024-03-14", "2024-02-22", "2024-03-01", "2024-03-10", "2024-03-15", "2024-03-20", "2024-02-22", "2024-02-27")),
  end = as.IDate(c("2024-03-12", "2024-03-20", "2024-02-28", "2024-03-07", "2024-03-13", "2024-03-18", "2024-03-23", "2024-02-25", "2024-03-01")))

# Campaign flags for entrants in ENTRANT_WINDOW (used by 01 and 02). A campaign is a burst relative to the group's own pre-shock level, so groups that
# recur every day (e.g. exchange withdrawals followed by a USDT transfer) are not flagged. Baseline = median daily count on ENTRANT_WINDOW[1]..PRE_END,
# counting days without entrants as zero. wave: first recipient x method group; batch: first funder (ETH, else token).
# Bounds: wave_size flags large groups regardless of history (catches recurring popular actions too); wave_funded requires the burst to be funded by
# bursting funders (misses campaigns whose funding is not observed, e.g. bridged in from L1).
campaign_flags <- function(first_out, fund_eth, fund_tok, window = ENTRANT_WINDOW) {
  X <- merge(first_out, fund_eth[, .(a, funder)], by = "a", all.x = TRUE)
  X <- merge(X, fund_tok[, .(a, tfunder)], by = "a", all.x = TRUE)
  X[, `:=`(day = as.IDate(first_dt, tz = "UTC"), funder_any = fifelse(!is.na(funder), funder, tfunder), pair = paste(first_to, first_sel))]
  X <- X[day >= window[1] & day <= window[2]]
  n_pre <- as.integer(PRE_END - window[1]) + 1L
  burst <- function(D, key, min) { D[, base := 0][D[day <= PRE_END, .(b = median(c(N, rep(0L, n_pre - .N)))), by = key], base := i.b, on = key]
    D[N >= min & N >= SPIKE_K * base, paste(day, get(key))] }
  FD <- X[!is.na(funder_any), .N, by = .(day, funder_any)]
  pr <- burst(X[, .N, by = .(day, pair)], "pair", SPIKE_MIN); fd <- burst(copy(FD), "funder_any", SPIKE_MIN); fb <- burst(copy(FD), "funder_any", FUNDER_BURST_MIN)
  X[, `:=`(wave = as.integer(paste(day, pair) %in% pr), batch = as.integer(!is.na(funder_any) & paste(day, funder_any) %in% fd), fburst = paste(day, funder_any) %in% fb)]
  X[, `:=`(wave_size = as.integer(.N >= WAVE_SIZE_ALT), wave_funded = as.integer(wave == 1 & mean(fburst) >= 0.5)), by = .(day, pair)][, fburst := NULL][] }

# ---- logging: say() and logp() print and keep lines; save_log() writes results/logs/<script>.md with sessionInfo ----
.LOG <- new.env()
new_log <- function(title) { .LOG$x <- character(0); say("# ", title); say("Run ", format(Sys.time(), usetz = TRUE)) }
say <- function(...) { x <- paste0(...); .LOG$x <- c(.LOG$x, x); cat(x, "\n") }
logp <- function(x) { o <- capture.output(print(x)); .LOG$x <- c(.LOG$x, o); cat(o, sep = "\n") }
save_log <- function(name) writeLines(c(.LOG$x, "", "## sessionInfo", "```", capture.output(sessionInfo()), "```"), res("logs", paste0(name, ".md")))
rnd <- function(dt, d = 3) dt[, lapply(.SD, function(z) if (is.numeric(z)) signif(z, d) else z)]

# ---- figures: one palette and theme; no titles (captions belong in the paper) ----
COL <- c(main = "#2a78d6", ref = "#8a8984", ink = "#0b0b0b", ink2 = "#52514e", grid = "#e8e7e2")   # treated series, comparison series, text, gridlines
theme_fig <- function() theme_minimal(base_size = 10) + theme(
  panel.grid.minor = element_blank(), panel.grid.major = element_line(colour = COL[["grid"]], linewidth = 0.3), axis.text = element_text(colour = COL[["ink2"]]),
  axis.title = element_text(colour = COL[["ink"]]), strip.text = element_text(colour = COL[["ink"]], hjust = 0, size = 9.5), legend.position = "bottom",
  legend.title = element_blank(), legend.text = element_text(colour = COL[["ink"]]), panel.spacing = unit(14, "pt"), plot.margin = margin(8, 16, 8, 8))
save_fig <- function(g, name, w, h) ggsave(res("figures", name), g, width = w, height = h, dpi = 200, bg = "white")

check_unique <- function(dt, keys, label = "") if (anyDuplicated(dt, by = keys)) stop(sprintf("%s: duplicate keys (%s)", label, paste(keys, collapse = ", ")))
read_pq <- function(path) { x <- as.data.table(nanoparquet::read_parquet(path)); for (v in names(x)) if (inherits(x[[v]], "POSIXct")) setattr(x[[v]], "tzone", "UTC"); x[] }

# Puts the named panel objects into the workspace; stops unless panel.rds passed 03_validate_panels.R and is unchanged since.
load_panel <- function(objs) {
  if (!file.exists(panel("contract.yaml"))) stop("data/panel/contract.yaml not found: run code/03_validate_panels.R first")
  ct <- yaml::read_yaml(panel("contract.yaml"))
  if (!isTRUE(ct$all_valid)) stop("panel.rds failed validation; see results/logs")
  if (unname(tools::md5sum(PANEL_FILE)) != ct$md5) stop("panel.rds changed since validation; rerun code/03_validate_panels.R")
  P <- readRDS(PANEL_FILE); miss <- setdiff(objs, names(P)); if (length(miss)) stop("not in panel.rds: ", paste(miss, collapse = ", "))
  for (o in objs) assign(o, P[[o]], envir = .GlobalEnv) }
