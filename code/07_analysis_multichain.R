# 07_analysis_multichain.R: replication across rollups with growthepie daily data (txs, active addresses, median fee in US$).
#  A  per-event daily DiD (+-14 days) at detected fee drops; controls = chains without a drop nearby; permutation p over placebo dates
#  B  blob adoption (first drop in 2024-03-01..05-15): stacked 2SLS of log txs on log fee; detected and documented dates
#  C  does the elasticity vary with the pre-drop fee level?
#  D  Callaway-Sant'Anna staggered DiD with protocol-upgrade dates
source(here::here("code", "00_setup.R"))
new_log("07 multichain")
load_panel(c("multichain_daily", "multichain_drops"))
P <- multichain_daily[chain != "ethereum"][order(chain, date)][, `:=`(lc = log(cost), ly = log(txcount), la = log(daa))]
ALLD <- multichain_drops   # all drop days; chains with one nearby are not controls
EV <- ALLD[local_max == 1][order(chain, -drop)][, head(.SD, 2), by = chain][order(chain, date)]
say(sprintf("Panel: %d chain-days, %d chains; %d candidate drop days; %d events (up to two per chain)", nrow(P), uniqueN(P$chain), nrow(ALLD), nrow(EV)))
controls <- function(ch, d0, W) { ctrl <- setdiff(unique(P$chain), c(ch, ALLD[abs(as.integer(date - d0)) <= W + 3, chain]))
  ctrl[sapply(ctrl, function(cc) P[chain == cc & date >= d0 - W & date <= d0 + W, sum(is.finite(lc))] >= 2 * W)] }   # controls need cost data

# ---- A. per-event DiD ----
est <- function(ch, d0, y, W = 14) { ctrl <- controls(ch, d0, W); d <- P[(chain == ch | chain %in% ctrl) & date >= d0 - W & date <= d0 + W & date != d0 & is.finite(get(y))]
  if (d[chain == ch, .N] < 2 * W - 4 || uniqueN(d[chain != ch, chain]) < 3) return(c(NA, NA, 0))
  f <- feols(as.formula(paste(y, "~ treat | chain + date")), data = d[, treat := as.integer(chain == ch & date > d0)], vcov = "hetero"); c(coef(f)[["treat"]], se(f)[["treat"]], uniqueN(d$chain) - 1) }
RA <- rbindlist(lapply(seq_len(nrow(EV)), function(i) { ch <- EV$chain[i]; d0 <- EV$date[i]; out <- lapply(c("lc", "ly", "la"), function(y) est(ch, d0, y))
  pl <- seq(as.IDate("2024-01-20"), as.IDate("2024-12-20"), by = 7); pl <- pl[sapply(pl, function(t) all(abs(as.integer(t - EV[chain == ch, date])) > 21))]
  fk <- sapply(pl, function(t) est(ch, t, "ly")[1])
  data.table(chain = ch, date = d0, drop_log = EV$drop[i], pre_level = EV$pre_level[i], post_level = EV$post_level[i], n_ctrl = out[[1]][3], b_cost = out[[1]][1],
             b_tx = out[[2]][1], se_tx = out[[2]][2], b_daa = out[[3]][1], se_daa = out[[3]][2], perm_p_tx = mean(abs(fk) >= abs(out[[2]][1]), na.rm = TRUE), n_placebo = sum(!is.na(fk))) }))
RA[, `:=`(el_tx = b_tx / b_cost, el_daa = b_daa / b_cost)]
say("## A. Per-event daily DiD; elasticity = beta / beta_cost"); logp(rnd(RA))
fwrite(RA, res("tables", "multichain_events.csv"))

# ---- B. blob adoption: stacked 2SLS (FE event x chain and event x date; SEs clustered by chain) ----
nonrollup <- c("celo", "polygon_pos")   # not Ethereum rollups in spring 2024
A <- RA[date >= as.IDate("2024-03-01") & date <= as.IDate("2024-05-15") & !(chain %in% nonrollup)][order(chain, date)][, .SD[1], by = chain][b_cost <= -0.7]
say(sprintf("B. Blob-adoption events: %d (%s)", nrow(A), paste(A$chain, A$date, collapse = "; ")))
# documented dates: Ecotone (Base, Optimism, Mode) 03-14, Starknet v0.13.1 03-13, ArbOS 20 03-14, Scroll Bernoulli 04-29; Linea, Manta, Mantle have none
Adoc <- data.table(chain = c("base", "optimism", "mode", "starknet", "arbitrum", "scroll"), date = as.IDate(c("2024-03-14", "2024-03-14", "2024-03-14", "2024-03-13", "2024-03-14", "2024-04-29")))
Adoc[, pre_level := sapply(seq_len(.N), function(i) P[chain == Adoc$chain[i] & date >= Adoc$date[i] - 7 & date < Adoc$date[i], median(cost, na.rm = TRUE)])]
stack <- function(E, W = 14) rbindlist(lapply(seq_len(nrow(E)), function(i) { ch <- E$chain[i]; d0 <- E$date[i]
  P[(chain == ch | chain %in% controls(ch, d0, W)) & date >= d0 - W & date <= d0 + W & date != d0][, `:=`(ev = paste(ch, d0), tr = as.integer(chain == ch), post = as.integer(date > d0), lvl = log(E$pre_level[i]))][] }))[is.finite(lc) & is.finite(ly)]
