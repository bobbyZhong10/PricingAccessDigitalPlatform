# PricingAccessDigitalPlatform

When a digital platform cuts the price of each use, how much does usage respond, through which margin (more activity by existing users or more participants), and who are the marginal participants: new people, or accounts created in batches by operators who run many identities?

The setting is Ethereum Layer-2 platforms in 2024. The project studies five abrupt fee cuts at hourly resolution:

- **March 2024, passed through from Ethereum's Dencun upgrade (EIP-4844):** Base (Ecotone, 03-14 00:00 UTC) and Arbitrum (ArbOS 20, 03-14 15:00 UTC).
- **March 2024, chosen by the platform:** Arbitrum lowered its minimum L2 base fee (03-19 08:00 UTC).
- **May 2024, chosen by the platform:** Base raised its block gas limit twice (05-28 19:00 and 05-30 20:00 UTC).

It estimates the usage response (regression discontinuity in time, with randomization inference), separates entry from activity by existing senders, replicates the result across rollups with daily data, classifies new accounts (burst-created accounts, bot-like accounts, other entrants) and validates that classification (funding clusters, synchronization, an external Sybil list, targets, persistence), and compares the two Base cuts, with Arbitrum as the comparison chain in May.

## Repository layout

```
PricingAccessDigitalPlatform.Rproj   RStudio project (sets the project root)
code/                                R scripts, run in order
data/raw/                            downloaded aggregates (~3 GB; not in git, rebuilt by 01)
data/external/                       inputs that cannot be downloaded by script (Google Trends capture)
data/panel/panel.rds                 analysis panels: a named list of 23 tables (~89 MB; in git)
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
| `06_analysis_users.R` | Entry and retention (local randomization), daily cohorts, burst / bot-like / other entrants with rule bounds, decomposition of the change in transactions, response by fee level; validation (LayerZero list, funding clusters, timing, targets, Google Trends, platform economics); who runs the burst accounts; the second Base cut (first actions, Arbitrum as comparison chain, window variants); dollar stakes, friction bounds and platform profit | `panel.rds` |
| `07_analysis_multichain.R` | Multi-rollup per-event DiD, stacked DiD/2SLS, Callaway–Sant'Anna with documented upgrade dates, fee-level test, second drops by rollup; Base May daily DiD and event study against seven other chains | `panel.rds` |
| `08_paper_exhibits.R` | Lays out the paper's Tables 1–6 from the outputs of `04`–`07` (`results/paper/tables.md`) and indexes every main and appendix exhibit with links to its file (`results/paper/README.md`) | outputs of `04`–`07` |

`panel.rds` is in the repository, so `03`–`08` run without downloading anything (a few minutes). Rebuilding from scratch requires `01` and `02`; `01` needs about 10 GB of memory for DuckDB and about 3 GB of disk. Given `data/raw`, `02`–`08` are deterministic: two full rebuilds produced the same `panel.rds` and the same tables and figures byte for byte (same platform and package versions). `01` reads live public sources (growthepie, Coinbase, GitHub mirrors) that can be revised, so a new download can differ slightly.

## Data sources

All public, no API keys:

- **AWS Public Blockchain Data** (`s3://aws-public-blockchain`, read anonymously with DuckDB): sonarx transaction, failed-transaction, trace, transfer, log and block tables for Base and Arbitrum; Ethereum and Bitcoin blocks.
- **growthepie** public exports: daily transactions, active addresses, median fee, fee revenue, L1 data cost and profit for Layer-2s.
- **LayerZero** provisional Sybil list (Wayback Machine capture of the official file, plus two public mirrors as checks).
- **Google Trends** daily search interest (captured in a browser; the capture is in `data/external`, see its README).
- **Coinbase Exchange** public candles: ETH/USD daily.
- **4byte.directory**: text signatures of the few method selectors named in `00_setup.R` and `06` (looked up once; hard-coded).
- **Blockscout** (base.blockscout.com): names of the most common tokens received by new accounts and the deployment time of the "EIP-4844 is Based" mint contract (looked up once; hard-coded in `06`).

## Software

Tested with R 4.5.3 and data.table 1.18.2.1, fixest 0.14.2, did 2.3.0, ggplot2 4.0.2, duckdb 1.5.0, nanoparquet 0.5.2, igraph 2.2.2, here 1.0.2 (full list in `00_setup.R`; versions in each log's sessionInfo).

## License

The code is released under the MIT License (see [`LICENSE`](LICENSE)). `data/panel`, `data/external` and `results` contain data derived from the sources above; their use is subject to those sources' terms, and they should be cited when the data are reused.
