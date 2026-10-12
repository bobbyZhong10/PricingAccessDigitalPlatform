# 07 multichain
Run 2026-10-12 20:11:29 UTC
Panel: 7833 chain-days, 23 chains; 414 candidate drop days; 34 events (up to two per chain)
## A. Per-event daily DiD; elasticity = beta / beta_cost
          chain       date drop_log pre_level post_level n_ctrl b_cost    b_tx  se_tx    b_daa se_daa perm_p_tx n_placebo   el_tx   el_daa
 1:    arbitrum 2024-03-18    2.240  0.268000   0.008720      4 -3.150  0.4390 0.0900  0.31400 0.0807    0.0500        40 -0.1390 -0.09960
 2:    arbitrum 2024-04-04    1.820  0.022900   0.007210      5 -0.476  0.2380 0.0522  0.08250 0.0766    0.2500        40 -0.4990 -0.17300
 3:        base 2024-03-14    4.810  0.589000   0.007070      4 -2.470  1.1600 0.0933  0.97100 0.1180    0.0000        36 -0.4700 -0.39200
 4:        base 2024-05-29    3.220  0.033700   0.002240      7 -2.530  0.3090 0.0505  0.24300 0.0672    0.2220        36 -0.1220 -0.09610
 5:        celo 2024-04-26    0.852  0.000708   0.000272      5 -1.110  0.5690 0.0870  0.95400 0.1760    0.0476        42 -0.5120 -0.85900
 6:         ink 2024-12-15    2.380  0.012900   0.000905      0     NA      NA     NA       NA     NA       NaN         0      NA       NA
 7:         ink 2024-12-31    2.510  0.004620   0.000572     10 -0.629  0.4570 0.1270  0.64400 0.1490       NaN         0 -0.7260 -1.02000
 8:       linea 2024-03-28    1.880  0.233000   0.045800      4 -2.000  0.2940 0.2470 -0.04060 0.1510    0.6110        36 -0.1470  0.02030
 9:       linea 2024-11-28    0.894  0.058200   0.046400      8 -0.357 -0.0768 0.0463 -0.17200 0.0586    0.9170        36  0.2150  0.48100