pooled <- function(S, set) { rf <- feols(c(lc, ly, la) ~ tr:post | ev^chain + ev^date, data = S[is.finite(la)], cluster = ~ chain)
  iv <- feols(ly ~ 1 | ev^chain + ev^date | lc ~ tr:post, data = S, cluster = ~ chain); iva <- feols(la ~ 1 | ev^chain + ev^date | lc ~ tr:post, data = S[is.finite(la)], cluster = ~ chain)
  say(sprintf("## B. %s: %d events, %d chains; reduced forms (log cost, log txs, log active addresses) and 2SLS elasticities", set, uniqueN(S$ev), uniqueN(S$chain)))
  logp(etable(rf, se.below = TRUE)); logp(etable(iv, iva, se.below = TRUE))
  data.table(set = set, n_events = uniqueN(S$ev), n_chains = uniqueN(S$chain), term = c("RF log cost", "RF log txs", "RF log DAA", "2SLS elasticity txs", "2SLS elasticity DAA"),
             est = c(sapply(rf, function(m) coef(m)[[1]]), coef(iv)[[1]], coef(iva)[[1]]), se = c(sapply(rf, function(m) se(m)[[1]]), se(iv)[[1]], se(iva)[[1]]),
             first_stage_F = c(NA, NA, NA, fitstat(iv, "ivwald1")[[1]]$stat, fitstat(iva, "ivwald1")[[1]]$stat)) }
SA <- stack(A)
PB <- rbind(pooled(SA, "detected blob-adoption dates"), pooled(stack(Adoc), "documented dates, 6 rollups"), pooled(stack(A[!(chain %in% c("linea", "manta", "mantle"))]), "detected dates excluding Linea/Manta/Mantle"))
per <- rbindlist(lapply(unique(SA$ev), function(e) { d <- SA[ev == e]; f <- tryCatch(feols(ly ~ 1 | chain + date | lc ~ tr:post, data = d, vcov = "hetero"), error = function(z) NULL)
  fr <- feols(ly ~ tr:post | chain + date, data = d, vcov = "hetero"); data.table(event = e, pre_level = exp(d$lvl[1]), b_tx = coef(fr)[[1]], se_tx = se(fr)[[1]],
    elasticity = if (is.null(f)) NA_real_ else coef(f)[[1]], se_el = if (is.null(f)) NA_real_ else se(f)[[1]]) }))
say("## B. Per-event: txs reduced form and 2SLS elasticity"); logp(rnd(per[order(-pre_level)]))

# ---- C. level test: log fee x log(pre-drop level), instrumented by treat x post x log(level) ----
old <- P[date <= as.IDate("2023-12-31") & !is.na(txcount), unique(chain)]
B <- RA[chain %in% old & b_cost <= -0.7 & !(chain %in% nonrollup)]
S2 <- stack(B)[, `:=`(lcx = lc * lvl * tr, z = tr * post, zx = tr * post * lvl)]
f_lv <- feols(ly ~ 1 | ev^chain + ev^date | lc + lcx ~ z + zx, data = S2, cluster = ~ chain)
say(sprintf("## C. Level test, %d drops (pre-drop levels $%.4f to $%.2f); negative interaction = more elastic at higher levels",
            uniqueN(S2$ev), min(exp(S2$lvl)), max(exp(S2$lvl)))); logp(etable(f_lv, se.below = TRUE))
b <- coef(f_lv); say(sprintf("Implied elasticity at $0.50: %.3f; at $0.05: %.3f; at $0.01: %.3f", b[["fit_lc"]] + b[["fit_lcx"]] * log(0.5), b[["fit_lc"]] + b[["fit_lcx"]] * log(0.05), b[["fit_lc"]] + b[["fit_lcx"]] * log(0.01)))
PB <- rbind(PB, data.table(set = "level test", n_events = uniqueN(S2$ev), n_chains = uniqueN(S2$chain), term = c("log cost", "log cost x log(pre-drop level)"), est = unname(b), se = unname(se(f_lv)), first_stage_F = NA))
fwrite(PB, res("tables", "multichain_pooled.csv")); fwrite(per[, c(list(chain = sub(" .*", "", event), date = as.IDate(sub(".* ", "", event))), .SD), .SDcols = !"event"], res("tables", "multichain_blob_events.csv"))
# Figure 3: per-rollup elasticities at blob adoption and the pooled estimate
pool <- PB[set == "detected blob-adoption dates" & term == "2SLS elasticity txs"]
F3 <- rbind(per[, .(lab = sprintf("%s, %s (median fee before: $%.2f)", tools::toTitleCase(sub(" .*", "", event)), format(as.IDate(sub(".* ", "", event)), "%d %b"), pre_level),
                    est = elasticity, se = se_el, pre_level, pooled = FALSE)],
            data.table(lab = sprintf("Pooled, %d rollups", nrow(per)), est = pool$est, se = pool$se, pre_level = 0, pooled = TRUE))
