import 'dart:io';

import 'package:desi_business_empire/core/money.dart';
import 'package:desi_business_empire/domain/economy/advisor.dart';
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
  test('nextMove returns a move on a fresh game with cash', () {
    final s = newGame().copyWith(cashPaisa: rupees(5000));
    expect(engine.nextMove(s), isNotNull);
  });

  test('nextMove picks claimGoals first when a reward is waiting', () {
    final s = newGame().copyWith(taps: 1000, cashPaisa: rupees(10000));
    if (engine.claimableRewardPaisa(s) > 0) {
      expect(engine.nextMove(s)!.kind, MoveKind.claimGoals);
    }
  });

  test('candidateMoves is not empty for a funded game', () {
    final s = newGame().copyWith(cashPaisa: rupees(10000000));
    expect(engine.candidateMoves(s), isNotEmpty);
  });

  test('secondsUntil is 0 when already affordable', () {
    final s = newGame().copyWith(cashPaisa: rupees(100000));
    expect(engine.secondsUntil(s, rupees(1)), 0);
  });

  test('secondsUntil is null or positive with no cash and no income', () {
    final s = newGame().copyWith(cashPaisa: 0);
    final wait = engine.secondsUntil(s, rupees(10000));
    expect(wait == null || wait > 0, isTrue);
  });
}
