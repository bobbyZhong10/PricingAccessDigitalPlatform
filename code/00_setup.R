# 00_setup.R: packages, paths and constants; sourced at the top of every script. Defines no functions.
# Open PricingAccessDigitalPlatform.Rproj and run 01-07 in order. All times are UTC.
#   01_download             public data -> data/raw (not in git)
#   02_build_panels         data/raw -> data/panel/panel.rds (named list of panels)
#   03_validate_panels      checks panel.rds -> data/panel/contract.yaml
#   04_analysis_main        hourly RD in time and DiD at the three fee drops
#   05_analysis_robustness  specification grid, alternative controls, placebo
#   06_analysis_users       entry, retention, campaigns and bots, fee-level heterogeneity
#   07_analysis_multichain  multi-rollup replication (growthepie)
# Each script writes its printed output to results/logs/<script>.md (via sink) and ends with sessionInfo().

PKGS <- c("here", "data.table", "fixest", "did", "ggplot2", "nanoparquet", "jsonlite", "yaml", "lubridate", "scales", "DBI", "duckdb")
miss <- PKGS[!vapply(PKGS, requireNamespace, logical(1), quietly = TRUE)]
if (length(miss)) stop("Install missing packages first: install.packages(c(", paste0('"', miss, '"', collapse = ", "), "))")
suppressPackageStartupMessages({
  library(here); library(data.table); library(fixest); library(ggplot2); library(jsonlite)
})
Sys.setenv(TZ = "UTC")
options(scipen = 6, warn = 1, width = 250, digits = 4, datatable.print.nrows = 200, datatable.print.class = FALSE, datatable.print.keys = FALSE)
set.seed(20240314)
while (sink.number() > 0) sink()   # close a log left open by an interrupted run

# ---- paths ----
DIR_RAW <- here("data", "raw"); DIR_PANEL <- here("data", "panel")
DIR_TAB <- here("results", "tables"); DIR_FIG <- here("results", "figures"); DIR_LOG <- here("results", "logs")
for (d in c(DIR_RAW, DIR_PANEL, DIR_TAB, DIR_FIG, DIR_LOG)) dir.create(d, recursive = TRUE, showWarnings = FALSE)
PANEL_FILE <- file.path(DIR_PANEL, "panel.rds"); CONTRACT_FILE <- file.path(DIR_PANEL, "contract.yaml")

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
RETENTION_MONTHS <- c("2024-04", "2024-06", "2024-09", "2024-12", "2025-03")   # activity measured on days 1-10
BOT_MIN_WEEK1 <- 100        # bot-like entrant: >= 100 txs in its first week
# Campaign rule (applied in 01 section G and 02 section C; the two blocks must stay identical). A campaign is a burst relative to the group's own
# pre-shock level, so groups that recur every day (e.g. exchange withdrawals followed by a USDT transfer) are not flagged.
PRE_END <- as.IDate("2024-03-13")   # last full day before any L2 fee drop; baselines use entrants on ENTRANT_WINDOW[1]..PRE_END only
SPIKE_MIN <- 1000; SPIKE_K <- 3     # burst: >= 1,000 entrants in a day and >= 3x the group's pre-shock median daily count
WAVE_SIZE_ALT <- 5000               # bound 1 (size only): first-action group of >= 5,000 entrants in a day
FUNDER_BURST_MIN <- 100             # bound 2: burst mostly funded by addresses that fund >= 100 entrants that day and >= 3x their pre-shock median
# sender windows for the fee-level analysis: before/after each drop, plus a placebo pair without a fee change (Arbitrum step 2: post1 -> post2)
FEE_WINDOWS <- data.table(chain = rep(c("base", "arbitrum"), c(4, 5)), window = c("pre", "post", "placebo_pre", "placebo_post", "pre1", "post1", "post2", "placebo_pre", "placebo_post"),
  start = as.IDate(c("2024-03-06", "2024-03-14", "2024-02-22", "2024-03-01", "2024-03-10", "2024-03-15", "2024-03-20", "2024-02-22", "2024-02-27")),
  end = as.IDate(c("2024-03-12", "2024-03-20", "2024-02-28", "2024-03-07", "2024-03-13", "2024-03-18", "2024-03-23", "2024-02-25", "2024-03-01")))

# ---- figures: one palette and theme; no titles (captions belong in the paper) ----
COL <- c(main = "#2a78d6", ref = "#8a8984", ink = "#0b0b0b", ink2 = "#52514e", grid = "#e8e7e2")   # treated series, comparison series, text, gridlines
THEME_FIG <- theme_minimal(base_size = 10) + theme(
  panel.grid.minor = element_blank(), panel.grid.major = element_line(colour = COL[["grid"]], linewidth = 0.3), axis.text = element_text(colour = COL[["ink2"]]),
  axis.title = element_text(colour = COL[["ink"]]), strip.text = element_text(colour = COL[["ink"]], hjust = 0, size = 9.5), legend.position = "bottom",
  legend.title = element_blank(), legend.text = element_text(colour = COL[["ink"]]), panel.spacing = unit(14, "pt"), plot.margin = margin(8, 16, 8, 8))
