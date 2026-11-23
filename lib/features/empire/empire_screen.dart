import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/game_controller.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/strings.dart';
import '../../domain/economy/advisor.dart';
import '../../domain/economy/economy_config.dart';
import '../../domain/economy/game_engine.dart';
import '../../domain/economy/game_state.dart';
import '../../domain/economy/goals.dart';
import '../common/photos.dart';
import '../common/run_command.dart';
import '../common/visuals.dart';
import '../common/widgets.dart';
import '../goals/goals_screen.dart';
import '../onboarding/tutorial.dart';

/// Home tab. One focus: the next move. Below it, quiet context.
class EmpireScreen extends ConsumerWidget {
  const EmpireScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider).requireValue;
    final engine = ref.read(gameControllerProvider.notifier).engine;
    final s = session.state;
    final goal = nextGoal(engine, s);

    // Say so when net worth earns a better card.
    ref.listen<int>(
      gameControllerProvider.select((a) {
        final st = a.value?.state;
        return st == null ? 0 : engine.config.cards.indexOf(engine.card(st));
      }),
      (before, now) {
        if (before != null && now > before) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(S.cardUpgraded(engine.config.cards[now].name)),
              ),
            );
        }
      },
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        AppSpacing.s8,
        AppSpacing.s20,
        AppSpacing.s32,
      ),
      children: [
        const TutorialCoach(),
        Center(child: Text(S.tabEmpire, style: context.text.headlineSmall)),
        const SizedBox(height: AppSpacing.s16),
        _Hero(
          netWorthPaisa: engine.netWorth(s),
          incomePaisaPerSec: engine.incomePerSec(s),
        ),
        const SizedBox(height: AppSpacing.s20),
        _BankCard(engine: engine, state: s),
        const SizedBox(height: AppSpacing.s20),
        _Overview(engine: engine, state: s),
        const SizedBox(height: AppSpacing.s20),
        NextMoveCard(engine: engine, state: s, blocked: session.saveFailed),
        const SizedBox(height: AppSpacing.s12),
        _WorkButton(
          pay: formatShort(engine.config.workPayPaisa),
          enabled: !session.saveFailed,
          onTap: () =>
              runCommand(context, ref, (state, now) => engine.work(state, now)),
        ),
        if (goal != null &&
            engine.goalStatus(s, goal) == GoalStatus.inProgress) ...[
          const SizedBox(height: AppSpacing.s24),
          SectionTitle(
            S.nextGoal,
            trailing: TextButton(
              onPressed: () => context.go('/goals'),
              child: const Text(S.tabGoals),
            ),
          ),
          GoalCard(
            goal: goal,
            engine: engine,
            state: s,
            blocked: session.saveFailed,
          ),
        ],
      ],
    );
  }
}

/// Centred net worth, with income per second in a soft green pill. The cash
/// counter that other tabs show at the top lives here as the net worth.
class _Hero extends StatelessWidget {
  const _Hero({required this.netWorthPaisa, required this.incomePaisaPerSec});

