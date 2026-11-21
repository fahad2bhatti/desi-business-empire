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
