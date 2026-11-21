import 'dart:io';

import 'package:desi_business_empire/core/money.dart';
import 'package:desi_business_empire/domain/economy/economy_config.dart';
import 'package:desi_business_empire/domain/economy/game_engine.dart';
import 'package:desi_business_empire/domain/economy/game_state.dart';
import 'package:desi_business_empire/domain/economy/settlement.dart';
import 'package:flutter_test/flutter_test.dart';

final config = EconomyConfig.parse(
  File('assets/config/economy.json').readAsStringSync(),
);
final engine = GameEngine(config);
final t0 = DateTime.utc(2026, 1, 1, 12);

DateTime at(Duration d) => t0.add(d);

/// Samosa thela at level 1 (Rs 2/s) plus one plot (Rs 45/s): Rs 47/s.
GameState owner() => GameState.newGame(config, t0).copyWith(
  cashPaisa: 0,
  businesses: {'samosa': 1},
  invested: {'samosa': 100000},
  properties: {'plot': 1},
);

void main() {
  test('pays income per second while the app is open', () {
    final r = engine.advanceTo(
      owner(),
      at(const Duration(minutes: 10)),
      foreground: true,
    );
    expect(r.earnedPaisa, rupees(47) * 600);
    expect(r.state.cashPaisa, rupees(47) * 600);
    expect(r.state.totalEarnedPaisa, rupees(47) * 600);
    expect(r.entries.single.deltaPaisa, rupees(47) * 600);
  });

  test('offline time is capped at 4 hours', () {
    final r = engine.advanceTo(
      owner(),
      at(const Duration(hours: 10)),
      foreground: false,
    );
    expect(r.credited, const Duration(hours: 4));
    expect(r.capped, isTrue);
    expect(r.earnedPaisa, rupees(47) * 4 * 3600);
    expect(r.state.lastSettledAt, at(const Duration(hours: 10)));
  });

  test('a clock moved backwards pays nothing', () {
    final s = owner();
    final r = engine.advanceTo(
      s,
      at(const Duration(hours: -3)),
      foreground: false,
    );
    expect(r.clockWentBack, isTrue);
    expect(identical(r.state, s), isTrue);
  });

  test('settling twice for the same time pays once', () {
    final end = at(const Duration(minutes: 30));
    final first = engine.advanceTo(owner(), end, foreground: false);
    final again = engine.advanceTo(first.state, end, foreground: false);
    expect(again.earnedPaisa, 0);
    expect(identical(again.state, first.state), isTrue);
  });

  test('leftover milliseconds wait for the next settlement', () {
    final r = engine.advanceTo(
      owner(),
      at(const Duration(seconds: 2, milliseconds: 700)),
      foreground: true,
    );
    expect(r.state.lastSettledAt, at(const Duration(seconds: 2)));
    expect(r.earnedPaisa, rupees(47) * 2);
  });

  test('nothing owned means nothing earned, but time still moves on', () {
    final s = GameState.newGame(config, t0);
    final r = engine.advanceTo(
      s,
      at(const Duration(minutes: 5)),
      foreground: true,
    );
    expect(r.earnedPaisa, 0);
    expect(r.entries, isEmpty);
    expect(r.state.lastSettledAt, at(const Duration(minutes: 5)));
  });
}
