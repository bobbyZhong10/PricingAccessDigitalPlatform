# Pricing Access to Digital Platforms: Fee Cuts, Participation, and Inflated Growth on Ethereum Layer-2 Networks

*Research proposal — draft, October 2026. All numbers are preliminary and come from `results/` in this repository; every figure and table is reproduced by `code/01`–`07`.*

## 1. Question

Platforms change the price of access all the time: they cut fees to grow, or start charging to monetize. Zhu, Shi, and Banerjee (2025) show that when Goodreads began charging authors to run Giveaways, participation fell, the exits came mostly from small and independent publishers, and match quality on the demand side declined. Their setting asks who leaves when access becomes more expensive. This project asks the mirror question about the price users face:

> When a platform's per-use price falls sharply, how much does usage respond, through which margin (more activity by existing users, or more participants), and who are the marginal participants?

Blockchain Layer-2 networks ("rollups") offer an unusually clean setting. On 13 March 2024 Ethereum's Dencun upgrade (EIP-4844) introduced cheap "blob" data space. Rollups adopted it at known times and their fees per transaction fell by roughly 85% within an hour. Every transaction and every address is public, so usage, entry, later retention, and the funding of new addresses can all be measured directly.

The mirror is about the price of access, not about who sets it. Goodreads' fee was the platform's own pricing decision. The Dencun fee drops mostly pass through a fall in the rollups' Layer-1 data costs. Only one event, Arbitrum's cut of its minimum fee on 19 March, is a pricing decision by the platform. The analysis therefore estimates how users respond to a lower price of access, and treats the platform-chosen cut as the closest analogue to Zhu et al.'s setting.

## 2. Competing hypotheses

- **H1 (inelastic demand).** Usage rises, but by much less than the fee falls (elasticity well below one in absolute value). This is consistent with Ilk et al. (2021), who find relatively inelastic demand for Bitcoin block space.
- **H2 (participation margin).** The response operates mainly through more participants (new and returning senders) rather than more transactions per existing sender.
- **H3a (noise).** Marginal participants are disproportionately automated or single-entity "campaign" accounts (airdrop farming, wash-style activity). Cheaper access mainly admits low-value activity, which inflates address-based growth metrics (cf. Cong et al. 2023 on wash trading).
- **H3b (niche genuine users).** Marginal participants are small but genuine users who were priced out before. This is the mirror image of Zhu et al. (2025), where the fee pushed out small genuine participants.

H3a and H3b make different predictions about who enters (funding structure, first actions, burstiness) and how long they stay (later retention). Either outcome is informative.

- **H4 (fee level).** Responsiveness does not depend strongly on the absolute fee level.

## 3. Setting and treatment timing

| Event | Time (UTC) | Nature |
|---|---|---|
| Ethereum Dencun fork (EIP-4844) | 2024-03-13 13:55 | Upstream: makes rollup data posting cheap |
| Base, OP-stack Ecotone | 2024-03-14 00:00:01 | Rollup starts using blobs (L1 data fee collapses) |
| Arbitrum, ArbOS 20 "Atlas" | 2024-03-14, fee break in the 15:00 hour | Rollup starts using blobs |
| Arbitrum, minimum L2 base fee 0.1 → 0.01 gwei | 2024-03-19, break in the 07:00–08:00 hour | Platform-chosen price cut (Security Council action initiated 5–6 March with a 13-day delay) |
| Other rollups (Optimism, Mode, Starknet, Scroll, …) | 13 March – 29 April 2024 | Staggered blob adoption |

The first two fee drops are **one upstream shock landing at different hours on different chains**, not independent shocks. The third is a separate parameter, but its governance post describes it as fixing an oversight in the same upgrade. It is the only drop that is a deliberate pricing decision with little publicity.

The window also contains several concurrent events:
- Bitcoin's all-time high on 14 March (≈ $73,750);
- Blast's mainnet launch on 29 February;
- the zkSync airdrop snapshot on 24 March;
- memecoin activity on Base.

Blast and zkSync do not enter the multi-rollup analysis: Blast is not in the growthepie data, and zkSync has no fee series for the period.

## 4. Data

All sources are public and need no keys:

