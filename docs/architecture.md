# Architecture Map
This is the concise implementation map. Detailed system behavior lives in technical-architecture-document.md; product scope lives in product-requirements.md.

```text
Flutter screens / immutable view models
                  |
          Application commands
                  |
 Pure Dart economy + progression + simulation
                  |
       Repository interfaces / unit of work
                  |
       SQLite + versioned content loader

Optional later adapters: authentication, verified purchases,
rewarded ads, analytics, cloud snapshots
```

## Decisions
ADR-001: Offline-first, single-player MVP; no mandatory login.
ADR-002: Flutter UI and pure Dart domain; no game engine initially.
ADR-003: SQLite is local authority; all economic writes atomic.
ADR-004: Integer minor-unit money; explicit wallet ledger.
ADR-005: Inject time and randomness; no wall-clock reads in domain.
ADR-006: Offline simulation shares foreground rules and is inventory constrained.
ADR-007: Content definitions are versioned and validated before use.
ADR-008: Paid entitlements require backend verification before release.
ADR-009: No multiplayer/competitive integrity promises for editable offline saves.
ADR-010: Backend vendor and multi-device currency authority remain undecided.

## Required command boundary
buyStock, runSale, buyUpgrade, hireWorker, unlockManager, expandBusiness, advanceTo, resetGame. Each validates preconditions and returns typed success/failure. advanceTo is the only path that settles elapsed time. Reset requires frontend confirmation and uses the same transactional persistence discipline.

## Changes requiring a new ADR
Server-authoritative economy, multiplayer, player trading, cash-out, cross-device consumable spending, new persistence engine, or switching to a scene-based game engine.
