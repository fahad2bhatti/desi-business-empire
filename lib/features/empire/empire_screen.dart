import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

/// The cheapest business not yet owned, or null when everything is owned.
BusinessDef? nextBusinessToBuy(GameEngine engine, GameState s) {
  BusinessDef? best;
  for (final b in engine.config.businesses) {
    if (s.level(b.id) == 0 &&
        (best == null || b.pricePaisa < best.pricePaisa)) {
      best = b;
    }
  }
  return best;
}

/// The owned business whose next level pays itself back fastest.
BusinessDef? bestUpgrade(GameEngine engine, GameState s) {
  BusinessDef? best;
  var bestRatio = double.infinity;
  for (final b in engine.config.businesses) {
    final level = s.level(b.id);
    if (level == 0 || level >= engine.config.maxLevel) {
      continue;
    }
    final gain =
        engine.businessIncome(b, level + 1) - engine.businessIncome(b, level);
    final ratio = engine.upgradeCost(b, level) / gain;
    if (ratio < bestRatio) {
      bestRatio = ratio;
      best = b;
    }
  }
  return best;
}

class EmpireScreen extends ConsumerWidget {
  const EmpireScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider).requireValue;
    final engine = ref.read(gameControllerProvider.notifier).engine;
    final s = session.state;
    final p = context.palette;
    final next = nextBusinessToBuy(engine, s);
    final upgrade = bestUpgrade(engine, s);
    final units = s.properties.values.fold(0, (a, b) => a + b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        AppSpacing.s20,
        AppSpacing.s20,
        AppSpacing.s32,
      ),
      children: [
        const TutorialCoach(),
        _WorkButton(
          pay: formatShort(engine.config.workPayPaisa),
          enabled: !session.saveFailed,
          onTap: () =>
              runCommand(context, ref, (state, now) => engine.work(state, now)),
        ),
        const SizedBox(height: AppSpacing.s20),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: S.businessesOwned,
                value:
                    '${s.businesses.length} / ${engine.config.businesses.length}',
                icon: Icons.storefront,
                color: p.shops,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: StatTile(
                label: S.propertiesOwned,
                value: '$units',
                icon: Icons.apartment,
                color: p.property,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: StatTile(
                label: S.lifetimeEarned,
                value: formatShort(s.totalEarnedPaisa),
                icon: Icons.trending_up,
                color: p.income,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),
        const SectionTitle(S.nextBuy),
        if (next == null)
          Text(
            S.everythingBought,
            style: context.text.bodyMedium?.copyWith(color: p.inkMuted),
          )
        else
          _NextBuyCard(business: next, engine: engine, cash: s.cashPaisa),
        const SizedBox(height: AppSpacing.s24),
        const SectionTitle(S.quickActions),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: upgrade == null
                ? Text(
                    S.nothingToUpgrade,
                    style: context.text.bodyMedium?.copyWith(color: p.inkMuted),
                  )
                : Row(
                    children: [
                      SignTile(
                        icon: iconFor(upgrade.id),
                        color: p.category(upgrade.categoryId),
                        size: 44,
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(S.upgradeBest, style: context.text.titleSmall),
                            Text(
                              S.upgradeBestDetail(
                                upgrade.name,
                                formatShort(
                                  engine.upgradeCost(
                                    upgrade,
                                    s.level(upgrade.id),
                                  ),
                                ),
                                formatShort(
                                  engine.businessIncome(
                                        upgrade,
                                        s.level(upgrade.id) + 1,
                                      ) -
                                      engine.businessIncome(
                                        upgrade,
                                        s.level(upgrade.id),
                                      ),
                                ),
                              ),
                              style: context.text.bodySmall
                                  ?.copyWith(color: p.inkMuted)
                                  .numbers,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: p.gold,
                          foregroundColor: p.onGold,
                        ),
                        onPressed:
                            session.saveFailed ||
                                engine.upgradeCost(
                                      upgrade,
                                      s.level(upgrade.id),
                                    ) >
                                    s.cashPaisa
                            ? null
                            : () => runCommand(
                                context,
                                ref,
                                (state, now) => engine.upgradeBusiness(
                                  state,
                                  upgrade.id,
                                  now,
                                ),
                              ),
                        child: const Icon(Icons.arrow_upward),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _NextBuyCard extends StatelessWidget {
  const _NextBuyCard({
    required this.business,
    required this.engine,
    required this.cash,
  });

  final BusinessDef business;
  final GameEngine engine;
  final int cash;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = p.category(business.categoryId);
    final progress = cash / business.pricePaisa;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/businesses'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            children: [
              Row(
                children: [
                  SignTile(icon: iconFor(business.id), color: color),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(business.name, style: context.text.titleMedium),
                        Text(
                          S.earnsPerSecond(
                            formatShort(engine.businessIncome(business, 1)),
                          ),
                          style: context.text.bodySmall
                              ?.copyWith(color: p.income)
                              .numbers,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatShort(business.pricePaisa),
                    style: context.text.titleMedium
                        ?.copyWith(color: p.gold)
                        .numbers,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              ProgressBar(
                value: progress,
                color: progress >= 1 ? p.income : p.gold,
                label: S.saveUpFor(business.name),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The big tap target. Each tap pops a small "+Rs 25" that floats up.
class _WorkButton extends StatefulWidget {
  const _WorkButton({
    required this.pay,
    required this.enabled,
    required this.onTap,
  });

  final String pay;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_WorkButton> createState() => _WorkButtonState();
}

class _WorkButtonState extends State<_WorkButton> {
  final _pops = <int>[];
  var _next = 0;
  var _pressed = false;

  void _tap() {
    widget.onTap();
    if (MediaQuery.of(context).disableAnimations) {
      return;
    }
    final id = _next++;
    setState(() => _pops.add(id));
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) {
        return;
      }
      setState(() => _pops.remove(id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          child: Material(
            color: p.gold,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.card),
              onTap: widget.enabled ? _tap : null,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              child: SizedBox(
                height: 96,
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app, size: 36, color: p.onGold),
                    const SizedBox(width: AppSpacing.s12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.work,
                          style: context.text.headlineSmall?.copyWith(
                            color: p.onGold,
                          ),
                        ),
                        Text(
                          S.workPay(widget.pay),
                          style: context.text.bodyMedium?.copyWith(
                            color: p.onGold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        for (final id in _pops)
          IgnorePointer(
            key: ValueKey(id),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: AppMotion.curve,
              builder: (context, t, child) => Transform.translate(
                offset: Offset(0, -24 - 40 * t),
                child: Opacity(opacity: 1 - t, child: child),
              ),
              child: Text(
                '+${widget.pay}',
                style: context.text.titleMedium
                    ?.copyWith(color: p.gold)
                    .numbers,
              ),
            ),
          ),
      ],
    );
  }
}
