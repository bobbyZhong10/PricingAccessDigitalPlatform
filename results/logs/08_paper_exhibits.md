# 08 paper exhibits
Run 2026-10-13 18:16:52 UTC

## Table 1. The fee cuts
        Cut                            Time (UTC)                                                    What changed            Set by Median fee per tx before (US$) After (US$) Change (log points)
1: Base Mar                      2024-03-14 00:00 Ethereum Dencun (EIP-4844) passed through: Base Ecotone upgrade cost pass-through                         0.5888      0.0079               -4.31
2:    Arb 1                      2024-03-14 15:00               Ethereum Dencun passed through: Arbitrum ArbOS 20 cost pass-through                         0.5502      0.0825               -1.90
3:    Arb 2                      2024-03-19 08:00       Arbitrum governance: minimum L2 base fee 0.1 to 0.01 gwei          platform                         0.0825      0.0091               -2.21
4: Base May 2024-05-28 19:00 and 2024-05-30 20:00    Base raised the block gas limit 60M to 75M to 90M (capacity)          platform                         0.0340      0.0022               -2.72

## Table 2. Usage at the five fee cuts: hourly regression discontinuity in time
                                         Outcome        Base, 14 Mar    Arbitrum, 14 Mar    Arbitrum, 19 Mar        Base, 28 May        Base, 30 May
1:           log median fee per tx (first stage) -4.16 (0.82) [0.02] -2.02 (0.18) [0.02] -1.82 (0.19) [0.02] -1.02 (0.23) [0.05] -1.02 (0.36) [0.05]
2: log mean fee per tx (first stage, robustness) -2.03 (0.27) [0.02] -1.82 (0.20) [0.02] -1.88 (0.25) [0.02] -0.48 (0.17) [0.16] -0.57 (0.30) [0.13]
3:                       log L2 base fee per gas                                                             -1.02 (0.26) [0.08] -1.60 (0.52) [0.03]
4:                                       log txs  0.79 (0.32) [0.02]  0.76 (0.09) [0.02]  0.14 (0.10) [0.29]  0.20 (0.03) [0.05] -0.02 (0.04) [0.84]
5:                          log distinct senders  0.87 (0.12) [0.02]  0.50 (0.07) [0.02]  0.18 (0.12) [0.12]  0.23 (0.09) [0.11] -0.02 (0.05) [0.89]
6:                               log new senders  0.82 (0.15) [0.05]  0.54 (0.10) [0.03]  0.05 (0.16) [0.80]  0.60 (0.25) [0.11] -0.55 (0.17) [0.13]
7:              elasticity of txs (median price)        -0.19 (0.08)        -0.38 (0.07)        -0.08 (0.06)        -0.20 (0.04)         0.01 (0.05)

## Table 3. Usage responds through entry: aggregate vs intensive-margin elasticities
                                 Margin                                      Design                             Sample Elasticity      SE                               Note
 1:                 Aggregate (all txs)                     Hourly fuzzy RD in time                       Base, 14 Mar      -0.19  (0.08)              first-stage Wald 25.6
 2:                 Aggregate (all txs)                     Hourly fuzzy RD in time                   Arbitrum, 14 Mar      -0.38  (0.07)             first-stage Wald 131.8
 3:                 Aggregate (all txs)                     Hourly fuzzy RD in time                   Arbitrum, 19 Mar      -0.08  (0.06)              first-stage Wald 89.7
 4:                 Aggregate (all txs)                     Hourly fuzzy RD in time                       Base, 28 May      -0.20  (0.04)              first-stage Wald 19.8
 5:                 Aggregate (all txs)                     Hourly fuzzy RD in time                       Base, 30 May       0.01  (0.05)               first-stage Wald 8.3
 6:                 Aggregate (all txs)                     Hourly fuzzy RD in time               Base, both May steps      -0.10  (0.04)              first-stage Wald 15.7
 7:                 Aggregate (all txs)                      Daily 2SLS vs 7 chains                          Base, May      -0.10  (0.02)      permutation p of the DiD 0.38
 8:                 Aggregate (all txs)                 Stacked 2SLS across rollups         6 events, documented dates      -0.20  (0.06)                   first-stage F 29
 9:                 Aggregate (all txs)                 Stacked 2SLS across rollups           9 events, detected dates      -0.16  (0.06)                   first-stage F 47
10: Intensive (txs per existing sender) Within sender, net of a placebo window pair     Base, 14 Mar (245,606 senders)     -0.041 (0.001) 3 fee-level bins, -0.060 to -0.036
11: Intensive (txs per existing sender) Within sender, net of a placebo window pair Arbitrum, 14 Mar (237,159 senders)     -0.030 (0.001) 3 fee-level bins, -0.050 to -0.011
12: Intensive (txs per existing sender) Within sender, net of a placebo window pair Arbitrum, 19 Mar (316,933 senders)      0.002 (0.021)  5 fee-level bins, -0.054 to 0.104

