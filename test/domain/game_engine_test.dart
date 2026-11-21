import 'dart:io';
import 'dart:math';

import 'package:desi_business_empire/core/money.dart';
import 'package:desi_business_empire/domain/economy/command_result.dart';
import 'package:desi_business_empire/domain/economy/economy_config.dart';
import 'package:desi_business_empire/domain/economy/game_engine.dart';
import 'package:desi_business_empire/domain/economy/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

final config = EconomyConfig.parse(File('assets/config/economy_v0.json').readAsStringSync());
final engine = GameEngine(config);
final t0 = DateTime.utc(2026, 1, 1, 12);

DateTime at(int seconds) => t0.add(Duration(seconds: seconds));

GameState newGame() => GameState.newGame(config, t0);

GameState ok(CommandResult r) {
  expect(r, isA<Success>(), reason: r is Failure ? 'failed: ${r.reason}' : null);
  return (r as Success).state;
}

Failure expectFail(CommandResult r, FailReason reason) {
  expect(r, isA<Failure>());
  final f = r as Failure;
  expect(f.reason, reason);
  return f;
}

GameState withCash(GameState s, int pkr) => s.copyWith(cashPaisa: rupees(pkr));

StageState stall(GameState s) => s.stages['stall']!;
LineState samosa(GameState s) => stall(s).lines['samosa']!;

