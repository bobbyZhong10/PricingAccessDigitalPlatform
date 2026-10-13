# 07 multichain
Run 2026-10-12 22:54:21 UTC
Panel: 7833 chain-days, 23 chains; 414 candidate drop days; 34 events (up to two per chain)
## A. Per-event daily DiD; elasticity = beta / beta_cost
          chain       date drop_log pre_level post_level n_ctrl  b_cost     b_tx   se_tx     b_daa  se_daa perm_p_tx n_placebo    el_tx    el_daa
 1:    arbitrum 2024-03-18   2.2370 0.2683317  0.0087184      4 -3.1544  0.43926 0.09000  0.314083 0.08075   0.05000        40 -0.13925 -0.099569
 2:    arbitrum 2024-04-04   1.8151 0.0228831  0.0072102      5 -0.4763  0.23750 0.05221  0.082535 0.07663   0.25000        40 -0.49866 -0.173290
 3:        base 2024-03-14   4.8078 0.5888029  0.0070729      4 -2.4740  1.16201 0.09326  0.970591 0.11809   0.00000        36 -0.46969 -0.392321
 4:        base 2024-05-29   3.2165 0.0336662  0.0022403      7 -2.5274  0.30860 0.05052  0.242805 0.06716   0.22222        36 -0.12210 -0.096070
 5:        celo 2024-04-26   0.8516 0.0007083  0.0002718      5 -1.1104  0.56867 0.08696  0.953813 0.17569   0.04762        42 -0.51214 -0.858992
 6:         ink 2024-12-15   2.3767 0.0128602  0.0009051      0      NA       NA      NA        NA      NA       NaN         0       NA        NA
 7:         ink 2024-12-31   2.5065 0.0046244  0.0005720     10 -0.6293  0.45716 0.12676  0.644070 0.14934       NaN         0 -0.72646 -1.023473
 8:       linea 2024-03-28   1.8759 0.2331013  0.0457733      4 -1.9971  0.29437 0.24670 -0.040583 0.15078   0.61111        36 -0.14740  0.020320
 9:       linea 2024-11-28   0.8942 0.0582140  0.0463964      8 -0.3566 -0.07679 0.04628 -0.171631 0.05861   0.91667        36  0.21535  0.481319
