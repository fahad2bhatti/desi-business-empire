# Technical Architecture Document
Status: proposed; framework/vendor versions must be selected and pinned during setup.

## 1. System boundary
Flutter renders the single-player application. A pure Dart simulation owns economic rules. Local storage is the MVP source of truth. An optional later backend handles identity, cloud snapshots, purchase verification, and ad reward verification. No backend is required to play the prototype.

## 2. Proposed stack
Flutter/Dart; Riverpod for dependency injection and state observation; go_router for navigation; Drift/SQLite for structured local persistence; bundled versioned JSON for balance definitions. These are architectural choices to validate in a technical spike, not claims about an existing implementation. Use Flutter widgets for the MVP; evaluate Flame only if later scenes need a continuous game/render loop.

## 3. Module layout
lib/app/ bootstrap, router, theme
lib/core/ ids, time, money, errors
lib/domain/economy/ wallet, ledger, transactions
lib/domain/simulation/ production, sales, staffing, offline simulation
lib/domain/progression/ prerequisites, stage transitions
lib/data/local/ database, migrations, repositories
lib/data/config/ content loader and validation
lib/features/ onboarding, dashboard, business, upgrades, staff, objectives, settings
lib/integrations/ analytics, ads, purchases, cloud (interfaces and later adapters)
assets/config/ versioned economy definitions

## 4. Dependency direction
Presentation -> application use cases -> pure domain. Data adapters implement repository interfaces consumed by use cases. Domain imports neither Flutter nor SDK integrations. UI never edits balances directly.

## 5. Canonical models
GameSave(saveId, schemaVersion, configVersion, revision, createdAt, lastSimulatedAtUtc).
Wallet(saveId, currencyMinor).
BusinessInstance(id, saveId, definitionId, stageId, level, inventory, finishedGoods, workerCount, managerUnlocked).
LedgerEntry(transactionId, saveId, revision, type, deltaMinor, reason, createdAtUtc).
ObjectiveProgress(objectiveId, currentValue, completedAtUtc).
ProcessedReward(rewardId, provider, processedAtUtc).
PurchaseEntitlement(store, productId, transactionId, status, verifiedAtUtc) is separate from consumable wallet credit.
BusinessDefinition includes recipes, batch duration, capacities, demand, wages, rent, upgrade costs, prerequisites, and visual asset IDs. Validate all references at build/test time.

## 6. Economic transaction
Load current revision -> validate command and affordability -> compute new state -> write wallet, business changes, ledger, and incremented revision in one DB transaction -> emit updated view model. Unique transaction IDs prevent accidental duplicate application. This local protection does not prevent a device owner from editing local data.

## 7. Simulation and lifecycle
Use an injected clock. During play, a foreground scheduler asks the simulation to advance to the current time; rendering is not the economic clock. On pause persist a checkpoint. On resume call advanceTo once, using lastSimulatedAtUtc; cap catch-up duration, constrain by inventory/capacity and eligible automation, settle costs and proceeds, persist the new checkpoint and reward atomically. Offline summary acknowledges an already committed settlement; closing/reopening it cannot pay twice. Negative time deltas yield zero and a diagnostic; large forward jumps are capped but not fully cheat-proof.
For long intervals use deterministic batch/event processing, not one iteration per second. Foreground and offline paths use the same rules. Draft cap is four hours.

## 8. Saves and migrations
Auto-save every economic transaction. Store periodic consistent SQLite backup snapshots outside a live DB copy operation; retain the last two known-good versions. Validate schema and invariants on load; recover from backup when possible, otherwise offer an explicit reset. Never silently reset. Test migration from every supported schema fixture. Store UTC timestamps and integer currency. Each save records its config version; incompatible balance changes require a documented migration.

## 9. Optional backend
Vendor TBD: evaluate Firebase or Supabase only when cloud/purchases are scheduled. Future endpoints: snapshot upload/download, store purchase verification, reward verification, account deletion. Authenticated ownership and revision checks apply to snapshots. Cloud conflict policy: never add wallet totals; preserve both versions and request selection where safe. Restore must not replay consumable credits. Cross-device economy consistency requires server authority or a tightly scoped single-writer design before launch.

## 10. Quality gates
Unit tests for wallet, production, costs, staffing, prerequisites, and offline settlement; repository integration tests for rollback and migrations; widget tests for critical states; device lifecycle and interrupted-save tests. Proposed performance targets: first interactive screen under 3 seconds on a named reference midrange device, smooth 60 Hz core UI under normal load, bounded offline simulation. Establish device and benchmark method before enforcing targets.

## 11. Delivery
Separate dev/staging/prod app IDs and service configurations. CI runs formatter, analyzer, domain/repository/widget tests, config validation, dependency checks, and release build smoke tests. Signing credentials remain in protected CI secret storage. Manual approval promotes a signed build; keep rollback packages and content versions.
