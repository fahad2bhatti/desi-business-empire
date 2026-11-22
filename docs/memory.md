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
2026-11-21: Idle v2 pushed by founder (commit 'Idle tycoon v2').
2026-11-21: Goals batch written: 32 goals in config (taps, businesses owned, business levels, total levels, property units, income per second, net worth) with one-time cash rewards; claimedGoals in the save (older v2 saves load with none, no reset); Goals tab with badge for rewards ready; next goal on the Empire tab. Not yet verified.
2026-11-22: Goals batch not yet pushed when the founder asked for the next batch; the next zip includes goals too. Founder did not pick among offered options; Claude chose Lifestyle.
2026-11-22: Lifestyle batch written: 8 vehicles/luxury items (Motorbike to Private Jet), owned once, each a permanent +2% to +12% on all income (+50% total), sell for 60%; Assets tab with Property / Lifestyle sub-tabs; two lifestyle goals. Not yet verified.
2026-11-22: Look v3 batch written. Founder rejected the "yellow / colorful" look; new calm finance look with two themes (dark + light). Key decisions: (1) AppPalette has dark and light variants with all tokens; (2) ThemeMode stored in prefs (default dark), user switches in More → Appearance; (3) Focus rule: one accent-filled element per screen (FocusCard or recommended row); green for income only, red for sell/errors; (4) Transport businesses added (rickshaw, taxi, loader, bus, rent-a-car); (5) Homes (6 tiers, free room → mansion, +0–15%); (6) Lifestyle expanded to 11 items +53%; (7) Goals expanded to 40 (added home and lifestyle goals); (8) Advisor (nextMove, candidateMoves, secondsUntil) drives FocusCard on Empire tab. Files changed: economy.json (v3), economy_config.dart, game_state.dart, game_state_codec.dart, goals.dart, game_engine.dart, advisor.dart (new), theme.dart (fully rewritten), prefs.dart, app.dart, common/widgets.dart (FocusCard + confirmSell), visuals.dart, strings.dart, empire_screen.dart, businesses_screen.dart, property_screen.dart, property/home_list.dart, lifestyle_list.dart, goals_screen.dart, wallet_screen.dart, money_header.dart, tutorial.dart, welcome_screen.dart, offline_summary_sheet.dart, more_screen.dart, game_shell.dart. Not yet verified on device.
2026-11-22: Photos for cars, helicopters, planes and houses added (assets/images, 16:9). Lifestyle items got a `group`; Assets screen split into Home, Property, Cars & Bikes, Helicopters, Planes, Luxury tabs. 10 homes, 27 lifestyle items (+81%). Not yet verified.

2026-11-22: Business photos added: samosa, chai, chaat, rickshaw, taxi, loader (Clion-style pickup), bus, transport (cargo). Business cards now show the photo banner like the Assets tabs. No config or test change. Not yet verified.
2026-11-22: Remaining business photos added: kiryana, mobile, cloth, mechanic, restaurant, hall, factory. All 15 businesses now have photos. Mechanic photo is small source (299x168), upscaled. Not yet verified.
## 2026-11-22 — Luxury split: Jewellery & Art sub-sections
- Added 18 new lifestyle items: 9 jewellery (`pendant`, `goldset`, `longset`, `kundan`, `bridal`, `temple`, `jewellery`, `diamondset`, `emerald`) and 9 art (`popart`, `canvas`, `floral`, `modernart`, `abstract`, `gallery`, `painting`, `oldmasters`, `museum`). Kept the existing ids `jewellery` and `painting` (renamed display name only) so old saves still decode.
- New `group` values `jewellery` and `art` added to `LifestyleDef`/config_validator alongside `road`/`heli`/`plane`/`luxury`; both still validate as `kind: luxury`.
- `LifestyleList` gained an optional `header` list of widgets shown above its items; the Luxury tab passes two `LifestyleCategoryCard`s (Jewellery, Art Collection) as that header. Each card shows owned/total + bonus % and pushes a new page with `LifestyleList(group: ...)` scoped to just that category.
- All 18 new items have photos (uploaded art-gallery / jewellery-set photography), priced by look from Rs 85,000 (pendant) up to Rs 10B (museum wing) / Rs 90M (emerald necklace), bonuses 1-4%.
- Lifestyle totals now 43 items / +106%. Vehicle count unchanged at 23.
- Not yet verified on device (no flutter binary in this sandbox) — Fahad should run `flutter analyze && flutter test` after unzip.

## 2026-11-22 — Watches & Yachts categories
- Watches (6) and Yachts (7) are now Luxury categories alongside Jewellery and Art; the Luxury tab shows four category cards and no loose items. `watch` and `yacht` ids moved into `watches`/`yachts` (Yacht repriced to Rs 150 crore, bonus 2, so the yacht ladder ascends from sailboat Rs 3 crore to gigayacht Rs 20,000 crore).
- The earlier watches/yachts config from Fahad's local copy was overwritten by the luxury.zip patch and was not in git; only its 13 photos survived, so the items were rebuilt from those photos.
- Totals: 54 items / +124%. `LifestyleList.summaryGroups` makes the Luxury tab's bonus line count all four categories.
- Not verified on device yet.

## 2026-11-22 — Bikes tab
- Motorbike moved from `road` to new `bike` group. 10 new bikes added (Kids Electric Bike, Kee-Way Cruiser 200, Royal Hunter 350, Benelly TRK 251, Yamah R-25, Suzki GSX-8T, Suzki GSX-R750, Yamah R-One, Suzki GSX-R1000, Kawasake Ninja H2).
- Assets tabs are now Cars, Bikes, Helicopters, Planes, Luxury (`bikes` tab key added to `PropertyScreen._tabs`).
- Totals: 64 items / +140%, 33 vehicles.
- Not verified on device yet.
