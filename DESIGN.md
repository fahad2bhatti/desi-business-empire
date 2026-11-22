# Design

## Overview
Desi Business Empire is an idle tycoon game. Creative north star: **calm finance app meets desi bazaar**. Two themes (dark default, light optional). One clear focal element per screen holds the player's attention. Everything else recedes.

## Themes
`AppPalette.dark` and `AppPalette.light` in `lib/app/theme.dart`, read with `context.palette`.
Theme mode is stored in prefs (key `themeMode`, default dark). The user switches in More → Appearance via `SegmentedButton<ThemeMode>`.

### Dark palette (`AppPalette.dark`)
| Token | Value |
|---|---|
| background | `#0E1217` |
| surface | `#161C23` |
| surfaceRaised | `#1E2630` |
| ink | `#EEF2F6` |
| inkMuted | `#94A0AE` |
| accent | `#3A6AD9` |
| accentInk | `#8DB0FF` |
| income | `#3DC985` |
| danger | `#F2706A` |

### Light palette (`AppPalette.light`)
| Token | Value |
|---|---|
| background | `#F3F5F8` |
| surface | `#FFFFFF` |
| surfaceRaised | `#E9EDF2` |
| ink | `#121820` |
| inkMuted | `#56616E` |
| accent | `#2F5FD0` |
| accentInk | `#2A55BD` |
| income | `#0B7341` |
| danger | `#BF332A` |

Category dots: Street `#C85A00`, Transport `#1A74C4`, Shops `#7B3FC4`, Companies `#1A8A6E`, Property `#1A74C4`.

## Focus Rule — one accent element per screen
Each screen has exactly **one** focal element that uses the full accent fill:
- Either a `FocusCard` (accent background, `onAccent` text, white action button with accent text, optional progress bar).
- Or a single recommended row, which gets a `FilledButton` plus a 1.5 px accent border.
Everything else uses `FilledButton.tonal` (neutral grey).

**Green is only for income values. Red is only for Sell / errors.** Accent blue is only for the focus element.

## Typography
System font through the theme `TextTheme`. Money and headings are heavy (700-800); body 400.
`displaySmall` 34 for the cash counter; `headlineSmall` 24; `titleLarge` 20; `titleMedium` 16; `bodyMedium` 14; `labelSmall` 11 for navigation. Every number uses tabular figures (`style.numbers`). Money uses `formatShort` (K, M, B, T — international units); exact values use `formatRs`.

## Layout
4-point spacing via `AppSpacing`. The money header is pinned above every tab. Lists of cards with 12–16 px between items.

## Elevation & Depth
No shadows. Depth from background → surface → surfaceRaised steps. `hairline` (0.5 px) border on the money header bottom.

## Shapes
Controls 12 px; sign tiles 14 px; cards 18 px.

## Components
- `MoneyHeader`: empire name, cash in ink, income in green text, hairline bottom.
- `FocusCard`: accent fill, `onAccent` text, white `FilledButton` with accent text, optional `LinearProgressIndicator`.
- `SignTile`: neutral grey tile with a small category colour dot; dimmed when not owned.
- Business card: sign tile, name, level, income, progress bar; `FilledButton` (focus row) or `FilledButton.tonal`; popup menu with Upgrade max and Sell (via `confirmSell`).
- Property card: same pattern. Home tab uses `home_list.dart` with current home card + FocusCard for next upgrade.
- Work button (`_WorkButton`): neutral grey tap target; income earned pops up in green.
- `StatTile`, `ProgressBar`, `SectionTitle`, `NoticeBanner`, `ConfirmSell` dialog.

## Homes
6 tiers: Rented Room (free) → Small Flat → Family Home → Bungalow → Villa → Mansion. Income bonus is not cumulative; only the current home's bonus applies. Encoded in `homeLevel` (int 0–5).

## Lifestyle & Vehicles
64 lifestyle items (33 vehicles), total +140% income bonus (cumulative across all owned items). Each item has a `group` in config: `road` (cars), `bike` (motorbikes and bikes), `heli`, `plane`, and the luxury sub-sections `watches`, `jewellery`, `art`, `yachts`; `luxury` is still accepted but currently empty. The Assets screen shows one tab per vehicle group: Cars, Bikes, Helicopters, Planes, plus Luxury, next to Home (10 homes) and Property. Items with a photo in `assets/images/<id>.jpg` (listed in `photos.dart`) show it as a banner card; others keep drawn art, then an icon.

Bike photos sit on white backgrounds and are centred on white at 800x450; the Kawasaki and Kids bike photos are cropped to drop their printed text, and the Royal Enfield-style photo is cropped below its title band.

The Luxury tab is four category cards (`LifestyleCategoryCard`): Watches (6, `wstreet`…`wdiver`), Jewellery (9, `pendant`…`emerald`), Art Collection (9, `popart`…`museum`) and Yachts (7, `sailboat`…`megayacht`). Each card shows its own owned-of-total and bonus %; tapping it pushes a `LifestyleList` scoped to that group on its own page. The tab's top line sums all four (`summaryGroups`). Old ids `watch`, `jewellery`, `painting`, `yacht`, `motorbike` are kept so saves still load.

Business cards use the same photo banner: samosa, chai, chaat, rickshaw, taxi, loader, bus, transport (Cargo Logistics) rentacar, and all 7 remaining businesses (Kiryana Store, Mobile Repair Shop, Cloth Shop, Mechanic Workshop, Restaurant, Wedding Hall, Textile Factory) have photos in `assets/images/<id>.jpg`; every business now has a photo, so the sign tile is only a fallback. Tall sources are blur-filled and white-background product shots are centred on white so nothing is cut by the 16:7 banner.

## Do's and Don'ts
- Do keep every string in `lib/core/strings.dart` (English).
- Do use `context.palette` and theme text styles; no hardcoded colours or sizes in widgets.
- Do use `.withValues(alpha:)`, never `.withOpacity()`.
- Do `dispose` controllers; add `mounted` guards after async gaps.
- Don't use gold, gradients, or colored borders > 1 px for decoration.
- Don't use emoji as icons.
- Don't put any color on price text inside `FilledButton` (let it inherit).
- Don't copy Business Empire: RichMan UI directly (genre reference only).

## Tax & Accounts
- Tax is a card on the Accounts screen: amount due, time left to the return, income tax rate now, and a File return button. Overdue states use the danger colour and show the missed count and penalty.
- The Empire screen has a Tax row that opens Accounts.
- Money uses short units everywhere: K, M, B, T (never lakh, crore, arab or kharab).

## Bank card
- A metal-coloured card on Empire: name, what it lets the player buy, progress to the next card. Locked buy buttons say which card is needed (e.g. "Gold card").
