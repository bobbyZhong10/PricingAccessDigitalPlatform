# 04 main analysis
Run 2026-10-17 01:44:42 UTC
Hourly panel: 2160 chain-hours, 2024-03-01..2024-04-14 23:00:00 UTC
## Summary: hourly transactions, median fee per transaction (US$) and active senders, mean and SD across hours
      chain                period hours txs_mean txs_sd fee_usd_mean fee_usd_sd senders_mean senders_sd
1:     base         7 days before   168    18109  10452     0.590564   0.146209         6299      845.2
2:     base          7 days after   168    57241  20028     0.066225   0.187911        19142    12986.8
3: arbitrum  7 days before step 1   168    30555   8101     0.549501   0.129735        10046     2598.0
4: arbitrum between steps 1 and 2   113    49230  13277     0.078702   0.017296        12816     2861.9
5: arbitrum   7 days after step 2   168    64475  14564     0.009103   0.003431        16677     4404.6
RI: 59/58/58 fake event hours per event
## A. RD in time (+-36 h), with market controls, and placebo RDs on L1 and Bitcoin: estimate (NW SE) [RI p]
                                                 y           Base (Ecotone)          Arbitrum step 1          Arbitrum step 2
 1:            log median fee per tx (first stage) -4.161 (0.822) [RI 0.02] -2.022 (0.176) [RI 0.02] -1.824 (0.193) [RI 0.02]
 2:  log mean fee per tx (first stage, robustness) -2.033 (0.268) [RI 0.02] -1.820 (0.203) [RI 0.02] -1.880 (0.247) [RI 0.02]
 3:                                        log txs  0.787 (0.325) [RI 0.02]  0.761 (0.092) [RI 0.02]  0.138 (0.103) [RI 0.29]
 4:                           log distinct senders  0.870 (0.119) [RI 0.02]  0.496 (0.074) [RI 0.02]  0.185 (0.124) [RI 0.12]
 5:                                log new senders  0.817 (0.150) [RI 0.05]  0.541 (0.103) [RI 0.03]  0.047 (0.158) [RI 0.80]
 6:                                 log failed txs  0.454 (0.680) [RI 0.18]  1.848 (0.189) [RI 0.02] -0.042 (0.194) [RI 0.92]
 7:                                   failed share -0.086 (0.057) [RI 0.07]  0.081 (0.010) [RI 0.10] -0.015 (0.011) [RI 0.59]
 8:                            log txs, HF senders  0.671 (0.163) [RI 0.02]  0.799 (0.135) [RI 0.02]  0.135 (0.131) [RI 0.34]
 9:                         log txs, other senders  0.826 (0.351) [RI 0.02]  0.710 (0.090) [RI 0.02]  0.156 (0.135) [RI 0.27]
10:                   placebo: log Ethereum L1 txs -0.000 (0.030) [RI 1.00] -0.015 (0.029) [RI 0.76]  0.103 (0.038) [RI 0.07]
11:                       placebo: log Bitcoin txs -0.093 (0.160) [RI 0.65] -0.145 (0.152) [RI 0.56]  0.190 (0.290) [RI 0.54]
12: log txs, RD with market controls (L1, Bitcoin)  0.786 (0.327) [RI 0.02]  0.749 (0.087) [RI 0.02]  0.097 (0.117) [RI 0.46]
## B. Median fee per tx (US$) and mean txs per hour by chain and period
      chain   pre Base only Arb step 1    both
1: arbitrum 0.514   0.45000    0.07820 0.00897
2:     base 0.552   0.00266    0.00386 0.05280
      chain   pre Base only Arb step 1  both
1: arbitrum 32054     33163      49230 66863
2:     base 17500     49826      56915 95685
## B. DiD Base vs Arbitrum, hours in [2024-03-07, 2024-03-14 15:00:00): 366 chain-hours (15 Base post hours)
                                         y      est    se_nw   se_day
1:                                 log txs 1.010197 0.070749 0.056057
2:         log txs, high-frequency senders 0.425463 0.086218 0.080349
3:                  log txs, other senders 1.125993 0.075854 0.056637
4:                          log failed txs 1.219867 0.151132 0.130905
5:                            failed share 0.006379 0.004217 0.003557
6:                         log new senders 0.796455 0.102753 0.088706
7: log distinct senders (sum over classes) 0.765398 0.056360 0.047175
Base pre-drop burst hours excluded from the event study: 03-13 19:00
## B. Event study by day (ref = day -1; day 0 = the 15 hours before Arbitrum's drop)
   day_rel Active senders All transactions Failed transactions New senders Transactions, high-frequency senders Transactions, other senders
