# 06_analysis_users.R: who responds. Entrants = addresses first active on 2024-03-01..27; campaign flags as in 00_setup.R.
#  A  entry and later activity around each drop: local randomization (W = 12/24/72 h), RI, marginal entrants; Base vs Arbitrum DiD
#  B  daily entrant cohorts
#  C  single-entity campaigns (burst rule, with size-only and funder-burst bounds); bot-like entrants as a separate class
#  D  campaign vs genuine entry; decomposition of Base's change in daily txs
#  E  response by the sender's own pre-drop fee level, net of a placebo window pair
source(here::here("code", "00_setup.R"))
new_log("06 users")
load_panel(c("entrants", "sender_window", "base_tx_by_class", "l2_hourly", "eth_usd_daily"))
E <- entrants
acts <- paste0("act_", gsub("-", "_", RETENTION_MONTHS)); E[, months5 := rowSums(.SD), .SDcols = acts]   # months active of the five retention months
say(sprintf("Entrants: %s", paste(E[, .N, by = chain][, sprintf("%s %d", chain, N)], collapse = "; ")))

# ---- A. entry and later activity (entrant-weighted means within W hours of each drop; 1-hour donut) ----
ys <- c(act_2024_04 = "active Apr 2024", act_2024_06 = "active Jun 2024", act_2024_09 = "active Sep 2024", act_2024_12 = "active Dec 2024", act_2025_03 = "active Mar 2025",
        any_later = "any activity in sampled months", months_active = "months active (of 10 sampled)", single_tx_wk1 = "single tx in first week", bot_wk1 = "bot-like (>= 100 txs in week 1)")
H <- E[, c(list(N = .N), lapply(.SD, mean)), by = .(chain, hr), .SDcols = names(ys)][order(chain, hr)]
win <- function(ch, t0, W) H[chain == ch & hr >= t0 - W * 3600 & hr < t0 + W * 3600 & !(hr %in% c(t0 - 3600, t0))][, post := as.integer(hr >= t0)]
stat <- function(d) { s <- d[, c(list(N = mean(N)), lapply(.SD, function(z) weighted.mean(z, N))), by = post, .SDcols = names(ys)][order(post)]
  if (nrow(s) < 2) return(NULL); r0 <- unlist(s[1, names(ys), with = FALSE]); r1 <- unlist(s[2, names(ys), with = FALSE])
  list(diff = c(lN = log(s$N[2]) - log(s$N[1]), r1 - r0), marg = (s$N[2] * r1 - s$N[1] * r0) / (s$N[2] - s$N[1]), before = r0, N0 = s$N[1], N1 = s$N[2]) }
grid <- seq(as.POSIXct("2024-03-01 12:00", tz = "UTC"), as.POSIXct("2024-03-27 12:00", tz = "UTC"), by = 6 * 3600)
RA <- rbindlist(lapply(seq_len(nrow(EVENTS)), function(i) rbindlist(lapply(c(12, 24, 72), function(W) { ch <- EVENTS$chain[i]; t0 <- EVENTS$t0[i]; st <- stat(win(ch, t0, W)); if (is.null(st)) return(NULL)
  cd <- grid[sapply(grid, function(t) all(abs(as.numeric(t - EVENTS$t0, units = "hours")) > W + 24) && t - W * 3600 >= as.POSIXct("2024-03-01", tz = "UTC") && t + W * 3600 <= as.POSIXct("2024-03-28", tz = "UTC"))]
  fk <- do.call(rbind, lapply(cd, function(t) { s <- stat(win(ch, t, W)); if (is.null(s)) NULL else s$diff }))
  ri <- if (is.null(fk) || nrow(fk) < 5) rep(NA, length(st$diff)) else sapply(seq_along(st$diff), function(j) mean(abs(fk[, j]) >= abs(st$diff[j])))
  set.seed(1); d0 <- win(ch, t0, W)
  bs <- replicate(300, { b <- d0[, .SD[sample(.N, replace = TRUE)], by = post]; s <- stat(b); if (is.null(s)) rep(NA, length(ys)) else s$marg })
  tab <- data.table(event = EVENTS$event[i], W = W, entrants_per_hour_before = st$N0, entrants_per_hour_after = st$N1, y = c("log entrants per hour", ys[names(st$diff)[-1]]),
                    before = c(log(st$N0), st$before), jump = st$diff, ri_p = ri, n_fake = if (is.null(fk)) 0L else nrow(fk),
                    marginal = c(NA, st$marg), m_lo = c(NA, apply(bs, 1, quantile, .025, na.rm = TRUE)), m_hi = c(NA, apply(bs, 1, quantile, .975, na.rm = TRUE)))
  say(sprintf("## A. %s, W = %d h each side: entrants/hour %.0f -> %.0f", EVENTS$event[i], W, st$N0, st$N1)); logp(rnd(tab[, !c("event", "W", "entrants_per_hour_before", "entrants_per_hour_after")])); tab }))))
