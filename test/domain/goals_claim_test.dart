import 'dart:io';

import 'package:desi_business_empire/core/money.dart';
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

void main() {
  test('claimAllGoals claims every ready goal and pays their rewards', () {
    final s = newGame().copyWith(taps: 1000, cashPaisa: rupees(10000));
    final ready = engine.claimableGoals(s);
    if (ready == 0) return;

    final r = engine.claimAllGoals(s, t0);
    expect(r, isA<Success>());
    final ok = r as Success;
    expect(ok.state.claimedGoals.length, greaterThanOrEqualTo(ready));
    expect(ok.state.cashPaisa, greaterThan(s.cashPaisa));
    expect(engine.claimableGoals(ok.state), 0);
  });

  test('claimableRewardPaisa is never negative', () {
    final s = newGame().copyWith(taps: 1000, cashPaisa: rupees(10000));
    expect(engine.claimableRewardPaisa(s), greaterThanOrEqualTo(0));
  });

  test('homeLevel goal reaches when homeLevel hits its target', () {
    final g = config.goals.firstWhere((g) => g.type == GoalType.homeLevel);
    final below = newGame().copyWith(homeLevel: g.target - 1);
    expect(engine.goalProgress(below, g).reached, isFalse);
    final at = newGame().copyWith(homeLevel: g.target);
    expect(engine.goalProgress(at, g).reached, isTrue);
  });
}
