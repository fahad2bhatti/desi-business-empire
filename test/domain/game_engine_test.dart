import 'dart:io';
import 'dart:math';

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
GameState withCash(GameState s, int pkr) => s.copyWith(cashPaisa: rupees(pkr));

GameState ok(CommandResult r) {
  expect(
    r,
    isA<Success>(),
    reason: r is Failure ? 'failed: ${r.reason}' : null,
  );
  return (r as Success).state;
}

Failure expectFail(CommandResult r, FailReason reason) {
  expect(r, isA<Failure>());
  final f = r as Failure;
  expect(f.reason, reason);
  return f;
}

BusinessDef biz(String id) => config.business(id)!;

void main() {
  test('new game starts with Rs 500 and nothing owned', () {
    final s = newGame();
    expect(s.cashPaisa, 50000);
    expect(s.businesses, isEmpty);
    expect(engine.incomePerSec(s), 0);
  });

  test('work pays Rs 25 per tap and counts taps', () {
    final r = engine.work(newGame(), t0) as Success;
    expect(r.state.cashPaisa, 50000 + 2500);
    expect(r.state.taps, 1);
    expect(r.state.revision, 1);
    expect(r.entries.single.type, LedgerType.work);
  });

  group('businesses', () {
    test('buying needs the full price, sets level 1 and starts income', () {
      final f = expectFail(
        engine.buyBusiness(newGame(), 'samosa', t0),
        FailReason.insufficientFunds,
      );
      expect(f.neededPaisa, 100000);
      expect(f.availablePaisa, 50000);
      final s = ok(engine.buyBusiness(withCash(newGame(), 1000), 'samosa', t0));
      expect(s.cashPaisa, 0);
      expect(s.level('samosa'), 1);
      expect(s.invested['samosa'], 100000);
      expect(engine.incomePerSec(s), 200);
      expectFail(
        engine.buyBusiness(withCash(s, 5000), 'samosa', t0),
        FailReason.alreadyOwned,
      );
      expectFail(engine.buyBusiness(s, 'pizza', t0), FailReason.unknownId);
    });

    test('income grows with level and doubles at milestones', () {
      final b = biz('samosa');
      expect(engine.businessIncome(b, 0), 0);
      expect(engine.businessIncome(b, 1), 200);
      expect(engine.businessIncome(b, 24), 200 * 24);
      expect(engine.businessIncome(b, 25), 200 * 25 * 2);
      expect(engine.businessIncome(b, 100), 200 * 100 * 16);
      expect(engine.nextMilestone(24)!.level, 25);
      expect(engine.nextMilestone(100), isNull);
    });

    test('upgrade cost follows price x 0.5 x 1.15^(level-1)', () {
      final b = biz('samosa');
      expect(engine.upgradeCost(b, 1), 50000);
      expect(engine.upgradeCost(b, 2), 57500);
      expect(engine.upgradeCost(b, 10), (100000 * 0.5 * pow(1.15, 9)).round());
    });

    test('costs never overflow at the top end', () {
      final b = biz('factory');
      expect(engine.upgradeCost(b, 99), lessThanOrEqualTo(maxCostPaisa));
      expect(engine.upgradeCost(b, 99), greaterThan(0));
    });

    test('upgrade spends cash, raises the level and tracks investment', () {
      var s = ok(engine.buyBusiness(withCash(newGame(), 1000), 'samosa', t0));
      expectFail(
        engine.upgradeBusiness(s, 'samosa', t0),
        FailReason.insufficientFunds,
      );
      s = ok(engine.upgradeBusiness(withCash(s, 500), 'samosa', t0));
      expect(s.level('samosa'), 2);
      expect(s.cashPaisa, 0);
      expect(s.invested['samosa'], 150000);
      expectFail(
        engine.upgradeBusiness(newGame(), 'samosa', t0),
        FailReason.notOwned,
      );
    });

    test('upgrade max buys as many levels as the cash allows', () {
      var s = ok(engine.buyBusiness(withCash(newGame(), 1000), 'samosa', t0));
      s = ok(
        engine.upgradeBusiness(withCash(s, 1100), 'samosa', t0, times: 100),
      );
      // 500 + 575 = 1075 fits, the next 661.25 does not.
      expect(s.level('samosa'), 3);
      expect(s.cashPaisa, rupees(1100) - 50000 - 57500);
    });

    test('max level stops upgrades', () {
      final s = newGame().copyWith(
        businesses: {'samosa': config.maxLevel},
        invested: {'samosa': 1},
      );
      expectFail(
        engine.upgradeBusiness(withCash(s, 1000000), 'samosa', t0),
        FailReason.maxLevel,
      );
    });

    test('selling returns half of everything spent and stops the income', () {
      var s = ok(engine.buyBusiness(withCash(newGame(), 1500), 'samosa', t0));
      s = ok(engine.upgradeBusiness(s, 'samosa', t0));
      final r = engine.sellBusiness(s, 'samosa', t0) as Success;
      expect(r.state.cashPaisa, s.cashPaisa + 75000);
      expect(r.state.businesses, isEmpty);
      expect(r.state.invested, isEmpty);
      expect(engine.incomePerSec(r.state), 0);
      expectFail(
        engine.sellBusiness(r.state, 'samosa', t0),
        FailReason.notOwned,
      );
    });
  });

  group('property', () {
    test('each unit costs 15% more and pays rent', () {
      final plot = config.property('plot')!;
      expect(engine.propertyPrice(plot, 0), 15000000);
      expect(engine.propertyPrice(plot, 1), 17250000);
      var s = ok(engine.buyProperty(withCash(newGame(), 400000), 'plot', t0));
      s = ok(engine.buyProperty(s, 'plot', t0));
      expect(s.owned('plot'), 2);
      expect(engine.incomePerSec(s), 2 * 4500);
      expect(s.cashPaisa, rupees(400000) - 15000000 - 17250000);
    });

    test('selling one unit returns 70% of what that unit cost', () {
      var s = ok(engine.buyProperty(withCash(newGame(), 400000), 'plot', t0));
      s = ok(engine.buyProperty(s, 'plot', t0));
      final r = engine.sellProperty(s, 'plot', t0) as Success;
      expect(r.state.cashPaisa - s.cashPaisa, (17250000 * 0.7).round());
      expect(r.state.owned('plot'), 1);
      final last = engine.sellProperty(r.state, 'plot', t0) as Success;
      expect(last.state.properties, isEmpty);
    });

    test('cannot own more than the maximum', () {
      final s = newGame().copyWith(
        properties: {'plot': 10},
        cashPaisa: rupees(100000000),
      );
      expectFail(engine.buyProperty(s, 'plot', t0), FailReason.maxOwned);
    });
  });

  test('net worth counts cash and resale value', () {
    var s = ok(engine.buyBusiness(withCash(newGame(), 1000), 'samosa', t0));
    s = withCash(s, 200);
    expect(engine.netWorth(s), rupees(200) + 50000);
  });

  test('random play never makes money negative and the ledger explains every change', () {
    final rnd = Random(7);
    var s = withCash(newGame(), 5000);
    final ids = config.businesses.take(4).map((b) => b.id).toList();
    var successes = 0;
    for (var i = 0; i < 4000; i++) {
      final id = ids[rnd.nextInt(ids.length)];
      final CommandResult r = switch (rnd.nextInt(6)) {
        0 => engine.work(s, t0),
        1 => engine.buyBusiness(s, id, t0),
        2 || 3 => engine.upgradeBusiness(s, id, t0, times: 1 + rnd.nextInt(5)),
        4 => engine.buyProperty(s, 'plot', t0),
        _ =>
          rnd.nextBool()
              ? engine.sellBusiness(s, id, t0)
              : engine.sellProperty(s, 'plot', t0),
      };
      if (r is Success) {
        expect(r.state.revision, s.revision + 1);
        expect(
          r.state.cashPaisa - s.cashPaisa,
          r.entries.fold<int>(0, (sum, e) => sum + e.deltaPaisa),
        );
        s = r.state;
        successes++;
      }
      expect(s.cashPaisa, greaterThanOrEqualTo(0));
    }
    expect(successes, greaterThan(600));
  });
}
