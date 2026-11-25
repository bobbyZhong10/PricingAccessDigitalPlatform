# 03 validate panels
Run 2026-11-20 16:05:09 UTC
  [ok] panel.rds holds the 17 expected tables
## l2_newsenders
  [ok] required columns present
  [ok] unique on (chain hr), 2928 rows
  [ok] new_senders non-negative
## eth_usd_daily
  [ok] required columns present
  [ok] unique on (day), 56 rows
  [ok] close non-negative
  [ok] every day 2024-02-15..04-09
## entrants
  [ok] required columns present
  [ok] months_active non-negative
  [ok] n_week1 non-negative
  [ok] csize200 non-negative
  [ok] csize500 non-negative
  [ok] csize2000 non-negative
  [ok] csizeF500 non-negative
  [ok] entry day in 03-01..27 and consistent with entry hour
  [ok] campaign flags are 0/1 and classes bot/campaign/genuine inside the entrant window
  [ok] validation flags are 0/1, defined for every window entrant, and component sizes >= 1
  [ok] component sizes shrink weakly as the service threshold falls (fewer links)
## multichain_daily
  [ok] required columns present
  [ok] unique on (chain date), 8261 rows
  [ok] txcount non-negative
  [ok] daa non-negative
  [ok] cost non-negative
## campaign_targets
  [ok] required columns present
  [ok] unique on (addr), 22 rows
  [ok] n_logs non-negative
  [ok] n_721 non-negative
  [ok] n_20 non-negative
## l2_economics_daily
  [ok] required columns present
  [ok] unique on (chain date), 238 rows
  [ok] fees_usd non-negative
  [ok] rent_usd non-negative
## may_hourly
  [ok] required columns present
  [ok] unique on (chain hr), 1440 rows
  [ok] n non-negative
  [ok] n_failed non-negative
  [ok] fee non-negative
  [ok] n_senders non-negative
  [ok] new_senders non-negative
  [ok] every UTC hour 2024-05-14..2024-06-12 present for both chains
## may_entrants
  [ok] required columns present
  [ok] n_week1 non-negative
  [ok] months4 non-negative
  [ok] csize500 non-negative
  [ok] both chains; entry day in MAY_WINDOW, classes bot/campaign/genuine, Base link flags 0/1
## fee_quantiles_hourly
  [ok] required columns present
  [ok] unique on (chain hr), 4368 rows
  [ok] n_paid non-negative
  [ok] p25 non-negative
  [ok] p50 non-negative
  [ok] p75 non-negative
  [ok] every UTC hour of the March and May pulls present for both chains
  [ok] 0 < p25 <= p50 <= p75
  [ok] growthepie median fee within a factor of 2 on >= 90% of chain-days: 100% of 172 (median ratio 0.97)
  [ok] median fee, Base (Ecotone): break at 03-14 00:00 UTC (documented 03-14 00:00), fall -5.81
  [ok] median fee, Arbitrum step 1: break at 03-14 15:00 UTC (documented 03-14 15:00), fall -2.17
  [ok] median fee, Arbitrum step 2: break at 03-19 08:00 UTC (documented 03-19 08:00), fall -1.71
  [ok] median fee, Base gas limit 60M to 75M: break at 05-28 20:00 UTC (documented 05-28 19:00), fall -1.67
  [ok] median fee, Base gas limit 75M to 90M: break at 05-30 18:00 UTC (documented 05-30 20:00), fall -1.46
## entrant_funding
  [ok] required columns present
  [ok] unique on (period class3 grp via), 62 rows
  [ok] n non-negative
  [ok] funded non-negative
  [ok] eth_sum non-negative
  [ok] eth_unswept non-negative
  [ok] fee_int_sum non-negative
  [ok] n_top_sum non-negative
  [ok] n_int_sum non-negative
  [ok] swept non-negative
  [ok] initiators non-negative
  [ok] top_level_funders non-negative
  [ok] shares in 0..1; quantiles ordered; both periods present
## long_daily
  [ok] required columns present
  [ok] unique on (grouping chain day), 1092 rows
  [ok] senders non-negative
  [ok] new non-negative
  [ok] heavy non-negative
  [ok] wave_new non-negative
  [ok] wave_heavy non-negative
  [ok] waves non-negative
  [ok] largest_wave non-negative
  [ok] size_new non-negative
  [ok] every day 2024-01-01..2024-06-30 for each grouping and chain (Layer-2s in both groupings; the comparison chain by recipient, and by recipient x method if LONG_CONTROL_SELECTOR); waves <= new addresses <= senders
  [ok] new addresses >= May window entrants on every chain-day (ratio 1.013-1.093 over 30 chain-days)
## long_waves
  [ok] required columns present
  [ok] unique on (grouping chain day first_to first_sel), 5761 rows
  [ok] n non-negative
  [ok] n_heavy non-negative
  [ok] base non-negative
  [ok] waves meet the rule: n >= SPIKE_MIN and n >= SPIKE_K x trailing median
## long_floor_daily
  [ok] required columns present
  [ok] unique on (floor chain day), 2912 rows
  [ok] wave_new non-negative
  [ok] wave_heavy non-negative
  [ok] every floor x chain covers LONG_FROM..LONG_END; the SPIKE_MIN floor reproduces long_daily; heavy <= wave addresses
## long_groups
  [ok] required columns present
  [ok] unique on (chain day first_to first_sel), 68255 rows
  [ok] n non-negative
  [ok] types (chain, first_to, first_sel character; day IDate; n numeric); chains base and ethereum; every day 2024-01-01..2024-03-19 and no other; n >= 1
## funder_labels
  [ok] required columns present
  [ok] unique on (chain address), 64 rows
  [ok] known categories; every labelled address is a service funder of window entrants on that chain
## recipient_labels
  [ok] required columns present
  [ok] unique on (chain address), 50 rows
  [ok] known categories; every labelled address is a first recipient of Base non-burst window entrants
## event_calendar
  [ok] required columns present
  [ok] unique on (date event), 19 rows
  [ok] dates in 2024-03..06, every event has a source, the cut times match EVENTS and EVENTS_MAY
Contract written: 17 objects, 0 with failed checks

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
