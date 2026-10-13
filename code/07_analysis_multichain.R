# 07_analysis_multichain.R: replication across rollups with growthepie daily data (txs, active addresses, median fee in US$).
#  A  per-event daily DiD (+-14 days) at detected fee drops; controls = chains without a drop nearby; permutation p over placebo dates
#  B  blob adoption (first drop in 2024-03-01..05-15): stacked 2SLS of log txs on log fee; detected and documented dates
#  C  does the elasticity vary with the pre-drop fee level?
#  D  Callaway-Sant'Anna staggered DiD with protocol-upgrade dates
source(here::here("code", "00_setup.R"))
sink(file.path(DIR_LOG, "07_analysis_multichain.md"), split = TRUE)
cat("# 07 multichain\nRun ", format(Sys.time(), usetz = TRUE), "\n", sep = "")
ct <- yaml::read_yaml(CONTRACT_FILE)   # panel.rds must have passed 03_validate_panels.R and be unchanged since
stopifnot(isTRUE(ct$all_valid), unname(tools::md5sum(PANEL_FILE)) == ct$md5)
PNL <- readRDS(PANEL_FILE)
P <- PNL$multichain_daily[chain != "ethereum"][order(chain, date)][, `:=`(lc = log(cost), ly = log(txcount), la = log(daa))]
ALLD <- PNL$multichain_drops   # all drop days; chains with one nearby are not controls
EV <- ALLD[local_max == 1][order(chain, -drop)][, head(.SD, 2), by = chain][order(chain, date)]
cat(sprintf("Panel: %d chain-days, %d chains; %d candidate drop days; %d events (up to two per chain)\n", nrow(P), uniqueN(P$chain), nrow(ALLD), nrow(EV)))
# Window and controls (sections A and B): days d0 - W..d0 + W around a drop of chain c on day d0. Controls are the other chains with no drop day
# within W + 3 days of d0 and with cost data on at least 2W days of the window.
W <- 14

# ---- A. per-event DiD ----
# Chain c with a drop on d0 against its controls, days in the window except d0:
#   y_kd = b * 1[k = c, d > d0] + chain FE + date FE + e_kd,   y = log median fee, log txs, log active addresses; robust SEs
# Needs >= 2W - 4 treated days and >= 3 controls. Elasticity = b(log txs) / b(log fee), likewise for active addresses.
# Permutation p: the log-txs regression at placebo dates (weekly 01-20..12-20, > 21 days from the chain's events); p = share of |b_placebo| >= |b|.
RA <- list()
for (i in seq_len(nrow(EV))) {
  ch <- EV$chain[i]; d0 <- EV$date[i]; own <- EV[chain == ch, date]
  pl <- seq(as.IDate("2024-01-20"), as.IDate("2024-12-20"), by = 7); far <- rep(TRUE, length(pl))
  for (q in seq_along(own)) far <- far & abs(as.integer(pl - own[q])) > 21
  JB <- rbind(data.table(date = d0, y = c("lc", "ly", "la")), data.table(date = pl[far], y = "ly"))   # rows 1-3: the event; then placebo dates
  b <- s <- nc <- rep(NA_real_, nrow(JB))
  for (k in seq_len(nrow(JB))) {
    dk <- JB$date[k]
    ctrl <- setdiff(unique(P$chain), c(ch, ALLD[abs(as.integer(date - dk)) <= W + 3, chain]))
    ctrl <- ctrl[ctrl %in% P[chain %in% ctrl & date >= dk - W & date <= dk + W, .(m = sum(is.finite(lc))), by = chain][m >= 2 * W, chain]]
    d <- P[(chain == ch | chain %in% ctrl) & date >= dk - W & date <= dk + W & date != dk & is.finite(get(JB$y[k]))]
    if (d[chain == ch, .N] < 2 * W - 4 || uniqueN(d[chain != ch, chain]) < 3) { nc[k] <- 0; next }
    f <- feols(as.formula(paste(JB$y[k], "~ treat | chain + date")), data = d[, treat := as.integer(chain == ch & date > dk)], vcov = "hetero")
    b[k] <- coef(f)[["treat"]]; s[k] <- se(f)[["treat"]]; nc[k] <- uniqueN(d$chain) - 1
  }
  fk <- b[-(1:3)]
  RA[[i]] <- data.table(chain = ch, date = d0, drop_log = EV$drop[i], pre_level = EV$pre_level[i], post_level = EV$post_level[i], n_ctrl = nc[1], b_cost = b[1],
                        b_tx = b[2], se_tx = s[2], b_daa = b[3], se_daa = s[3], perm_p_tx = mean(abs(fk) >= abs(b[2]), na.rm = TRUE), n_placebo = sum(!is.na(fk)))
}
RA <- rbindlist(RA)
RA[, `:=`(el_tx = b_tx / b_cost, el_daa = b_daa / b_cost)]
cat("## A. Per-event daily DiD; elasticity = beta / beta_cost\n"); print(RA)
fwrite(RA, file.path(DIR_TAB, "multichain_events.csv"))

