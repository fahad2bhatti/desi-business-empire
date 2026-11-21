import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_controller.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/strings.dart';
import '../../domain/economy/economy_config.dart';
import '../../domain/economy/game_engine.dart';
import '../../domain/economy/game_state.dart';
import '../common/run_command.dart';
import '../common/visuals.dart';
import '../common/widgets.dart';
import '../onboarding/tutorial.dart';

class BusinessesScreen extends ConsumerWidget {
  const BusinessesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider).requireValue;
    final engine = ref.read(gameControllerProvider.notifier).engine;
    final categories = engine.config.categories;
    final p = context.palette;

    return DefaultTabController(
      length: categories.length,
      child: Column(
        children: [
          TabBar(
            tabs: [
              for (final c in categories)
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: p.category(c.id)),
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
                  ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s16,
                      AppSpacing.s16,
                      AppSpacing.s16,
                      AppSpacing.s32,
                    ),
                    children: [
                      const TutorialCoach(),
                      for (final b in engine.config.businesses.where(
                        (b) => b.categoryId == c.id,
                      )) ...[
                        _BusinessCard(
                          business: b,
                          state: session.state,
                          engine: engine,
                          blocked: session.saveFailed,
                        ),
                        const SizedBox(height: AppSpacing.s12),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessCard extends ConsumerWidget {
  const _BusinessCard({
    required this.business,
    required this.state,
    required this.engine,
    required this.blocked,
  });

  final BusinessDef business;
  final GameState state;
  final GameEngine engine;
  final bool blocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final b = business;
    final level = state.level(b.id);
    final owned = level > 0;
    final color = p.category(b.categoryId);
    final cash = state.cashPaisa;
    final max = engine.config.maxLevel;
    final muted = context.text.bodySmall?.copyWith(color: p.inkMuted);

    Widget actions;
    if (!owned) {
      final canBuy = cash >= b.pricePaisa;
      actions = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!canBuy) ...[
            ProgressBar(value: cash / b.pricePaisa, label: b.name),
            const SizedBox(height: AppSpacing.s4),
            Text(
              S.locked('${(cash * 100 ~/ b.pricePaisa).clamp(0, 100)}%'),
              style: muted,
            ),
            const SizedBox(height: AppSpacing.s8),
          ],
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: p.income,
              foregroundColor: p.onIncome,
            ),
            onPressed: blocked || !canBuy
                ? null
                : () => runCommand(
                    context,
                    ref,
                    (s, now) => engine.buyBusiness(s, b.id, now),
                  ),
            child: Text(S.buyFor(formatShort(b.pricePaisa))),
          ),
        ],
      );
    } else if (level >= max) {
      actions = Text(
        S.maxed,
        style: context.text.titleSmall?.copyWith(color: p.gold),
      );
    } else {
      final cost = engine.upgradeCost(b, level);
      final gain =
          engine.businessIncome(b, level + 1) - engine.businessIncome(b, level);
      final canUp = cash >= cost;
      actions = Row(
        children: [
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: p.gold,
                foregroundColor: p.onGold,
              ),
              onPressed: blocked || !canUp
                  ? null
                  : () => runCommand(
                      context,
                      ref,
                      (s, now) => engine.upgradeBusiness(s, b.id, now),
                    ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(S.upgradeFor(formatShort(cost))),
                    Text(
                      S.plusIncome(formatShort(gain)),
                      style: context.text.bodySmall?.copyWith(color: p.onGold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          OutlinedButton(
            onPressed: blocked || !canUp
                ? null
                : () => runCommand(
                    context,
                    ref,
                    (s, now) =>
                        engine.upgradeBusiness(s, b.id, now, times: max),
                  ),
            child: const Text(S.upgradeMax),
          ),
        ],
      );
    }

    final milestone = owned ? engine.nextMilestone(level) : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SignTile(icon: iconFor(b.id), color: color, dimmed: !owned),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.name, style: context.text.titleMedium),
                      Text(
                        owned
                            ? S.level(level, max)
                            : S.earnsAtLevel1(
                                formatShort(engine.businessIncome(b, 1)),
                              ),
                        style: muted.numbers,
                      ),
                    ],
                  ),
                ),
                if (owned) ...[
                  Text(
                    S.perSecond(formatShort(engine.businessIncome(b, level))),
                    style: context.text.titleSmall
                        ?.copyWith(color: p.income)
                        .numbers,
                  ),
                  PopupMenuButton<void>(
                    icon: Icon(Icons.more_vert, color: p.inkMuted),
                    itemBuilder: (_) => [
                      PopupMenuItem<void>(
                        onTap: blocked
                            ? null
                            : () => _confirmSell(context, ref),
                        child: Text(S.sell, style: TextStyle(color: p.danger)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            if (owned) ...[
              const SizedBox(height: AppSpacing.s12),
              if (milestone != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        S.nextBonus(milestone.level, milestone.multiplier),
                        style: muted,
                      ),
                    ),
                    Text('$level / ${milestone.level}', style: muted.numbers),
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                ProgressBar(
                  value: level / milestone.level,
                  color: color,
                  label: S.nextBonus(milestone.level, milestone.multiplier),
                ),
              ] else
                Text(S.allBonuses, style: muted),
            ],
            const SizedBox(height: AppSpacing.s12),
            actions,
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSell(BuildContext context, WidgetRef ref) async {
    final value = formatShort(engine.businessSellValue(state, business.id));
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.sellTitle(business.name)),
        content: Text(S.sellBody(value)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(S.keep),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.danger,
              foregroundColor: context.palette.background,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(S.sell),
          ),
        ],
      ),
    );
    if ((ok ?? false) && context.mounted) {
      await runCommand(
        context,
        ref,
        (s, now) => engine.sellBusiness(s, business.id, now),
        successText: S.sold(business.name, value),
      );
    }
  }
}
