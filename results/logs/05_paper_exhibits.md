# 05 paper exhibits
Run 2026-11-20 16:05:59 UTC

## Table 1. Counted New Addresses and Entry Outside Batch Waves on Base, Before and After the Cut
                   Sample and window Per day, before -> after Ratio, all Ratio, outside waves or bursts Share of increase in waves or bursts
1: Long series, 6 v 6 days (primary)        23,387 -> 162,328       6.94                           1.69                                  90%
2:           Long series, 7 v 7 days        24,239 -> 157,481       6.50                           1.76                                  88%
3:       Window entrants, 6 v 6 days        19,670 -> 145,230       7.38                           1.61                                  91%

## Table 2. Entry Outside Batch Waves, Base Relative to Ethereum L1
                                  Window Estimate (log) Ratio                       Rank, pre-cut Rank, all dates Ratio, Base alone
1:                  6 v 6 days (primary)          0.452  1.57                             1 of 62        3 of 140              1.68
2:                            7 v 7 days          0.495  1.64                             1 of 60        1 of 134              1.74
3:                            5 v 5 days          0.405  1.50                             1 of 64        3 of 146              1.66
4:                            4 v 4 days          0.370  1.45                             3 of 66        6 of 152              1.62
5:             6 v 5 days (19 March out)          0.406  1.50                             1 of 63        4 of 143              1.66
6:              14 v 14 days (path only)          0.695  2.00                                                                      
7:              28 v 28 days (path only)          0.959  2.61                                                                      
8: Panel B. Funding entities, 6 v 6 days                 1.35 95% interval, delta only: 1.28-1.41                                  
9: Panel B. Funding entities, 7 v 7 days                 1.41 95% interval, delta only: 1.34-1.47                                  

## Table 3. Characteristics of Window Entrants on Base, Six Days Before and After the Cut
                                            Characteristic            Burst        Non-burst     Heavy
 1:                      Entrants per day, before -> after 1,617 -> 115,852 17,959 -> 28,928 94 -> 451
 2:                                                  Ratio             71.7             1.61      4.79
 3:              Funding entities per day, before -> after     241 -> 3,661 13,063 -> 18,027 50 -> 168
 4:                                                 Ratio              15.2             1.38      3.38
 5:                            Share of the added entrants              91%               9%      0.3%
 6:      After the cut: in a funding cluster of 20 or more              95%              30%       64%
 7:  First transaction in a same-block group of 10 or more              73%               6%        4%
 8:          Held by the 10 / 100 largest funding entities        52% / 88%        21% / 28% 56% / 68%
 9: First transaction to the class's most common recipient              88%               8%       12%
10:                             Later months active (of 3)             0.02             0.18      0.28
11:                On the LayerZero provisional Sybil list             0.1%             4.1%      0.3%

## Table A.7. The Primary Statistic Under Alternative Counterfactuals and Outcome Definitions
                Panel                                                       Counterfactual or outcome Estimate (log) Ratio Rank among placebo dates In the paper
 1: A. counterfactual                                     mean over the 6 days 2024-03-08..2024-03-13          0.452  1.57                  1 of 62        shown
 2: A. counterfactual                                    mean over the 12 days 2024-03-02..2024-03-13          0.513  1.67                  1 of 56         note
 3: A. counterfactual                                    mean over the 18 days 2024-02-25..2024-03-13          0.449  1.57                  1 of 50         note
 4: A. counterfactual                                    mean over the 24 days 2024-02-19..2024-03-13          0.447  1.56                  1 of 44         note
 5: A. counterfactual                                    mean over the 30 days 2024-02-13..2024-03-13          0.465  1.59                  1 of 38        shown
 6: A. counterfactual                                     mean over the 6 days 2024-03-01..2024-03-06          0.600  1.82                  1 of 55        shown
 7: A. counterfactual                                    mean over the 12 days 2024-02-24..2024-03-06          0.446  1.56                  1 of 49         note
 8: A. counterfactual                                    mean over the 24 days 2024-02-12..2024-03-06          0.472  1.60                  1 of 37        shown
 9: A. counterfactual                            linear trend over the 12 days 2024-03-02..2024-03-13          0.333  1.40                  4 of 56        shown