1:      -7          0.248            0.207               0.253       0.427                                0.262                       0.252
2:      -6          0.125            0.060              -0.090       0.407                                0.225                       0.059
3:      -5          0.091            0.215               0.492       0.137                                0.498                       0.123
4:      -4          0.188            0.256               0.254       0.173                                0.498                       0.195
5:      -3          0.126            0.108              -0.040       0.241                                0.247                       0.106
6:      -2         -0.030           -0.031              -0.123      -0.206                                0.033                      -0.041
7:      -1          0.000            0.000               0.000       0.000                                0.000                       0.000
8:       0          0.872            1.127               1.326       0.965                                0.677                       1.225
## C. Share of successful txs by type, 2024-03-01..12
              typ arbitrum  base
1:        approve    0.061 0.113
2: erc20_transfer    0.110 0.028
3:         native    0.160 0.132
4:     other_call    0.611 0.588
5:           swap    0.058 0.139
## C. RD in time by type (successful txs); elasticity = d log txs / d log fee per tx
              event           type d_log_txs  se_txs    ri_p d_log_fee elasticity
 1:  Base (Ecotone)        approve   0.67213 0.13189 0.01667    -3.020  -0.222542
 2:  Base (Ecotone) erc20_transfer   1.12891 0.15225 0.01667    -3.411  -0.330916
 3:  Base (Ecotone)         native   0.58449 0.12117 0.03333    -2.764  -0.211458
 4:  Base (Ecotone)     other_call   1.04377 0.31412 0.01667    -2.062  -0.506257
 5:  Base (Ecotone)           swap   0.75662 0.17021 0.01667    -2.720  -0.278199
 6: Arbitrum step 1        approve   0.47624 0.04583 0.03390    -2.677  -0.177887
 7: Arbitrum step 1 erc20_transfer   0.51863 0.11654 0.01695    -2.626  -0.197461
 8: Arbitrum step 1         native   0.63120 0.15311 0.01695    -2.931  -0.215381
 9: Arbitrum step 1     other_call   0.70919 0.08795 0.01695    -1.731  -0.409727
10: Arbitrum step 1           swap   0.73712 0.09970 0.01695    -1.858  -0.396684
11: Arbitrum step 2        approve   0.14993 0.10949 0.22034    -1.780  -0.084234
12: Arbitrum step 2 erc20_transfer   0.01007 0.04660 0.96610    -1.781  -0.005655
13: Arbitrum step 2         native   0.14231 0.17344 0.33898    -1.675  -0.084969
14: Arbitrum step 2     other_call   0.26037 0.09337 0.06780    -1.985  -0.131171
15: Arbitrum step 2           swap  -0.57551 0.18297 0.01695    -1.556   0.369942
## D. Second Base event: RD in time (+-36 h) at the gas-limit increases: estimate (NW SE) [RI p, number of fake hours]
                                               y        Base gas limit 60M to 75M        Base gas limit 75M to 90M
1:           log median fee per tx (first stage) -1.024 (0.230) [RI 0.05, K = 37] -1.021 (0.355) [RI 0.05, K = 37]
2: log mean fee per tx (first stage, robustness) -0.480 (0.172) [RI 0.16, K = 37] -0.573 (0.304) [RI 0.13, K = 37]
3:        log L2 base fee per gas (block median) -1.017 (0.263) [RI 0.08, K = 37] -1.600 (0.518) [RI 0.03, K = 37]
4:                                       log txs  0.200 (0.029) [RI 0.05, K = 37] -0.015 (0.044) [RI 0.84, K = 37]
5:                          log distinct senders  0.228 (0.090) [RI 0.11, K = 37] -0.023 (0.048) [RI 0.89, K = 37]
6:            log new senders (none since 02-15)  0.597 (0.252) [RI 0.11, K = 37] -0.553 (0.169) [RI 0.13, K = 37]
## D. Elasticities at the five cuts and both May steps together (fuzzy RD; NW SEs; first-stage Wald statistic), median and mean price
                         event  price elasticity_txs  se_txs elasticity_senders se_senders first_stage_wald
 1:             Base (Ecotone) median       -0.18906 0.08297           -0.20897    0.04347           25.629
 2:             Base (Ecotone)   mean       -0.38696 0.14664           -0.42771    0.06063           57.376
 3:            Arbitrum step 1 median       -0.37659 0.07054           -0.24533    0.05065          131.828
 4:            Arbitrum step 1   mean       -0.41845 0.08832           -0.27259    0.06087           80.468
 5:            Arbitrum step 2 median       -0.07554 0.05766           -0.10139    0.07138           89.678
 6:            Arbitrum step 2   mean       -0.07329 0.05640           -0.09838    0.07007           58.042
 7:  Base gas limit 60M to 75M median       -0.19530 0.03969           -0.22233    0.10371           19.848
 8:  Base gas limit 60M to 75M   mean       -0.41658 0.14676           -0.47423    0.25484            7.827
 9:  Base gas limit 75M to 90M median        0.01496 0.04543            0.02300    0.04612            8.252
