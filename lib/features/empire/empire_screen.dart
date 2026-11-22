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
        AppSpacing.s16,
        AppSpacing.s20,
        AppSpacing.s32,
      ),
      children: [
        const TutorialCoach(),
        _BankCard(engine: engine, state: s),
        const SizedBox(height: AppSpacing.s16),
        _WorkButton(
          pay: formatShort(engine.config.workPayPaisa),
          enabled: !session.saveFailed,
          onTap: () =>
              runCommand(context, ref, (state, now) => engine.work(state, now)),
        ),
        const SizedBox(height: AppSpacing.s12),
        NextMoveCard(engine: engine, state: s, blocked: session.saveFailed),
        const SizedBox(height: AppSpacing.s24),
        const SectionTitle(S.yourEmpire),
        _Overview(engine: engine, state: s),
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

/// Four quiet rows that lead to the other tabs.
class _Overview extends StatelessWidget {
  const _Overview({required this.engine, required this.state});

  final GameEngine engine;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final c = engine.config;
    final p = context.palette;
    final units = s.properties.values.fold(0, (a, b) => a + b);
    var rent = 0;
    for (final prop in c.properties) {
      rent += prop.rentPaisaPerSec * s.owned(prop.id);
    }
    final vehicles = c.lifestyle.where((i) => i.kind == 'vehicle');
    final ownedVehicles = vehicles.where((i) => s.lifestyle.contains(i.id));
    final home = engine.currentHome(s);

    final rows = [
      (
        Icons.storefront,
        'kiryana',
        S.tabBusinesses,
        S.rowBusinesses(s.businesses.length, c.businesses.length),
        '/businesses',
      ),
      (
        Icons.apartment,
        'plaza',
        S.property,
        S.rowProperty(units, formatShort(rent)),
        '/property?tab=property',
      ),
      (
        Icons.directions_car,
        'sportscar',
        S.tabVehicles,
        S.rowVehicles(ownedVehicles.length, vehicles.length),
        '/property?tab=vehicles',
      ),
      (
        Icons.receipt_long,
        'tax',
        S.tax,
        '${S.taxDue}: ${formatShort(s.taxDuePaisa)}',
        '/more/wallet',
      ),
      if (home != null)
        (
          iconFor(home.id),
          home.id,
          S.tabHome,
          S.rowHome(home.name, home.incomeBonusPercent),
          '/property?tab=home',
        ),
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, (icon, photo, title, subtitle, path))
              in rows.indexed) ...[
            if (i > 0) const Divider(indent: AppSpacing.s16),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s4,
              ),
              leading: PhotoThumb(
                id: photo,
                size: 44,
                fallback: SignTile(icon: icon, size: 40),
              ),
              title: Text(title, style: context.text.titleSmall),
              subtitle: Text(
                subtitle,
                style: context.text.bodySmall
                    ?.copyWith(color: p.inkMuted)
                    .numbers,
              ),
              trailing: Icon(Icons.chevron_right, color: p.inkMuted),
              onTap: () => context.go(path),
            ),
          ],
        ],
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

/// The player's bank card, drawn like a real one: logo, card name, net
/// worth, what it lets them buy, and how far the next card is.
class _BankCard extends StatelessWidget {
  const _BankCard({required this.engine, required this.state});

  final GameEngine engine;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final card = engine.card(state);
    final next = engine.nextCard(state);
    final worth = engine.netWorth(state);
    final color = _cardColor(card.id);
    final dark = ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
    final on = dark ? Colors.white : const Color(0xFF14181D);
    final span = next == null ? 1 : next.netWorthPaisa - card.netWorthPaisa;
    final progress = next == null
        ? 1.0
        : ((worth - card.netWorthPaisa) / span).clamp(0.0, 1.0);
    final small = context.text.bodySmall?.copyWith(color: on);
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
        child: AspectRatio(
          aspectRatio: 1.7,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.s20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card + 4),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(color, Colors.white, 0.18)!,
                  color,
                  Color.lerp(color, Colors.black, 0.22)!,
                ],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 32,
                        height: 32,
                        errorBuilder: (_, _, _) => const SizedBox(width: 32),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      card.name.toUpperCase(),
                      style: context.text.titleMedium?.copyWith(
                        color: on,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  S.netWorth,
                  style: small?.copyWith(color: on.withValues(alpha: 0.8)),
                ),
                Text(
                  formatShort(worth),
                  style: context.text.headlineMedium
                      ?.copyWith(color: on, fontWeight: FontWeight.w700)
                      .numbers,
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(limit, style: small),
                const SizedBox(height: AppSpacing.s12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    color: on,
                    backgroundColor: on.withValues(alpha: 0.25),
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  next == null
                      ? S.cardTop
                      : S.cardNext(
                          next.name,
                          formatShort(next.netWorthPaisa),
                          formatShort(worth),
                        ),
                  style: small?.numbers,
                ),
              ],
            ),
          ),
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
    final color = _cardColor(card.id);
    final on = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : const Color(0xFF14181D);
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
              Container(
                width: 64,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  locked ? Icons.lock_outline : Icons.credit_card,
                  color: on,
                  size: 20,
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
