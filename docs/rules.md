# Project Rules
Applies to human and AI-assisted contributions. Proposed baseline; maintainers may change it through review.

## Product
1. Ship one coherent food-business journey before adding branches.
2. Currency is fictional; never imply withdrawable earnings.
3. Use original branding and legally usable assets; no competitor asset copying.
4. Separate founder-approved scope from suggestions and experiments.

## Engineering
5. UI dispatches commands; it does not mutate money or inventory.
6. Domain remains pure Dart and uses injected time/randomness.
7. Money uses integer minor units. All economy mutations use atomic transactions.
8. Repeated commands/rewards must not accidentally duplicate credits.
9. Never simulate offline time once in a lifecycle handler and again in a claim button.
10. No new dependency without purpose, maintenance/license review, and a locked version.
11. Never silently wipe an incompatible/corrupt save; provide explicit recovery/reset.
12. Include migration and rollback/recovery considerations with schema changes.

## Security and privacy
13. No secrets, tokens, purchase receipts or personal data in source control or logs.
14. Never trust client claims for paid entitlements or backend ownership.
15. Offline anti-cheat limitations must remain documented.
16. New analytics/ads SDKs require privacy and audience review before initialization.
17. No competitive or transferable-value features without revisiting economy authority.

## Delivery
18. Every ticket needs acceptance evidence and tests appropriate to its risk.
19. Keep architecture, design, phases, and memory aligned with approved changes.
20. Do not mark proposals as implemented or tests as passing unless verified.
21. PRs should identify scope, tests performed, unresolved risks and save compatibility.
22. CI must pass before merge; signed production release requires manual approval.
