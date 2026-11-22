import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_controller.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/strings.dart';
import '../../domain/economy/economy_config.dart';
import '../../domain/economy/game_engine.dart';
import '../../domain/economy/game_state.dart';
import '../../domain/economy/goals.dart';
import '../common/run_command.dart';
import '../common/visuals.dart';
import '../common/widgets.dart';

String goalTitle(GoalDef g, EconomyConfig c) => switch (g.type) {
  GoalType.taps => S.goalTaps(g.target),
  GoalType.businessesOwned => S.goalOwn(g.target),
  GoalType.businessLevel => S.goalLevel(
    c.business(g.businessId ?? '')?.name ?? '',
    g.target,
  ),
  GoalType.totalLevels => S.goalTotalLevels(g.target),
  GoalType.propertyUnits => S.goalUnits(g.target),
  GoalType.incomePerSecond => S.goalIncome(formatShort(g.target)),
  GoalType.netWorth => S.goalWorth(formatShort(g.target)),
  GoalType.lifestyleOwned => S.goalLifestyle(g.target),
  GoalType.homeLevel => S.goalHome(
    g.target < c.homes.length ? c.homes[g.target].name : '',
  ),
};

/// Photo shown beside a goal; falls back to [goalIcon].
String goalPhoto(GoalDef g, EconomyConfig c) => switch (g.type) {
  GoalType.taps => 'goal_taps',
  GoalType.businessesOwned => 'kiryana',
  GoalType.businessLevel => g.businessId ?? '',
  GoalType.totalLevels => 'goal_levels',
  GoalType.propertyUnits => 'plaza',
  GoalType.incomePerSecond => 'goal_income',
  GoalType.netWorth => 'goal_worth',
  GoalType.lifestyleOwned => 'sportscar',
  GoalType.homeLevel =>
    g.target < c.homes.length ? c.homes[g.target].id : 'familyhome',
};

IconData goalIcon(GoalDef g) => switch (g.type) {
  GoalType.taps => Icons.touch_app,
  GoalType.businessesOwned => Icons.storefront,
  GoalType.businessLevel => iconFor(g.businessId ?? ''),
  GoalType.totalLevels => Icons.trending_up,
  GoalType.propertyUnits => Icons.apartment,
  GoalType.incomePerSecond => Icons.bolt,
  GoalType.netWorth => Icons.account_balance,
  GoalType.lifestyleOwned => Icons.directions_car,
  GoalType.homeLevel => Icons.home,
};

/// Progress text that reads well for counts and money alike.
String progressText(GoalDef g, GoalProgress p) {
  final have = p.have > p.need ? p.need : p.have;
  return moneyGoalTypes.contains(g.type)
      ? '${formatShort(have)} / ${formatShort(p.need)}'
      : '$have / ${p.need}';
}

/// The unclaimed goal closest to done, for the Empire tab.
GoalDef? nextGoal(GameEngine engine, GameState s) {
  GoalDef? best;
  var bestFraction = -1.0;
  for (final g in engine.config.goals) {
    if (s.claimedGoals.contains(g.id)) {
      continue;
    }
    final f = engine.goalProgress(s, g).fraction;
    if (f > bestFraction) {
      bestFraction = f;
      best = g;
    }
  }
  return best;
}

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider).requireValue;
    final engine = ref.read(gameControllerProvider.notifier).engine;
    final s = session.state;
    final goals = engine.config.goals;
    final ready = goals
        .where((g) => engine.goalStatus(s, g) == GoalStatus.claimable)
        .toList();
    final open =
        goals
            .where((g) => engine.goalStatus(s, g) == GoalStatus.inProgress)
            .toList()
          ..sort(
            (a, b) => engine
                .goalProgress(s, b)
                .fraction
                .compareTo(engine.goalProgress(s, a).fraction),
          );
    final done = goals
        .where((g) => engine.goalStatus(s, g) == GoalStatus.claimed)
        .toList();
    final p = context.palette;

    Widget card(GoalDef g) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: GoalCard(
        goal: g,
        engine: engine,
        state: s,
        blocked: session.saveFailed,
      ),
    );

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
                S.goalsIntro,
                style: context.text.bodyMedium?.copyWith(color: p.inkMuted),
              ),
            ),
            Text(
              S.goalsDone(done.length, goals.length),
              style: context.text.bodySmall
                  ?.copyWith(color: p.inkMuted)
                  .numbers,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        ProgressBar(value: goals.isEmpty ? 1 : done.length / goals.length),
        const SizedBox(height: AppSpacing.s24),
        if (ready.isNotEmpty) ...[
          FocusCard(
            icon: Icons.emoji_events,
            photoId: 'goal_trophy',
            title: S.goalsReady(ready.length),
            detail: S.focusWaiting(formatShort(engine.claimableRewardPaisa(s))),
            actionLabel: S.collectAll(
              formatShort(engine.claimableRewardPaisa(s)),
            ),
            onAction: session.saveFailed
                ? null
                : () => runCommand(
                    context,
                    ref,
                    (st, now) => engine.claimAllGoals(st, now),
                    successText: S.collected(
                      formatShort(engine.claimableRewardPaisa(s)),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.s24),
          const SectionTitle(S.readyToClaim),
          for (final g in ready) card(g),
          const SizedBox(height: AppSpacing.s12),
        ],
        if (open.isNotEmpty) ...[
          const SectionTitle(S.inProgress),
          for (final g in open) card(g),
          const SizedBox(height: AppSpacing.s12),
        ],
        if (done.isNotEmpty) ...[
          const SectionTitle(S.completed),
          for (final g in done) card(g),
        ],
      ],
    );
  }
}

class GoalCard extends ConsumerWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.engine,
    required this.state,
    required this.blocked,
  });

  final GoalDef goal;
  final GameEngine engine;
  final GameState state;
  final bool blocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final status = engine.goalStatus(state, goal);
    final progress = engine.goalProgress(state, goal);
    final reward = formatShort(goal.rewardPaisa);
    final claimed = status == GoalStatus.claimed;
    final muted = context.text.bodySmall?.copyWith(color: p.inkMuted);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SignTile(
                  icon: goalIcon(goal),
                  artId: goalPhoto(goal, engine.config),
                  dimmed: claimed,
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goalTitle(goal, engine.config),
                        style: context.text.titleSmall?.copyWith(
                          color: claimed ? p.inkMuted : p.ink,
                        ),
                      ),
                      Text(
                        S.reward(reward),
                        style: context.text.bodySmall
                            ?.copyWith(color: claimed ? p.inkMuted : p.income)
                            .numbers,
                      ),
                    ],
                  ),
                ),
                if (claimed) Icon(Icons.check_circle, color: p.income),
              ],
            ),
            if (status == GoalStatus.inProgress) ...[
              const SizedBox(height: AppSpacing.s12),
              Row(
                children: [
                  Expanded(
                    child: ProgressBar(
                      value: progress.fraction,
                      label: goalTitle(goal, engine.config),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Text(progressText(goal, progress), style: muted.numbers),
                ],
              ),
            ],
            if (status == GoalStatus.claimable) ...[
              const SizedBox(height: AppSpacing.s12),
              FilledButton.tonal(
                onPressed: blocked
                    ? null
                    : () => runCommand(
                        context,
                        ref,
                        (s, now) => engine.claimGoal(s, goal.id, now),
                        successText: S.collected(reward),
                      ),
                child: Text(S.claimFor(reward)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
