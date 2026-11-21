import 'dart:math' as math;

import 'command_result.dart';
import 'economy_config.dart';
import 'game_engine.dart';
import 'game_state.dart';

/// How far a goal is: [have] out of [need].
class GoalProgress {
  const GoalProgress(this.have, this.need);

  final int have;
  final int need;

  bool get reached => have >= need;
  double get fraction => need <= 0 ? 1 : math.min(1, have / need);
}

enum GoalStatus { claimable, inProgress, claimed }

extension Goals on GameEngine {
  GoalProgress goalProgress(GameState s, GoalDef g) {
    final have = switch (g.type) {
      GoalType.taps => s.taps,
      GoalType.businessesOwned => s.businesses.length,
      GoalType.businessLevel => s.level(g.businessId ?? ''),
      GoalType.totalLevels => s.businesses.values.fold(0, (a, b) => a + b),
      GoalType.propertyUnits => s.properties.values.fold(0, (a, b) => a + b),
      GoalType.incomePerSecond => incomePerSec(s),
      GoalType.netWorth => netWorth(s),
      GoalType.lifestyleOwned => s.lifestyle.length,
      GoalType.homeLevel => s.homeLevel,
    };
    return GoalProgress(have, g.target);
  }

  GoalStatus goalStatus(GameState s, GoalDef g) {
    if (s.claimedGoals.contains(g.id)) {
      return GoalStatus.claimed;
    }
    return goalProgress(s, g).reached
        ? GoalStatus.claimable
        : GoalStatus.inProgress;
  }

  int claimableGoals(GameState s) => config.goals
      .where((g) => goalStatus(s, g) == GoalStatus.claimable)
      .length;

  /// Collects every reached goal at once, as one command.
  CommandResult claimAllGoals(GameState s, DateTime now) {
    var total = 0;
    final ids = <String>[];
    for (final g in config.goals) {
      if (goalStatus(s, g) == GoalStatus.claimable) {
        total += g.rewardPaisa;
        ids.add(g.id);
      }
    }
    if (ids.isEmpty) {
      return const Failure(FailReason.goalNotReached);
    }
    return Success(
      s.copyWith(
        revision: s.revision + 1,
        cashPaisa: s.cashPaisa + total,
        claimedGoals: {...s.claimedGoals, ...ids},
      ),
      [
        for (final id in ids)
          LedgerEntry(
            type: LedgerType.goalReward,
            deltaPaisa: config.goal(id)!.rewardPaisa,
            reason: id,
            at: now,
          ),
      ],
    );
  }

  /// Total reward waiting in reached, unclaimed goals.
  int claimableRewardPaisa(GameState s) => config.goals
      .where((g) => goalStatus(s, g) == GoalStatus.claimable)
      .fold(0, (a, g) => a + g.rewardPaisa);

  /// Collects a reached goal's reward once.
  CommandResult claimGoal(GameState s, String id, DateTime now) {
    final g = config.goal(id);
    if (g == null) {
      return const Failure(FailReason.unknownId);
    }
    if (s.claimedGoals.contains(id)) {
      return const Failure(FailReason.alreadyClaimed);
    }
    if (!goalProgress(s, g).reached) {
      return const Failure(FailReason.goalNotReached);
    }
    return Success(
      s.copyWith(
        revision: s.revision + 1,
        cashPaisa: s.cashPaisa + g.rewardPaisa,
        claimedGoals: {...s.claimedGoals, id},
      ),
      [
        LedgerEntry(
          type: LedgerType.goalReward,
          deltaPaisa: g.rewardPaisa,
          reason: id,
          at: now,
        ),
      ],
    );
  }
}