- **AWS Public Blockchain Data (sonarx).** Transaction-level tables for Base and Arbitrum (successful and failed), token transfers, and Ethereum and Bitcoin block data. Queries are aggregated on the fly with DuckDB; only aggregates are stored (≈ 1.9 GB raw).
  - Hourly activity, 15 February – 15 April 2024: transactions, fees, distinct senders, senders first seen since 15 February, and transaction types by 4-byte method selector.
  - Sender × day activity.
  - Entrant cohorts (first-ever activity on 1–27 March), with a lookback to Base's genesis and to March 2023 for Arbitrum.
  - Later activity on days 1–10 of April, June, September, and December 2024 and March 2025.
  - Each entrant's first outgoing transaction and first funder, selected by chain order.
- **growthepie public exports.** Daily transactions, active addresses, and median fee (US$) for 23 Layer-2s, December 2023 – January 2025.
- **Coinbase public candles.** ETH/USD, used to express fees in dollars.

Protocol system transactions are removed: one per block, about 3% of Base and 22% of Arbitrum raw transactions. Daily counts then match growthepie within 0.0–0.9%.

**Table 1. Hourly activity before and after the fee drops** (mean across hours, standard deviation in parentheses)

| Chain | Period | Hours | Transactions per hour | Fee per transaction (US$) | Active senders per hour |
|---|---|---:|---:|---:|---:|
| Base | 7 days before the drop | 168 | 18,109 (10,452) | 0.99 (0.28) | 6,299 (845) |
| Base | 7 days after the drop | 168 | 57,241 (20,028) | 0.26 (0.40) | 19,142 (12,987) |
| Arbitrum | 7 days before step 1 | 168 | 30,555 (8,101) | 0.87 (0.22) | 10,046 (2,598) |
| Arbitrum | Between steps 1 and 2 | 113 | 49,230 (13,277) | 0.13 (0.07) | 12,816 (2,862) |
| Arbitrum | 7 days after step 2 | 168 | 64,475 (14,564) | 0.015 (0.011) | 16,677 (4,405) |

*Notes:* Protocol system transactions are excluded. Fees are converted at the daily ETH/USD close. Senders are counted separately for successful and failed transactions, so a sender with both in the same hour counts twice. Base's mean fee after the drop is pulled up by 20 March, when congestion pushed fees back to about $1 per transaction; the hourly median over that week is $0.12. Source: `results/tables/summary_hourly.csv`.

## 5. Measurement

