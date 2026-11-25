# 02 build panels
Run 2026-11-20 15:53:10 UTC
A: 2928 chain-hours of new senders
B: ETH/USD days 56
C0: LayerZero list: 801635 EVM addresses
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
C2: Base entrants receiving tokens after entry: 0.727; ETH: 0.121
C3: Base entrants funded before entry: 0.982 (top-level 0.518, internal 0.474); internal funding transfers 1681352
D: 8261 chain-days, 24 chains
E: 22 first-action targets (12 contracts); 238 chain-days of fees, rent and profit
F: May chain-hours 1440; entrants arbitrum 2679981, base 1130971; Base burst share pre 0.209, post 0.529; March burst operators 1573; May entrants linked to one 0.0013
F: fee quantiles for 4368 chain-hours
G target x method, base: 182 days; new addresses per day 77662; in waves 0.437 (size-only 0.409); 913 wave group-days
G target x method, arbitrum: 182 days; new addresses per day 120295; in waves 0.310 (size-only 0.536); 734 wave group-days
G target x method, ethereum: 182 days; new addresses per day 156591; in waves 0.194 (size-only 0.236); 1265 wave group-days
G target, base: 182 days; new addresses per day 77662; in waves 0.429 (size-only 0.421); 856 wave group-days
G target, arbitrum: 182 days; new addresses per day 120295; in waves 0.306 (size-only 0.557); 708 wave group-days
G target, ethereum: 182 days; new addresses per day 156591; in waves 0.196 (size-only 0.265); 1285 wave group-days
G: wave volume at 8 size floors, Base and ethereum: 2912 rows
G: first-action groups, Base and ethereum, 2024-01-01..2024-03-19: 68255 group-days
Saved panel.rds (62.0 MB): l2_newsenders, eth_usd_daily, entrants, multichain_daily, campaign_targets, l2_economics_daily, may_hourly, may_entrants, fee_quantiles_hourly, entrant_funding, long_daily, long_waves, long_floor_daily, long_groups, funder_labels, recipient_labels, event_calendar

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
 [1] sandwich_3.1-3      generics_0.1.4      tidyr_1.3.2         dreamerr_1.5.0      lattice_0.23-1      bigmemory_4.6.6     magrittr_2.0.5      timechange_0.4.0    grid_4.6.1          estimability_2.0.0  RColorBrewer_1.1-3  mvtnorm_1.4-2      
[13] rprojroot_2.1.1     Matrix_1.7-6        DBI_1.3.0           Formula_1.2-6       survival_3.8-12     multcomp_1.4-32     gridExtra_2.3.1     purrr_1.2.2         bigmemory.sri_0.1.8 scales_1.4.0        TH.data_1.1-5       stringmagic_1.3.0  
[25] codetools_0.2-20    numDeriv_2016.8-1.1 duckdb_1.5.6        cli_3.6.6           rlang_1.3.0         BMisc_1.4.10        splines_4.6.1       withr_3.0.3         yaml_2.3.12         otel_0.2.0          fastglm_0.1.2       DRDID_1.3.0        
[37] tools_4.6.1         uuid_1.2-2          coda_0.19-4.1       dplyr_1.2.1         did_2.5.1           vctrs_0.7.3         R6_2.6.1            lubridate_1.9.5     zoo_1.9-1           lifecycle_1.0.5     emmeans_2.0.4       MASS_7.3-66        
[49] trust_0.1-9         pkgconfig_2.0.3     pillar_1.11.1       gtable_0.3.6        glue_1.8.1          Rcpp_1.1.2          nanoparquet_0.5.2   tibble_3.3.1        tidyselect_1.2.1    farver_2.1.2        xtable_1.8-8        igraph_2.3.4       
[61] nlme_3.1-171        compiler_4.6.1      S7_0.2.2           
```
