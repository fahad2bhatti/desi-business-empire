import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_controller.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/strings.dart';
import '../../domain/economy/advisor.dart';
import '../../domain/economy/economy_config.dart';
import '../../domain/economy/game_engine.dart';
import '../../domain/economy/game_state.dart';
import '../common/run_command.dart';
import '../common/visuals.dart';
import '../common/widgets.dart';
import '../onboarding/tutorial.dart';

/// One tab per category. In each tab only the best affordable move gets the
/// accent button; every other action is tonal.
class BusinessesScreen extends ConsumerWidget {
  const BusinessesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider).requireValue;
    final engine = ref.read(gameControllerProvider.notifier).engine;
    final categories = engine.config.categories;
    final s = session.state;
    final p = context.palette;

    return DefaultTabController(
      length: categories.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final c in categories)
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 10, color: p.category(c.id)),
                      const SizedBox(width: AppSpacing.s8),
                      Text(c.name),
                    ],
                  ),
                ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                for (final c in categories)
                  _CategoryList(
                    category: c,
                    engine: engine,
                    state: s,
                    blocked: session.saveFailed,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.category,
    required this.engine,
    required this.state,
    required this.blocked,
  });

  final CategoryDef category;
  final GameEngine engine;
  final GameState state;
  final bool blocked;

  @override
  Widget build(BuildContext context) {
    final list = engine.config.businesses
        .where((b) => b.categoryId == category.id)
        .toList();
    final owned = list.where((b) => state.level(b.id) > 0).length;
    var income = 0;
    for (final b in list) {
      income += engine.businessIncome(b, state.level(b.id));
    }
    final focus = engine.bestBusinessIn(state, category.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s32,
      ),
      children: [
        const TutorialCoach(),
        Text(
          S.categorySummary(formatShort(income), owned, list.length),
          style: context.text.bodySmall
              ?.copyWith(color: context.palette.inkMuted)
              .numbers,
        ),
        const SizedBox(height: AppSpacing.s12),
        for (final b in list) ...[
          _BusinessCard(
            business: b,
            state: state,
            engine: engine,
            blocked: blocked,
            focus: b.id == focus,
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
      ],
    );
  }
}

class _BusinessCard extends ConsumerWidget {
  const _BusinessCard({
    required this.business,
    required this.state,
    required this.engine,
    required this.blocked,
    required this.focus,
  });

  final BusinessDef business;
  final GameState state;
  final GameEngine engine;
  final bool blocked;

  /// The one business on this tab that gets the accent button.
  final bool focus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final b = business;
    final level = state.level(b.id);
    final owned = level > 0;
    final cash = state.cashPaisa;
    final max = engine.config.maxLevel;
    final muted = context.text.bodySmall?.copyWith(color: p.inkMuted);

    Widget? action;
    double? saving;
    if (!owned) {
      final canBuy = cash >= b.pricePaisa;
      if (!canBuy) {
        saving = cash / b.pricePaisa;
      }
      action = _ActionButton(
        label: S.buyShort,
        price: formatShort(b.pricePaisa),
        focus: focus,
        onPressed: blocked || !canBuy
            ? null
            : () => runCommand(
                context,
                ref,
                (s, now) => engine.buyBusiness(s, b.id, now),
              ),
      );
    } else if (level < max) {
      final cost = engine.upgradeCost(b, level);
      action = _ActionButton(
        label: S.upgradeShort,
        price: formatShort(cost),
        focus: focus,
        onPressed: blocked || cash < cost
            ? null
            : () => runCommand(
                context,
                ref,
                (s, now) => engine.upgradeBusiness(s, b.id, now),
              ),
      );
    }

    final milestone = owned ? engine.nextMilestone(level) : null;
    return Card(
      shape: focus
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              side: BorderSide(color: p.accent, width: 1.5),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s12,
          AppSpacing.s8,
          AppSpacing.s12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SignTile(
                  icon: iconFor(b.id),
                  dot: p.category(b.categoryId),
                  dimmed: !owned,
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.name, style: context.text.titleMedium),
                      if (owned)
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: S.levelIncome(level)),
                              TextSpan(
                                text: S.perSecond(
                                  formatShort(engine.businessIncome(b, level)),
                                ),
                                style: TextStyle(color: p.income),
                              ),
                            ],
                          ),
                          style: muted.numbers,
                        )
                      else
                        Text(
                          S.earnsAtLevel1(
                            formatShort(engine.businessIncome(b, 1)),
                          ),
                          style: muted.numbers,
                        ),
                    ],
                  ),
                ),
                if (action != null)
                  action
                else
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.s8),
                    child: Text(S.maxed, style: muted),
                  ),
                if (owned)
                  PopupMenuButton<void>(
                    icon: Icon(Icons.more_vert, color: p.inkMuted),
                    itemBuilder: (_) => [
                      if (level < max)
                        PopupMenuItem<void>(
                          enabled:
                              !blocked && cash >= engine.upgradeCost(b, level),
                          onTap: () => runCommand(
                            context,
                            ref,
                            (s, now) => engine.upgradeBusiness(
                              s,
                              b.id,
                              now,
                              times: max,
                            ),
                          ),
                          child: const Text(S.upgradeMax),
                        ),
                      PopupMenuItem<void>(
                        enabled: !blocked,
                        onTap: () => _confirmSell(context, ref),
                        child: Text(S.sell, style: TextStyle(color: p.danger)),
                      ),
                    ],
                  )
                else
                  const SizedBox(width: AppSpacing.s8),
              ],
            ),
            if (saving != null) ...[
              const SizedBox(height: AppSpacing.s12),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s8),
                child: ProgressBar(value: saving, label: S.saveUpFor(b.name)),
              ),
            ],
            if (milestone != null) ...[
              const SizedBox(height: AppSpacing.s12),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s8),
                child: Row(
                  children: [
                    Expanded(
                      child: ProgressBar(
                        value: level / milestone.level,
                        label: S.nextBonus(
                          milestone.level,
                          milestone.multiplier,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Text(
                      S.nextBonus(milestone.level, milestone.multiplier),
                      style: muted,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSell(BuildContext context, WidgetRef ref) async {
    final value = formatShort(engine.businessSellValue(state, business.id));
    final ok = await confirmSell(
      context,
      S.sellTitle(business.name),
      S.sellBody(value),
    );
    if (ok && context.mounted) {
      await runCommand(
        context,
        ref,
        (s, now) => engine.sellBusiness(s, business.id, now),
        successText: S.sold(business.name, value),
      );
    }
  }
}

/// Compact two-line button: action over price. Accent only when [focus].
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.price,
    required this.focus,
    required this.onPressed,
  });

  final String label;
  final String price;
  final bool focus;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        // No colour here, so it follows the button's foreground.
        Text(
          price,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ).numbers,
        ),
      ],
    );
    final style = FilledButton.styleFrom(
      minimumSize: const Size(96, 52),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
    );
    return focus
        ? FilledButton(style: style, onPressed: onPressed, child: child)
        : FilledButton.tonal(style: style, onPressed: onPressed, child: child);
  }
}
