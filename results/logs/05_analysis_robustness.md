# 05 robustness
Run 2026-10-12 22:52:15 UTC
Panel 2024-02-22..2024-04-14 23:00:00 UTC; campaign share of Base successful txs 03-14..21: 0.176
## A. Log txs: estimate [RI p]
                spec Base (Ecotone) Arbitrum step 1 Arbitrum step 2
 1:  W12 mean donut0    0.65 [0.01]     0.51 [0.00]     0.35 [0.06]
 2:  W12 mean donut1    0.66 [0.01]     0.53 [0.00]     0.36 [0.08]
 3: W12 trend donut0   -0.16 [0.49]     0.19 [0.55]     0.33 [0.12]
 4: W12 trend donut1   -0.44 [0.09]     0.14 [0.73]     0.40 [0.15]
 5:  W24 mean donut0    0.99 [0.00]     0.61 [0.00]     0.35 [0.00]
 6:  W24 mean donut1    1.01 [0.00]     0.64 [0.00]     0.36 [0.00]
 7:  W24 mean donut3    1.04 [0.00]     0.71 [0.00]     0.37 [0.00]
 8:  W36 mean donut0    1.11 [0.00]     0.56 [0.00]     0.45 [0.00]
 9:  W36 mean donut1    1.12 [0.00]     0.56 [0.00]     0.46 [0.00]
10:  W36 mean donut3    1.14 [0.00]     0.57 [0.00]     0.48 [0.00]
11: W36 trend donut0    0.77 [0.00]     0.73 [0.00]     0.13 [0.32]
12: W36 trend donut1    0.79 [0.00]     0.76 [0.00]     0.14 [0.30]
13: W36 trend donut3    0.82 [0.00]     0.85 [0.00]     0.17 [0.27]
14:  W72 mean donut0    1.24 [0.00]     0.43 [0.00]     0.40 [0.00]
15:  W72 mean donut1    1.25 [0.00]     0.43 [0.00]     0.40 [0.00]
16:  W72 mean donut3    1.27 [0.00]     0.43 [0.00]     0.41 [0.00]
17: W72 trend donut0    0.83 [0.00]     0.59 [0.00]     0.44 [0.00]
18: W72 trend donut1    0.85 [0.00]     0.59 [0.00]     0.45 [0.00]
19: W72 trend donut3    0.88 [0.00]     0.62 [0.00]     0.47 [0.00]
## A. First stage (log fee per tx)
                spec Base (Ecotone) Arbitrum step 1 Arbitrum step 2
 1:  W12 mean donut0          -2.47           -1.91           -1.84
 2:  W12 mean donut1          -2.58           -1.88           -1.82
 3: W12 trend donut0          -2.06           -2.20           -1.57
 4: W12 trend donut1          -2.44           -2.16           -1.37
 5:  W24 mean donut0          -1.91           -1.77           -1.86
 6:  W24 mean donut1          -1.93           -1.74           -1.85
 7:  W24 mean donut3          -1.92           -1.67           -1.99
 8:  W36 mean donut0          -1.88           -1.73           -1.84
 9:  W36 mean donut1          -1.89           -1.72           -1.84
