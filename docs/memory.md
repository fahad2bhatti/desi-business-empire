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
2026-11-21: Batch 1 code written (core money/clock, economy config + validator, pure GameEngine commands, unit tests). Not yet verified on the founder's machine.
