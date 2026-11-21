import 'dart:io';

import 'package:desi_business_empire/core/money.dart';
import 'package:desi_business_empire/domain/economy/command_result.dart';
import 'package:desi_business_empire/domain/economy/economy_config.dart';
import 'package:desi_business_empire/domain/economy/game_engine.dart';
import 'package:desi_business_empire/domain/economy/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

final config = EconomyConfig.parse(
  File('assets/config/economy.json').readAsStringSync(),
);
final engine = GameEngine(config);
final t0 = DateTime.utc(2026, 1, 1, 12);

GameState newGame() => GameState.newGame(config, t0);

void main() {
  test('config has 6 homes, first is free with no bonus', () {
    expect(config.homes.length, 6);
    expect(config.homes.first.pricePaisa, 0);
    expect(config.homes.first.incomeBonusPercent, 0);
  });

  test('home prices and bonuses are strictly ascending', () {
    for (var i = 1; i < config.homes.length; i++) {
      expect(
        config.homes[i].pricePaisa,
        greaterThan(config.homes[i - 1].pricePaisa),
      );
      expect(
        config.homes[i].incomeBonusPercent,
        greaterThan(config.homes[i - 1].incomeBonusPercent),
      );
    }
  });

  test('new game starts at the free rented room', () {
    final s = newGame();
    expect(s.homeLevel, 0);
    expect(engine.currentHome(s)?.id, 'room');
  });

  test('moveHome succeeds with enough cash and logs a moveHome entry', () {
    final cost = config.homes[1].pricePaisa;
    final s = newGame().copyWith(cashPaisa: cost + rupees(1));
    final r = engine.moveHome(s, t0);
    expect(r, isA<Success>());
    final ok = r as Success;
    expect(ok.state.homeLevel, 1);
    expect(ok.state.cashPaisa, rupees(1));
    expect(ok.entries.last.type, LedgerType.moveHome);
  });

  test('moveHome fails when funds are insufficient', () {
    final cost = config.homes[1].pricePaisa;
    final s = newGame().copyWith(cashPaisa: cost - 1);
    final r = engine.moveHome(s, t0);
    expect(r, isA<Failure>());
    expect((r as Failure).reason, FailReason.insufficientFunds);
  });

  test('moveHome fails at the top home', () {
    final s = newGame().copyWith(
      homeLevel: config.homes.length - 1,
      cashPaisa: rupees(1000000000),
    );
    final r = engine.moveHome(s, t0);
    expect(r, isA<Failure>());
    expect((r as Failure).reason, FailReason.maxLevel);
  });

  test('home bonus raises incomePerSec', () {
    final base = newGame().copyWith(businesses: {'samosa': 1});
    final s = base.copyWith(homeLevel: 2);
    expect(engine.homeBonusPercent(s), greaterThan(0));
    expect(engine.incomePerSec(s), greaterThan(engine.incomePerSec(base)));
  });
}
