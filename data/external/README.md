# External inputs that cannot be downloaded by script

## gtrends_daily.csv

Google Trends daily search interest, 2024-02-15 to 2024-04-15, worldwide, all categories, web search (hl = en-US, tz = 0). Google Trends has no keyless API and rate-limits scripted requests, so the series were read in a browser session from trends.google.com (explore and widgetdata/multiline responses) on 2026-10-12. Read by `code/02_build_panels.R` (panel `gtrends_daily`) and used in `code/06_analysis_users.R` (validation V5).

Columns: `request`, `keyword`, `date`, `value` (0-100), `partial`.

- `request = "shared"`: one request with "Base airdrop", "Arbitrum airdrop", "Dencun" and "EIP-4844" on a common 0-100 scale.
- `request = "single"`: one request per term, each on its own scale. "EIP-4844" alone returned no series (volume below Google's threshold).

Google Trends values are sampled and rounded, and low-volume terms are 0 on most days, so a new capture can differ slightly. Source: Google Trends (https://trends.google.com).

## funder_labels.csv

Names of the "service" ETH funders of the window entrants (funders with at least 500 distinct ETH recipients on 2024-02-15..03-07; 02 section C), used to classify where non-burst entrants' first ETH came from (06 section M). Block explorers expose name tags only on their web pages, so the tags were read on 2026-10-15: Base addresses from the basescan.org address pages (page title), Arbitrum addresses from the public label set dawsbot/evm-labels (`data/csv/accounts.csv`, Etherscan tags, MIT license; the Arbitrum tag, else the tag of the same address on Ethereum) or, for addresses also active on Base, from basescan.org. Arbiscan pages could not be read (bot check), so several large Arbitrum funders remain untagged; service funders absent from the file count as untagged.

Columns: `chain`, `address`, `name_tag` (empty if none, or if the only tag is a personal ENS name), `category` (`exchange`: an exchange hot wallet, i.e. a withdrawal; `exchange deposit funder`: gas sent by an exchange to a customer's deposit address; `bridge`: a bridge, relayer or gas-refuel service; `untagged`), `source`.

Explorer tags are maintained by the explorers and can change; a new reading can differ. Sources: BaseScan (https://basescan.org), dawsbot/evm-labels (https://github.com/dawsbot/evm-labels).

## event_calendar.csv

Dated events around the 2024 fee cuts, with a public source for each, used to list confounding events and to drop Base's gas-target steps of 2024-03-26 and 2024-04-01 from one set of placebo windows (06 section N). Columns: `date`, `time_utc` (empty if only the day is known), `event`, `relevance`, `source`. Gas-target dates come from Base's and its lead's posts on X and a news report of the May announcement; the ETF and LayerZero dates from law-firm and news reports. Base-specific demand events (memecoin trading, record fees and deposits, congestion, the Onchain Summer campaign) come from news reports and the campaign's announcements, searched for 2024-03-01..21 and for the windows behind the largest placebo values (2024-06-17..30); a report's date is the day it describes, or its publication day when it describes the past week. A search for a 2024 change in Coinbase's pricing of withdrawals to Base found no source, so no such event is listed.

## recipient_labels.csv

Names of the 50 most common first recipients of Base's non-burst window entrants after the March cut (06 section S2; together 62% of those entrants), read on 2026-10-16. Block-explorer pages and APIs (basescan.org, base.blockscout.com) showed a bot check, so tags come from: basescan.org page titles read on 2026-10-15 for the funder tags above; the public label set dawsbot/evm-labels (`data/csv/accounts.csv`, Etherscan tags; the Base tag, else the tag of the same address on Ethereum, Optimism or Arbitrum); the verified contract name and sources on Sourcify (https://sourcify.dev, chain 8453), for a proxy the verified name of its implementation (EIP-1967 slot or minimal-proxy target); token names and symbols and whether an address holds code, read from Base's public RPC endpoint (https://mainnet.base.org); and method names of the first call from 4byte.directory (https://www.4byte.directory). Addresses no source names are kept as `unidentified`.

Columns: `chain`, `address`, `name_tag`, `category` (`exchange`: an exchange hot wallet; `stablecoin or WETH`; `other token`: a token contract other than those, so the first tx is a transfer or an approval; `dex router`; `dex aggregator`; `trading bot`: a trading-bot router; `bridge`: a bridge, bridge aggregator or cross-chain solver; `nft mint or claim`: an NFT, credential or token drop that the first tx mints or claims; `app`: another application; `unidentified`), `first_call` (the most common first call of these entrants: a plain ETH transfer or the method name), `source`.
