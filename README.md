# PricingAccessDigitalPlatform

What does a fee cut buy on an open platform, where one operator can create thousands of accounts at almost no cost? This repository reproduces every table, figure and reported number of the paper *What Does a Fee Cut Buy? Participation Costs, Replicable Identities, and Entry on a Digital Platform*.

**Design.** At 00:00 UTC on 14 March 2024 the Ecotone upgrade cut the median transaction fee on Base, an Ethereum Layer-2 platform, by 99% for six days. The rise in counted new addresses on Base is broken down into batch waves (synchronized groups of new addresses taking the same first action) and entry outside them. Entry outside waves on Base is compared with Ethereum L1 over the six low-fee days and ranked against the same comparison at earlier (placebo) dates, under alternative baselines and outcome definitions. New accounts are classified (burst, heavy, non-burst) and linked by funding flows into funding entities. Alternative explanations are examined with the hours of the cut day, the first recipients and funding sources of new accounts, OP Mainnet (which received the same upgrade at the same moment), a donor pool of chains without a fee cut, and Base's second fee cut in May.

## Repository layout

```
PricingAccessDigitalPlatform.Rproj   RStudio project (sets the project root)
code/                                R scripts, run in order
data/raw/                            downloaded aggregates (not in git, rebuilt by 01)
data/external/                       inputs that cannot be downloaded by script (name tags of funders and first recipients, the event calendar)
data/panel/panel.rds                 analysis panels: a named list of 17 tables (in git)
data/panel/contract.yaml             validation record; 04 and 05 refuse to run without it
results/tables/                      CSV tables written by 04
results/figures/                     PNG figures written by 04
results/paper/                       Tables 1-3 and A.7 laid out as in the paper, and an index of every exhibit and the files behind it (written by 05)
results/logs/                        one log per script, with sessionInfo
```

## How to run

1. Open `PricingAccessDigitalPlatform.Rproj` in RStudio, or run `Rscript code/0X_....R` from the project root.
2. Run the scripts in order. Each one sources `code/00_setup.R` first and runs standalone. The scripts define no functions and run top to bottom; every regression is preceded by its equation in a comment. `00_setup.R` stops with an `install.packages()` command if any package is missing.

| Script | What it does | Needs |
|---|---|---|
| `00_setup.R` | Packages, paths, constants (event times, the wave and burst rules, funding-graph thresholds, the May windows, method selectors), figure theme | |
| `01_download.R` | Public data → `data/raw`. Each section is skipped if its files exist | Internet; about 10 GB of memory and 3 GB of disk; 4-5 hours |
| `02_build_panels.R` | `data/raw` → `data/panel/panel.rds`: hourly new senders, window entrants and their classes, funding entities, the long series of new addresses with its waves and first-action groups, the May event, growthepie aggregates | `data/raw`, about 5 minutes |
| `03_validate_panels.R` | Checks every panel table; cross-checks the median fee against growthepie and its break at each event hour; writes `contract.yaml` | `panel.rds` |
| `04_analysis.R` | All estimates: the breakdown of counted new addresses, the entry effect against Ethereum L1 with its placebo inference, alternative counterfactuals, outcome definitions and size floors, entrant classes and funding entities, the cut day by hour, first recipients and funding sources, OP Mainnet and the donor pool, the four fee cuts and the May waves | `panel.rds`, about 1 minute |
| `05_paper_exhibits.R` | Lays out Tables 1-3 and A.7 as in the paper and writes `results/paper/README.md`, which maps every table and figure of the paper, and the numbers its text derives, to the files of `results/`; checks that every file 04 writes is used | outputs of 04 |

`panel.rds` is in the repository, so `03`-`05` run without downloading anything. Rebuilding from scratch requires `01` and `02`. Given `data/raw`, `02`-`05` are deterministic: a rebuild reproduces `panel.rds` and every table and figure (same platform and package versions; numbers can differ in the last floating-point digits across platforms). `01` reads live public sources (growthepie, Coinbase) that can be revised, so a new download can differ slightly. `results/logs/01_download.md` records the download that produced `data/raw`.

## Data sources

All public, no API keys:

- **AWS Public Blockchain Data** (`s3://aws-public-blockchain`, read anonymously with DuckDB): sonarx transaction, failed-transaction, trace, transfer and log tables for Base and Arbitrum; Ethereum L1 transactions (the comparison chain of the long series).
- **growthepie** public exports: daily transactions, active addresses, median fee, fee revenue, L1 data cost and profit for Layer-2 platforms.
- **Coinbase Exchange** public candles: ETH/USD daily.
- **LayerZero** provisional Sybil list (Internet Archive capture of the official file).
- **Name tags** of the service addresses that funded new accounts and of the most common first recipients of new accounts (BaseScan pages, the dawsbot/evm-labels set, Sourcify verified contracts and Base's public RPC endpoint; looked up once, in `data/external`, see its README).
- **Dated events** around the cuts (news reports and project announcements; each with its link in `data/external/event_calendar.csv`).
- **4byte.directory**: text signatures of the method selectors named in `00_setup.R` and `data/external/recipient_labels.csv` (looked up once).

## Software

Tested with R 4.6.1 and data.table 1.18.6.1, fixest 0.14.2, ggplot2 4.0.3, duckdb 1.5.6, nanoparquet 0.5.2, igraph 2.3.4, here 1.0.2 (full list in `00_setup.R`; versions in each log's sessionInfo).

## License

The code is released under the MIT License (see [`LICENSE`](LICENSE)). `data/panel`, `data/external` and `results` contain data derived from the sources above; their use is subject to those sources' terms, and they should be cited when the data are reused.