fwrite(RA, res("tables", "entry_retention_local_randomization.csv"))
t0 <- EVENTS$t0[1]; sb <- stat(win("base", t0, 12)); sa <- stat(win("arbitrum", t0, 12)); dd <- sb$diff - sa$diff
cd <- grid[sapply(grid, function(t) all(abs(as.numeric(t - EVENTS$t0, units = "hours")) > 36))]
fk <- do.call(rbind, lapply(cd, function(t) { b <- stat(win("base", t, 12)); a <- stat(win("arbitrum", t, 12)); if (is.null(b) || is.null(a)) NULL else b$diff - a$diff }))
RD2 <- data.table(y = c("log entrants per hour", ys[names(dd)[-1]]), base = sb$diff, arbitrum = sa$diff, did = dd, ri_p = sapply(seq_along(dd), function(j) mean(abs(fk[, j]) >= abs(dd[j]))))
say(sprintf("## A. DiD at Base's drop (W = 12 h): Base change minus Arbitrum change; RI over %d fake times", nrow(fk))); logp(rnd(RD2))
fwrite(RD2, res("tables", "entry_retention_did_base_vs_arbitrum.csv"))

# ---- B. daily cohorts ----
DC <- E[, .(N = .N, single_tx_wk1 = mean(single_tx_wk1), active_apr24 = mean(act_2024_04), active_sep24 = mean(act_2024_09), active_mar25 = mean(act_2025_03), months_active_of5 = mean(months5)),
        by = .(chain, day)][day >= as.IDate("2024-03-04") & day <= as.IDate("2024-03-26")][order(chain, day)]
say("## B. Daily entrant cohorts (UTC entry day)"); logp(rnd(DC)); fwrite(DC, res("tables", "daily_cohorts.csv"))

# ---- C. campaigns on Base ----
X <- E[chain == "base" & !is.na(wave)][, campaign := as.integer(batch == 1 | wave == 1)]
say(sprintf("C. Base entrants %s..%s: %d; in campaign bursts %d; funded by bursting funders %d", ENTRANT_WINDOW[1], ENTRANT_WINDOW[2], nrow(X), sum(X$wave), sum(X$batch)))
conc <- function(v) { t <- sort(table(v[!is.na(v)]), decreasing = TRUE); n <- length(v); c(top1 = if (length(t)) t[[1]] / n else NA, top10 = sum(head(t, 10)) / n) }
WD <- X[, { a1 <- conc(first_to); s1 <- conc(first_sel); f1 <- conc(funder_any)
  .(N = .N, to_top1 = a1[["top1"]], to_top10 = a1[["top10"]], sel_top1 = s1[["top1"]], funder_top1 = f1[["top1"]], funder_top10 = f1[["top10"]], no_funder_seen = mean(is.na(funder_any)),
    campaign = mean(wave), bursting_funder = mean(batch), months_active = mean(months5), months_active_noncampaign = mean(months5[wave == 0]), N_noncampaign = sum(wave == 0)) }, by = day][order(day)]
say("## C. By entry day (Base): concentration of first recipient, method and funder"); logp(rnd(WD))
say("## C. Top first recipient x method and top funders on the largest campaign days")
for (d in as.IDate(c("2024-03-15", "2024-03-16", "2024-03-20"))) { y <- X[day == d]
  logp(y[, .N, by = .(first_to, first_sel)][order(-N)][1:5][, share := round(N / nrow(y), 3)][]); logp(y[!is.na(funder_any), .N, by = funder_any][order(-N)][1:5][, share := round(N / nrow(y), 3)][]) }