  final int netWorthPaisa;
  final int incomePaisaPerSec;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Semantics(
      label:
          '${S.netWorth} ${formatShort(netWorthPaisa)}, ${S.perSecond(formatShort(incomePaisaPerSec))}',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            S.netWorth,
            style: context.text.titleSmall?.copyWith(color: p.inkMuted),
          ),
          const SizedBox(height: AppSpacing.s4),
          TweenAnimationBuilder<double>(
            tween: Tween(end: netWorthPaisa.toDouble()),
            duration: reduceMotion ? Duration.zero : AppMotion.counter,
            curve: AppMotion.curve,
            builder: (context, value, _) => FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatRs(value.round() - value.round() % paisaPerRupee),
                style: context.text.displaySmall
                    ?.copyWith(fontSize: 44, height: 1.1)
                    .numbers,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: p.income.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s4 + 2,
              ),
              child: Text(
                S.perSecond(formatShort(incomePaisaPerSec)),
                style: context.text.titleSmall
                    ?.copyWith(color: p.income)
                    .numbers,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The focus card for the advisor's best move.
class NextMoveCard extends ConsumerWidget {
  const NextMoveCard({
    super.key,
    required this.engine,
    required this.state,
    required this.blocked,
  });

  final GameEngine engine;
  final GameState state;
  final bool blocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = state;
    final move = engine.nextMove(s);
    if (move == null) {
      return const FocusCard(
        icon: Icons.emoji_events,
        photoId: 'goal_trophy',
        title: S.allDone,
      );
    }
    final c = engine.config;
    final cost = formatShort(move.costPaisa);
    final (
      IconData icon,
      String title,
      String action,
      String? done,
    ) = switch (move.kind) {
      MoveKind.claimGoals => (
        Icons.emoji_events,
        S.focusClaim,
        S.collectAll(formatShort(move.gainPaisa)),
        S.collected(formatShort(move.gainPaisa)),
      ),
      MoveKind.buyBusiness => (
        iconFor(move.id!),
        S.focusBuy(c.business(move.id!)!.name),
        S.buyFor(cost),
        null,
      ),
      MoveKind.upgradeBusiness => (
        iconFor(move.id!),
        S.focusUpgrade(c.business(move.id!)!.name),
        S.upgradeFor(cost),
        null,
      ),
      MoveKind.moveHome => (
        iconFor(engine.nextHome(s)!.id),
        S.focusMove(engine.nextHome(s)!.name),
        S.moveFor(cost),
        S.movedTo(engine.nextHome(s)!.name),
      ),
      MoveKind.buyItem => (
        iconFor(move.id!),
        S.focusBuy(c.item(move.id!)!.name),
        S.buyFor(cost),
        null,
      ),
    };
    final detail = move.kind == MoveKind.claimGoals
        ? S.focusWaiting(formatShort(move.gainPaisa))
        : S.focusGain(
            formatShort(move.gainPaisa),
            S.eta(move.payback.isFinite ? move.payback.ceil() : 0),
          );
    final affordable = move.costPaisa <= s.cashPaisa;
    if (!affordable) {
      final wait = engine.secondsUntil(s, move.costPaisa);
      return FocusCard(
        icon: icon,
        title: title,
        detail: '$cost · $detail',
        progress: s.cashPaisa / move.costPaisa,
        progressText: wait == null ? S.workToSave : S.readyIn(S.eta(wait)),
      );
    }
    return FocusCard(
      icon: icon,
      title: title,
      detail: detail,
      actionLabel: action,
      onAction: blocked
          ? null
          : () => runCommand(
              context,
              ref,
              (st, now) => switch (move.kind) {
                MoveKind.claimGoals => engine.claimAllGoals(st, now),
                MoveKind.buyBusiness => engine.buyBusiness(st, move.id!, now),
                MoveKind.upgradeBusiness => engine.upgradeBusiness(
                  st,
                  move.id!,
                  now,
                ),
                MoveKind.moveHome => engine.moveHome(st, now),
                MoveKind.buyItem => engine.buyItem(st, move.id!, now),
              },
              successText: done,
            ),
    );
  }
}

/// What the empire is worth, split by kind: a coloured bar, then two columns
/// of soft tiles. Each tile opens the tab where that kind is managed.
class _Overview extends StatelessWidget {
  const _Overview({required this.engine, required this.state});

  final GameEngine engine;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final c = engine.config;

    final worth = <String, int>{for (final cat in c.categories) cat.id: 0};
    for (final id in s.businesses.keys) {
      final b = c.business(id);
      if (b != null) {
        worth[b.categoryId] =
            (worth[b.categoryId] ?? 0) + engine.businessSellValue(s, id);
      }
    }
    var property = 0;
    for (final prop in c.properties) {
      for (var i = s.owned(prop.id); i > 0; i--) {
        property += engine.propertySellValue(prop, i);
      }
    }
    var lifestyle = 0;
    for (final item in c.lifestyle) {
      if (s.lifestyle.contains(item.id)) {
        lifestyle += engine.itemSellValue(item);
      }
    }
    lifestyle +=
        ((engine.currentHome(s)?.pricePaisa ?? 0) * c.lifestyleSellRefund)
            .round();

