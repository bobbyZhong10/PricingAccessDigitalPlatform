# 08 paper exhibits
Run 2026-10-18 20:11:09 UTC

## Table 1A. Median fee per transaction around the cut (US$)
                      Period            Base      OP Mainnet        Arbitrum     Ethereum L1
1: before, 6 days: 03-08..13         $0.5853         $0.5051         $0.5502        $10.5977
2:       days 0-5: 03-14..19 $0.0063 (-4.53) $0.0087 (-4.06) $0.0825 (-1.90) $6.1312 (-0.55)
3:      days 6-13: 03-20..27 $0.1650 (-1.27) $0.0083 (-4.11) $0.0087 (-4.15) $4.3011 (-0.90)

## Table 1B. Dated events, March-June 2024
          Date Time (UTC)                                                                                                                               Event                    Source
 1: 2024-03-05                                             Base deposits reach a record US$566 million; memecoins hold 14 of the top 20 trading pairs on Base                dlnews.com
 2: 2024-03-13      13:55                                                                                      Dencun upgrade on Ethereum L1 (EIP-4844 blobs)         blog.ethereum.org
 3: 2024-03-14                                                                                                         Bitcoin all-time high (about US$73.7k)             bloomberg.com
 4: 2024-03-14      00:00                                                              Ecotone upgrade on Base and OP Mainnet (L1 data fee priced from blobs)          docs.optimism.io
 5: 2024-03-14      15:00                                                                                       ArbOS 20 Atlas on Arbitrum One (blob pricing)          blog.arbitrum.io
 6: 2024-03-19            Base fee revenue reaches a daily record of about US$1.67 million (memecoin traders and arbitrageurs; bot sniping at token launches)                dlnews.com
 7: 2024-03-19      08:00                                                                                          Arbitrum minimum base fee 0.1 -> 0.01 gwei forum.arbitrum.foundation
 8: 2024-03-21                                                                 Coinbase Wallet warns that heavy Base traffic leaves some transactions pending        bitcoinworld.co.in
 9: 2024-03-26                                                                                                             Base gas target 2.5 -> 3.75 Mgas/s                     x.com
10: 2024-03-26                    Base deposits near US$1 billion (about double the start of March); record daily users and transactions shortly after Dencun               theblock.co
11: 2024-03-26                                                             Base memecoins (TOSHI; TYBG; NORMIE; BRETT) up as much as 1300% over the past week              fxstreet.com
12: 2024-04-01                                                                                                                    Base gas target -> 5 Mgas/s                     x.com
13: 2024-05-01      23:59                                                                                                       LayerZero airdrop snapshot #1               theblock.co
14: 2024-05-23                                                                                                   SEC approves spot ether ETF listings (19b-4)            mayerbrown.com
15: 2024-05-28      19:00                                                                         Base block gas limit 60M -> 75M (gas target -> 6.25 Mgas/s)                bitget.com
16: 2024-05-30      20:00                                                                          Base block gas limit 75M -> 90M (gas target -> 7.5 Mgas/s)                bitget.com
17: 2024-05-31                                                                                         Onchain Summer Buildathon on Base opens (05-31..06-30)               devfolio.co
18: 2024-06-03                                                                                    Base's Onchain Summer II campaign starts (June 3 to August)         tpan.substack.com
19: 2024-06-20      11:00                                                                                       LayerZero ZRO airdrop claims open (7 a.m. ET)               theblock.co

## Table 2. Entry of new addresses outside batch-creation waves, Base minus Ethereum L1
                           Window Estimate Ratio Pre-cut placebos (non-overlapping) Rank p Placebo SDs AR(1) z All dates: rank of K + 1 Base alone
1:           6 v 6 days (primary)    0.452 x1.57                             61 (6)   1/62         3.1     2.6                 3 of 140      x1.68
2:                     7 v 7 days    0.495 x1.64                             59 (5)   1/60         3.6     3.0                 1 of 134      x1.74
3:                     4 v 4 days    0.370 x1.45                             65 (9)   3/66         2.2     1.8                 6 of 152      x1.62
4:                     5 v 5 days    0.405 x1.50                             63 (7)   1/64         2.6     2.1                 3 of 146      x1.66
5: 6 v 5 days (19 March left out)    0.406 x1.50                             62 (6)   1/63         2.7     2.2                 4 of 143      x1.66
6:            14 v 14 days (path)    0.695 x2.00                                                                                                  
7:            28 v 28 days (path)    0.959 x2.61                                                                                                  