10:        lisk 2024-08-01    1.640  0.000397   0.000470      7 -0.204 -0.5460 0.1590 -0.28500 0.1630    0.5560        18  2.6800  1.39000
11:        lisk 2024-09-27    2.350  0.003990   0.001250     11 -0.845  1.0300 0.2610  0.47300 0.1000    0.3330        18 -1.2100 -0.56000
12:       manta 2024-03-14    4.270  0.338000   0.005110      4 -3.870  0.4760 0.1130  0.24600 0.1030    0.3330        36 -0.1230 -0.06360
13:       manta 2024-05-02    2.300  0.007700   0.002140      5 -0.864 -0.0547 0.0535 -0.29200 0.0787    0.8610        36  0.0634  0.33800
14:      mantle 2024-03-14    3.170  0.446000   0.019700      4 -3.030  0.2010 0.0755  0.00861 0.1040    0.4500        40 -0.0664 -0.00284
15:       metis 2024-07-22    1.310  0.010200   0.006670      6 -1.330  0.0836 0.1170 -0.20800 0.1640    0.7060        34 -0.0627  0.15600
16:       metis 2024-09-06    1.440  0.005680   0.001530      9 -1.300  0.5590 0.0616  1.09000 0.0954    0.1180        34 -0.4290 -0.84000
17:        mode 2024-03-14    6.550  0.482000   0.001130      4 -4.860  0.8560 0.0735  0.42900 0.0866    0.1390        36 -0.1760 -0.08830
18:        mode 2024-04-04    2.090  0.021800   0.004190      5 -0.816  0.4690 0.0754  0.01900 0.0859    0.2500        36 -0.5750 -0.02320
19:    optimism 2024-03-15    4.190  0.498000   0.008050      4 -3.430  0.4900 0.0887  0.27500 0.0746    0.0000        36 -0.1430 -0.08020
20:    optimism 2024-07-11    3.490  0.034100   0.007230      7  0.160 -0.0812 0.0417 -0.15200 0.0580    0.5560        36 -0.5070 -0.94700
21: polygon_pos 2024-04-18    0.926  0.008530   0.004760      3 -0.642  0.0565 0.0843 -0.00766 0.1560    0.6750        40 -0.0880  0.01190
22: polygon_pos 2024-05-01    0.839  0.003680   0.001420      5 -0.925  0.0142 0.0457 -0.11600 0.0785    0.9000        40 -0.0154  0.12500
23:      scroll 2024-04-27    1.550  0.598000   0.182000      5 -0.862  0.4470 0.0838 -0.00814 0.0905    0.2820        39 -0.5190  0.00945
24:      scroll 2024-05-12    0.929  0.243000   0.092600      5 -0.675 -0.3020 0.0919 -0.15300 0.0825    0.4620        39  0.4480  0.22600
25:     soneium 2024-12-22    3.200  0.016600   0.002860      8 -2.150  2.7500 0.3870  0.42700 0.2970       NaN         0 -1.2800 -0.19900
26:     soneium 2024-12-23    3.200  0.014000   0.002860      8 -1.980  2.4900 0.2680  0.16200 0.2690       NaN         0 -1.2600 -0.08220
27:    starknet 2024-03-14    4.330  0.848000   0.012500      4 -4.110  0.1630 0.1610 -0.12000 0.1660    0.5130        39 -0.0396  0.02930
28:    starknet 2024-04-03    3.170  0.053800   0.006770      5 -0.883 -0.1810 0.1080 -0.35800 0.1430    0.4870        39  0.2060  0.40500
29:       taiko 2024-05-29   13.200  0.008180   0.001540      0     NA      NA     NA       NA     NA       NaN        21      NA       NA
30:       taiko 2024-07-03    0.749  0.001020   0.004450      7  1.040 -0.1970 0.0896 -0.24700 0.0839    0.4290        21 -0.1900 -0.23700
31:    unichain 2024-11-27    2.680  0.000929   0.000914      8 -0.252 -0.0673 0.1600 -1.65000 0.3610       NaN         0  0.2670  6.55000
32:    unichain 2024-11-28    2.680  0.000929   0.000914      8 -0.272 -0.0927 0.1580 -1.56000 0.3230       NaN         0  0.3410  5.75000
33:  worldchain 2024-11-27    1.650  0.004160   0.006290      8  0.116  0.2820 0.0544  0.14800 0.0432    0.7500         4  2.4200  1.27000
34:  worldchain 2024-12-31    1.680  0.015300   0.003370     10 -0.578  0.1110 0.0410  0.09680 0.0617    1.0000         4 -0.1920 -0.16700
          chain       date drop_log pre_level post_level n_ctrl b_cost    b_tx  se_tx    b_daa se_daa perm_p_tx n_placebo   el_tx   el_daa
B. Blob-adoption events: 9 (arbitrum 2024-03-18; base 2024-03-14; linea 2024-03-28; manta 2024-03-14; mantle 2024-03-14; mode 2024-03-14; optimism 2024-03-15; scroll 2024-04-27; starknet 2024-03-14)
## B. detected blob-adoption dates: 9 events, 12 chains; reduced forms (log cost, log txs, log active addresses) and 2SLS elasticities
                     rf.1     rf.2     rf.3
Dependent Var.:        lc       ly       la
                                           
tr x post       -3.076***  0.5031*  0.2293 
                (0.4470)  (0.2011) (0.2001)
Fixed-Effects:  --------- -------- --------
ev-chain              Yes      Yes      Yes
ev-date               Yes      Yes      Yes
_______________ _________ ________ ________
S.E.: Clustered by: chain by: ch.. by: ch..
Observations        1,288    1,288    1,288
R2                0.97547  0.95755  0.97332
Within R2         0.71595  0.12758  0.02566
---
Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
                      iv      iva
