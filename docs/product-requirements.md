# Product Requirements Document
Version: 0.1 — proposed baseline, pending founder approval
Product working title: Desi Business Empire

## 1. Vision
A single-player business simulation in which the player progresses from self-employment to ownership, management, and a connected business empire. The setting uses fictional Pakistani/desi neighborhoods, markets, workshops, and industrial areas. Currency is virtual PKR and cannot be withdrawn or exchanged for real money.

## 2. Confirmed direction
The founder requested multiple businesses including cloth, mechanic shops, naan/samosa stalls, vegetable sellers, and rickshaws, with visible progression from small operations to shops, halls, and empires. The founder builds with Flutter/Dart. Existing app code and reusable assets have not been inspected.

## 3. Proposed scope
MVP: one food-business journey: samosa stall -> takeaway shop -> restaurant -> catering and marriage hall. These are proposed progression stages, not a requirement to build every stage before the first playtest. First playable ends at takeaway; public MVP includes the complete food journey. Android and iOS are targets; launch order remains undecided.
Future branches: rickshaw -> fleet -> logistics; vegetables -> shop -> wholesale -> cold storage; roadside mechanic -> workshop -> service chain; cloth stall -> shop -> stitching unit -> textile/export brand.

## 4. Target experience
Short sessions with clear next goals. The player buys stock, serves demand, earns virtual revenue, pays operating costs, upgrades capacity, hires staff, automates operations, and reinvests. Early active play should gradually give way to ownership decisions. No real financial advice or real investment transactions.

## 5. Functional requirements
PR-01 New game and resumable local save.
PR-02 Wallet with atomic virtual-currency transactions.
PR-03 Purchase ingredients and produce/sell samosas; stock and finished goods cannot become negative.
PR-04 Display revenue, ingredient cost, wages, rent, and net profit separately.
PR-05 Upgrade equipment and locations using data-defined costs and unlocks.
PR-06 Hire workers and managers; automation unlocks only at configured milestones.
PR-07 Calculate capped offline profit once per absence; show an itemized claim summary.
PR-08 Provide guided onboarding, settings, audio/haptics toggles, and save recovery.
PR-09 Track objectives and allow player-chosen fictional business names.
PR-10 Later: optional rewarded advertising and store purchases, gated on security and store-policy review.

## 6. Non-goals for MVP
Multiplayer, trading, leaderboards, real payments between players, real-money rewards, generative AI, a full city simulator, mandatory login, and all business branches at launch.

## 7. Economy constraints
Use integer minor currency units. One authoritative transaction service handles all economic mutation. Each upgrade must define cost, prerequisites, effect, and next target. Disallow spending below zero. Offline earnings apply only to eligible automated operations, use an explicit configurable cap, and do not assume infinite ingredients. Offline simulation uses existing stock and production constraints; it never purchases stock automatically in MVP. Draft cap: 4 hours, subject to playtesting. Define and test a recovery path for low cash: a free basic work action that cannot require inventory or payment.

## 8. Success criteria and validation
First playable: at least 4 of 5 observed testers complete the first sale without verbal help; record findings rather than treating the small sample as market validation. Public-release gate: no known critical save-loss, purchase, or wallet bugs. Measure tutorial completion, first upgrade, stage progression, session duration, and return behavior with consent where required. Retention and commercial targets are TBD after an initial baseline; revenue is not guaranteed.

## 9. Monetization proposal
Start playtests without ads. Later evaluate optional rewarded ads and clearly described cosmetic/convenience purchases. No forced ads during core actions in the proposed experience. No paid random rewards. Ads and purchase entitlements must not be assumed to share one definition of 'no ads'. Final pricing, territories, age audience, and ad-removal behavior need approval.

## 10. Open decisions
Final name, art direction, audience age, launch platform, budget, locale set, offline cap, ads/IAP inclusion, backend vendor, and cloud-save timing. Urdu/RTL is a future candidate, not a launch commitment.