pre <- X[day >= as.IDate("2024-03-08") & day <= as.IDate("2024-03-12")]; post <- X[day >= as.IDate("2024-03-14") & day <= as.IDate("2024-03-21")]
vr <- function(lab, sel) data.table(set = lab, pre_per_day = pre[eval(sel), .N] / 5, post_per_day = post[eval(sel), .N] / 8, pre_months = pre[eval(sel), mean(months5)], post_months = post[eval(sel), mean(months5)])
WS <- rbind(vr("all entrants", quote(TRUE)), vr("genuine (main definition: not campaign, not bot-like)", quote(class3 == "genuine")),
            vr("campaign bursts only", quote(wave == 1)), vr("bot-like only (>= 100 txs, week 1)", quote(class3 == "bot")),
            vr("excluding campaign bursts (bots kept)", quote(wave == 0)), vr("excluding campaign bursts and bursting funders", quote(campaign == 0)))
WS[, `:=`(entry_ratio = post_per_day / pre_per_day, months_ratio = post_months / pre_months)]
say(sprintf("Share of post-drop (03-14..21) Base entrants in campaign bursts: %.3f", post[, mean(wave)]))
say("## C. Entry and retention, pre (Mar 8-12) vs post (Mar 14-21), with and without campaign addresses"); logp(rnd(WS))
fwrite(WD, res("tables", "campaigns_by_day_base.csv")); fwrite(WS, res("tables", "campaigns_entry_retention_base.csv"))
# Campaign rule bounds: the main burst rule against a size-only rule and a rule that also requires bursting funders (00_setup.R); bot-like entrants
# are a separate class under every rule. Pre = 03-08..12; post = 03-14 (Base) or 03-15 (Arbitrum) to 03-21.
rules <- c(wave = "main: burst vs own pre-shock level", wave_size = "bound: size only (>= 5,000 a day)", wave_funded = "bound: burst funded by bursting funders")
RB <- rbindlist(lapply(CHAINS, function(ch) rbindlist(lapply(names(rules), function(v) {
  Z <- E[chain == ch & !is.na(wave)][, cls := fcase(bot_wk1 == 1, "bot", get(v) == 1, "campaign", default = "genuine")]
  pre <- Z[day >= ENTRANT_WINDOW[1] & day <= as.IDate("2024-03-12")]; post <- Z[day >= as.IDate(if (ch == "base") "2024-03-14" else "2024-03-15") & day <= ENTRANT_WINDOW[2]]
  per_day <- function(d, k) d[cls == k, .N] / uniqueN(d$day)
  data.table(chain = ch, rule = rules[[v]], campaign_share_pre = pre[, mean(cls == "campaign")], campaign_share_post = post[, mean(cls == "campaign")],
             genuine_entry_ratio = per_day(post, "genuine") / per_day(pre, "genuine"), campaign_entry_ratio = per_day(post, "campaign") / per_day(pre, "campaign"),
             genuine_months_pre = pre[cls == "genuine", mean(months5)], genuine_months_post = post[cls == "genuine", mean(months5)], campaign_months_post = post[cls == "campaign", mean(months5)]) }))))
say("## C. Campaign rule bounds (entry ratios = post / pre entrants per day; months active of the five retention months)"); logp(rnd(RB))
fwrite(RB, res("tables", "campaign_rule_bounds.csv"))

# ---- D. campaign vs genuine entry ----
EW <- E[!is.na(wave)][, grp2 := fcase(class3 == "campaign", "campaign", class3 == "bot", "bot-like (>= 100 txs, week 1)", default = "genuine")]
EW[, grp := fcase(class3 != "genuine", grp2, batch == 1, "genuine: bursting funder", default = "genuine: other")]
say("## D. Entrants by group and chain (03-08..21)"); logp(EW[, .N, by = .(chain, grp)][, share := round(N / sum(N), 3), by = chain][order(chain, grp)])
ev <- copy(EVENTS)[, `:=`(pre0 = as.IDate(c("2024-03-08", "2024-03-10", "2024-03-15")), pre1 = as.IDate(c("2024-03-12", "2024-03-13", "2024-03-18")),
                          post0 = as.IDate(c("2024-03-14", "2024-03-15", "2024-03-20")), post1 = as.IDate(c("2024-03-21", "2024-03-18", "2024-03-21")))]