Dependent Var.:       ly       la
                                 
lc              -0.1635* -0.0745 
                (0.0571) (0.0614)
Fixed-Effects:  -------- --------
ev-chain             Yes      Yes
ev-date              Yes      Yes
_______________ ________ ________
S.E.: Clustered by: ch.. by: ch..
Observations       1,288    1,288
R2               0.95755  0.97332
Within R2        0.12758  0.02566
---
Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## B. documented dates, 6 rollups: 6 events, 11 chains; reduced forms (log cost, log txs, log active addresses) and 2SLS elasticities
                     rf.1     rf.2     rf.3
Dependent Var.:        lc       ly       la
                                           
tr x post       -3.272***  0.6619*  0.3614 
                (0.6024)  (0.2319) (0.2567)
Fixed-Effects:  --------- -------- --------
ev-chain              Yes      Yes      Yes
ev-date               Yes      Yes      Yes
_______________ _________ ________ ________
S.E.: Clustered by: chain by: ch.. by: ch..
Observations          868      868      868
R2                0.97267  0.96145  0.97181
Within R2         0.71704  0.22369  0.06003
---
Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
                       iv      iva
Dependent Var.:        ly       la
                                  
lc              -0.2023** -0.1105 
                (0.0638)  (0.0741)
Fixed-Effects:  --------- --------
ev-chain              Yes      Yes
ev-date               Yes      Yes
_______________ _________ ________
S.E.: Clustered by: chain by: ch..
Observations          868      868
R2                0.96145  0.97181
Within R2         0.22369  0.06003
---
Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## B. detected dates excluding Linea/Manta/Mantle: 6 events, 11 chains; reduced forms (log cost, log txs, log active addresses) and 2SLS elasticities
                     rf.1     rf.2     rf.3
Dependent Var.:        lc       ly       la
                                           
tr x post       -3.132***  0.5920*  0.3077 
                (0.5835)  (0.2361) (0.2509)
Fixed-Effects:  --------- -------- --------
ev-chain              Yes      Yes      Yes
ev-date               Yes      Yes      Yes
_______________ _________ ________ ________
S.E.: Clustered by: chain by: ch.. by: ch..
Observations          868      868      868
R2                0.96879  0.95984  0.97196
Within R2         0.67328  0.17890  0.04421
---
Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
                      iv      iva
Dependent Var.:       ly       la
                                 
lc              -0.1890* -0.0983 
                (0.0661) (0.0751)
Fixed-Effects:  -------- --------
ev-chain             Yes      Yes
ev-date              Yes      Yes
_______________ ________ ________
S.E.: Clustered by: ch.. by: ch..
Observations         868      868
R2               0.95984  0.97196
Within R2        0.17890  0.04421
---
Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
## B. Per-event: txs reduced form and 2SLS elasticity
                 event pre_level  b_tx  se_tx elasticity  se_el
1: starknet 2024-03-14     0.848 0.163 0.1610    -0.0396 0.0383
2:   scroll 2024-04-27     0.598 0.447 0.0838    -0.5190 0.0967
3:     base 2024-03-14     0.589 1.160 0.0933    -0.4700 0.0866
4: optimism 2024-03-15     0.498 0.490 0.0887    -0.1430 0.0260
5:     mode 2024-03-14     0.482 0.856 0.0735    -0.1760 0.0175
6:   mantle 2024-03-14     0.446 0.201 0.0755    -0.0664 0.0245
7:    manta 2024-03-14     0.338 0.476 0.1130    -0.1230 0.0290
8: arbitrum 2024-03-18     0.268 0.439 0.0900    -0.1390 0.0247
9:    linea 2024-03-28     0.233 0.294 0.2470    -0.1470 0.1260
## C. Level test, 13 drops (pre-drop levels $0.0057 to $0.85); negative interaction = more elastic at higher levels
                    f_lv
