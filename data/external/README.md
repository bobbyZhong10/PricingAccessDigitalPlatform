# External inputs that cannot be downloaded by script

## gtrends_daily.csv

Google Trends daily search interest, 2024-02-15 to 2024-04-15, worldwide, all categories, web search (hl = en-US, tz = 0). Google Trends has no keyless API and rate-limits scripted requests, so the series were read in a browser session from trends.google.com (explore and widgetdata/multiline responses) on 2026-10-12. Read by `code/02_build_panels.R` (panel `gtrends_daily`) and used in `code/06_analysis_users.R` (validation V5).

Columns: `request`, `keyword`, `date`, `value` (0-100), `partial`.

- `request = "shared"`: one request with "Base airdrop", "Arbitrum airdrop", "Dencun" and "EIP-4844" on a common 0-100 scale.
- `request = "single"`: one request per term, each on its own scale. "EIP-4844" alone returned no series (volume below Google's threshold).

Google Trends values are sampled and rounded, and low-volume terms are 0 on most days, so a new capture can differ slightly. Source: Google Trends (https://trends.google.com).