## Table 3. Counted new addresses against entry outside batch-creation waves, Base, March 2024
                                                Sample                        Window or rule Before -> after (per day)   All Outside waves or bursts Share of the added in waves or bursts
 1:      Long series: new addresses (no tx in 60 days)                            6 v 6 days         23,387 -> 162,328 x6.94                   x1.69                                   90%
 2:      Long series: new addresses (no tx in 60 days)                            7 v 7 days         24,239 -> 157,481 x6.50                   x1.76                                   88%
 3:      Long series: new addresses (no tx in 60 days)                          14 v 14 days         23,687 -> 111,187 x4.69                   x2.16                                   74%
 4:      Long series: new addresses (no tx in 60 days)                          28 v 28 days         24,625 -> 110,296 x4.48                   x3.03                                   56%
 5: Window entrants (never active on Base), 6 v 6 days                       main burst rule         19,670 -> 145,230 x7.38                   x1.61                                   91%
 6: Window entrants (never active on Base), 6 v 6 days            size only (>= 5,000 a day)         19,670 -> 145,230 x7.38                   x1.90                                   86%
 7: Window entrants (never active on Base), 6 v 6 days      burst funded by bursting funders         19,670 -> 145,230 x7.38                   x1.97                                   85%
 8: Window entrants (never active on Base), 6 v 6 days                same, pre-entry funder         19,670 -> 145,230 x7.38                   x1.93                                   86%
 9:         Funding entities behind non-burst entrants           implied, 6 days (net of L1)                                      x1.35 [1.28, 1.41]                                      
10:         Funding entities behind non-burst entrants           implied, 7 days (net of L1)                                      x1.41 [1.34, 1.47]                                      
11:         Funding entities behind non-burst entrants direct count, 6 v 6 days (Base alone)          13,063 -> 18,027            x1.38 [1.27, 1.49]                                      

## Table 4. Who the new accounts are: Base window entrants, 6 days before vs 6 days after the cut
                                         Characteristic                    Burst               Non-burst         Bot-like
 1:                   Entrants per day, before -> after 1,617 -> 115,852 (x71.7) 17,959 -> 28,928 (x1.6) 94 -> 451 (x4.8)
 2:           Funding entities per day, before -> after     241 -> 3,661 (x15.2) 13,063 -> 18,027 (x1.4) 50 -> 168 (x3.4)
 3:                     Share of entrants after the cut                      80%                     20%               0%
 4:                         Share of the added entrants                      91%                      9%               0%
 5:                         In a funding cluster of 20+                      95%                     30%              64%
 6:               First tx in a same-block group of 10+                      73%                      6%               4%
 7:             Held by the 10 / 100 largest components                52% / 88%               21% / 28%        56% / 68%
 8:             Went to the most common first recipient                      88%                      8%              12%
 9: Months active of Sep 2024, Dec 2024, Mar 2025 (0-3)                     0.02                    0.18             0.28
10:             On the LayerZero provisional Sybil list                     0.1%                    4.1%             0.3%
11:               Address / funder also enters Arbitrum              0.5% / 2.3%             7.5% / 5.9%      6.3% / 5.1%
12:                   Received tokens / ETH after entry                 88% / 3%               55% / 28%        91% / 59%

## Table 5. Threats to the estimate and the evidence on each
                                                                   Threat
 1:                       A Base-specific shock: the cut day hour by hour
 2:           A Base-specific shock: the memecoin boom (first recipients)
 3:                        A Base-specific shock: swap-like first actions
 4:                               A Base-specific shock: exchange inflows
 5:                                  A Base-specific shock: the ETH rally
 6: A shock common to OP-stack chains (OP Mainnet, same cut, same second)
 7:                                         Ethereum L1 as the comparison
 8:                                                  Delay, not new entry
 9:                    Batch accounts the rules miss; the choice of floor
