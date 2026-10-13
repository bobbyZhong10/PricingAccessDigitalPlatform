# 03 validate panels
Run 2026-10-13 18:03:26 UTC
  [ok] panel.rds holds the 23 expected tables
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
  [ok] n_week1 non-negative
  [ok] csize200 non-negative
  [ok] csize500 non-negative
  [ok] csize2000 non-negative
  [ok] csizeF500 non-negative
  [ok] entry day in 03-01..27 and consistent with entry hour
  [ok] campaign flags are 0/1 and classes bot/campaign/genuine inside the entrant window
  [ok] validation flags are 0/1, defined for every window entrant, and component sizes >= 1
  [ok] component sizes shrink weakly as the service threshold falls (fewer links)
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
## lz_meta
  [ok] required columns present
  [ok] unique on (copy), 3 rows
  [ok] lines non-negative
  [ok] evm non-negative
  [ok] official provisional list: 803,093 lines
  [ok] a second copy agrees with the archive within 0.1% (V1 acceptance rule)
## campaign_targets
  [ok] required columns present
  [ok] unique on (addr), 22 rows
  [ok] n_logs non-negative
  [ok] n_721 non-negative
  [ok] n_20 non-negative
## l2_economics_daily
  [ok] required columns present
  [ok] unique on (chain date), 238 rows
  [ok] fees_usd non-negative
  [ok] rent_usd non-negative
## gtrends_daily
  [ok] required columns present
  [ok] unique on (request keyword date), 427 rows
  [ok] value non-negative
  [ok] values in 0..100, every day 02-15..04-15 for each series
## receipts_by_token
  [ok] required columns present
  [ok] unique on (class3 tok), 423 rows
  [ok] recipients non-negative
  [ok] senders non-negative
## fb_sent
  [ok] required columns present
  [ok] unique on (tok), 8 rows
  [ok] transfers non-negative
  [ok] recipients non-negative
## may_hourly
  [ok] required columns present
  [ok] unique on (chain hr), 1440 rows
  [ok] n non-negative
  [ok] n_failed non-negative
  [ok] fee non-negative
  [ok] n_senders non-negative
  [ok] new_senders non-negative
  [ok] every UTC hour 2024-05-14..2024-06-12 present for both chains
## may_entrants
  [ok] required columns present
  [ok] n_week1 non-negative
  [ok] months4 non-negative
  [ok] csize500 non-negative
  [ok] both chains; entry day in MAY_WINDOW, classes bot/campaign/genuine, Base link flags 0/1
## may_ops
  [ok] required columns present
  [ok] march_burst_operators non-negative
  [ok] active_again_in_may non-negative
## eth_usd_daily_may
  [ok] required columns present
  [ok] unique on (day), 61 rows
  [ok] close non-negative
  [ok] every day 2024-05-01..06-30
## may_blocks
  [ok] required columns present
  [ok] unique on (hr), 720 rows
  [ok] gas_limit_min non-negative
  [ok] gas_limit_max non-negative
  [ok] base_fee_gwei non-negative
  [ok] gas_used non-negative
  [ok] blocks non-negative
  [ok] gas limit steps up to 75M in the 05-28 19:00 hour and to 90M in the 05-30 20:00 hour (EVENTS_MAY)
## fee_quantiles_hourly
  [ok] required columns present
  [ok] unique on (chain hr), 4368 rows
  [ok] n_paid non-negative
  [ok] p25 non-negative
  [ok] p50 non-negative
  [ok] p75 non-negative
  [ok] every UTC hour of the March and May pulls present for both chains
  [ok] 0 < p25 <= p50 <= p75
  [ok] growthepie median fee within a factor of 2 on >= 90% of chain-days: 100% of 172 (median ratio 0.97)
  [ok] median fee, Base (Ecotone): break at 03-14 00:00 UTC (documented 03-14 00:00), fall -5.81
  [ok] median fee, Arbitrum step 1: break at 03-14 15:00 UTC (documented 03-14 15:00), fall -2.17
  [ok] median fee, Arbitrum step 2: break at 03-19 08:00 UTC (documented 03-19 08:00), fall -1.71
  [ok] median fee, Base gas limit 60M to 75M: break at 05-28 20:00 UTC (documented 05-28 19:00), fall -1.67
  [ok] median fee, Base gas limit 75M to 90M: break at 05-30 18:00 UTC (documented 05-30 20:00), fall -1.46
Contract written: 23 objects, 0 with failed checks

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

time zone: UTC
tzcode source: internal

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
[1] jsonlite_2.0.0      ggplot2_4.0.2       fixest_0.14.2       data.table_1.18.2.1 here_1.0.2         

loaded via a namespace (and not attached):
 [1] tidyselect_1.2.1     nanoparquet_0.5.2    timeDate_4052.112    dplyr_1.2.0          farver_2.1.2         S7_0.2.1             duckdb_1.5.0         pROC_1.19.0.1        caret_7.0-1          digest_0.6.39        rpart_4.1.24        
[12] DRDID_1.2.3          timechange_0.4.0     estimability_1.5.1   lifecycle_1.0.5      dreamerr_1.5.0       survival_3.8-6       magrittr_2.0.4       compiler_4.5.3       rlang_1.1.7          tools_4.5.3          igraph_2.2.2        
[23] yaml_2.3.12          plyr_1.8.9           RColorBrewer_1.1-3   withr_3.0.2          purrr_1.2.1          numDeriv_2016.8-1.1  nnet_7.3-20          grid_4.5.3           stats4_4.5.3         xtable_1.8-8         future_1.70.0       
[34] BMisc_1.4.8          globals_0.19.1       emmeans_2.0.2        scales_1.4.0         iterators_1.0.14     MASS_7.3-65          cli_3.6.5            mvtnorm_1.3-6        generics_0.1.4       otel_0.2.0           future.apply_1.20.2 
[45] bigmemory.sri_0.1.8  reshape2_1.4.5       DBI_1.3.0            stringr_1.6.0        splines_4.5.3        parallel_4.5.3       fastglm_0.0.4        stringmagic_1.2.0    vctrs_0.7.1          hardhat_1.4.2        Matrix_1.7-4        
[56] sandwich_3.1-1       did_2.3.0            Formula_1.2-5        listenv_0.10.1       foreach_1.5.2        trust_0.1-9          gower_1.0.2          tidyr_1.3.2          recipes_1.3.1        glue_1.8.0           bigmemory_4.6.4     
[67] parallelly_1.46.1    codetools_0.2-20     lubridate_1.9.5      stringi_1.8.7        gtable_0.3.6         tibble_3.3.1         pillar_1.11.1        ipred_0.9-15         lava_1.8.2           R6_2.6.1             rprojroot_2.1.1     
[78] lattice_0.22-9       class_7.3-23         Rcpp_1.1.1           uuid_1.2-2           coda_0.19-4.1        nlme_3.1-168         prodlim_2026.03.11   zoo_1.8-15           pkgconfig_2.0.3      ModelMetrics_1.2.2.2
```
