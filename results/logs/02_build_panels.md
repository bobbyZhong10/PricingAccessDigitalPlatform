# 02 build panels
Run 2026-10-12 22:40:42 UTC
A base: 1464 hours; system txs removed 2635201 (3.1% of raw txs)
A arbitrum: 1464 hours; system txs removed 20663038 (22.1% of raw txs)
B: control hours 1512; ETH/USD days 56
C base: campaign bursts (>= 1000 entrants/day and >= 3x pre-shock median): campaign share pre 0.082, post 0.752
C base: cohort 2011474; prior activity 0.190 -> entrants 1628756; in window 2024-03-08..2024-03-21: 1169350 (campaign 0.685, bursting funder 0.467)
C arbitrum: campaign bursts (>= 1000 entrants/day and >= 3x pre-shock median): campaign share pre 0.142, post 0.153
C arbitrum: cohort 2244930; prior activity 0.453 -> entrants 1228511; in window 2024-03-08..2024-03-21: 571992 (campaign 0.149, bursting funder 0.102)
D base: 13583539 sender-days; 922633 senders kept for the fee-level analysis
D arbitrum: 13814292 sender-days; 1033838 senders kept for the fee-level analysis
E: campaign-wallet txs 3029532 over 1122 hours
F: 8261 chain-days, 24 chains; 414 drop days, 128 events
Saved panel.rds (59.0 MB): l2_hourly, l2_hourly_type, l2_newsenders, control_hourly, eth_usd_daily, entrants, sender_window, base_tx_by_class, base_hourly_campaign, multichain_daily, multichain_drops

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
 [1] tidyselect_1.2.1     nanoparquet_0.5.2    timeDate_4052.112    dplyr_1.2.0          farver_2.1.2         S7_0.2.1             duckdb_1.5.0         pROC_1.19.0.1        caret_7.0-1          digest_0.6.39        rpart_4.1.24        
[12] DRDID_1.2.3          timechange_0.4.0     estimability_1.5.1   lifecycle_1.0.5      dreamerr_1.5.0       survival_3.8-6       magrittr_2.0.4       compiler_4.5.3       rlang_1.1.7          tools_4.5.3          yaml_2.3.12         
[23] plyr_1.8.9           RColorBrewer_1.1-3   withr_3.0.2          purrr_1.2.1          numDeriv_2016.8-1.1  nnet_7.3-20          grid_4.5.3           stats4_4.5.3         xtable_1.8-8         future_1.70.0        BMisc_1.4.8         
[34] globals_0.19.1       emmeans_2.0.2        scales_1.4.0         iterators_1.0.14     MASS_7.3-65          cli_3.6.5            mvtnorm_1.3-6        generics_0.1.4       otel_0.2.0           future.apply_1.20.2  bigmemory.sri_0.1.8 
[45] reshape2_1.4.5       DBI_1.3.0            stringr_1.6.0        splines_4.5.3        parallel_4.5.3       fastglm_0.0.4        stringmagic_1.2.0    vctrs_0.7.1          hardhat_1.4.2        Matrix_1.7-4         sandwich_3.1-1      
[56] did_2.3.0            Formula_1.2-5        listenv_0.10.1       foreach_1.5.2        trust_0.1-9          gower_1.0.2          tidyr_1.3.2          recipes_1.3.1        glue_1.8.0           bigmemory_4.6.4      parallelly_1.46.1   
[67] codetools_0.2-20     lubridate_1.9.5      stringi_1.8.7        gtable_0.3.6         tibble_3.3.1         pillar_1.11.1        ipred_0.9-15         lava_1.8.2           R6_2.6.1             rprojroot_2.1.1      lattice_0.22-9      
[78] class_7.3-23         Rcpp_1.1.1           uuid_1.2-2           coda_0.19-4.1        nlme_3.1-168         prodlim_2026.03.11   zoo_1.8-15           pkgconfig_2.0.3      ModelMetrics_1.2.2.2
```
