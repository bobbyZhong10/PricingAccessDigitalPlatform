# PricingAccessDigitalPlatform

When a digital platform cuts the price of each use, how much does usage respond, through which margin (more activity by existing users or more participants), and who are the marginal participants?

The setting is the March 2024 Ethereum Dencun upgrade (EIP-4844), which cut transaction fees on Layer-2 rollups by about 85% within an hour. The project studies three fee drops at hourly resolution: Base (Ecotone), and Arbitrum's two steps (ArbOS 20, then a lower minimum base fee). It replicates the result across rollups with daily data and measures who enters after each drop.

## Repository layout

```
PricingAccessDigitalPlatform.Rproj   RStudio project (sets the project root)
code/                                R scripts, run in order
data/raw/                            downloaded aggregates (~1.9 GB; not in git, rebuilt by 01)
data/panel/panel.rds                 analysis panels: a named list of 11 tables (~59 MB; in git)
data/panel/contract.yaml             validation record; analyses refuse to run without it
results/tables/                      CSV tables
results/figures/                     PNG figures
results/logs/                        one log per script, with sessionInfo
proposal/                            research proposal (Markdown and PDF)
```

## How to run

1. Open `PricingAccessDigitalPlatform.Rproj` in RStudio, or run `Rscript code/0X_....R` from the project root.
2. Run the scripts in order. Each one sources `code/00_setup.R` first and runs standalone. `00_setup.R` stops with an `install.packages()` command if any package is missing.

| Script | What it does | Needs |
|---|---|---|
| `00_setup.R` | Packages, paths, constants (event times, campaign rule), helpers | |
| `01_download.R` | Public data → `data/raw`. Each section is skipped if its files exist | Internet, ~80 min |
| `02_build_panels.R` | `data/raw` → `data/panel/panel.rds` | `data/raw`, ~3 min |
| `03_validate_panels.R` | Checks every panel table, cross-checks counts against growthepie and the fee break at each event hour, writes `contract.yaml` | `panel.rds` |
| `04_analysis_main.R` | Hourly RD in time at the three fee drops (market controls, placebo RDs, randomization inference), elasticities, Base vs not-yet-treated Arbitrum DiD and event study, responses by transaction type | `panel.rds` |
| `05_analysis_robustness.R` | Specification grid, weekly differencing, market controls, campaign-net activity, inference variants, placebo at the L1 fork hour | `panel.rds` |
| `06_analysis_users.R` | Entry and retention (local randomization), daily cohorts, campaign / bot-like / genuine entrants with rule bounds, decomposition of the change in transactions, response by fee level | `panel.rds` |
| `07_analysis_multichain.R` | Multi-rollup per-event DiD, stacked DiD/2SLS, Callaway–Sant'Anna with documented upgrade dates, fee-level test | `panel.rds` |

`panel.rds` is in the repository, so `03`–`07` run without downloading anything (about 2 minutes in total). Rebuilding from scratch requires `01` and `02`. Every run is deterministic: rerunning the pipeline reproduces `panel.rds`, all tables, and all figures byte for byte.

## Data sources

All public, no API keys:

- **AWS Public Blockchain Data** (`s3://aws-public-blockchain`, read anonymously with DuckDB): sonarx transaction, failed-transaction, and transfer tables for Base and Arbitrum; Ethereum and Bitcoin blocks.
- **growthepie** public exports: daily transactions, active addresses, and median fee for Layer-2s.
- **Coinbase Exchange** public candles: ETH/USD daily.

Only aggregates are stored; the transaction-level tables are hundreds of GB. Protocol system transactions are removed in `02`. All times are UTC.

## Software

Tested with R 4.5.3 and data.table 1.18.2, fixest 0.14.2, did 2.3.0, ggplot2 4.0.2, duckdb 1.5.0, nanoparquet 0.5.2, here 1.0.2 (full list in `00_setup.R`; versions in each log's sessionInfo).

## License

See [`LICENSE`](LICENSE).