10:  W36 mean donut3          -1.86           -1.70           -1.89
11: W36 trend donut0          -1.96           -1.85           -1.90
12: W36 trend donut1          -2.03           -1.82           -1.88
13: W36 trend donut3          -1.92           -1.74           -2.15
14:  W72 mean donut0          -2.07           -1.81           -2.00
15:  W72 mean donut1          -2.08           -1.81           -2.00
16:  W72 mean donut3          -2.06           -1.79           -2.03
17: W72 trend donut0          -1.83           -1.75           -1.74
18: W72 trend donut1          -1.86           -1.72           -1.73
19: W72 trend donut3          -1.79           -1.65           -1.82
Share of specifications with estimate > 0 and RI p <= 0.10: Base (Ecotone) 0.89; Arbitrum step 1 0.89; Arbitrum step 2 0.74 
## B-E. Other checks
                                                                              check           event     est      se    ri_p
 1:                                 B. weekly-differenced log txs (mean diff, 36 h)  Base (Ecotone) 1.18914 0.17207 0.00000
 2:                                 B. weekly-differenced log txs (mean diff, 36 h) Arbitrum step 1 0.61939 0.07619 0.00000
 3:                                 B. weekly-differenced log txs (mean diff, 36 h) Arbitrum step 2 0.31448 0.14677 0.04615
 4:         C1. market controls: log L1 and Bitcoin txs as covariates (trend, 36 h)  Base (Ecotone) 0.78554 0.32669 0.00000
 5:         C1. market controls: log L1 and Bitcoin txs as covariates (trend, 36 h) Arbitrum step 1 0.74887 0.08732 0.00000
 6:         C1. market controls: log L1 and Bitcoin txs as covariates (trend, 36 h) Arbitrum step 2 0.09695 0.11705 0.45070
 7:                                C2. market controls, mean difference within 72 h  Base (Ecotone) 1.27124 0.12337 0.00000
 8:                                C2. market controls, mean difference within 72 h Arbitrum step 1 0.42817 0.06384 0.00000
 9:                                C2. market controls, mean difference within 72 h Arbitrum step 2 0.33215 0.06564 0.00000
10:                                                        E1. main spec, NW(24) SE  Base (Ecotone) 0.78670 0.18251      NA
11:                                                        E1. main spec, NW(24) SE Arbitrum step 1 0.76138 0.04758      NA
12:                                                        E1. main spec, NW(24) SE Arbitrum step 2 0.13776 0.07873      NA
13:                                              E2. main spec, SE clustered by day  Base (Ecotone) 0.78670 0.07729      NA
14:                                              E2. main spec, SE clustered by day Arbitrum step 1 0.76138 0.05134      NA
15:                                              E2. main spec, SE clustered by day Arbitrum step 2 0.13776 0.06085      NA
16:           C3. Base minus Arbitrum, before Arbitrum's drop (36 h pre, 15 h post)  Base (Ecotone) 1.23245 0.10739      NA
17:     D. Base successful txs net of campaign wallets and collectors (trend, 36 h)  Base (Ecotone) 0.91002 0.20830 0.00000
18: D. Base successful txs net of campaign wallets and collectors (mean diff, 72 h)  Base (Ecotone) 0.98129 0.04666 0.00000
## F. Placebo at the L1 fork hour (+-10 h); RI over the same clock hour on 24 / 22 other days (daily / weekly differenced)
       chain                                       outcome burst_dropped      est   ri_p fake_sd
 1:     base         log txs, minus same hour previous day         FALSE  0.45816 0.0000  0.1004
 2:     base         log txs, minus same hour previous day          TRUE  0.15926 0.1250  0.1004
 3:     base  log fee per tx, minus same hour previous day         FALSE -0.15027 0.4583  0.3334
 4:     base  log fee per tx, minus same hour previous day          TRUE -0.06734 0.6667  0.3334
 5:     base        log txs, minus same hour previous week         FALSE  0.62164 0.0000  0.1000
 6:     base        log txs, minus same hour previous week          TRUE  0.33460 0.0000  0.1000
 7:     base log fee per tx, minus same hour previous week         FALSE -0.22919 0.4545  0.4292
 8:     base log fee per tx, minus same hour previous week          TRUE -0.16522 0.6818  0.4292
 9: arbitrum         log txs, minus same hour previous day         FALSE -0.08840 0.6667  0.1732
10: arbitrum         log txs, minus same hour previous day          TRUE -0.10787 0.5417  0.1732
11: arbitrum  log fee per tx, minus same hour previous day         FALSE -0.04477 0.8333  0.3334
12: arbitrum  log fee per tx, minus same hour previous day          TRUE -0.06683 0.7917  0.3334
13: arbitrum        log txs, minus same hour previous week         FALSE  0.13172 0.4545  0.1882
14: arbitrum        log txs, minus same hour previous week          TRUE  0.11104 0.5455  0.1882
15: arbitrum log fee per tx, minus same hour previous week         FALSE -0.15341 0.4091  0.3206
16: arbitrum log fee per tx, minus same hour previous week          TRUE -0.16586 0.4091  0.3206

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
