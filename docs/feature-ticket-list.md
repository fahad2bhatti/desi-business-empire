# Feature Ticket List
All tickets are initially TODO. Sizes are relative: S/M/L, not calendar estimates. One developer may own multiple roles. Exit gates override estimates.

| ID | Phase | Ticket | Size | Depends on | Acceptance criteria |
|---|---|---|---|---|---|
| F01 | 0 | Approve MVP and audience | S | — | Founder records platform order, starter route, intended audience and non-goals |
| F02 | 0 | Economy spreadsheet/config prototype | M | F01 | Recipe, costs, wages, demand and unlocks produce a complete viable path with a recovery action |
| F03 | 0 | Navigation and visual wireframes | M | F01 | Founder can inspect onboarding, business, upgrade and offline summary flow |
| F04 | 1 | Flutter project and CI | M | F01 | Dev/staging/prod setup; formatting, analysis and tests run in CI |
| F05 | 1 | Content schema and validator | M | F02,F04 | Invalid IDs, negative costs, cycles and missing assets fail validation |
| F06 | 1 | Integer wallet and ledger | M | F04 | Atomic spend/credit; no negative balance; duplicate transaction test passes |
| F07 | 1 | Database and recovery | L | F06 | Atomic save, migration fixture, consistent backup and explicit recovery tests pass |
| F08 | 1 | Production/sales simulation | L | F05,F06 | Stock, capacity, demand and operating costs have deterministic unit tests |
| F09 | 1 | Stall screen and stock purchase | M | F03,F07,F08 | User buys stock and sells first batch; failed persistence does not show false success |
| F10 | 1 | Basic upgrades and takeover stage | M | F09 | Affordability/prerequisites enforced; takeaway transition survives restart |
| F11 | 1 | Guided onboarding | M | F09,F10 | First sale and upgrade achievable; tutorial progress survives restart |
| F12 | 2 | Worker and manager system | M | F08,F10 | Wages and staffing effects applied once; automation requires manager unlock |
| F13 | 2 | Offline settlement | L | F07,F08,F12 | Cap, negative clock, depleted stock, repeated resume, and process-kill tests pass |
| F14 | 2 | Restaurant and hall progression | L | F10,F12 | Entire food route unlockable without debug tools or purchases |
| F15 | 2 | Goals and economy recovery | M | F14 | Next goal visible; free recovery action cannot deadlock or create negative stock |
| F16 | 2 | Settings, accessibility, localization scaffolding | M | F03,F09 | Toggles persist; screen-reader labels, text scaling and reset confirmation tested |
| F17 | 2 | Privacy and telemetry decision | M | F01 | Data inventory and consent decision approved; no undeclared SDK collection |
| F18 | 2 | Playtest and performance pass | L | F11,F13,F14,F15,F16 | Observed tutorial test recorded; named-device benchmark and priority fixes complete |
| F19 | 3 | Store, identity and authority design | L | F17,F18 | Store requirements checked; verification, refunds and cross-device economy policy approved |
| F20 | 3 | Verified purchase integration | L | F19 | Pending, cancel, replay, restore and refund tests; backend idempotency demonstrated |
| F21 | 3 | Optional rewarded ads | M | F17,F19 | Consent, no-fill, dismissal, verified/duplicate reward handling tested |
| F22 | 3 | Monetized release review | M | F20,F21 | Disclosures accurate; no known critical money/save/privacy bugs |
| F23 | 4 | Second business branch | L | F18 | Chosen branch uses common engine plus one distinct mechanic and balance tests |
| F24 | 4 | Optional cloud sync | L | F19 | Ownership isolation, conflicts, restore safety and deletion tests pass |
| F25 | 4 | Connected supply-chain bonuses | L | F23 | Dependencies visible; no circular or duplicate bonus exploits in tests |

## Definition of ready
Approved behavior, screen/state notes, domain rules, dependencies and test cases exist. Missing decisions become explicit blockers, not hidden assumptions.

## Definition of done
Code reviewed; analyzer/tests pass; errors and recovery covered; accessibility checked for changed screens; telemetry/privacy assessed; docs updated; acceptance evidence recorded. Monetization/cloud tickets additionally require security review. No ticket is complete merely because a screen renders.