Dependent Var.:       ly
                        
lc              -0.1567*
                (0.0657)
lcx             -0.0052 
                (0.0198)
Fixed-Effects:  --------
ev-chain             Yes
ev-date              Yes
_______________ ________
S.E.: Clustered by: ch..
Observations       2,184
R2               0.97334
Within R2        0.07223
---
Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
Implied elasticity at $0.50: -0.153; at $0.05: -0.141; at $0.01: -0.133
D. documented dates (few rollups per cohort: small-group inference, no pre-test Wald statistic): treated arbitrum, base, mode, optimism, scroll, starknet; never treated metis, ronin
D. documented where available, else detected (few rollups per cohort: small-group inference, no pre-test Wald statistic): treated arbitrum, base, linea, manta, mantle, mode, optimism, scroll, starknet; never treated metis, ronin
## D. Callaway-Sant'Anna ATT over event days 0..14 (not-yet-treated controls) and implied elasticities
                                         set              outcome    att    se elasticity
1:                          documented dates       log median fee -3.060 0.631     1.0000
2:                          documented dates              log txs  0.543 0.184    -0.1780
3:                          documented dates log active addresses  0.360 0.206    -0.1180
4: documented where available, else detected       log median fee -2.630 0.520     1.0000
5: documented where available, else detected              log txs  0.284 0.165    -0.1080
6: documented where available, else detected log active addresses  0.169 0.162    -0.0645

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
 [1] tidyselect_1.2.1     nanoparquet_0.5.2    timeDate_4052.112    dplyr_1.2.0          farver_2.1.2         S7_0.2.1             duckdb_1.5.0         pROC_1.19.0.1        DRDID_1.2.3          caret_7.0-1          digest_0.6.39       
[12] rpart_4.1.24         estimability_1.5.1   timechange_0.4.0     lifecycle_1.0.5      dreamerr_1.5.0       survival_3.8-6       magrittr_2.0.4       compiler_4.5.3       rlang_1.1.7          tools_4.5.3          yaml_2.3.12         
[23] labeling_0.4.3       plyr_1.8.9           RColorBrewer_1.1-3   withr_3.0.2          purrr_1.2.1          numDeriv_2016.8-1.1  stats4_4.5.3         nnet_7.3-20          grid_4.5.3           xtable_1.8-8         future_1.70.0       
[34] BMisc_1.4.8          emmeans_2.0.2        globals_0.19.1       scales_1.4.0         iterators_1.0.14     MASS_7.3-65          cli_3.6.5            mvtnorm_1.3-6        ragg_1.5.1           generics_0.1.4       otel_0.2.0          
[45] bigmemory.sri_0.1.8  future.apply_1.20.2  reshape2_1.4.5       DBI_1.3.0            stringr_1.6.0        splines_4.5.3        parallel_4.5.3       fastglm_0.0.4        stringmagic_1.2.0    vctrs_0.7.1          hardhat_1.4.2       
[56] Matrix_1.7-4         sandwich_3.1-1       did_2.3.0            Formula_1.2-5        listenv_0.10.1       systemfonts_1.3.2    trust_0.1-9          foreach_1.5.2        tidyr_1.3.2          gower_1.0.2          recipes_1.3.1       
[67] bigmemory_4.6.4      glue_1.8.0           parallelly_1.46.1    codetools_0.2-20     lubridate_1.9.5      stringi_1.8.7        gtable_0.3.6         tibble_3.3.1         pillar_1.11.1        ipred_0.9-15         lava_1.8.2          
[78] R6_2.6.1             textshaping_1.0.5    rprojroot_2.1.1      lattice_0.22-9       class_7.3-23         uuid_1.2-2           Rcpp_1.1.1           coda_0.19-4.1        nlme_3.1-168         prodlim_2026.03.11   zoo_1.8-15          
[89] pkgconfig_2.0.3      ModelMetrics_1.2.2.2
```
