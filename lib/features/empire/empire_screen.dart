import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/game_controller.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/strings.dart';
import '../../domain/economy/advisor.dart';
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        AppSpacing.s16,
        AppSpacing.s20,
        AppSpacing.s32,
      ),
      children: [
        const TutorialCoach(),
        NextMoveCard(engine: engine, state: s, blocked: session.saveFailed),
        const SizedBox(height: AppSpacing.s12),
        _WorkButton(
          pay: formatShort(engine.config.workPayPaisa),
          enabled: !session.saveFailed,
          onTap: () =>
              runCommand(context, ref, (state, now) => engine.work(state, now)),
        ),
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
          for (final (i, (icon, photo, title, subtitle, path)) in rows.indexed) ...[
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