# ---- B. blob adoption: stacked DiD and 2SLS ----
nonrollup <- c("celo", "polygon_pos")   # not Ethereum rollups in spring 2024
A <- RA[date >= as.IDate("2024-03-01") & date <= as.IDate("2024-05-15") & !(chain %in% nonrollup)][order(chain, date)][, .SD[1], by = chain][b_cost <= -0.7]
cat(sprintf("B. Blob-adoption events: %d (%s)\n", nrow(A), paste(A$chain, A$date, collapse = "; ")))
# documented dates: Ecotone (Base, Optimism, Mode) 03-14, Starknet v0.13.1 03-13, ArbOS 20 03-14, Scroll Bernoulli 04-29; Linea, Manta, Mantle have none
Adoc <- data.table(chain = c("base", "optimism", "mode", "starknet", "arbitrum", "scroll"), date = as.IDate(c("2024-03-14", "2024-03-14", "2024-03-14", "2024-03-13", "2024-03-14", "2024-04-29")))
Adoc[, pre_level := NA_real_]   # median fee in the 7 days before the documented date
for (i in seq_len(nrow(Adoc))) Adoc[i, pre_level := P[chain == Adoc$chain[i] & date >= Adoc$date[i] - 7 & date < Adoc$date[i], median(cost, na.rm = TRUE)]]
old_chains <- P[date <= as.IDate("2023-12-31") & !is.na(txcount), unique(chain)]
SETS <- list("detected blob-adoption dates" = A, "documented dates, 6 rollups" = Adoc, "detected dates excluding Linea/Manta/Mantle" = A[!(chain %in% c("linea", "manta", "mantle"))],
             level = RA[chain %in% old_chains & b_cost <= -0.7 & !(chain %in% nonrollup)])   # level: every large drop of chains live before 2024 (section C)
# Stacked sample for each event set: for every event e = (chain c, day d0), c and its controls on the window days except d0, with
# tr = 1[chain = c], post = 1[day > d0], lvl = log of c's pre-drop median fee; chain-days without finite log fee and log txs are dropped.
ST <- list()
for (nm in names(SETS)) {
  Ev <- SETS[[nm]]; S <- list()
  for (e in seq_len(nrow(Ev))) {
    ch <- Ev$chain[e]; d0 <- Ev$date[e]
    ctrl <- setdiff(unique(P$chain), c(ch, ALLD[abs(as.integer(date - d0)) <= W + 3, chain]))
    ctrl <- ctrl[ctrl %in% P[chain %in% ctrl & date >= d0 - W & date <= d0 + W, .(m = sum(is.finite(lc))), by = chain][m >= 2 * W, chain]]
    S[[e]] <- P[(chain == ch | chain %in% ctrl) & date >= d0 - W & date <= d0 + W & date != d0][, `:=`(ev = paste(ch, d0), tr = as.integer(chain == ch), post = as.integer(date > d0), lvl = log(Ev$pre_level[e]))]
  }
  ST[[nm]] <- rbindlist(S)[is.finite(lc) & is.finite(ly)]
}
# Stacked reduced forms, event e, chain k, day d; FE event x chain and event x day; SEs clustered by chain:
#   y_ekd = b * tr_ek * post_ed + FE + e_ekd,   y = log fee, log txs, log active addresses
# Stacked 2SLS, same FE and clustering: log txs_ekd (or log active addresses) = eta * log fee_ekd + FE + u_ekd, log fee instrumented by tr x post;
# eta = elasticity; first-stage F = Wald statistic of the instrument.
PB <- list()
for (nm in names(SETS)[1:3]) {
  S <- ST[[nm]]
  rf <- feols(c(lc, ly, la) ~ tr:post | ev^chain + ev^date, data = S[is.finite(la)], cluster = ~ chain)
  iv <- feols(ly ~ 1 | ev^chain + ev^date | lc ~ tr:post, data = S, cluster = ~ chain); iva <- feols(la ~ 1 | ev^chain + ev^date | lc ~ tr:post, data = S[is.finite(la)], cluster = ~ chain)
  cat(sprintf("## B. %s: %d events, %d chains; reduced forms (log cost, log txs, log active addresses) and 2SLS elasticities\n", nm, uniqueN(S$ev), uniqueN(S$chain)))
  print(etable(rf, se.below = TRUE)); print(etable(iv, iva, se.below = TRUE))
  PB[[nm]] <- data.table(set = nm, n_events = uniqueN(S$ev), n_chains = uniqueN(S$chain), term = c("RF log cost", "RF log txs", "RF log DAA", "2SLS elasticity txs", "2SLS elasticity DAA"),
                         est = c(coef(rf[[1]])[[1]], coef(rf[[2]])[[1]], coef(rf[[3]])[[1]], coef(iv)[[1]], coef(iva)[[1]]),
                         se = c(se(rf[[1]])[[1]], se(rf[[2]])[[1]], se(rf[[3]])[[1]], se(iv)[[1]], se(iva)[[1]]),
                         first_stage_F = c(NA, NA, NA, fitstat(iv, "ivwald1")[[1]]$stat, fitstat(iva, "ivwald1")[[1]]$stat))
}
PB <- rbindlist(PB)
# Per event (detected dates), chain and day FE, robust SEs: reduced form log txs_kd = b * tr x post + FE + e_kd, and the 2SLS of log txs on log fee
SA <- ST[["detected blob-adoption dates"]]
per <- list()
for (e in unique(SA$ev)) {
  d <- SA[ev == e]
  f <- try(feols(ly ~ 1 | chain + date | lc ~ tr:post, data = d, vcov = "hetero"), silent = TRUE); ok <- !inherits(f, "try-error")
  fr <- feols(ly ~ tr:post | chain + date, data = d, vcov = "hetero")
  per[[e]] <- data.table(event = e, pre_level = exp(d$lvl[1]), b_tx = coef(fr)[[1]], se_tx = se(fr)[[1]], elasticity = if (ok) coef(f)[[1]] else NA_real_, se_el = if (ok) se(f)[[1]] else NA_real_)
}
per <- rbindlist(per)
cat("## B. Per-event: txs reduced form and 2SLS elasticity\n"); print(per[order(-pre_level)])

