import 'dart:io';

import 'package:desi_business_empire/app/prefs.dart';
import 'package:desi_business_empire/domain/economy/command_result.dart';
import 'package:desi_business_empire/domain/economy/economy_config.dart';
import 'package:desi_business_empire/domain/economy/game_engine.dart';
import 'package:desi_business_empire/domain/economy/game_state.dart';
import 'package:desi_business_empire/features/onboarding/tutorial.dart';
import 'package:flutter_test/flutter_test.dart';

final config = EconomyConfig.parse(
  File('assets/config/economy.json').readAsStringSync(),
);
final engine = GameEngine(config);
final t0 = DateTime.utc(2026, 1, 1, 12);

GameState ok(CommandResult r) => (r as Success).state;

void main() {
  test('steps follow work, the first business and the first upgrade', () {
    var s = GameState.newGame(config, t0);
    var step = Tutorial.work;
    expect(advanceTutorial(step, s), Tutorial.work);

    s = ok(engine.work(s, t0));
    step = advanceTutorial(step, s);
    expect(step, Tutorial.buyBusiness);

    s = ok(engine.buyBusiness(s.copyWith(cashPaisa: 200000), 'samosa', t0));
    step = advanceTutorial(step, s);
    expect(step, Tutorial.upgrade);

    s = ok(engine.upgradeBusiness(s, 'samosa', t0));
    expect(advanceTutorial(step, s), Tutorial.done);
  });

  test('a returning player skips steps already done', () {
    final s = GameState.newGame(config, t0).copyWith(businesses: {'samosa': 5});
    expect(advanceTutorial(Tutorial.work, s), Tutorial.done);
  });

  test('welcome and done never move on their own', () {
    final s = GameState.newGame(config, t0).copyWith(taps: 3);
    expect(advanceTutorial(Tutorial.welcome, s), Tutorial.welcome);
    expect(advanceTutorial(Tutorial.done, s), Tutorial.done);
  });
}
