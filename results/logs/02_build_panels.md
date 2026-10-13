# 02 build panels
Run 2026-10-13 17:58:34 UTC
A base: 1464 hours; system txs removed 2635201 (3.1% of raw txs)
A arbitrum: 1464 hours; system txs removed 20663038 (22.1% of raw txs)
B: control hours 1512; ETH/USD days 56
C0: LayerZero list copies (share_of_archive = share of the archive's EVM addresses found in the copy)
                               copy   lines     evm share_of_archive share_in_archive
1:       lz_archive/initialList.txt  803093  801635            1.000           1.0000
2:                lz_copy/LO Report  801932  801932            1.000           0.9996
3: lz_mirror/LayerZeroSybilList.txt 1315149 1315149            0.576           0.3511
C base: services at h = 200: 79 funders, 337 sweep targets; entrants in components of >= 20: 0.710
C base: services at h = 500: 39 funders, 251 sweep targets; entrants in components of >= 20: 0.726
C base: services at h = 2000: 26 funders, 107 sweep targets; entrants in components of >= 20: 0.748
C base: campaign bursts (>= 1000 entrants/day and >= 3x pre-shock median): campaign share pre 0.082, post 0.752
C base: cohort 2011474; prior activity 0.190 -> entrants 1628756; in window 2024-03-08..2024-03-21: 1169350 (campaign 0.685, bursting funder 0.467)
C arbitrum: services at h = 200: 102 funders, 277 sweep targets; entrants in components of >= 20: 0.123
C arbitrum: services at h = 500: 66 funders, 201 sweep targets; entrants in components of >= 20: 0.141
C arbitrum: services at h = 2000: 32 funders, 105 sweep targets; entrants in components of >= 20: 0.205
C arbitrum: campaign bursts (>= 1000 entrants/day and >= 3x pre-shock median): campaign share pre 0.142, post 0.153
C arbitrum: cohort 2244930; prior activity 0.453 -> entrants 1228511; in window 2024-03-08..2024-03-21: 571992 (campaign 0.149, bursting funder 0.102)
C2: Base entrants receiving tokens after entry: 0.727; ETH: 0.121; 423 token x class cells with >= 1,000 recipients
D base: 13583539 sender-days; 922633 senders kept for the fee-level analysis
D arbitrum: 13814292 sender-days; 1033838 senders kept for the fee-level analysis
E: campaign-wallet txs 3029532 over 1122 hours
F: 8261 chain-days, 24 chains; 414 drop days, 128 events
G: 22 first-action targets (12 contracts); 238 chain-days of fees, rent and profit; 427 Google Trends rows
H: May chain-hours 1440; entrants arbitrum 2679981, base 1130971; Base burst share pre 0.209, post 0.529; March burst operators 1573, of which active again in May 61; May entrants linked to one 0.0013
H: fee quantiles for 4368 chain-hours
Saved panel.rds (88.8 MB): l2_hourly, l2_hourly_type, l2_newsenders, control_hourly, eth_usd_daily, entrants, sender_window, base_tx_by_class, base_hourly_campaign, multichain_daily, multichain_drops, lz_meta, campaign_targets, l2_economics_daily, gtrends_daily, receipts_by_token, fb_sent, may_hourly, may_entrants, may_ops, eth_usd_daily_may, may_blocks, fee_quantiles_hourly

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