    final tiles = <_TileData>[
      for (final cat in c.categories)
        _TileData(cat.id, cat.name, worth[cat.id] ?? 0, '/businesses'),
      _TileData('property', S.property, property, '/property?tab=property'),
      _TileData('lifestyle', S.lifestyle, lifestyle, '/property?tab=vehicles'),
    ];
    final total = tiles.fold<int>(0, (a, t) => a + (t.paisa > 0 ? t.paisa : 0));

    final p = context.palette;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                for (final (i, t) in tiles.indexed) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    flex: total == 0
                        ? 1
                        : ((t.paisa > 0 ? t.paisa : 0) * 1000 ~/ total).clamp(
                            12,
                            1000,
                          ),
                    child: ColoredBox(color: p.category(t.id)),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(child: _CategoryTile(data: tiles[i])),
              const SizedBox(width: AppSpacing.s12),
              if (i + 1 < tiles.length)
                Expanded(child: _CategoryTile(data: tiles[i + 1]))
              else
                const Spacer(),
            ],
          ),
        ],
      ],
    );
  }
}

class _TileData {
  const _TileData(this.id, this.label, this.paisa, this.path);

  final String id;
  final String label;
  final int paisa;
  final String path;
}

/// Soft tile in the category's colour with a strip on its left edge.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.data});

  final _TileData data;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: '${data.label}, ${formatShort(data.paisa)}',
      excludeSemantics: true,
      child: Material(
        color: p.tint(data.id),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go(data.path),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 9,
                  child: ColoredBox(color: p.category(data.id)),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12,
                      vertical: AppSpacing.s12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.label,
                          style: context.text.bodySmall?.copyWith(
                            color: p.inkMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.s4 / 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatShort(data.paisa),
                            style: context.text.titleMedium?.numbers,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Neutral tap target. Each tap pops a small "+Rs 25" that floats up.
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
      alignment: Alignment.topRight,
      children: [
        AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          child: Material(
            color: p.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.card),
              onTap: widget.enabled ? _tap : null,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: AppSpacing.s12,
                ),
                child: Row(
                  children: [
                    PhotoThumb(
                      id: 'samosa',
                      fallback: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: p.surfaceRaised,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.touch_app, color: p.ink),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(S.work, style: context.text.titleMedium),
                          Text(
                            S.workPay(widget.pay),
                            style: context.text.bodySmall?.copyWith(
                              color: p.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        for (final id in _pops)
          Positioned(
            right: AppSpacing.s20,
            top: AppSpacing.s16,
            child: IgnorePointer(
              key: ValueKey(id),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: AppMotion.curve,
                builder: (context, t, child) => Transform.translate(
                  offset: Offset(0, -32 * t),
                  child: Opacity(opacity: 1 - t, child: child),
                ),
                child: Text(
                  '+${widget.pay}',
                  style: context.text.titleMedium
                      ?.copyWith(color: p.income)
                      .numbers,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Metal colour for each card.
Color _cardColor(String id) => switch (id) {
  'bronze' => const Color(0xFF9A6A3C),
  'silver' => const Color(0xFFA9B1BA),
  'gold' => const Color(0xFFC9A227),
  'platinum' => const Color(0xFF7D8A99),
  'diamond' => const Color(0xFF4A9BD0),
  _ => const Color(0xFF1F3A5F),
};

/// The card's picture, with a plain tile in its colour if it cannot load.
class _CardPicture extends StatelessWidget {
  const _CardPicture({required this.id, this.width});

  final String id;
  final double? width;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/card_$id.webp',
    width: width,
    fit: BoxFit.contain,
    errorBuilder: (_, _, _) => AspectRatio(
      aspectRatio: 1.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _cardColor(id),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
    ),
  );
}

/// The player's bank card as a big picture. Under it: net worth, what the
/// card lets them buy, and how far the next card is. Tap for every card.
class _BankCard extends StatelessWidget {
  const _BankCard({required this.engine, required this.state});

  final GameEngine engine;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final card = engine.card(state);
    final next = engine.nextCard(state);
    final worth = engine.netWorth(state);
    final span = next == null ? 1 : next.netWorthPaisa - card.netWorthPaisa;
    final progress = next == null
        ? 1.0
        : ((worth - card.netWorthPaisa) / span).clamp(0.0, 1.0);
    final muted = context.text.bodySmall?.copyWith(color: p.inkMuted);
    final limit = card.limitPaisa == noCardLimit
        ? S.cardNoLimit
        : S.cardLimit(formatShort(card.limitPaisa));
    return Semantics(
      container: true,
      button: true,
      label:
          '${S.cardShort(card.name)}. ${S.netWorth} ${formatShort(worth)}. $limit',
      child: GestureDetector(
        onTap: () => _showCards(context, engine, state),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card + 4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: _CardPicture(id: card.id),
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(limit, style: muted),
            const SizedBox(height: AppSpacing.s8),
            ProgressBar(value: progress),
            const SizedBox(height: AppSpacing.s4),
            Text(
              next == null
                  ? S.cardTop
                  : S.cardNext(
                      next.name,
                      formatShort(next.netWorthPaisa),
                      formatShort(worth),
                    ),
              style: muted?.numbers,
            ),
          ],
        ),
      ),
    );
  }
}

/// Every card from first to last: the player's own, the ones already
/// passed, and the ones still locked with what they need.
void _showCards(BuildContext context, GameEngine engine, GameState s) {
  final p = context.palette;
  final current = engine.card(s);
  final cards = engine.config.cards;
  final at = cards.indexOf(current);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s20,
          0,
          AppSpacing.s20,
          AppSpacing.s20,
        ),
        children: [
          Text(S.cardsTitle, style: sheet.text.titleLarge),
          const SizedBox(height: AppSpacing.s4),
          Text(
            S.cardsIntro,
            style: sheet.text.bodyMedium?.copyWith(color: p.inkMuted),
          ),
          const SizedBox(height: AppSpacing.s16),
          for (final (i, c) in cards.indexed)
            _CardRow(card: c, index: i, current: at),
        ],
      ),
    ),
  );
}

class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.card,
    required this.index,
    required this.current,
  });

  final CardDef card;
  final int index;
  final int current;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final locked = index > current;
    final isCurrent = index == current;
    final limit = card.limitPaisa == noCardLimit
        ? S.cardNoLimit
        : S.cardLimit(formatShort(card.limitPaisa));
    final status = locked
        ? S.cardNeedsWorth(formatShort(card.netWorthPaisa))
        : isCurrent
        ? S.cardYours
        : index == 0
        ? S.cardStart
        : S.cardUnlocked;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Opacity(
        opacity: locked ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isCurrent ? p.accent : p.inkMuted.withValues(alpha: 0.25),
              width: isCurrent ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _CardPicture(id: card.id, width: 80),
                    if (locked)
                      const Icon(Icons.lock_outline, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.cardShort(card.name),
                      style: context.text.titleSmall,
                    ),
                    Text(
                      limit,
                      style: context.text.bodySmall?.copyWith(
                        color: p.inkMuted,
                      ),
                    ),
                    Text(
                      status,
                      style: context.text.bodySmall
                          ?.copyWith(
                            color: isCurrent ? p.accentInk : p.inkMuted,
                          )
                          .numbers,
                    ),
                  ],
                ),
              ),
              if (!locked && !isCurrent)
                Icon(Icons.check, color: p.income, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
