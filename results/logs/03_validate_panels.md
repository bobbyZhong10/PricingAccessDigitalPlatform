# 03 validate panels
Run 2026-10-12 20:10:28 UTC
  [ok] panel.rds holds the 11 expected tables
## l2_hourly
  [ok] required columns present
  [ok] unique on (chain hr hf failed), 11712 rows
  [ok] n non-negative
  [ok] fee non-negative
  [ok] n_senders non-negative
  [ok] every UTC hour 2024-02-15..2024-04-15 present for both chains
  [ok] base: daily txs / growthepie txcount in [0.99, 1.02]: 1.0018-1.0094 over 45 days
  [ok] Base (Ecotone): break at 03-14 01:00 UTC (documented 03-14 00:00), fall -2.20
  [ok] arbitrum: daily txs / growthepie txcount in [0.99, 1.02]: 1.0002-1.0008 over 45 days
  [ok] Arbitrum step 1: break at 03-14 15:00 UTC (documented 03-14 15:00), fall -1.98
  [ok] Arbitrum step 2: break at 03-19 08:00 UTC (documented 03-19 08:00), fall -1.71
## l2_hourly_type
  [ok] required columns present
  [ok] unique on (chain hr typ failed), 26552 rows
  [ok] n non-negative
  [ok] fee non-negative
  [ok] every UTC hour 2024-02-15..2024-04-15 present for both chains
  [ok] five transaction types
## l2_newsenders
  [ok] required columns present
  [ok] unique on (chain hr), 2928 rows
  [ok] new_senders non-negative
## control_hourly
  [ok] required columns present
  [ok] unique on (hr), 1512 rows
  [ok] n_eth non-negative
  [ok] n_btc non-negative
  [ok] Ethereum every hour; Bitcoin > 95% of hours (no block = missing)
## eth_usd_daily
  [ok] required columns present
  [ok] unique on (day), 56 rows
  [ok] close non-negative
  [ok] every day 2024-02-15..04-09
## entrants
  [ok] required columns present
  [ok] months_active non-negative
  [ok] entry day in 03-01..27 and consistent with entry hour
  [ok] campaign flags are 0/1 and classes bot/campaign/genuine inside the entrant window
## sender_window
  [ok] required columns present
  [ok] unique on (chain window id), 3319464 rows
  [ok] n non-negative
  [ok] fee non-negative
  [ok] windows match FEE_WINDOWS
## base_tx_by_class
  [ok] required columns present
  [ok] unique on (cls day), 42 rows
  [ok] txs non-negative
## base_hourly_campaign
  [ok] required columns present
  [ok] unique on (hr), 1122 rows
  [ok] n_campaign non-negative
## multichain_daily
  [ok] required columns present
  [ok] unique on (chain date), 8261 rows
  [ok] txcount non-negative
  [ok] daa non-negative
  [ok] cost non-negative
## multichain_drops
  [ok] required columns present
  [ok] unique on (chain date), 414 rows
  [ok] every drop >= 50%
Contract written: 11 objects, 0 with failed checks

## sessionInfo
```
R version 4.5.3 (2026-03-11)
Platform: aarch64-apple-darwin25.3.0
Running under: macOS 27.0.1

Matrix products: default
BLAS:   /opt/homebrew/Cellar/openblas/0.3.33/lib/libopenblasp-r0.3.33.dylib 
LAPACK: /opt/homebrew/Cellar/r/4.5.3/lib/R/lib/libRlapack.dylib;  LAPACK version 3.12.1

locale:
[1] en_US/en_US/en_US/C/en_US/en_US

time zone: America/New_York
tzcode source: internal

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
[1] jsonlite_2.0.0      ggplot2_4.0.2       fixest_0.14.2       data.table_1.18.2.1 here_1.0.2         

loaded via a namespace (and not attached):
 [1] gtable_0.3.6        dplyr_1.2.0         compiler_4.5.3      tidyselect_1.2.1    Rcpp_1.1.1          scales_1.4.0        yaml_2.3.12         lattice_0.22-9      coda_0.19-4.1       R6_2.6.1            generics_0.1.4      Formula_1.2-5      
[13] tibble_3.3.1        rprojroot_2.1.1     lubridate_1.9.5     DBI_1.3.0           pillar_1.11.1       RColorBrewer_1.1-3  rlang_1.1.7         nanoparquet_0.5.2   S7_0.2.1            stringmagic_1.2.0   otel_0.2.0          timechange_0.4.0   
[25] estimability_1.5.1  cli_3.6.5           withr_3.0.2         magrittr_2.0.4      emmeans_2.0.2       grid_4.5.3          mvtnorm_1.3-6       xtable_1.8-8        sandwich_3.1-1      lifecycle_1.0.5     nlme_3.1-168        vctrs_0.7.1        
[37] glue_1.8.0          duckdb_1.5.0        farver_2.1.2        numDeriv_2016.8-1.1 zoo_1.8-15          dreamerr_1.5.0      tools_4.5.3         pkgconfig_2.0.3    
```