HF <- l2_hourly[, .(n = sum(n), fee = sum(fee)), by = .(day = as.IDate(hr, tz = "UTC"), chain)]
ev[, dlf := sapply(seq_len(.N), function(i) { h <- HF[chain == ev$chain[i]]; log(h[day >= ev$post0[i] & day <= ev$post1[i], sum(fee) / sum(n)]) - log(h[day >= ev$pre0[i] & day <= ev$pre1[i], sum(fee) / sum(n)]) })]
say("## D. Fee change over the daily windows (log, pooled fee per tx)"); logp(ev[, .(event, pre = paste(pre0, pre1), post = paste(post0, post1), dlf = round(dlf, 3))])
R1 <- rbindlist(lapply(seq_len(nrow(ev)), function(i) { e <- ev[i]; Dd <- rbind(EW[chain == e$chain, .N, by = .(day, g = grp2)], EW[chain == e$chain & class3 == "genuine", .N, by = .(day, g = grp)])
  Dd <- dcast(Dd, day ~ g, value.var = "N", fill = 0); grps <- setdiff(names(Dd), "day"); pre <- Dd[day >= e$pre0 & day <= e$pre1]; post <- Dd[day >= e$post0 & day <= e$post1]
  chg <- function(pr, po) sapply(grps, function(g) log(mean(po[[g]]) + 1) - log(mean(pr[[g]]) + 1)); pt <- chg(pre, post)
  set.seed(1); bs <- replicate(500, chg(pre[sample(.N, replace = TRUE)], post[sample(.N, replace = TRUE)]))
  bd <- bs - matrix(bs[grps == "genuine", ], nrow = length(grps), ncol = 500, byrow = TRUE)
  data.table(event = e$event, grp = grps, pre_per_day = sapply(grps, function(g) mean(pre[[g]])), post_per_day = sapply(grps, function(g) mean(post[[g]])), dlog = pt,
             lo = apply(bs, 1, quantile, .025), hi = apply(bs, 1, quantile, .975), entry_elasticity = pt / e$dlf,
             diff_vs_genuine = pt - pt[grps == "genuine"], diff_lo = apply(bd, 1, quantile, .025), diff_hi = apply(bd, 1, quantile, .975)) }))
say("## D. Daily entrants pre vs post: log change, entry elasticity, difference vs genuine (day bootstrap)"); logp(rnd(R1))
HE <- dcast(EW[, .N, by = .(chain, hr, grp2)], chain + hr ~ grp2, value.var = "N", fill = 0); setnames(HE, "campaign", "camp")
stat2 <- function(ch, t0, W = 24) { d <- HE[chain == ch & hr >= t0 - W * 3600 & hr < t0 + W * 3600 & !(hr %in% c(t0 - 3600, t0))]; if (d[hr >= t0, .N] < 6 || d[hr < t0, .N] < 6) return(c(NA, NA, NA))
  g <- d[hr >= t0, log(mean(genuine) + 1)] - d[hr < t0, log(mean(genuine) + 1)]; cp <- d[hr >= t0, log(mean(camp) + 1)] - d[hr < t0, log(mean(camp) + 1)]; c(g, cp, cp - g) }
grid2 <- seq(as.POSIXct("2024-03-09 12:00", tz = "UTC"), as.POSIXct("2024-03-24 12:00", tz = "UTC"), by = 6 * 3600)
R2 <- rbindlist(lapply(seq_len(nrow(ev)), function(i) { e <- ev[i]; s <- stat2(e$chain, e$t0)
  cd <- grid2[sapply(grid2, function(t) all(abs(as.numeric(t - EVENTS$t0, units = "hours")) > 48))]; fk <- do.call(rbind, lapply(cd, function(t) stat2(e$chain, t))); fk <- fk[stats::complete.cases(fk), , drop = FALSE]
  data.table(event = e$event, genuine_dlog = s[1], campaign_dlog = s[2], diff = s[3], ri_p_genuine = mean(abs(fk[, 1]) >= abs(s[1])), ri_p_campaign = mean(abs(fk[, 2]) >= abs(s[2])),
             ri_p_diff = mean(abs(fk[, 3]) >= abs(s[3])), n_fake = nrow(fk)) }))
