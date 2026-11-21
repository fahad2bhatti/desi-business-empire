# Frontend Specification Document
Status: proposed mobile portrait experience.

## 1. Visual direction
An original illustrated desi market: warm cream surfaces, deep teal primary actions, amber currency accents, terracotta warnings. Avoid copying another game's artwork, characters, icon, text, or exact layouts. Color tokens are proposals: background #FFF8ED, primary #155E63, accent #E6A23C, text #202A32. Check contrast on actual component combinations before approval. Use bundled licensed fonts; English and Roman Urdu copy are candidates. Full Urdu localization/RTL is a separate milestone.

## 2. Information architecture
Bottom navigation: Home, Businesses, Goals, More. Business detail contains Overview, Upgrades, and Staff sections. The top wallet opens an income/cost breakdown; it must not resemble a real bank account or imply cash withdrawal.

## 3. Key screens
Onboarding: fictional-world introduction, starter-business explanation, one guided sale, first upgrade, save confirmation. Include skip/replay support where it does not create duplicate rewards.
Home: wallet, net profit summary for a labeled period, current objective, active business cards, collect/continue action only when valid.
Business detail: illustrated location, inventory, production progress, demand, selling action, costs, and next milestone.
Inventory: ingredient quantity, purchase quantity selector, total price, affordability, purchase confirmation/result.
Upgrades: current level, next effect, full price, prerequisites, buy state.
Staff: role, hiring cost, recurring wages, effect, and manager automation status.
Expansion: stage preview, cost, prerequisites, explicit confirmation.
Offline summary: absence duration, credited duration, inventory limitation, revenue/cost/net breakdown, acknowledge button. Settlement already occurred atomically; acknowledgment never grants funds again.
Goals: objective progress, next suggested action, claimed state if rewards are introduced.
Settings: audio, haptics, language, privacy, support, save status, and destructive reset with explicit confirmation.
Future shop: local store price, virtual-currency disclaimer, purchase state, restore for eligible products, privacy and terms links.

## 4. Reusable components
WalletChip; BusinessCard; ProfitBreakdown; InventoryRow; UpgradeCard; RequirementList; StaffCard; StageProgress; PrimaryButton; ConfirmationSheet; ErrorBanner; OfflineSummarySheet. Widgets consume immutable view models and dispatch commands; no economy calculations inside widgets.

## 5. Interaction and state contracts
Every asynchronous action has idle/loading/success/recoverable-error states. Disable duplicate submissions but retain repository idempotency. Locked upgrades show unmet requirements, not only a disabled button. Insufficient funds shows required and available amounts. Recoverable save errors block further economic mutation until persistence is safe, offer retry/recovery, and never claim success. Empty state explains how to begin. Optional ads/network outages never block the offline core.

## 6. Accessibility and responsive behavior
Proposed minimum touch target: 48 logical pixels. Support semantic labels, screen readers, text scaling, reduced motion, safe areas, and notches. No critical information encoded only by color or sound. Test compact and large phones and long localized text. Format virtual money consistently through one formatter; abbreviations must have an accessible full value. No precision loss from display rounding.

## 7. Animation and assets
Short purchase/upgrade feedback; reduced-motion alternative. Production animation is decorative, never the simulation timer. Stage upgrades visibly change the business illustration. Keep asset licenses and provenance in the repository. Do not ship generated or commissioned assets without documented usage rights.

## 8. Frontend acceptance
User can complete the first sale and first upgrade; app resumes without duplicate settlement; unaffordable actions remain clear; all critical screens have loading/error/empty states; screen reader can identify money and primary actions; no clipping at the agreed text scale and device matrix. Final mockups and asset budget are not yet approved.
