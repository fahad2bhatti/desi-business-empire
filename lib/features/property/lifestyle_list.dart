import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_controller.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/strings.dart';
import '../../domain/economy/economy_config.dart';
import '../../domain/economy/game_engine.dart';
import '../../domain/economy/game_state.dart';
import '../common/photos.dart';
import '../common/run_command.dart';
import '../common/visuals.dart';
import '../common/widgets.dart';

/// One section of vehicles or luxury items ([group]): each owned once, each
/// adds a permanent percentage to all income. [what] names them in the bonus
/// line. Focus: the cheapest one not owned yet, when it is affordable.
/// [header] sits above the items (the Luxury tab puts its sub-sections there).
/// [summaryGroups], when set, makes the bonus line count those groups too.
class LifestyleList extends ConsumerWidget {
  const LifestyleList({
    super.key,
    required this.group,
    required this.what,
    this.header = const [],
    this.summaryGroups,
  });

  /// `road`, `heli`, `plane`, `luxury`, `jewellery` or `art`.
  final String group;
  final String what;
  final List<Widget> header;
  final Set<String>? summaryGroups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider).requireValue;
    final engine = ref.read(gameControllerProvider.notifier).engine;
    final s = session.state;
    final p = context.palette;
    final items = engine.config.lifestyle
        .where((i) => i.group == group)
        .toList();
    final counted = summaryGroups == null
        ? items
        : engine.config.lifestyle
              .where((i) => summaryGroups!.contains(i.group))
              .toList();
    final owned = counted.where((i) => s.lifestyle.contains(i.id)).toList();
    final bonus = owned.fold(0, (a, i) => a + i.incomeBonusPercent);
    String? focus;
    for (final i in items) {
      if (!s.lifestyle.contains(i.id)) {
        if (i.pricePaisa <= s.cashPaisa) {
          focus = i.id;
        }
        break;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s32,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                S.sectionBonus(what, bonus),
                style: context.text.bodySmall
                    ?.copyWith(color: p.inkMuted)
                    .numbers,
              ),
            ),
            Text(
              S.ownedOf(owned.length, counted.length),
              style: context.text.bodySmall
                  ?.copyWith(color: p.inkMuted)
                  .numbers,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        for (final h in header) ...[h, const SizedBox(height: AppSpacing.s8)],
        for (final item in items) ...[
          _ItemCard(
            item: item,
            state: s,
            engine: engine,
            blocked: session.saveFailed,
            focus: item.id == focus,
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
      ],
    );
  }
}

class _ItemCard extends ConsumerWidget {
  const _ItemCard({
    required this.item,
    required this.state,
    required this.engine,
    required this.blocked,
    required this.focus,
  });

  final LifestyleDef item;
  final GameState state;
  final GameEngine engine;
  final bool blocked;
  final bool focus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final owned = state.lifestyle.contains(item.id);
    final lock = engine.cardAllows(state, item.pricePaisa)
        ? null
        : engine.cardFor(item.pricePaisa).name;
    final canBuy = !owned && lock == null && state.cashPaisa >= item.pricePaisa;
    final onBuy = blocked || !canBuy
        ? null
        : () => runCommand(
            context,
            ref,
            (s, now) => engine.buyItem(s, item.id, now),
          );
    final buyChild = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(S.buyShort),
        Text(
          lock != null && !owned
              ? S.cardShort(lock)
              : formatShort(item.pricePaisa),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ).numbers,
        ),
      ],
    );
    final buyStyle = FilledButton.styleFrom(
      minimumSize: const Size(96, 52),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
    );

    final photo = hasPhoto(item.id);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: focus
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              side: BorderSide(color: p.accent, width: 1.5),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (photo) PhotoBanner(id: item.id, dimmed: !owned && !canBuy),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s12,
              AppSpacing.s8,
              AppSpacing.s12,
            ),
            child: Row(
              children: [
                if (!photo) ...[
                  SignTile(
                    icon: iconFor(item.id),
                    artId: item.id,
                    dimmed: !owned && !canBuy,
                  ),
                  const SizedBox(width: AppSpacing.s12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: context.text.titleMedium),
                      Text(
                        S.lifestyleBonus(item.incomeBonusPercent),
                        style: context.text.bodySmall?.copyWith(
                          color: owned ? p.income : p.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (owned)
                  PopupMenuButton<void>(
                    tooltip: S.owned,
                    itemBuilder: (_) => [
                      PopupMenuItem<void>(
                        enabled: !blocked,
                        onTap: () => _confirmSell(context, ref),
                        child: Text(S.sell, style: TextStyle(color: p.danger)),
                      ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s8,
                        vertical: AppSpacing.s12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, color: p.income, size: 18),
                          const SizedBox(width: AppSpacing.s4),
                          Text(
                            S.owned,
                            style: context.text.titleSmall?.copyWith(
                              color: p.income,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  if (focus)
                    FilledButton(
                      style: buyStyle,
                      onPressed: onBuy,
                      child: buyChild,
                    )
                  else
                    FilledButton.tonal(
                      style: buyStyle,
                      onPressed: onBuy,
                      child: buyChild,
                    ),
                  const SizedBox(width: AppSpacing.s8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSell(BuildContext context, WidgetRef ref) async {
    final value = formatShort(engine.itemSellValue(item));
    final ok = await confirmSell(
      context,
      S.sellItemTitle(item.name),
      S.sellItemBody(value, item.incomeBonusPercent),
    );
    if (ok && context.mounted) {
      await runCommand(
        context,
        ref,
        (s, now) => engine.sellItem(s, item.id, now),
        successText: S.sold(item.name, value),
      );
    }
  }
}

/// A luxury sub-section (jewellery, art) shown as one card; tapping it opens
/// that section's items on their own page.
class LifestyleCategoryCard extends ConsumerWidget {
  const LifestyleCategoryCard({
    super.key,
    required this.group,
    required this.title,
    required this.photoId,
  });

  final String group;
  final String title;

  /// Photo used as the card banner.
  final String photoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameControllerProvider).requireValue.state;
    final engine = ref.read(gameControllerProvider.notifier).engine;
    final p = context.palette;
    final items = engine.config.lifestyle
        .where((i) => i.group == group)
        .toList();
    final owned = items.where((i) => s.lifestyle.contains(i.id)).toList();
    final bonus = owned.fold(0, (a, i) => a + i.incomeBonusPercent);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(title: Text(title)),
              body: LifestyleList(group: group, what: title.toLowerCase()),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasPhoto(photoId)) PhotoBanner(id: photoId),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                AppSpacing.s12,
                AppSpacing.s8,
                AppSpacing.s12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: context.text.titleMedium),
                        Text(
                          S.categoryInfo(owned.length, items.length, bonus),
                          style: context.text.bodySmall
                              ?.copyWith(
                                color: bonus > 0 ? p.income : p.inkMuted,
                              )
                              .numbers,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: p.inkMuted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