10:                                              Returners counted as new
11:                                                       Entrant quality
                                                                                                                                                                                                                                                                                                                                                                                   Evidence
 1: Base non-burst entrants on 14 March against the same hours of 8-13 March: +0.06 log in hours 00-05 (median fee 0.14 cents), +0.32 in 06-11, +0.41 in 12-14, +0.50 in 15-23. Base minus not-yet-cut Arbitrum: +0.33 in 06-11 (placebo days -0.40 to 0.20), +0.26 in 12-14; entities +0.24 in 06-11 (placebo days -0.45 to 0.16). Arbitrum rose +0.15 in 12-14, before its own 15:00 cut.
 2:                                                                                                                                                                                               NFT mints and claims, other tokens and a trading-bot contract: x6.8, 21% of the rise in non-burst entrants and 17% of the rise in funding entities. Without them: x1.49 (entities x1.33).
 3:                                                                                                                                                                                                                                                   A DEX-swap selector or a first recipient named as a DEX router, aggregator or trading bot: x1.27, 9% of the rise; without them x1.70.
 4:                                                                                                                                                                                               Non-burst entrants by source of their first ETH: exchange withdrawals x1.34, direct transfers from other addresses x1.98, all x1.61. Without bridge and exchange first recipients: x1.59.
 5:                                                                                                                                                                                                                                                     Mean daily gap (Base minus L1 entry outside waves, relative to the week before the cut) while ETH rose to its 11 March peak: -0.09.
 6:                                                                                                                                OP Mainnet minus L1, 6 days: transactions +0.53 (above 61 of 61 pre-cut placebos), active addresses +0.14 (75th percentile). Base minus OP Mainnet, active addresses: +0.74; without 16 March and Base's new addresses in waves +0.39 (95th percentile).
 7:                                                         L1's fee fell 42% (Base's 99%); L1's own entry outside waves rose 0.07. Active addresses, donor pool of 6 chains whose fees fell less than 1 log: L1 minus the donor mean +0.17 (90th percentile); Base minus the donor mean +1.04 against +0.88 minus L1; Base minus each donor 0.72 to 1.50, each above all pre-cut placebos.
 8:                                                                                                                                                                                                                                        Base minus L1 against 28 days before (c-42..c-15): run-up -0.05, after +0.64, net +0.30 over the 28 days around the cut (a path, without tests).
 9:                                                                                                                                                                                       Wave and burst floors from 50 to 10,000 a day: estimate x1.46 to x1.93, each above all 61 pre-cut placebos; implied entity effect x1.35 to x1.45. Clusters of 20+ hold 49% of the non-burst rise.
10:                                                                                                                                                                                                                                                                                                                            Window entrants never active on Base, outside bursts: x1.61.
11:                                                                                                                                                                                                                                                              Share of non-burst entrants active later (Sep 2024, Dec 2024 or Mar 2025): 14.7% before, 13.2% after (x0.90 [0.82, 0.97]).
                                                           Source
 1:             cut_day_hours.csv, cut_day_hours_placebo_days.csv
 2:                               entry_by_recipient_category.csv
 3:                                     entry_by_first_action.csv
 4:   entrant_funding_source.csv, entry_by_recipient_category.csv
 5:                                                timing_eth.csv
 6:              op_mainnet_vs_l1.csv, base_minus_op_adjusted.csv
 7: fee_path_march.csv, inference_primary.csv, donor_pool_daa.csv
 8:                                          entry_delay_test.csv
 9: inference_wave_size_floors.csv, entrant_entities_nonburst.csv
10:                                       headline_one_sample.csv
11:                                   entrant_persistence_cut.csv

Wrote 6 main tables, tables.md and README.md (9 main exhibits, 41 appendix files indexed) to results/paper

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
[23] yaml_2.3.12          plyr_1.8.9           RColorBrewer_1.1-3   withr_3.0.2          purrr_1.2.1          numDeriv_2016.8-1.1  nnet_7.3-20          grid_4.5.3           stats4_4.5.3         xtable_1.8-8         future_1.70.0       
[34] BMisc_1.4.8          globals_0.19.1       emmeans_2.0.2        scales_1.4.0         iterators_1.0.14     MASS_7.3-65          cli_3.6.5            mvtnorm_1.3-6        generics_0.1.4       otel_0.2.0           future.apply_1.20.2 
[45] bigmemory.sri_0.1.8  reshape2_1.4.5       DBI_1.3.0            stringr_1.6.0        splines_4.5.3        parallel_4.5.3       fastglm_0.0.4        stringmagic_1.2.0    vctrs_0.7.1          hardhat_1.4.2        Matrix_1.7-4        
[56] sandwich_3.1-1       did_2.3.0            Formula_1.2-5        listenv_0.10.1       foreach_1.5.2        trust_0.1-9          gower_1.0.2          tidyr_1.3.2          recipes_1.3.1        glue_1.8.0           bigmemory_4.6.4     
[67] parallelly_1.46.1    codetools_0.2-20     lubridate_1.9.5      stringi_1.8.7        gtable_0.3.6         tibble_3.3.1         pillar_1.11.1        ipred_0.9-15         lava_1.8.2           R6_2.6.1             rprojroot_2.1.1     
[78] lattice_0.22-9       class_7.3-23         Rcpp_1.1.1           uuid_1.2-2           coda_0.19-4.1        gridExtra_2.3        nlme_3.1-168         prodlim_2026.03.11   zoo_1.8-15           pkgconfig_2.0.3      ModelMetrics_1.2.2.2
```