void main() {
  test('new game starts with Rs 500 and only the stall open', () {
    final s = newGame();
    expect(s.cashPaisa, 50000);
    expect(s.revision, 0);
    expect(s.stages.keys, ['stall']);
    expect(samosa(s).stock, 0);
  });

  group('buyStock', () {
    test('deducts cost, adds stock, writes one ledger entry', () {
      final r = engine.buyStock(newGame(), 'stall', 'samosa', 10, t0) as Success;
      expect(r.state.cashPaisa, 50000 - 12000);
      expect(samosa(r.state).stock, 10);
      expect(r.state.revision, 1);
      expect(r.entries.single.deltaPaisa, -12000);
      expect(r.entries.single.type, LedgerType.stockPurchase);
    });

    test('refuses to spend below zero and reports needed vs available', () {
      final f = expectFail(engine.buyStock(newGame(), 'stall', 'samosa', 50, t0), FailReason.insufficientFunds);
      expect(f.neededPaisa, 60000);
      expect(f.availablePaisa, 50000);
    });

    test('respects storage and rejects bad quantities and ids', () {
      final rich = withCash(newGame(), 100000);
      expectFail(engine.buyStock(rich, 'stall', 'samosa', 301, t0), FailReason.storageFull);
      expectFail(engine.buyStock(rich, 'stall', 'samosa', 0, t0), FailReason.invalidQuantity);
      expectFail(engine.buyStock(rich, 'stall', 'pizza', 1, t0), FailReason.unknownId);
      expectFail(engine.buyStock(rich, 'takeaway', 'samosa', 1, t0), FailReason.stageLocked);
    });
  });

  group('cooking and selling', () {
    test('needs stock, cooks one batch at a time, finishes on time', () {
      var s = newGame();
      expectFail(engine.startBatch(s, 'stall', 'samosa', t0), FailReason.noStock);
      s = ok(engine.buyStock(s, 'stall', 'samosa', 10, t0));
      s = ok(engine.startBatch(s, 'stall', 'samosa', t0));
      expect(samosa(s).stock, 2);
      expect(samosa(s).batchSize, 8);
      expectFail(engine.startBatch(s, 'stall', 'samosa', at(10)), FailReason.batchInProgress);
      expect(samosa(engine.observe(s, at(29))).ready, 0);
      expect(samosa(engine.observe(s, at(30))).ready, 8);
    });

    test('a short batch uses what stock is left', () {
      var s = ok(engine.buyStock(newGame(), 'stall', 'samosa', 3, t0));
      s = ok(engine.startBatch(s, 'stall', 'samosa', t0));
      expect(samosa(s).batchSize, 3);
      expect(samosa(s).stock, 0);
    });

    test('serve needs a customer and a ready item, then pays the price', () {
      var s = ok(engine.buyStock(newGame(), 'stall', 'samosa', 8, t0));
      s = ok(engine.startBatch(s, 'stall', 'samosa', t0));
      expectFail(engine.serve(s, 'stall', 'samosa', t0), FailReason.noCustomer);
      expectFail(engine.serve(s, 'stall', 'samosa', at(10)), FailReason.nothingReady);
      final cashBefore = s.cashPaisa;
      final r = engine.serve(s, 'stall', 'samosa', at(30)) as Success;
      expect(r.state.cashPaisa, cashBefore + 3000);
      expect(stall(r.state).sold, 1);
      expect(samosa(r.state).ready, 7);
      expect(stall(r.state).queue, config.maxQueue - 1);
      expect(r.entries.single.type, LedgerType.sale);
    });
  });

  group('customers', () {
    test('arrive deterministically at 14 per minute and cap at maxQueue', () {
      final s = newGame();
      expect(stall(engine.observe(s, at(4))).queue, 0); // 0.93 customers
      expect(stall(engine.observe(s, at(5))).queue, 1); // 1.17 customers
      expect(stall(engine.observe(s, at(3600))).queue, config.maxQueue);
    });

    test('a clock moved backwards adds nobody and does not crash', () {
      expect(stall(engine.observe(newGame(), at(-600))).queue, 0);
    });

    test('carry keeps fractions so arrivals are not lost between commands', () {
      // 4 s gives 0.93 of a customer; a command at 4 s and the next at 8 s
      // must still add 1 customer in total (1.87), not 0 + 0.
      var s = withCash(newGame(), 1000);
      s = ok(engine.buyStock(s, 'stall', 'samosa', 1, at(4)));
      expect(stall(s).queue, 0);
      expect(stall(engine.observe(s, at(8))).queue, 1);
    });
  });

  group('upgrades', () {
    test('change price and batch size, and stop at the last level', () {
      var s = withCash(newGame(), 100000);
      final stallDef = config.stage('stall')!;
      final line = stallDef.line('samosa')!;
      s = ok(engine.buyUpgrade(s, 'masala', t0));
      expect(engine.lineStats(s, stallDef, line).pricePaisa, 3500);
      for (var i = 0; i < 3; i++) {
        s = ok(engine.buyUpgrade(s, 'kadhai', t0));
      }
      expect(engine.lineStats(s, stallDef, line).batch, 30);
      expectFail(engine.buyUpgrade(s, 'kadhai', t0), FailReason.maxLevel);
    });

    test('price multipliers round to whole paisa', () {
      final def = config.stage('takeaway')!;
      final s = newGame().copyWith(upgrades: {'chutney': 1});
      expect(engine.lineStats(s, def, def.line('samosa')!).pricePaisa, 3850);
    });

    test('cannot buy an upgrade for a locked stage or without money', () {
      expectFail(engine.buyUpgrade(withCash(newGame(), 100000), 'tawa', t0), FailReason.stageLocked);
      final f = expectFail(engine.buyUpgrade(newGame(), 'masala', t0), FailReason.insufficientFunds);
      expect(f.neededPaisa, 80000);
    });
  });

  group('staff', () {
    test('respects max count and the manager sales requirement', () {
      var s = withCash(newGame(), 10000);
      s = ok(engine.hire(s, 'stall', StaffRole.helper, t0));
      s = ok(engine.hire(s, 'stall', StaffRole.helper, t0));
      expectFail(engine.hire(s, 'stall', StaffRole.helper, t0), FailReason.maxStaff);
      final f = expectFail(engine.hire(s, 'stall', StaffRole.manager, t0), FailReason.requirementsNotMet);
      expect(f.unmet.single.need, 200);
      s = s.withStage('stall', stall(s).copyWith(sold: 200));
      s = ok(engine.hire(s, 'stall', StaffRole.manager, t0));
      expect(stall(s).staffCount(StaffRole.manager), 1);
    });
  });

  group('takeaway unlock', () {
    test('lists every unmet requirement', () {
      final f = expectFail(engine.unlockStage(withCash(newGame(), 20000), 'takeaway', t0),
          FailReason.requirementsNotMet);
      expect(f.unmet.map((u) => u.kind),
          containsAll([RequirementKind.sold, RequirementKind.upgrade, RequirementKind.staff]));
    });

    test('opens with all lines once requirements and money are there', () {
      var s = newGame().copyWith(upgrades: {'kadhai': 2});
      s = s.withStage('stall', stall(s).copyWith(sold: 300, staff: {StaffRole.manager: 1}));
      expectFail(engine.unlockStage(s, 'takeaway', t0), FailReason.insufficientFunds);
      s = ok(engine.unlockStage(withCash(s, 10000), 'takeaway', t0));
      expect(s.cashPaisa, 0);
      expect(s.stages['takeaway']!.lines.keys, containsAll(['samosa', 'pakora', 'roll']));
      expect(s.stages.containsKey('stall'), isTrue);
      expectFail(engine.unlockStage(s, 'takeaway', t0), FailReason.alreadyUnlocked);
    });
  });

  test('recovery work pays and then waits for its cooldown', () {
    var s = withCash(newGame(), 0);
    s = ok(engine.doWork(s, t0));
    expect(s.cashPaisa, 6000);
    final f = expectFail(engine.doWork(s, at(14)), FailReason.cooldown);
    expect(f.retryAt, at(15));
    s = ok(engine.doWork(s, at(15)));
    expect(s.cashPaisa, 12000);
  });

  test('random play never makes money or items negative', () {
    final rnd = Random(42);
    var s = newGame();
    var successes = 0;
    for (var i = 0; i < 5000; i++) {
      final now = at(i * 3);
      final CommandResult r = switch (rnd.nextInt(7)) {
        0 => engine.buyStock(s, 'stall', 'samosa', 1 + rnd.nextInt(20), now),
        1 => engine.startBatch(s, 'stall', 'samosa', now),
        2 || 3 => engine.serve(s, 'stall', 'samosa', now),
        4 => engine.buyUpgrade(s, config.upgrades[rnd.nextInt(5)].id, now),
        5 => engine.hire(s, 'stall', StaffRole.all[rnd.nextInt(3)], now),
        _ => engine.doWork(s, now),
      };
      if (r is Success) {
        expect(r.state.revision, s.revision + 1);
        expect(r.state.cashPaisa - s.cashPaisa,
            r.entries.fold<int>(0, (sum, e) => sum + e.deltaPaisa),
            reason: 'ledger must explain every cash change');
        s = r.state;
        successes++;
      }
      expect(s.cashPaisa, greaterThanOrEqualTo(0));
      expect(samosa(s).stock, greaterThanOrEqualTo(0));
      expect(samosa(s).ready, greaterThanOrEqualTo(0));
      expect(stall(s).queue, inInclusiveRange(0, config.maxQueue));
    }
    expect(successes, greaterThan(500));
  });
}