F3[, lab := factor(lab, F3[order(-pooled, pre_level), lab])]   # highest pre-drop fee on top, pooled at the bottom
g <- ggplot(F3, aes(est, lab, colour = pooled)) + geom_vline(xintercept = 0, colour = COL[["ink2"]], linewidth = 0.3) +
  geom_linerange(aes(xmin = est - 1.96 * se, xmax = est + 1.96 * se), linewidth = 0.6) + geom_point(aes(shape = pooled, size = pooled)) +
  scale_colour_manual(values = c(COL[["main"]], COL[["ink"]]), guide = "none") + scale_shape_manual(values = c(16, 18), guide = "none") + scale_size_manual(values = c(2.2, 3.6), guide = "none") +
  labs(x = "Elasticity of daily transactions with respect to the median fee (2SLS, 95% CI)", y = NULL) + theme_fig() + theme(panel.grid.major.y = element_blank())
save_fig(g, "fig3_multichain_elasticities.png", 8.5, 4.2)

# ---- D. staggered DiD (Callaway and Sant'Anna 2021) ----
# Cohort = documented blob-adoption date (robustness: detected date for rollups without one). Fee-series break dates are not used as cohorts: a late
# detected date (Arbitrum 03-18 vs 03-14) turns an already-treated chain into a not-yet-treated control. Controls = not-yet-treated and never-treated
# rollups with complete data in the window; chains with a fee drop in the window that is not a blob adoption (Celo, Polygon PoS) are dropped.
# ATTs are averaged over event days 0..14 (balanced), matching the stacked window; elasticity = ATT(log txs) / ATT(log fee).
win <- as.IDate(c("2024-02-20", "2024-05-15"))
cs_run <- function(adopt, set) {
  Pw <- P[date >= win[1] & date <= win[2] & is.finite(lc) & is.finite(ly)]
  Pw <- Pw[chain %in% Pw[, .N, by = chain][N == as.integer(win[2] - win[1]) + 1, chain] & !(chain %in% setdiff(ALLD[date >= win[1] & date <= win[2], chain], adopt$chain))]
  Pw <- merge(Pw, adopt[, .(chain, g_date = date)], by = "chain", all.x = TRUE)
  Pw[, `:=`(id = as.numeric(factor(chain)), t = as.numeric(date - win[1]) + 1, g = fifelse(is.na(g_date), 0, as.numeric(g_date - win[1]) + 1))]   # numeric: did codes never-treated as Inf
  say(sprintf("D. %s (few rollups per cohort: small-group inference, no pre-test Wald statistic): treated %s; never treated %s", set, paste(Pw[g > 0, unique(chain)], collapse = ", "), paste(Pw[g == 0, unique(chain)], collapse = ", ")))
  r <- rbindlist(lapply(c("lc", "ly", "la"), function(y) { set.seed(20240314)
    a <- withCallingHandlers(did::att_gt(yname = y, tname = "t", idname = "id", gname = "g", data = as.data.frame(Pw[is.finite(get(y))]), control_group = "notyettreated",
                     est_method = "reg", base_period = "universal", bstrap = TRUE, cband = FALSE, print_details = FALSE),
      warning = function(w) if (grepl("small groups|pre-test Wald|missing data", conditionMessage(w))) invokeRestart("muffleWarning"))   # expected with few rollups per cohort
    ag <- did::aggte(a, type = "dynamic", min_e = 0, max_e = 14, balance_e = 14, na.rm = TRUE)
    data.table(set = set, outcome = c(lc = "log median fee", ly = "log txs", la = "log active addresses")[[y]], att = ag$overall.att, se = ag$overall.se) }))
  r[, elasticity := att / att[outcome == "log median fee"]][] }
Ahyb <- rbind(Adoc[, .(chain, date)], A[!(chain %in% Adoc$chain), .(chain, date)])   # documented dates where available, else detected
CS <- rbind(cs_run(Adoc[, .(chain, date)], "documented dates"), cs_run(Ahyb, "documented where available, else detected"))
say("## D. Callaway-Sant'Anna ATT over event days 0..14 (not-yet-treated controls) and implied elasticities"); logp(rnd(CS))
fwrite(CS, res("tables", "multichain_callaway_santanna.csv"))
save_log("07_analysis_multichain")
