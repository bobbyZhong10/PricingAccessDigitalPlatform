# 04 main analysis
Run 2026-10-12 21:40:10 UTC
Hourly panel: 2160 chain-hours, 2024-03-01..2024-04-14 23:00:00 UTC
## Summary: hourly transactions, fee per transaction (US$) and active senders, mean and SD across hours
      chain                period hours txs_mean txs_sd fee_usd_mean fee_usd_sd senders_mean senders_sd
1:     base         7 days before   168    18100  10500       0.9900     0.2790         6300        845
2:     base          7 days after   168    57200  20000       0.2630     0.3950        19100      13000
3: arbitrum  7 days before step 1   168    30600   8100       0.8680     0.2180        10000       2600
4: arbitrum between steps 1 and 2   113    49200  13300       0.1310     0.0648        12800       2860
5: arbitrum   7 days after step 2   168    64500  14600       0.0153     0.0109        16700       4400
RI: 59/58/58 fake event hours per event
## A. RD in time (+-36 h), with market controls, and placebo RDs on L1 and Bitcoin: estimate (NW SE) [RI p]
                                                 y           Base (Ecotone)          Arbitrum step 1          Arbitrum step 2
 1:                   log fee per tx (first stage) -2.033 (0.268) [RI 0.00] -1.820 (0.203) [RI 0.00] -1.880 (0.247) [RI 0.00]
 2:                                        log txs  0.787 (0.325) [RI 0.00]  0.761 (0.092) [RI 0.00]  0.138 (0.103) [RI 0.28]
 3:                           log distinct senders  0.870 (0.119) [RI 0.00]  0.496 (0.074) [RI 0.00]  0.185 (0.124) [RI 0.10]
 4:                                log new senders  0.817 (0.150) [RI 0.03]  0.541 (0.103) [RI 0.02]  0.047 (0.158) [RI 0.79]
 5:                                 log failed txs  0.454 (0.680) [RI 0.17]  1.848 (0.189) [RI 0.00] -0.042 (0.194) [RI 0.91]
 6:                                   failed share -0.086 (0.057) [RI 0.05]  0.081 (0.010) [RI 0.09] -0.015 (0.011) [RI 0.59]
 7:                            log txs, HF senders  0.671 (0.163) [RI 0.00]  0.799 (0.135) [RI 0.00]  0.135 (0.131) [RI 0.33]
 8:                         log txs, other senders  0.826 (0.351) [RI 0.00]  0.710 (0.090) [RI 0.00]  0.156 (0.135) [RI 0.26]
 9:                   placebo: log Ethereum L1 txs -0.000 (0.030) [RI 1.00] -0.015 (0.029) [RI 0.76]  0.103 (0.038) [RI 0.05]
10:                       placebo: log Bitcoin txs -0.093 (0.160) [RI 0.64] -0.145 (0.152) [RI 0.55]  0.190 (0.290) [RI 0.53]
11: log txs, RD with market controls (L1, Bitcoin)  0.786 (0.327) [RI 0.00]  0.749 (0.087) [RI 0.00]  0.097 (0.117) [RI 0.45]
## A. Elasticities = RD log txs (or senders) / RD log fee per tx
             event rd_log_fee rd_log_txs rd_log_senders elasticity_txs elasticity_senders
1:  Base (Ecotone)      -2.03      0.787          0.870        -0.3870            -0.4280
2: Arbitrum step 1      -1.82      0.761          0.496        -0.4180            -0.2730
3: Arbitrum step 2      -1.88      0.138          0.185        -0.0733            -0.0984
## B. Median fee per tx (US$) and mean txs per hour by chain and period
      chain   pre Base only Arb step 1   both
1: arbitrum 0.804    0.7480      0.123 0.0141
2:     base 0.877    0.0786      0.109 0.2890
      chain   pre Base only Arb step 1  both
1: arbitrum 32054     33163      49230 66863
2:     base 17500     49826      56915 95685
## B. DiD Base vs Arbitrum, hours in [2024-03-07, 2024-03-14 15:00:00): 366 chain-hours (15 Base post hours)
                                         y     est   se_nw  se_day
