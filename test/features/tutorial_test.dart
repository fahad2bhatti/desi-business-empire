import 'dart:io';

import 'package:desi_business_empire/app/prefs.dart';
import 'package:desi_business_empire/domain/economy/command_result.dart';
import 'package:desi_business_empire/domain/economy/economy_config.dart';
import 'package:desi_business_empire/domain/economy/game_engine.dart';
import 'package:desi_business_empire/domain/economy/game_state.dart';
import 'package:desi_business_empire/features/onboarding/tutorial.dart';
import 'package:flutter_test/flutter_test.dart';

final config = EconomyConfig.parse(
  File('assets/config/economy_v0.json').readAsStringSync(),
);
final engine = GameEngine(config);
final t0 = DateTime.utc(2026, 1, 1, 12);

GameState ok(CommandResult r) => (r as Success).state;

void main() {
  test('steps follow the first sale and the first helper', () {
    var s = GameState.newGame(config, t0);
    var step = Tutorial.buyStock;
    expect(advanceTutorial(step, s, 'stall'), Tutorial.buyStock);

    s = ok(engine.buyStock(s, 'stall', 'samosa', 10, t0));
    step = advanceTutorial(step, s, 'stall');
    expect(step, Tutorial.cook);

    s = ok(engine.startBatch(s, 'stall', 'samosa', t0));
    step = advanceTutorial(step, s, 'stall');
    expect(step, Tutorial.sell);

    final later = t0.add(const Duration(seconds: 30));
    s = ok(engine.serve(s, 'stall', 'samosa', later));
    step = advanceTutorial(step, s, 'stall');
    expect(step, Tutorial.hireHelper);

    s = ok(engine.hire(s, 'stall', StaffRole.helper, later));
    expect(advanceTutorial(step, s, 'stall'), Tutorial.done);
  });

  test('a returning player skips steps already done', () {
    var s = GameState.newGame(config, t0);
    s = s.withStage(
      'stall',
      s.stages['stall']!.copyWith(sold: 50, staff: {StaffRole.helper: 1}),
    );
    expect(advanceTutorial(Tutorial.buyStock, s, 'stall'), Tutorial.done);
  });

  test('welcome and done never move on their own', () {
    final s = GameState.newGame(config, t0);
    expect(advanceTutorial(Tutorial.welcome, s, 'stall'), Tutorial.welcome);
    expect(advanceTutorial(Tutorial.done, s, 'stall'), Tutorial.done);
  });
}