10:        lisk 2024-08-01   1.6381 0.0003974  0.0004698      7 -0.2041 -0.54607 0.15896 -0.284653 0.16265   0.55556        18  2.67506  1.394437
11:        lisk 2024-09-27   2.3547 0.0039874  0.0012541     11 -0.8455  1.02619 0.26123  0.473150 0.10017   0.33333        18 -1.21374 -0.559627
12:       manta 2024-03-14   4.2659 0.3382521  0.0051148      4 -3.8656  0.47647 0.11286  0.245819 0.10283   0.33333        36 -0.12326 -0.063591
13:       manta 2024-05-02   2.2964 0.0077010  0.0021443      5 -0.8636 -0.05472 0.05352 -0.291540 0.07874   0.86111        36  0.06336  0.337593
14:      mantle 2024-03-14   3.1676 0.4460156  0.0196964      4 -3.0293  0.20126 0.07554  0.008614 0.10442   0.45000        40 -0.06644 -0.002843
15:       metis 2024-07-22   1.3063 0.0101716  0.0066744      6 -1.3332  0.08358 0.11685 -0.207621 0.16378   0.70588        34 -0.06269  0.155732
16:       metis 2024-09-06   1.4393 0.0056797  0.0015315      9 -1.3006  0.55855 0.06158  1.091846 0.09538   0.11765        34 -0.42947 -0.839517
17:        mode 2024-03-14   6.5545 0.4820687  0.0011277      4 -4.8551  0.85634 0.07353  0.428547 0.08655   0.13889        36 -0.17638 -0.088268
18:        mode 2024-04-04   2.0919 0.0217556  0.0041916      5 -0.8161  0.46892 0.07536  0.018958 0.08586   0.25000        36 -0.57460 -0.023231
19:    optimism 2024-03-15   4.1908 0.4975215  0.0080485      4 -3.4272  0.49002 0.08867  0.274929 0.07463   0.00000        36 -0.14298 -0.080221
20:    optimism 2024-07-11   3.4859 0.0340795  0.0072291      7  0.1601 -0.08123 0.04168 -0.151639 0.05797   0.55556        36 -0.50737 -0.947110
21: polygon_pos 2024-04-18   0.9258 0.0085308  0.0047569      3 -0.6417  0.05648 0.08428 -0.007655 0.15557   0.67500        40 -0.08803  0.011930
22: polygon_pos 2024-05-01   0.8389 0.0036801  0.0014176      5 -0.9253  0.01423 0.04571 -0.115729 0.07853   0.90000        40 -0.01537  0.125077
23:      scroll 2024-04-27   1.5510 0.5978838  0.1824292      5 -0.8616  0.44720 0.08378 -0.008144 0.09050   0.28205        39 -0.51906  0.009453
24:      scroll 2024-05-12   0.9285 0.2427148  0.0925825      5 -0.6752 -0.30227 0.09192 -0.152635 0.08246   0.46154        39  0.44770  0.226069
25:     soneium 2024-12-22   3.1983 0.0166247  0.0028646      8 -2.1516  2.75288 0.38729  0.427186 0.29740       NaN         0 -1.27948 -0.198547
26:     soneium 2024-12-23   3.1983 0.0140242  0.0028646      8 -1.9773  2.48541 0.26835  0.162497 0.26898       NaN         0 -1.25697 -0.082181
27:    starknet 2024-03-14   4.3345 0.8475686  0.0125214      4 -4.1142  0.16311 0.16073 -0.120434 0.16553   0.51282        39 -0.03965  0.029273
28:    starknet 2024-04-03   3.1696 0.0537604  0.0067721      5 -0.8828 -0.18148 0.10803 -0.357554 0.14297   0.48718        39  0.20558  0.405039
29:       taiko 2024-05-29  13.2277 0.0081761  0.0015403      0      NA       NA      NA        NA      NA       NaN        21       NA        NA
30:       taiko 2024-07-03   0.7493 0.0010246  0.0044456      7  1.0398 -0.19743 0.08959 -0.246844 0.08391   0.42857        21 -0.18988 -0.237403
31:    unichain 2024-11-27   2.6838 0.0009291  0.0009140      8 -0.2520 -0.06734 0.16014 -1.649377 0.36085       NaN         0  0.26721  6.545210
32:    unichain 2024-11-28   2.6838 0.0009291  0.0009140      8 -0.2720 -0.09269 0.15826 -1.563512 0.32295       NaN         0  0.34074  5.747652
33:  worldchain 2024-11-27   1.6478 0.0041577  0.0062901      8  0.1163  0.28172 0.05442  0.147974 0.04317   0.75000         4  2.42320  1.272794
34:  worldchain 2024-12-31   1.6798 0.0153263  0.0033653     10 -0.5783  0.11121 0.04097  0.096836 0.06173   1.00000         4 -0.19230 -0.167449
          chain       date drop_log pre_level post_level n_ctrl  b_cost     b_tx   se_tx     b_daa  se_daa perm_p_tx n_placebo    el_tx    el_daa
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
                 event pre_level   b_tx   se_tx elasticity   se_el
1: starknet 2024-03-14    0.8476 0.1631 0.16073   -0.03965 0.03835
2:   scroll 2024-04-27    0.5979 0.4472 0.08378   -0.51906 0.09667
3:     base 2024-03-14    0.5888 1.1620 0.09326   -0.46969 0.08656
4: optimism 2024-03-15    0.4975 0.4900 0.08867   -0.14298 0.02600
5:     mode 2024-03-14    0.4821 0.8563 0.07353   -0.17638 0.01749
6:   mantle 2024-03-14    0.4460 0.2013 0.07554   -0.06644 0.02451
7:    manta 2024-03-14    0.3383 0.4765 0.11286   -0.12326 0.02895
8: arbitrum 2024-03-18    0.2683 0.4393 0.09000   -0.13925 0.02469
9:    linea 2024-03-28    0.2331 0.2944 0.24670   -0.14740 0.12573
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
                                         set              outcome     att     se elasticity
1:                          documented dates       log median fee -3.0558 0.6308    1.00000
2:                          documented dates              log txs  0.5429 0.1836   -0.17766
3:                          documented dates log active addresses  0.3602 0.2057   -0.11786
4: documented where available, else detected       log median fee -2.6274 0.5199    1.00000
5: documented where available, else detected              log txs  0.2844 0.1652   -0.10825
6: documented where available, else detected log active addresses  0.1694 0.1621   -0.06448

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
