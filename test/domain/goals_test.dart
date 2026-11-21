import 'dart:convert';
import 'dart:io';

import 'package:desi_business_empire/core/money.dart';
import 'package:desi_business_empire/data/local/game_state_codec.dart';
import 'package:desi_business_empire/domain/economy/command_result.dart';
import 'package:desi_business_empire/domain/economy/economy_config.dart';
import 'package:desi_business_empire/domain/economy/game_engine.dart';
import 'package:desi_business_empire/domain/economy/game_state.dart';
import 'package:desi_business_empire/domain/economy/goals.dart';
import 'package:flutter_test/flutter_test.dart';

final config = EconomyConfig.parse(
  File('assets/config/economy.json').readAsStringSync(),
);
final engine = GameEngine(config);
final t0 = DateTime.utc(2026, 1, 1, 12);

GameState newGame() => GameState.newGame(config, t0);
GoalDef goal(String id) => config.goal(id)!;

void main() {
  test('config has goals and money targets are in paisa', () {
    expect(config.goals.length, greaterThanOrEqualTo(30));
    expect(goal('income100').target, rupees(100));
    expect(goal('work10').target, 10);
    expect(goal('samosa25').businessId, 'samosa');
  });

  test('progress counts taps, levels, units, income and net worth', () {
    final s = newGame().copyWith(
      taps: 7,
      businesses: {'samosa': 12, 'chai': 3},
      invested: {'samosa': 100000, 'chai': 600000},
      properties: {'plot': 2},
    );
    expect(engine.goalProgress(s, goal('work10')).have, 7);
    expect(engine.goalProgress(s, goal('own3')).have, 2);
    expect(engine.goalProgress(s, goal('samosa10')).reached, isTrue);
    expect(engine.goalProgress(s, goal('levels50')).have, 15);
    expect(engine.goalProgress(s, goal('units10')).have, 2);
    expect(
      engine.goalProgress(s, goal('income100')).have,
      engine.incomePerSec(s),
    );
    expect(engine.goalProgress(s, goal('worth1lakh')).have, engine.netWorth(s));
  });

  test('a reached goal pays once, an unreached one not at all', () {
    var s = newGame().copyWith(taps: 10);
    expect(engine.goalStatus(s, goal('work10')), GoalStatus.claimable);
    expect(engine.claimableGoals(s), 1);
    final r = engine.claimGoal(s, 'work10', t0) as Success;
    expect(r.state.cashPaisa, s.cashPaisa + rupees(100));
    expect(r.entries.single.type, LedgerType.goalReward);
    expect(r.state.revision, s.revision + 1);
    s = r.state;
    expect(engine.goalStatus(s, goal('work10')), GoalStatus.claimed);
    expect(
      (engine.claimGoal(s, 'work10', t0) as Failure).reason,
      FailReason.alreadyClaimed,
    );
    expect(
      (engine.claimGoal(s, 'work100', t0) as Failure).reason,
      FailReason.goalNotReached,
    );
    expect(
      (engine.claimGoal(s, 'nope', t0) as Failure).reason,
      FailReason.unknownId,
    );
  });

  test(
    'claimed goals survive a save round trip, and older saves have none',
    () {
      final s = newGame().copyWith(claimedGoals: {'work10', 'own1'});
      final json = jsonEncode(encodeGameState(s));
      final back = decodeGameState(
        jsonDecode(json) as Map<String, Object?>,
        config,
      );
      expect(back.claimedGoals, {'work10', 'own1'});

      final old = encodeGameState(newGame())..remove('claimedGoals');
      expect(decodeGameState(old, config).claimedGoals, isEmpty);
    },
  );
}