# ---- C. level test ----
# Stacked 2SLS over the level set, FE event x chain and event x day, SEs clustered by chain:
#   log txs_ekd = eta0 * log fee_ekd + eta1 * (log fee_ekd x lvl_e x tr_ek) + FE + u_ekd,   instruments tr x post and tr x post x lvl_e
# The elasticity at pre-drop level L is eta0 + eta1 * log(L); eta1 < 0 means more elastic at higher levels.
S2 <- ST$level[, `:=`(lcx = lc * lvl * tr, z = tr * post, zx = tr * post * lvl)]
f_lv <- feols(ly ~ 1 | ev^chain + ev^date | lc + lcx ~ z + zx, data = S2, cluster = ~ chain)
cat(sprintf("## C. Level test, %d drops (pre-drop levels $%.4f to $%.2f); negative interaction = more elastic at higher levels\n",
            uniqueN(S2$ev), min(exp(S2$lvl)), max(exp(S2$lvl)))); print(etable(f_lv, se.below = TRUE))
b <- coef(f_lv); cat(sprintf("Implied elasticity at $0.50: %.3f; at $0.05: %.3f; at $0.01: %.3f\n", b[["fit_lc"]] + b[["fit_lcx"]] * log(0.5), b[["fit_lc"]] + b[["fit_lcx"]] * log(0.05), b[["fit_lc"]] + b[["fit_lcx"]] * log(0.01)))
PB <- rbind(PB, data.table(set = "level test", n_events = uniqueN(S2$ev), n_chains = uniqueN(S2$chain), term = c("log cost", "log cost x log(pre-drop level)"), est = unname(b), se = unname(se(f_lv)), first_stage_F = NA))
fwrite(PB, file.path(DIR_TAB, "multichain_pooled.csv")); fwrite(per[, c(list(chain = sub(" .*", "", event), date = as.IDate(sub(".* ", "", event))), .SD), .SDcols = !"event"], file.path(DIR_TAB, "multichain_blob_events.csv"))
# Figure 3: per-rollup elasticities at blob adoption and the pooled estimate
pool <- PB[set == "detected blob-adoption dates" & term == "2SLS elasticity txs"]
F3 <- rbind(per[, .(lab = sprintf("%s, %s (median fee before: $%.2f)", tools::toTitleCase(sub(" .*", "", event)), format(as.IDate(sub(".* ", "", event)), "%d %b"), pre_level),
                    est = elasticity, se = se_el, pre_level, pooled = FALSE)],
            data.table(lab = sprintf("Pooled, %d rollups", nrow(per)), est = pool$est, se = pool$se, pre_level = 0, pooled = TRUE))