say("## D. Hourly entrants, +-24 h: log change genuine vs campaign, RI over fake hours"); logp(rnd(R2))
TD <- dcast(base_tx_by_class[, .(txs = sum(txs)), by = .(period = fifelse(day <= as.IDate("2024-03-12"), "pre", "post"), cls)][, txs_per_day := txs / 7], cls ~ period, value.var = "txs_per_day", fill = 0)
TD[, change := post - pre][, share_of_change := change / sum(change)]; setcolorder(TD, c("cls", "pre", "post"))
say("## D. Base: change in daily txs (03-06..12 vs 03-14..20) by sender class"); logp(rnd(TD, 4))
fwrite(R1, res("tables", "campaign_vs_genuine_daily.csv")); fwrite(R2, res("tables", "campaign_vs_genuine_hourly_ri.csv")); fwrite(TD, res("tables", "tx_decomposition_base.csv"))

# ---- E. response by pre-drop fee level (US$ per tx); changes net of a no-fee-change placebo window pair ----
px <- eth_usd_daily[, .(day, usd = close)]
bins <- c(0, 0.005, 0.01, 0.02, 0.05, 0.10, 0.25, 0.50, Inf); labs <- c("<0.5c", "0.5-1c", "1-2c", "2-5c", "5-10c", "10-25c", "25-50c", ">50c")
ndays <- function(w) as.integer(w$end - w$start) + 1L
chg <- function(ch, pre, post) { w0 <- FEE_WINDOWS[chain == ch & window == pre]; w1 <- FEE_WINDOWS[chain == ch & window == post]
  P <- sender_window[chain == ch & window == pre & n >= 2, .(id, n0 = n, f0 = fee)]
  X <- merge(P, sender_window[chain == ch & window == post, .(id, n1 = n, f1 = fee)], by = "id", all.x = TRUE)[is.na(n1), `:=`(n1 = 0, f1 = 0)]
  X <- X[f0 > 0]   # sponsored senders have no fee level
  X[, `:=`(lvl_usd = f0 / n0 * px[day >= w0$start & day <= w0$end, mean(usd)], dy = log1p(n1 / ndays(w1)) - log1p(n0 / ndays(w0)),
           dlf = fifelse(n1 > 0 & f1 > 0, log(f1 / n1) - log(f0 / n0), NA_real_))]
  X[, bin := cut(lvl_usd, bins, labels = labs, right = FALSE)][] }
summ <- function(X) X[, .(N = .N, dy = mean(dy), se_dy = sd(dy) / sqrt(.N), dlf = mean(dlf, na.rm = TRUE), se_dlf = sd(dlf, na.rm = TRUE) / sqrt(sum(!is.na(dlf))), lvl = median(lvl_usd)), by = bin]
evl <- data.table(name = EVENTS$event, chain = EVENTS$chain, pre = c("pre", "pre1", "post1"), post = c("post", "post1", "post2"))   # windows in FEE_WINDOWS
RL <- rbindlist(lapply(seq_len(nrow(evl)), function(i) { e <- evl[i]; M <- merge(summ(chg(e$chain, e$pre, e$post)), summ(chg(e$chain, "placebo_pre", "placebo_post")), by = "bin", suffixes = c("", "_pl"))
  M[, `:=`(event = e$name, did_y = dy - dy_pl, se_y = sqrt(se_dy^2 + se_dy_pl^2), did_f = dlf - dlf_pl, se_f = sqrt(se_dlf^2 + se_dlf_pl^2))]
  M[, `:=`(elasticity = did_y / did_f, se_el = abs(did_y / did_f) * sqrt((se_y / did_y)^2 + (se_f / did_f)^2))][order(bin)] }))