## Table 4. Who the new accounts are: burst accounts vs non-burst entrants, Base, first cut
                                                                Characteristic          Burst accounts       Non-burst entrants
 1:                                  Entrants per day, before -> after the cut 1,940 -> 98,714 (x50.9) 18,277 -> 32,149 (x1.76)
 2:                                  Entities per day, before -> after the cut    289 -> 4,791 (x16.6) 13,410 -> 19,615 (x1.46)
 3:                          Entry ratio across the three classification rules              x51 to x74           x1.76 to x2.13
 4:                   Share of all entrants after the cut (range across rules)              69% to 75%                         
 5:                                     In a funding cluster of >= 20 entrants                   93.5%                    30.8%
 6: First tx in the same block as >= 10 others with the same target and method                   67.4%                     6.7%
 7:                                Share held by the largest 10 / 100 entities               50% / 84%                23% / 28%
 8:     First action: zero-value or native transfer to an account without code                     86%                         
 9:                  Months active of Sep 2024, Dec 2024, Mar 2025 (mean, 0-3)                    0.03                     0.18
10:                                    On the LayerZero provisional Sybil list                   0.13%                    3.66%
11:      Address also enters on Arbitrum / funder also funds Arbitrum entrants             0.6% / 2.3%              6.9% / 5.6%
12:                              Received tokens / ETH after entry (to 15 Apr)                81% / 4%                55% / 29%

## Table 5. The second cut: Base, March vs May 2024
                                                                                 First cut: March 2024 (L1 data cost) Second cut: May 2024 (capacity raised by Base)
 1:                                     Median fee per tx, before -> after (US$)                      0.589 -> 0.0079                                0.034 -> 0.0022
 2:                                      Burst accounts per day, before -> after              1,940 -> 98,714 (x50.9)                        11,364 -> 50,876 (x4.5)
 3:                                      Burst entities per day, before -> after                289 -> 4,791 (x16.59)                         4,828 -> 4,097 (x0.85)
 4:                                  Non-burst entrants per day, before -> after             18,277 -> 32,149 (x1.76)                       42,706 -> 44,553 (x1.04)
 5:                                                  All entrants per day, ratio                                x6.47                                          x1.77
 6:                Overstatement of participation growth (all / non-burst ratio)                                 3.68                                           1.70
 7:                                        Burst share of entrants after the cut                                  75%                                            53%
 8:                            Share held by the largest 10 / 100 burst entities                            50% / 84%                                      82% / 91%
 9:                                 Burst accounts in a funding cluster of >= 20                                93.5%                                          91.5%
10: Months active of Sep 2024, Dec 2024, Mar 2025 (mean, 0-3): burst / non-burst                          0.03 / 0.18                                    0.04 / 0.14
11:                                    March burst operators active again in May                                                                  61 of 1,573 (3.9%)
12:                 May burst accounts funded or swept by a March burst operator                                                                              0.006%
13:    Burst accounts' first action: transfer / DEX swap / mint or claim / other                   90% / 2% / 6% / 2%                           15% / 59% / 19% / 8%
14:                 Non-burst entry jump in the cut hour (hourly RD, log points)                          0.30 (0.10)                      0.53 (0.20) / 0.01 (0.04)
15:                                Relative to Arbitrum: burst accounts (95% CI)                                                                  x0.41 [0.14, 1.66]
16:                            Relative to Arbitrum: non-burst entrants (95% CI)                                                                  x0.88 [0.59, 1.48]

## Table 6. Dollar stakes, the cost of an identity, and platform profit at each cut
        Cut            Set by Fee revenue, before -> after (US$ k/day) L1 data cost (US$ k/day) Profit (US$ k/day) Profit change (log) Stake: individual entrant (US$) Stake: operator of the average burst account (US$)
1: Base Mar cost pass-through                               405 -> 435             279.9 -> 1.5         125 -> 433               +1.25                            1.16                                             16,526
2:    Arb 1 cost pass-through                               653 -> 168             556.0 -> 7.1          97 -> 160               +0.50                            0.47                                                 69
3:    Arb 2          platform                                168 -> 31               7.1 -> 8.0          160 -> 23               -1.96                            0.07                                                 35
4: Base May          platform                               328 -> 121               0.6 -> 1.0         327 -> 120               -1.00                            0.06                                              1,587
   Cost of an identity, before -> after (US$)
1:                            0.589 -> 0.0079
2:                            1.650 -> 0.2475
3:                            0.248 -> 0.0272
4:                            0.068 -> 0.0045

Wrote 6 main tables, tables.md and README.md (9 main exhibits, 47 appendix files indexed) to results/paper

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