F3[, lab := factor(lab, F3[order(-pooled, pre_level), lab])]   # highest pre-drop fee on top, pooled at the bottom
g <- ggplot(F3, aes(est, lab, colour = pooled)) + geom_vline(xintercept = 0, colour = COL[["ink2"]], linewidth = 0.3) +
  geom_linerange(aes(xmin = est - 1.96 * se, xmax = est + 1.96 * se), linewidth = 0.6) + geom_point(aes(shape = pooled, size = pooled)) +
  scale_colour_manual(values = c(COL[["main"]], COL[["ink"]]), guide = "none") + scale_shape_manual(values = c(16, 18), guide = "none") + scale_size_manual(values = c(2.2, 3.6), guide = "none") +
  labs(x = "Elasticity of daily transactions with respect to the median fee (2SLS, 95% CI)", y = NULL) + THEME_FIG + theme(panel.grid.major.y = element_blank())
ggsave(file.path(DIR_FIG, "fig3_multichain_elasticities.png"), g, width = 8.5, height = 4.2, dpi = 200, bg = "white")

# ---- D. staggered DiD (Callaway and Sant'Anna 2021) ----
# Cohort = documented blob-adoption date (robustness: detected date for rollups without one). Fee-series break dates are not used as cohorts: a late
# detected date (Arbitrum 03-18 vs 03-14) turns an already-treated chain into a not-yet-treated control. Controls = not-yet-treated and never-treated
# rollups with complete data in the window; chains with a fee drop in the window that is not a blob adoption (Celo, Polygon PoS) are dropped.
#   ATT(g, t) = E[y_t - y_{g-1} | cohort g] - E[y_t - y_{g-1} | not yet treated at t]   (outcome regression, universal base period g - 1)
#   ATT = average of the cohort-weighted ATT(g, g + e) over event days e = 0..14 (balanced), matching the stacked window; multiplier-bootstrap SEs
# Elasticity = ATT(log txs) / ATT(log fee). With few rollups per cohort, did warns about small groups and skips the pre-test; those warnings are suppressed.
win <- as.IDate(c("2024-02-20", "2024-05-15"))
Ahyb <- rbind(Adoc[, .(chain, date)], A[!(chain %in% Adoc$chain), .(chain, date)])   # documented dates where available, else detected
ADOPT <- list("documented dates" = Adoc[, .(chain, date)], "documented where available, else detected" = Ahyb)
CS <- list()
for (nm in names(ADOPT)) {
  adopt <- ADOPT[[nm]]
  Pw <- P[date >= win[1] & date <= win[2] & is.finite(lc) & is.finite(ly)]
  Pw <- Pw[chain %in% Pw[, .N, by = chain][N == as.integer(win[2] - win[1]) + 1, chain] & !(chain %in% setdiff(ALLD[date >= win[1] & date <= win[2], chain], adopt$chain))]
  Pw <- merge(Pw, adopt[, .(chain, g_date = date)], by = "chain", all.x = TRUE)
  Pw[, `:=`(id = as.numeric(factor(chain)), t = as.numeric(date - win[1]) + 1, g = fifelse(is.na(g_date), 0, as.numeric(g_date - win[1]) + 1))]   # numeric: did codes never-treated as Inf
  cat(sprintf("D. %s (few rollups per cohort: small-group inference, no pre-test Wald statistic): treated %s; never treated %s\n", nm, paste(Pw[g > 0, unique(chain)], collapse = ", "), paste(Pw[g == 0, unique(chain)], collapse = ", ")))
  r <- list()
  for (y in c("lc", "ly", "la")) {
    set.seed(20240314)
    a <- suppressWarnings(did::att_gt(yname = y, tname = "t", idname = "id", gname = "g", data = as.data.frame(Pw[is.finite(get(y))]), control_group = "notyettreated",
                                      est_method = "reg", base_period = "universal", bstrap = TRUE, cband = FALSE, print_details = FALSE))
    ag <- did::aggte(a, type = "dynamic", min_e = 0, max_e = 14, balance_e = 14, na.rm = TRUE)
    r[[y]] <- data.table(set = nm, outcome = c(lc = "log median fee", ly = "log txs", la = "log active addresses")[[y]], att = ag$overall.att, se = ag$overall.se)
  }
  CS[[nm]] <- rbindlist(r)[, elasticity := att / att[outcome == "log median fee"]]
}
CS <- rbindlist(CS)
cat("## D. Callaway-Sant'Anna ATT over event days 0..14 (not-yet-treated controls) and implied elasticities\n"); print(CS)
fwrite(CS, file.path(DIR_TAB, "multichain_callaway_santanna.csv"))
cat("\n## sessionInfo\n```\n"); print(sessionInfo()); cat("```\n"); sink()