say("## E. Response by pre-drop fee level; elasticity = did_y / did_f")
logp(RL[, .(event, bin, N, lvl = signif(lvl, 2), did_y = round(did_y, 3), se_y = round(se_y, 3), did_f = round(did_f, 2), elasticity = round(elasticity, 3), se_el = round(se_el, 3))])
Rp <- RL[N >= 500 & is.finite(elasticity) & se_el > 0]
f1 <- feols(elasticity ~ log(lvl), data = Rp, weights = ~ 1 / se_el^2, vcov = "hetero"); f2 <- feols(elasticity ~ log(lvl) | event, data = Rp, weights = ~ 1 / se_el^2, vcov = "hetero")
say("## E. Elasticity on log fee level (cells with N >= 500, inverse-variance weights); slope < 0 = more elastic at higher fees"); logp(etable(f1, f2, se.below = TRUE))
X1 <- chg("arbitrum", "pre1", "post1"); X2 <- chg("arbitrum", "post1", "post2")
WS2 <- merge(X1[, .(id, lvl1 = lvl_usd, dy1 = dy, dlf1 = dlf)], X2[, .(id, lvl2 = lvl_usd, dy2 = dy, dlf2 = dlf)], by = "id")
mr <- summ(chg("arbitrum", "placebo_pre", "placebo_post"))[, weighted.mean(dy, N)]
WS2[, grp := cut(lvl2, c(0, 0.01, 0.02, 0.05, Inf), labels = c("step-2 level <1c", "1-2c", "2-5c", ">=5c"), right = FALSE)]
say(sprintf("## E. Within-sender, Arbitrum (%d senders active before both steps); placebo mean dy %.3f", nrow(WS2), mr))
logp(WS2[, .(N = .N, lvl_step1 = signif(median(lvl1), 2), lvl_step2 = signif(median(lvl2), 2), dy_step1 = round(mean(dy1) - mr, 3), dy_step2 = round(mean(dy2) - mr, 3),
             dlf_step1 = round(mean(dlf1, na.rm = TRUE), 2), dlf_step2 = round(mean(dlf2, na.rm = TRUE), 2)), by = grp][order(grp)])
fwrite(RL[, c(list(event = event, bin = bin, N = N, fee_level_usd = lvl), .SD), .SDcols = c("did_y", "se_y", "did_f", "se_f", "elasticity", "se_el", "dy", "se_dy", "dlf", "se_dlf", "N_pl", "dy_pl", "se_dy_pl", "dlf_pl", "se_dlf_pl")],
       res("tables", "response_by_fee_level.csv"))
# Figure 4: elasticity by the sender's pre-drop fee level (bins with >= 500 senders)
# Confidence intervals beyond +-0.12 are cut at the panel edge and marked with an arrow.
lim <- 0.12
F4 <- RL[N >= 500][, `:=`(label = factor(EVENTS$label[match(event, EVENTS$event)], EVENTS$label), lo = pmax(elasticity - 1.96 * se_el, -lim), hi = pmin(elasticity + 1.96 * se_el, lim))]
g <- ggplot(F4, aes(lvl, elasticity)) + geom_hline(yintercept = 0, colour = COL[["ink2"]], linewidth = 0.3) +
  geom_linerange(aes(ymin = lo, ymax = hi), colour = COL[["main"]], linewidth = 0.6) + geom_point(colour = COL[["main"]], size = 2.2) +
  geom_segment(data = F4[elasticity + 1.96 * se_el > lim], aes(x = lvl, xend = lvl, y = lim - 0.01, yend = lim), colour = COL[["main"]], linewidth = 0.6, arrow = arrow(length = unit(5, "pt"))) +
  facet_wrap(~ label, nrow = 1) + scale_x_log10(labels = scales::dollar, breaks = c(0.03, 0.1, 0.3, 1)) + coord_cartesian(ylim = c(-lim, lim)) +
  labs(x = "Sender's fee per transaction before the drop (US$, log scale; bin median)", y = "Elasticity of the sender's transactions\nwith respect to the fee (95% CI)") + theme_fig()
save_fig(g, "fig4_elasticity_by_fee_level.png", 10, 3.6)
save_log("06_analysis_users")