1:                                 log txs 1.01000 0.07070 0.05610
2:         log txs, high-frequency senders 0.42500 0.08620 0.08030
3:                  log txs, other senders 1.13000 0.07590 0.05660
4:                          log failed txs 1.22000 0.15100 0.13100
5:                            failed share 0.00638 0.00422 0.00356
6:                         log new senders 0.79600 0.10300 0.08870
7: log distinct senders (sum over classes) 0.76500 0.05640 0.04720
## B. Staggered TWFE with both drops (two units; heterogeneous-timing caveat)
                                         y     est  se_day
1:                                 log txs 0.33300 0.07250
2:         log txs, high-frequency senders 0.25800 0.04220
3:                  log txs, other senders 0.41700 0.07400
4:                          log failed txs 0.36900 0.11000
5:                            failed share 0.00832 0.00675
6:                         log new senders 0.20500 0.08330
7: log distinct senders (sum over classes) 0.10700 0.07060
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
              event           type d_log_txs se_txs   ri_p d_log_fee elasticity
 1:  Base (Ecotone)        approve    0.6720 0.1320 0.0000     -3.02   -0.22300
 2:  Base (Ecotone) erc20_transfer    1.1300 0.1520 0.0000     -3.41   -0.33100
 3:  Base (Ecotone)         native    0.5840 0.1210 0.0169     -2.76   -0.21100
 4:  Base (Ecotone)     other_call    1.0400 0.3140 0.0000     -2.06   -0.50600
 5:  Base (Ecotone)           swap    0.7570 0.1700 0.0000     -2.72   -0.27800
 6: Arbitrum step 1        approve    0.4760 0.0458 0.0172     -2.68   -0.17800
 7: Arbitrum step 1 erc20_transfer    0.5190 0.1170 0.0000     -2.63   -0.19700
 8: Arbitrum step 1         native    0.6310 0.1530 0.0000     -2.93   -0.21500
 9: Arbitrum step 1     other_call    0.7090 0.0880 0.0000     -1.73   -0.41000
10: Arbitrum step 1           swap    0.7370 0.0997 0.0000     -1.86   -0.39700
11: Arbitrum step 2        approve    0.1500 0.1090 0.2070     -1.78   -0.08420
12: Arbitrum step 2 erc20_transfer    0.0101 0.0466 0.9660     -1.78   -0.00566
13: Arbitrum step 2         native    0.1420 0.1730 0.3280     -1.67   -0.08500
14: Arbitrum step 2     other_call    0.2600 0.0934 0.0517     -1.98   -0.13100
15: Arbitrum step 2           swap   -0.5760 0.1830 0.0000     -1.56    0.37000

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
[23] labeling_0.4.3       plyr_1.8.9           RColorBrewer_1.1-3   withr_3.0.2          purrr_1.2.1          numDeriv_2016.8-1.1  nnet_7.3-20          grid_4.5.3           stats4_4.5.3         xtable_1.8-8         future_1.70.0       
[34] BMisc_1.4.8          globals_0.19.1       emmeans_2.0.2        scales_1.4.0         iterators_1.0.14     MASS_7.3-65          cli_3.6.5            mvtnorm_1.3-6        ragg_1.5.1           generics_0.1.4       otel_0.2.0          
[45] future.apply_1.20.2  bigmemory.sri_0.1.8  reshape2_1.4.5       DBI_1.3.0            stringr_1.6.0        splines_4.5.3        parallel_4.5.3       fastglm_0.0.4        stringmagic_1.2.0    vctrs_0.7.1          hardhat_1.4.2       
[56] Matrix_1.7-4         sandwich_3.1-1       did_2.3.0            Formula_1.2-5        listenv_0.10.1       systemfonts_1.3.2    foreach_1.5.2        trust_0.1-9          gower_1.0.2          tidyr_1.3.2          recipes_1.3.1       
[67] glue_1.8.0           bigmemory_4.6.4      parallelly_1.46.1    codetools_0.2-20     lubridate_1.9.5      stringi_1.8.7        gtable_0.3.6         tibble_3.3.1         pillar_1.11.1        ipred_0.9-15         lava_1.8.2          
[78] R6_2.6.1             textshaping_1.0.5    rprojroot_2.1.1      lattice_0.22-9       class_7.3-23         Rcpp_1.1.1           uuid_1.2-2           coda_0.19-4.1        nlme_3.1-168         prodlim_2026.03.11   zoo_1.8-15          
[89] pkgconfig_2.0.3      ModelMetrics_1.2.2.2
```
