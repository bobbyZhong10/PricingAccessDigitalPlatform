# 05 robustness
Run 2026-10-12 20:10:50 UTC
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
                                                                              check           event    est     se   ri_p
 1:                                 B. weekly-differenced log txs (mean diff, 36 h)  Base (Ecotone) 1.1900 0.1720 0.0000
 2:                                 B. weekly-differenced log txs (mean diff, 36 h) Arbitrum step 1 0.6190 0.0762 0.0000
 3:                                 B. weekly-differenced log txs (mean diff, 36 h) Arbitrum step 2 0.3140 0.1470 0.0462
 4:         C1. market controls: log L1 and Bitcoin txs as covariates (trend, 36 h)  Base (Ecotone) 0.7860 0.3270 0.0000
 5:         C1. market controls: log L1 and Bitcoin txs as covariates (trend, 36 h) Arbitrum step 1 0.7490 0.0873 0.0000
 6:         C1. market controls: log L1 and Bitcoin txs as covariates (trend, 36 h) Arbitrum step 2 0.0969 0.1170 0.4510
 7:                                C2. market controls, mean difference within 72 h  Base (Ecotone) 1.2700 0.1230 0.0000
 8:                                C2. market controls, mean difference within 72 h Arbitrum step 1 0.4280 0.0638 0.0000
 9:                                C2. market controls, mean difference within 72 h Arbitrum step 2 0.3320 0.0656 0.0000
10:                                                        E1. main spec, NW(24) SE  Base (Ecotone) 0.7870 0.1830     NA
11:                                                        E1. main spec, NW(24) SE Arbitrum step 1 0.7610 0.0476     NA
12:                                                        E1. main spec, NW(24) SE Arbitrum step 2 0.1380 0.0787     NA
13:                                              E2. main spec, SE clustered by day  Base (Ecotone) 0.7870 0.0773     NA
14:                                              E2. main spec, SE clustered by day Arbitrum step 1 0.7610 0.0513     NA
15:                                              E2. main spec, SE clustered by day Arbitrum step 2 0.1380 0.0608     NA
16:           C3. Base minus Arbitrum, before Arbitrum's drop (36 h pre, 15 h post)  Base (Ecotone) 1.2300 0.1070     NA
17:     D. Base successful txs net of campaign wallets and collectors (trend, 36 h)  Base (Ecotone) 0.9100 0.2080 0.0000
18: D. Base successful txs net of campaign wallets and collectors (mean diff, 72 h)  Base (Ecotone) 0.9810 0.0467 0.0000
## F. Placebo at the L1 fork hour (+-10 h); RI over the same clock hour on 24 / 22 other days (daily / weekly differenced)
       chain                                       outcome burst_dropped     est  ri_p fake_sd
 1:     base         log txs, minus same hour previous day         FALSE  0.4580 0.000   0.100
 2:     base         log txs, minus same hour previous day          TRUE  0.1590 0.125   0.100
 3:     base  log fee per tx, minus same hour previous day         FALSE -0.1500 0.458   0.333
 4:     base  log fee per tx, minus same hour previous day          TRUE -0.0673 0.667   0.333
 5:     base        log txs, minus same hour previous week         FALSE  0.6220 0.000   0.100
 6:     base        log txs, minus same hour previous week          TRUE  0.3350 0.000   0.100
 7:     base log fee per tx, minus same hour previous week         FALSE -0.2290 0.455   0.429
 8:     base log fee per tx, minus same hour previous week          TRUE -0.1650 0.682   0.429
 9: arbitrum         log txs, minus same hour previous day         FALSE -0.0884 0.667   0.173
10: arbitrum         log txs, minus same hour previous day          TRUE -0.1080 0.542   0.173
11: arbitrum  log fee per tx, minus same hour previous day         FALSE -0.0448 0.833   0.333
12: arbitrum  log fee per tx, minus same hour previous day          TRUE -0.0668 0.792   0.333
13: arbitrum        log txs, minus same hour previous week         FALSE  0.1320 0.455   0.188
14: arbitrum        log txs, minus same hour previous week          TRUE  0.1110 0.545   0.188
15: arbitrum log fee per tx, minus same hour previous week         FALSE -0.1530 0.409   0.321
16: arbitrum log fee per tx, minus same hour previous week          TRUE -0.1660 0.409   0.321

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