- **Price:** fee per transaction (ETH and US$).
- **Usage:** transactions, distinct senders, new-or-returning senders (first seen since 15 February; 19% of these on Base and 45% on Arbitrum had been active earlier), failed transactions, transactions by type, and transactions by high-frequency senders (≥ 700 transactions in 15–21 February, defined before any fee change).
- **Entrants and retention:** addresses with no earlier activity on the chain (checked back to Base's genesis; for Arbitrum only back to March 2023, so Arbitrum entrants may include users last active before then), and whether they are active in later sampled months.
- **Who enters.** Every entrant in 8–21 March is placed in one of three classes:
  1. **bot-like:** at least 100 transactions in its first week;
  2. **campaign:** its first action (recipient × method) belongs to a same-day group of at least 1,000 entrants that is at least 3× that group's median daily size over 8–13 March (before any fee drop). This makes the rule relative to each group's own pre-shock level, so actions that recur every day (for example, exchange withdrawals followed by a USDT transfer) are not flagged;
  3. **genuine:** everything else.

  Two alternative rules are reported as bounds:
  - a size-only rule: at least 5,000 entrants a day;
  - a stricter rule: the burst must also be funded mostly by addresses that themselves fund a burst of entrants that day.

  Ties within a block are resolved by chain order, so the classification is reproducible.
- **ERC-4337.** Bundled account-abstraction transactions are negligible in the window: 0.03% and 0.26% of Base transactions on the two sampled days (10 and 16 March), so senders closely track users.

## 6. Empirical strategy

1. **Regression discontinuity in time (main design; Hausman & Rapson 2018).** Hourly data, ±36 hours around each fee drop.
   - Specification: hour-of-day fixed effects, side-specific linear trends, a one-hour donut, and Newey–West standard errors.
   - Inference: randomization inference over placebo event hours at the same clock hour on other days.
   - Market-wide demand: Ethereum L1 and Bitcoin activity enter as covariates, and are tested for a break of their own at each event hour. They are not used as difference-in-differences control groups, because L1 is also affected by Dencun and activity could move from L1 to L2.
2. **Elasticities.** The ratio of the usage discontinuity to the fee discontinuity, i.e. an IV/Wald estimator with the upgrade as the instrument. Fees after the drop are partly demand-determined, because the L2 execution fee responds to congestion; regressing usage on the fee directly would suffer from simultaneity.
3. **Difference-in-differences with a not-yet-treated chain.** Base versus Arbitrum in the hours between Base's drop and Arbitrum's, with an event study by day.
4. **Multi-rollup replication.**
   - Stacked daily difference-in-differences and 2SLS around each rollup's blob adoption, with controls restricted to rollups without a fee drop within 17 days.
   - Staggered difference-in-differences (Callaway & Sant'Anna 2021) with protocol-upgrade dates as cohorts and not-yet-treated rollups as controls.
   - A test of whether the elasticity varies with the pre-drop fee level.
5. **Who enters.** Two designs, reported separately:
   - *Local randomization (causal).* Entrants per hour and their later activity, compared within narrow windows (±12, 24, 72 hours) around each drop, with randomization inference. Outcomes of marginal entrants are recovered from the change in the entrant mix.
   - *Daily before/after comparison (descriptive).* Campaign, bot-like, and genuine entrants per day in 8–12 March vs 14–21 March (Arbitrum: 15–21 March), with a day-block bootstrap, and a decomposition of the change in Base's daily transactions by sender class. These windows span several days and are exposed to concurrent demand shocks, so they describe composition rather than identify effects.
6. **Fee-level heterogeneity at the sender level.** Each sender's change around a drop, net of the same statistic over a placebo window pair with no fee change, grouped by the sender's own pre-drop fee.

**Robustness:**
- a specification grid (12–72 hour windows × mean difference or trends × 0/1/3-hour donut, each with its own randomization inference);
- weekly differencing;
- alternative standard errors;
- Base activity net of campaign wallets;
- a placebo at the L1 fork hour.

## 7. Preliminary results

**Main hourly estimates** (RD in time, ±36 h; randomization-inference p in brackets, from K = 58–59 placebo event hours, so the smallest attainable p is 1/K ≈ 0.02 and "< 0.02" means no placebo was as large):

| | Base | Arbitrum step 1 | Arbitrum step 2 |
|---|---|---|---|
| Log fee per transaction (first stage) | −2.03 [< 0.02] | −1.82 [< 0.02] | −1.88 [< 0.02] |
| Log transactions | 0.79 [< 0.02] | 0.76 [< 0.02] | 0.14 [0.28] |
| … with market controls (L1, Bitcoin) | 0.79 [< 0.02] | 0.75 [< 0.02] | 0.10 [0.45] |
| Log distinct senders | 0.87 [< 0.02] | 0.50 [< 0.02] | 0.19 [0.10] |
| Log new-or-returning senders (first seen since 15 Feb) | 0.82 [0.03] | 0.54 [0.02] | 0.05 [0.79] |
| Elasticity of transactions | −0.39 | −0.42 | −0.07 |
| Placebo: Ethereum L1 transactions | 0.00 [1.00] | −0.02 [0.76] | 0.10 [0.05] |

**Base vs not-yet-treated Arbitrum.**
- Log transactions +1.01 (SE 0.07).
- In the daily event study (day −1 = 0), the first 15 hours after Base's drop show +1.13 for transactions and +0.87 for active senders. Days −7 to −2 range from −0.03 to 0.26: Base drifted slightly down relative to Arbitrum before the drop.

**Robustness.**
- Of 19 specifications per event, the share with a positive estimate and randomization-inference p ≤ 0.10 is 0.89 (Base), 0.89 (Arbitrum step 1), and 0.74 (Arbitrum step 2).
- Weekly-differenced estimates are 1.19, 0.62, and 0.31.
- Net of campaign wallets, Base's estimate is 0.91 to 0.98.

**Multiple rollups.**
- Pooled 2SLS elasticity of daily transactions with respect to the median fee: −0.16 (SE 0.06) with detected dates and −0.20 (SE 0.06) with documented upgrade dates.
- Callaway–Sant'Anna with documented dates: ATT on log fee −3.06 (SE 0.63), on log transactions +0.54 (SE 0.18), implied elasticity −0.18. With documented dates where available and detected dates otherwise, it is −0.11 (transactions ATT +0.28, SE 0.17).
- The level test finds no dependence on the pre-drop fee level: the interaction is −0.005 (SE 0.020) for fees from $0.006 to $0.85.

**Sender-level responses** are small and similar across fee levels: elasticities of −0.01 to −0.06 in every bin with at least 500 senders except one (Arbitrum step 2, 2–5¢: +0.10 with a very wide interval). The aggregate response therefore comes mainly from participation, not from existing senders transacting more (H2).

**Entry around the drop (local randomization, ±24 h).** Entrants per hour rise by 0.75 log points on Base (RI p = 0.06), 0.34 at Arbitrum step 1 (0.03), and 0.28 at step 2 (0.06). Later activity of the marginal entrants is close to that of entrants just before the drop: on Base, 6.2% of marginal entrants are active in September 2024 (95% CI 5.2–7.6%) against 5.3% before. The largest campaign bursts come on 15–16 and 20–21 March, mostly outside this window, which is why the daily comparison below shows a different composition.

**Who enters — descriptive daily comparison (Base, entrants per day in 8–12 vs 14–21 March; not the local-randomization design).**

| | Main rule | Range across the three rules |
|---|---|---|
| Campaign share of entrants: before → after | 9.6% → 75.1% | after: 63–75% |
| Entrants per day, after / before: genuine | 1.76× | 1.76–2.52× |
| Entrants per day, after / before: campaign | 51× | 51–74× |
| Months active of 5 sampled: genuine (before → after) | 0.60 → 0.53 | after: 0.44–0.53 |
| Months active of 5 sampled: campaign (after) | 0.09 | 0.06–0.09 |

- **Campaign vs genuine entry** (same daily comparison). The difference in log daily entry between campaign and genuine entrants is 3.36 (day-bootstrap 95% CI 1.31–5.38).
- **Arbitrum shows no campaign surge.** Under every rule the campaign share stays at 12–18% before and after, and genuine entry rises 1.17–1.33×; these genuine entrants may include users last active before March 2023.
- **Decomposition of Base's daily transactions.** The increase splits into:
  - bot-like entrants: 26%;
  - campaign entrants: 16%;
  - genuine entrants: 14%;
  - incumbents: 16%;
  - returning and earlier entrants: 27%.

**Reading so far.**
- Demand is inelastic (H1).
- The response runs through participation (H2).
- On Base, most measured new addresses come from single-entity campaigns that barely persist (H3a). Genuine entry also roughly doubles. Whether these extra genuine users are lower-value depends on the classification rule: their later activity falls by 12% under the main rule (0.60 → 0.53 months), 15% under the size-only rule, and 27% under the funder-burst rule (0.44). The data cannot yet separate H3b from a mild version of H3a for genuine users.
- On Arbitrum, the response is smaller and not driven by campaigns.
- The platform-chosen price cut (Arbitrum step 2) produces the weakest response.

## 8. Threats and how they are addressed

- **Concurrent demand shocks (Bitcoin's high, memecoins).** Hourly discontinuities with side trends absorb slow-moving demand. Ethereum L1 and Bitcoin show no break at the Base and Arbitrum step-1 hours. Day-level comparisons in the entrant analysis are more exposed and are labeled as such.
- **Anticipation and publicity (exclusion restriction for the elasticity).** Dencun was widely publicized and may attract users, especially airdrop farmers, through a channel other than price.
  - At the L1 fork hour, before either rollup changed its fees, Base's transactions were already above the same hour one week earlier (+0.34, RI p < 1/22 ≈ 0.05: none of 22 placebo days was as large; a one-off burst is excluded). Relative to the previous day the gap is +0.16 and not significant. Arbitrum shows no such pattern.
  - Both the anticipation pattern and the weak response to the quiet step-2 cut are consistent with a publicity channel.
  - The reduced-form "upgrade effect" is the robust object; reading it as a price elasticity needs this caveat.
- **Treatment dates.** Cohorts use protocol-upgrade dates, not fee-series breaks. A late detected date (Arbitrum 18 March instead of 14 March) turns an already-treated chain into a control and attenuates staggered estimates toward zero.
- **Classification choices.** The campaign rule uses only pre-shock baselines and is reported with two bounds. Conclusions are stated only where all three rules agree. Sybil claims are restricted to Base.
- **New vs returning users.** Entrants are checked against history back to Base's genesis and to March 2023 for Arbitrum. The hourly new-or-returning-senders outcome only looks back to 15 February: 19% (Base) and 45% (Arbitrum) of these senders were active earlier. Arbitrum's 2021–22 history is not yet checked.

## 9. Contributions

1. **Platform pricing (economics of IS).** The mirror image of Zhu et al. (2025) on the user side: a cut in the price of use, with three fee drops at hourly resolution plus a staggered multi-platform replication. Two drops are cost pass-through and one is a platform pricing decision, which lets the analysis compare the two. The marginal participants admitted by cheaper access are measured directly, including their later retention.
2. **Blockchain fee markets.** Causal, discontinuity-based estimates of the fee elasticity of rollup usage (≈ −0.4 for a single event; −0.16 to −0.20 across rollups), complementing Ilk et al. (2021) on Bitcoin demand and Basu et al. (2023) on fee-market design. Prior Dencun studies document protocol and blob-market effects (Park et al. 2024; Huang et al. 2024) rather than demand elasticities and who enters.
3. **Measurement and platform integrity.** Address-based growth after a price cut can be dominated by single-entity campaigns, so address counts overstate user growth. This parallels evidence on fabricated activity in crypto markets (Cong et al. 2023) and gives a reproducible, pre-shock-calibrated rule with bounds.

## 10. Next steps

- **Supply side.** Newly deployed contracts, newly issued tokens, and distinct contracts called per hour, to speak to the two-sided-market question in Zhu et al. (2025).
- **Platform profit.** Estimate fee revenue net of Layer-1 data costs (the rollup's margin), not revenue alone. With inelastic demand a fee cut lowers revenue, but Layer-1 data costs fell even more, so the margin can rise.
- **Longer histories.** Rebuild the hourly new-sender measure with full lookback, and extend Arbitrum's history to its 2021 launch.
- **Validation.** Check the campaign classification against public sybil lists, if an official copy with chain coverage can be located.
- **Publicity.** Test the publicity channel directly, for example by comparing announced and unannounced parameter changes across rollups.

## 11. Reproducibility

`PricingAccessDigitalPlatform.Rproj`, then run `code/00`–`07` in order:

| Step | What it does |
|---|---|
| `01` | Downloads public data to `data/raw` (≈ 80 min; not in git) |
| `02` | Builds `data/panel/panel.rds` (in git) |
| `03` | Validates the panel and writes `contract.yaml`; analyses stop unless it passes |
| `04`–`07` | Write tables, figures, and logs to `results/` |

## References

- Basu, S., Easley, D., O'Hara, M., & Sirer, E. G. (2023). StableFees: A predictable fee market for cryptocurrencies. *Management Science*, 69(11), 6508–6524. https://doi.org/10.1287/mnsc.2023.4735
- Callaway, B., & Sant'Anna, P. H. C. (2021). Difference-in-differences with multiple time periods. *Journal of Econometrics*, 225(2), 200–230.
- Cong, L. W., Li, X., Tang, K., & Yang, Y. (2023). Crypto wash trading. *Management Science*, 69(11), 6427–6454. https://doi.org/10.1287/mnsc.2021.02709
- Hausman, C., & Rapson, D. S. (2018). Regression discontinuity in time: Considerations for empirical applications. *Annual Review of Resource Economics*, 10, 533–552. https://doi.org/10.1146/annurev-resource-121517-033306
- Huang, Y., Wang, S., Huang, Y., Tyson, G., Duan, H., & Tang, J. (2024). A first look at Ethereum blob revolution: Market, strategies, and optimality. arXiv:2411.03892.
- Ilk, N., Shang, G., Fan, S., & Zhao, J. L. (2021). Stability of transaction fees in Bitcoin: A supply and demand perspective. *MIS Quarterly*, 45(2). https://doi.org/10.25300/MISQ/2021/15718
- Park, S., Mun, B., Lee, S., Jeong, W., Lee, J., Eom, H., & Jang, H. (2024). Impact of EIP-4844 on Ethereum: Consensus security, Ethereum usage, rollup transaction dynamics, and blob gas fee markets. arXiv:2405.03183.
- Zhu, K., Shi, Q., & Banerjee, S. (2025). Monetizing platforms: An empirical analysis of supply and demand responses to entry costs in two-sided markets. *Management Science*, 72(3), 2380–2397. https://doi.org/10.1287/mnsc.2023.01390
