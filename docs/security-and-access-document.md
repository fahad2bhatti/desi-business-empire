# Security and Access Document
Status: proposed threat model and release requirements, not a security audit.

## 1. Assets and boundaries
Protect saves, purchase entitlements, credentials, signing keys, analytics data, backend access, and reward integrity. Boundaries: UI/domain, app/local database, app/third-party SDKs, app/backend, backend/store verification, and developer/CI accounts. Virtual PKR has no cash-out value.

## 2. Offline trust limitation
Offline clients cannot guarantee cheat resistance against their device owner. Checksums detect accidental corruption, not a determined attacker. Obfuscation is not a security boundary. Accept local cheating in the offline prototype; do not add competitive rankings, player trading, or valuable transferable rewards on top of this trust model. Server-authoritative currency is a separate architectural decision.

## 3. Roles
Guest player: own local save only.
Authenticated player (future): own cloud records and deletion request only.
Support (future): minimal account diagnostics; no arbitrary wallet edits by default.
Content operator (future): draft balance content, no production publish permission.
Release administrator: approved deploy/publish access with MFA.
CI service identity: minimum permissions for its environment; no reusable personal administrator token.
Production changes require review and audit logging. Prototype has no in-app admin interface.

## 4. Access controls
Backend derives owner identity from validated authentication context, never a client-supplied owner ID alone. Enforce record ownership on reads/writes/deletes. Default-deny rules and negative tests for other-user access. Separate environments and service accounts. Rate-limit sensitive endpoints and validate input size, schema, product IDs, and enum values.

## 5. Local and transport handling
Persist ordinary progress in SQLite. Store authentication/refresh tokens using platform secure storage, not the save DB or logs. Do not embed private service keys or store-server credentials in the app. Public SDK configuration is not treated as an authorization control. Use HTTPS and platform transport security; do not disable certificate validation. Certificate pinning is not an MVP requirement.

## 6. Purchases and rewarded ads: later release gate
Verify store purchases on a trusted backend before granting durable paid entitlements. Bind verified transaction IDs to the account and use idempotent fulfillment. Handle pending, canceled, restored, refunded, and revoked states explicitly. Consumable purchases and non-consumable restoration require distinct flows. Do not grant new consumables from a repeated restore operation. If offline spending and multi-device consumable purchases are supported, resolve the authority/conflict design first.
For rewarded ads use a provider-supported verification flow when available, unique reward IDs, expiry, and replay prevention. If verification is unavailable or incomplete, document residual risk and do not claim fraud-proof rewards. An unavailable ad must not block basic progression.

## 7. Privacy and audience
Collect no contacts, precise location, microphone, or unrelated permissions. Start with local diagnostics; analytics requires an explicit data inventory, SDK review, retention schedule, consent implementation where applicable, and accurate store disclosures. Proposed operational log retention is 30 days; final policy and SDK retention must be approved. Do not log tokens, receipts, full identifiers, or user-entered names. Decide intended age audience before integrating ads; child-directed distribution needs a separate compliance assessment. This document is not legal advice.

## 8. Threat controls and residual risk
Clock manipulation: injected clock, negative-delta handling, cap; offline bypass remains possible.
Save tampering: validation and recovery; device owner can still edit data.
Duplicate settlement: atomic checkpoint and unique IDs.
Cloud account takeover: MFA for operators, secure tokens, reauthentication for deletion where supported.
Unauthorized cloud reads: ownership policies and adversarial integration tests.
Supply-chain compromise: dependency review, lockfiles, secret scanning, least-privilege CI.
Data loss: atomic transactions, migrations, recovery snapshots, explicit user recovery.

## 9. Incident and release checklist
Disable affected monetization/cloud capability using a preplanned safe mode when available; revoke leaked credentials; preserve redacted evidence; assess notification obligations; patch and document root cause. Before release: test isolation, deletion, token redaction, restore/refund, duplicate rewards, interrupted save, backup recovery, and store privacy declarations. Security owner and escalation contact are TBD.
