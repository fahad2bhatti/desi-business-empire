# Design

## Overview
Desi Business Empire is an idle tycoon game. Creative north star: **a night bazaar of glowing shop signs**. Deep navy ground, raised panels, gold money that counts up, green income, and one signal colour per kind of business. The game must feel like a game (headings, icons, colour, movement), not a document.

## Colors
`AppPalette.night` in `lib/app/theme.dart`, read with `context.palette`. Dark only.
- Ground `#0D1117`, surface `#161B24`, raised `#1F2632`.
- Ink `#F3F5F8`, muted `#9AA4B2` (>= 6:1 on surfaces).
- Gold `#F5C451`: cash, prices, upgrade buttons, the Work button. Text on gold `#2B1F00`.
- Income green `#4CD787`: income per second and Buy buttons. Text on green `#00210F`.
- Danger `#FF7A70`: selling and errors.
- Category signals: Street `#FF9447`, Shops `#5AA9FF`, Companies `#B794FF`, Property `#3ED6C4`.

## Typography
System font through the theme `TextTheme`. Money and headings are heavy (700-800); body 400. `displaySmall` 34 for the cash counter, `headlineSmall` 24, `titleLarge` 20, `titleMedium` 16, `bodyMedium` 14, `labelSmall` 11 for navigation. Every number uses tabular figures (`style.numbers`). Money is shown in the South Asian system with `formatShort` (K, lakh, crore, arab, kharab); exact values with `formatRs` where precision matters.

## Layout
4-point spacing via `AppSpacing`. The money header is pinned above every tab. Lists of business or property cards, 12-16 between cards.

## Elevation & Depth
No shadows. Depth from ground, surface and raised steps.

## Shapes
Controls 12, sign tiles 14, cards 18.

## Components
- `MoneyHeader`: empire name, net worth, gold cash counter (animated count-up, off when animations are disabled), green income per second.
- `SignTile`: rounded tile in the category colour with the business or property icon; dimmed when not owned. The signature element.
- Business card: sign tile, name, level, income, next-bonus progress, gold Upgrade (+income shown) and Upgrade max, green Buy with a saving-up bar when locked, Sell in the overflow menu with confirmation.
- Property card: sign tile, area and units owned, rent each and total, Buy and Sell.
- Work button: the big gold tap target with a floating "+Rs 25".
- `StatTile`, `ProgressBar`, `SectionTitle`, `NoticeBanner`.

## Do's and Don'ts
- Do keep every string in `lib/core/strings.dart` (English).
- Do use `context.palette` and theme text styles; no hardcoded colours or sizes in widgets.
- Do use category colour only for that category's signs and tabs.
- Don't copy another game's art, icons or layouts (Business Empire: RichMan is a genre reference only).
- Don't use emoji as icons or glows and gradients as decoration.
