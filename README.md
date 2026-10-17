# PricingAccessDigitalPlatform

What does a fee cut buy on an open platform, where one operator can create thousands of accounts at almost no cost? The project estimates the causal effect of one abrupt fee cut on entry, and breaks the rise in counted new accounts down into batch-created accounts and other entry.

**Main design.** At 00:00 UTC on 14 March 2024 the Ecotone upgrade cut the median transaction fee on Base, an Ethereum Layer-2 platform, from tens of cents to under one cent for six days. Daily entry of new addresses outside batch-creation waves on Base is compared with Ethereum L1 and judged against the same comparison at earlier (placebo) dates. The rise in counted new addresses is broken down into batch waves and other entry; new accounts are classified (burst-created, bot-like, other) and the classification is validated (funding clusters, synchronization, an external Sybil list, persistence). Alternative explanations are tested with the hours of the cut day, the first recipients and funding sources of new accounts, OP Mainnet (which received the same upgrade at the same second), and a donor pool of chains without a fee cut.

**Other cuts and earlier analyses.** The repository also covers four further cuts at hourly resolution (Arbitrum: ArbOS 20 at 03-14 15:00 UTC and its minimum base fee at 03-19 08:00 UTC; Base: block gas limit raised at 05-28 19:00 and 05-30 20:00 UTC) and the usage response (regression discontinuity in time with randomization inference, elasticities, a multi-rollup replication). `results/paper/README.md` lists which exhibits the paper uses.

## Repository layout

```
PricingAccessDigitalPlatform.Rproj   RStudio project (sets the project root)
code/                                R scripts, run in order
data/raw/                            downloaded aggregates (~3 GB; not in git, rebuilt by 01)
data/external/                       inputs that cannot be downloaded by script (Google Trends capture, funder and recipient name tags, event calendar)
data/panel/panel.rds                 analysis panels: a named list of 32 tables (~91 MB; in git)
data/panel/contract.yaml             validation record; analyses refuse to run without it
results/tables/                      CSV tables
results/figures/                     PNG figures
results/logs/                        one log per script, with sessionInfo
results/paper/                       the paper's main tables (tables.md) and an index of every exhibit (README.md), written by 08
```

## How to run

1. Open `PricingAccessDigitalPlatform.Rproj` in RStudio, or run `Rscript code/0X_....R` from the project root.
2. Run the scripts in order. Each one sources `code/00_setup.R` first and runs standalone. The scripts define no functions and run top to bottom; every regression is preceded by its equation in a comment. `00_setup.R` stops with an `install.packages()` command if any package is missing.

