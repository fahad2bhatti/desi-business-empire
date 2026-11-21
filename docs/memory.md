# Project Memory
Last updated: 2026-11-21
Purpose: maintain factual continuity; do not treat proposals as approved requirements or completed work.

## Confirmed from founder
- Founder: Fahad Bhatti, Flutter/Dart app developer, based in Faisalabad.
- Reports having four existing apps; their identities/code/metrics have not been provided.
- Shared Business Empire: RichMan as a reference.
- Wants an original desi business game with cloth, mechanic, naan/samosa, vegetables, rickshaws and many businesses.
- Wants gradual growth from small work/stalls to shops, halls and empires.
- Requested planning documents and architecture.md, rules.md, phases.md, desgin.md, memory.md.

## Proposed, not yet approved
- Working title: Desi Business Empire.
- Single-player offline-first Flutter architecture.
- Food route first: samosa stall -> takeaway -> restaurant -> catering/marriage hall.
- Local SQLite, Riverpod, go_router and versioned JSON content.
- Four-hour offline cap; integer currency; manager-gated automation.
- Optional verified purchases, rewarded ads and later cloud saves.
- Android/iOS targets, but launch order and release scope remain undecided.

## Known limitations
No implementation, device tests, validated demand, market sizing, revenue forecast, final artwork, production balance, legal review, or current platform-policy audit has been completed. Existing apps have not been inspected. These files are a planning baseline, not proof of a working product.

## Next decisions
Approve scope and first route; choose initial platform and age audience; select active/idle pacing; approve visual direction; decide if MVP monetization is necessary; test the economy before expanding.

## Update protocol
After an approved decision, record date, decision, rationale and affected files. After implementation, record ticket and verified test evidence. Keep unresolved questions visible. Never add guessed user facts or invented metrics.

## Decision log
2026-11-21: Initial documentation drafted from conversation. No technical proposal has received explicit founder approval yet.
2026-11-21: Founder approved: hybrid pacing (active early, manager-run idle later); Claude writes the code directly; stack Riverpod + Drift + go_router; Phase 0 deliverables first. Affects: architecture.md, technical-architecture-document.md.
2026-11-21: Economy v0 drafted and checked with a pacing simulation (assets/config/economy_v0.json). Draft values, to be tuned in playtests. Takeaway requires the stall manager; offline costs accrue only while a stage is running.
2026-11-21: Batch 1 verified on founder's machine: flutter analyze clean, 29 tests passed.
2026-11-21: Batch 2 written: advanceTo settlement (wages, rent, staff automation, 4h offline cap, stock-limited, costs stop when a business runs dry, costs never push cash below zero; unpaid remainder forgiven). Per-second deterministic stepping, max 14,400 steps per offline settlement. Not yet verified.
2026-11-21: Batch 2 verified on founder's machine: analyze clean, 39 tests passed. Founder allowed Claude to edit pubspec.yaml (assets/config/ added in batch 3).
2026-11-21: Batch 3 written: Drift save slots (main + 2 rotating backups) and ledger table, JSON save codec with invariant checks, SaveRepository (atomic commit with revision check, explicit reset, backup fallback), GameController (Riverpod AsyncNotifier, serialized commands, 1 s foreground tick, offline settle on launch/resume, save-failure banner), Stall screen and offline summary sheet. Not yet verified.
2026-11-21: Batch 3 verified (after removing fireImmediately): 47 tests passed, build_runner OK.
2026-11-21: Batch 4 written: bottom navigation (Home, Karobar) with StatefulShellRoute, Home (last-hour profit from ledger, next-goal card, business cards with unmet requirements), Upgrades and Staff screens (generic by stageId, before/after preview, needed vs available), ledger pruning (keep 2 days). Not yet verified.
2026-11-21: Batch 4 verified on Pixel 7a (57 tests passed; 4 unnecessary '!' warnings fixed by founder).
2026-11-21: Batch 5 written: generic BusinessScreen (all item lines, shared queue, business switcher chips) replaces StallScreen; ExpansionScreen (what you get, requirement checklist with have/need, confirm dialog before unlock; hall shows 'Jald aa raha hai' until Phase 2); Home cards open business/expansion; next-goal routes to expansion. Not yet verified.
2026-11-21: Batch 5 verified on Pixel 7a (57 tests passed; dart fix applied for curly braces).
2026-11-21: Batch 6 written: Drift schema v2 adds Prefs table (migration from v1), AppPrefs (business name, tutorial step, sound, haptics), welcome screen with player-chosen fictional business name, 4-step tutorial (buy stock, cook, first sale, first helper) that advances from game state and survives restart, Aur tab (wallet/ledger screen, rename, sound/vibration toggles, tutorial replay, privacy note, double-confirm reset). Phase 1 feature-complete pending verification and playtest.
2026-11-21: Founder asked to make the UI look natural (not AI) using flutter-unslop + impeccable, with both light and dark themes, and all UI strings in English in one strings file (Roman Urdu possibly later). Batch 6 was not verified separately before this.
2026-11-21: UI pass written: AppPalette ThemeExtension (light + dark, contrast checked), AppSpacing/AppRadius, theme text roles, tabular numbers, LedgerBlock signature (double rule above totals), all screens rewritten without per-row cards/coloured tiles/placeholders/exclamations, English strings in lib/core/strings.dart, English upgrade/item names in config, theme mode setting (System/Light/Dark). DESIGN.md added. Not yet verified.
2026-11-21: UI pass (light/dark ledger look) was rejected by the founder: too plain, 'like reading a document'; a game needs game UI.
2026-11-21: Founder decision: switch from hybrid (buy stock, cook, sell) to a pure idle tycoon like the reference Business Empire: RichMan. Player buys businesses (thela, shops, companies) that earn on their own, upgrades them, and can sell them; plus property that pays rent. No manual production. Look: dark tycoon. Scope v1: businesses + property. Old saves reset (fresh start).
2026-11-21: Idle economy v2 drafted (assets/config/economy.json): 12 businesses in 3 categories, 6 properties, start Rs 500, Work tap Rs 25, upgrade cost price x 0.5 x 1.15^(level-1), x2 income at levels 25/50/75/100, max level 100, business sells for 50% of spend, property +15% per unit and sells for 70%, offline cap 4 h. Pacing sim: last business after ~66 h non-stop, ~3.5 days for a regular player, ~7 days casual. Not yet verified on device.