10: A. counterfactual                            linear trend over the 21 days 2024-02-22..2024-03-13          0.527  1.69                  1 of 47         note
11: A. counterfactual                            linear trend over the 28 days 2024-02-15..2024-03-13          0.464  1.59                  1 of 40        shown
12: A. counterfactual                            linear trend over the 42 days 2024-02-01..2024-03-13          0.471  1.60                  1 of 26         note
13: A. counterfactual                            linear trend over the 73 days 2024-01-01..2024-03-13          0.336  1.40                       --        shown
14:        B. outcome                  wave threshold six times the group's baseline instead of three          0.422  1.53                  1 of 62        shown
15:        B. outcome                                      established first actions, daily wave rule          0.313  1.37                  1 of 33        shown
16:        B. outcome                                         established first actions, no wave rule          0.448  1.56                  6 of 33        shown
17:        B. outcome established first actions, excluding groups with a wave in the reference period          0.223  1.25                  8 of 33        shown

Wrote 4 laid-out tables, tables.md and README.md (21 exhibits, 40 result files) to results/paper
                       where number                                                                                                                                              meaning
1: Section 6.3, Appendix A.3   1.45                                   the estimate over the largest of the 61 pre-cut placebo statistics (inference_primary.csv: estimate / placebo_max)
2:               Section 6.2    4.1                  growth of counted new addresses over growth of entry outside waves, 6 v 6 days (headline_one_sample.csv: all_ratio / outside_ratio)
3:              Appendix A.4  -0.09                                             mean Base-minus-L1 gap, relative to the week before the cut, while ETH rose to its peak (timing_eth.csv)
4:              Appendix A.2    49%                                               share of the rise in non-burst entry in funding clusters of 20 or more (entrant_entities_nonburst.csv)
5:              Appendix A.4    62% share of post-cut non-burst entrants whose first recipient is one of the 50 named recipients (entry_top_recipients.csv over entrant_classes_6v6.csv)

## sessionInfo
```
R version 4.6.1 (2026-06-24)
Platform: aarch64-apple-darwin23
Running under: macOS Golden Gate 27.2.1

Matrix products: default
BLAS:   /Library/Frameworks/R.framework/Versions/4.6/Resources/lib/libRblas.0.dylib 
LAPACK: /Library/Frameworks/R.framework/Versions/4.6/Resources/lib/libRlapack.dylib;  LAPACK version 3.12.1

locale:
[1] en_US/en_US/en_US/C/en_US/en_US

time zone: UTC
tzcode source: internal

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
[1] jsonlite_2.0.0      ggplot2_4.0.3       fixest_0.14.2       data.table_1.18.6.1 here_1.0.2         

loaded via a namespace (and not attached):
 [1] sandwich_3.1-3      generics_0.1.4      dreamerr_1.5.0      lattice_0.23-1      magrittr_2.0.5      grid_4.6.1          estimability_2.0.0  timechange_0.4.0    RColorBrewer_1.1-3  mvtnorm_1.4-2       rprojroot_2.1.1     Matrix_1.7-6       
[13] DBI_1.3.0           Formula_1.2-6       survival_3.8-12     multcomp_1.4-32     gridExtra_2.3.1     scales_1.4.0        TH.data_1.1-5       stringmagic_1.3.0   codetools_0.2-20    numDeriv_2016.8-1.1 duckdb_1.5.6        cli_3.6.6          
[25] rlang_1.3.0         splines_4.6.1       withr_3.0.3         yaml_2.3.12         otel_0.2.0          tools_4.6.1         coda_0.19-4.1       dplyr_1.2.1         vctrs_0.7.3         R6_2.6.1            zoo_1.9-1           lifecycle_1.0.5    
[37] emmeans_2.0.4       lubridate_1.9.5     MASS_7.3-66         pkgconfig_2.0.3     pillar_1.11.1       gtable_0.3.6        glue_1.8.1          Rcpp_1.1.2          nanoparquet_0.5.2   tibble_3.3.1        tidyselect_1.2.1    farver_2.1.2       
[49] xtable_1.8-8        igraph_2.3.4        nlme_3.1-171        compiler_4.6.1      S7_0.2.2           
```