| Script | What it does | Needs |
|---|---|---|
| `00_setup.R` | Packages, paths, constants (event times, burst rule, graph thresholds, May windows, method selectors), figure theme | |
| `01_download.R` | Public data → `data/raw`. Each section is skipped if its files exist | Internet |
| `02_build_panels.R` | `data/raw` → `data/panel/panel.rds` | `data/raw`, ~5 min |
| `03_validate_panels.R` | Checks every panel table; cross-checks daily counts and the median fee against growthepie and the fee break at each event hour; writes `contract.yaml` | `panel.rds` |
| `04_analysis_main.R` | Hourly RD in time at the five cuts with randomization inference (market controls and L1/Bitcoin placebo RDs at the March cuts), elasticities as fuzzy RD with the median fee per tx as the price, Base vs not-yet-treated Arbitrum DiD and event study, responses by transaction type | `panel.rds` |
| `05_analysis_robustness.R` | Specification grid, weekly differencing, market controls, burst-net activity, inference variants, placebo at the L1 fork hour | `panel.rds` |
| `06_analysis_users.R` | Entry and retention (local randomization), daily cohorts, burst / bot-like / other entrants with rule bounds, decomposition of the change in transactions, response by fee level; validation (LayerZero list, funding clusters, timing, targets, Google Trends, platform economics); who runs the burst accounts; the second Base cut (first actions, Arbitrum as comparison chain, window variants); dollar stakes, friction bounds and platform profit; robustness of the composition results (hourly entry with classes fixed in time, address vs entity growth under alternative linkage rules, leave-one-out); the largest burst groups, an address-poisoning check, the cost of a manufactured address, and non-burst entry at the four cuts with one estimator; with one definition of a new address over 2024-01..06 on both chains, waves of new addresses before and after the fee regime changed and entry at the four cuts, each against placebo dates, with Ethereum L1 as a chain without a fee change; the Base March entry effect (daily event study against L1, placebo dates before the cut, delay vs new entry, persistence) and where the extra non-burst entrants' first ETH came from (exchanges, bridges, individuals, funding clusters); both Base cuts with one estimator against L1 and Arbitrum (placebo sets, p floors, non-overlapping windows), waves per day around the May steps, Base against OP Mainnet, the cut hour by outcome and estimator, and the funding entities behind non-burst entry (accounting variants and the composition deflator); headline numbers from one sample (with the batch share under each rule), the inference table for the primary statistic (the 6 days of low fees, 7 days, the 4-7-day path and the window without 03-19; the largest placebos with their before-window slopes and the events in their windows; wave and burst size floors from 50 to 10,000 with the breakdown and the implied entity effect), entrant classes on equal 6-day windows, the cut hour with pre-cut fake hours, checks against a Base-specific demand shock (named first recipients, recipient categories, the ETH rally, the cut day in blocks of hours, first actions), the four cuts in one table (pre-cut fake hours; entry minus L1 up to each chain's next cut), the daily fee path on Base, OP Mainnet, Arbitrum and L1, the March cut on OP Mainnet against L1, and a donor pool of chains without a fee cut against the L1 comparison | `panel.rds` |
| `07_analysis_multichain.R` | Multi-rollup per-event DiD, stacked DiD/2SLS, Callaway–Sant'Anna with documented upgrade dates, fee-level test, second drops by rollup; Base May daily DiD and event study against seven other chains | `panel.rds` |
| `08_paper_exhibits.R` | Lays out the paper's Tables 1–5 from the outputs of `04`–`07` (`results/paper/tables.md`) and indexes every main exhibit (five tables, four figures) and appendix exhibit with links to its file (`results/paper/README.md`) | outputs of `04`–`07` |

`panel.rds` is in the repository, so `03`–`08` run without downloading anything (a few minutes). Rebuilding from scratch requires `01` and `02`; `01` needs about 10 GB of memory for DuckDB and about 3 GB of disk. Given `data/raw`, `02`–`08` are deterministic: two full rebuilds produced the same `panel.rds` and the same tables and figures byte for byte (same platform and package versions). `01` reads live public sources (growthepie, Coinbase, GitHub mirrors) that can be revised, so a new download can differ slightly.

## Data sources

All public, no API keys:

- **AWS Public Blockchain Data** (`s3://aws-public-blockchain`, read anonymously with DuckDB): sonarx transaction, failed-transaction, trace, transfer, log and block tables for Base and Arbitrum; Ethereum transactions (the comparison chain of the long series) and Ethereum and Bitcoin blocks.
- **growthepie** public exports: daily transactions, active addresses, median fee, fee revenue, L1 data cost and profit for Layer-2s.
- **LayerZero** provisional Sybil list (Wayback Machine capture of the official file, plus two public mirrors as checks).
- **Google Trends** daily search interest (captured in a browser; the capture is in `data/external`, see its README).
- **Name tags** of the service addresses that funded new accounts and of the most common first recipients of new accounts (BaseScan pages, the dawsbot/evm-labels set, Sourcify verified contracts and Base's public RPC endpoint; looked up once, in `data/external`, see its README).
- **Dated events** around the cuts (news reports and project announcements; each with its link in `data/external/event_calendar.csv`).
- **Coinbase Exchange** public candles: ETH/USD daily.
- **4byte.directory**: text signatures of the method selectors named in `00_setup.R`, `06` and `data/external/recipient_labels.csv` (looked up once; hard-coded).
- **Blockscout** (base.blockscout.com): names of the most common tokens received by new accounts and the deployment time of the "EIP-4844 is Based" mint contract (looked up once; hard-coded in `06`).

## Software

Tested with R 4.5.3 and data.table 1.18.2.1, fixest 0.14.2, did 2.3.0, ggplot2 4.0.2, duckdb 1.5.0, nanoparquet 0.5.2, igraph 2.2.2, here 1.0.2 (full list in `00_setup.R`; versions in each log's sessionInfo).

## License

The code is released under the MIT License (see [`LICENSE`](LICENSE)). `data/panel`, `data/external` and `results` contain data derived from the sources above; their use is subject to those sources' terms, and they should be cited when the data are reused.