10:  Base gas limit 75M to 90M   mean        0.02668 0.07028            0.04100    0.09379            3.558
11: Base gas limit, both steps median       -0.10033 0.04398           -0.11074    0.06413           15.663
12: Base gas limit, both steps   mean       -0.18537 0.13050           -0.20247    0.15279            5.216
## D. Table 2: RD in time at all five fee cuts, estimate (NW SE) [RI p]; March new senders = none since 02-15 (hourly panel), May likewise
                                               y      Base (Ecotone)     Arbitrum step 1     Arbitrum step 2 Base gas limit 60M to 75M Base gas limit 75M to 90M
1:           log median fee per tx (first stage) -4.16 (0.82) [0.02] -2.02 (0.18) [0.02] -1.82 (0.19) [0.02]       -1.02 (0.23) [0.05]       -1.02 (0.36) [0.05]
2: log mean fee per tx (first stage, robustness) -2.03 (0.27) [0.02] -1.82 (0.20) [0.02] -1.88 (0.25) [0.02]       -0.48 (0.17) [0.16]       -0.57 (0.30) [0.13]
3:                                       log txs  0.79 (0.32) [0.02]  0.76 (0.09) [0.02]  0.14 (0.10) [0.29]        0.20 (0.03) [0.05]       -0.02 (0.04) [0.84]
4:                          log distinct senders  0.87 (0.12) [0.02]  0.50 (0.07) [0.02]  0.18 (0.12) [0.12]        0.23 (0.09) [0.11]       -0.02 (0.05) [0.89]
5:                               log new senders  0.82 (0.15) [0.05]  0.54 (0.10) [0.03]  0.05 (0.16) [0.80]        0.60 (0.25) [0.11]       -0.55 (0.17) [0.13]
6:              elasticity of txs (median price)        -0.19 (0.08)        -0.38 (0.07)        -0.08 (0.06)              -0.20 (0.04)               0.01 (0.05)

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
 [1] nanoparquet_0.5.2    tidyselect_1.2.1     timeDate_4052.112    dplyr_1.2.0          farver_2.1.2         S7_0.2.1             duckdb_1.5.0         pROC_1.19.0.1        caret_7.0-1          digest_0.6.39        rpart_4.1.24        
[12] DRDID_1.2.3          timechange_0.4.0     estimability_1.5.1   lifecycle_1.0.5      dreamerr_1.5.0       survival_3.8-6       magrittr_2.0.4       compiler_4.5.3       rlang_1.1.7          tools_4.5.3          igraph_2.2.2        
[23] yaml_2.3.12          labeling_0.4.3       plyr_1.8.9           RColorBrewer_1.1-3   withr_3.0.2          purrr_1.2.1          numDeriv_2016.8-1.1  nnet_7.3-20          grid_4.5.3           stats4_4.5.3         xtable_1.8-8        
[34] future_1.70.0        BMisc_1.4.8          globals_0.19.1       emmeans_2.0.2        scales_1.4.0         iterators_1.0.14     MASS_7.3-65          cli_3.6.5            mvtnorm_1.3-6        ragg_1.5.1           generics_0.1.4      
[45] otel_0.2.0           future.apply_1.20.2  bigmemory.sri_0.1.8  reshape2_1.4.5       DBI_1.3.0            stringr_1.6.0        splines_4.5.3        parallel_4.5.3       fastglm_0.0.4        stringmagic_1.2.0    vctrs_0.7.1         
[56] hardhat_1.4.2        Matrix_1.7-4         sandwich_3.1-1       did_2.3.0            Formula_1.2-5        listenv_0.10.1       systemfonts_1.3.2    foreach_1.5.2        trust_0.1-9          gower_1.0.2          tidyr_1.3.2         
[67] recipes_1.3.1        glue_1.8.0           bigmemory_4.6.4      parallelly_1.46.1    codetools_0.2-20     lubridate_1.9.5      stringi_1.8.7        gtable_0.3.6         tibble_3.3.1         pillar_1.11.1        ipred_0.9-15        
[78] lava_1.8.2           R6_2.6.1             textshaping_1.0.5    rprojroot_2.1.1      lattice_0.22-9       class_7.3-23         Rcpp_1.1.1           uuid_1.2-2           coda_0.19-4.1        gridExtra_2.3        nlme_3.1-168        
[89] prodlim_2026.03.11   zoo_1.8-15           pkgconfig_2.0.3      ModelMetrics_1.2.2.2
```
