import 'dart:io';

import 'package:desi_business_empire/core/money.dart';
import 'package:desi_business_empire/domain/economy/command_result.dart';
import 'package:desi_business_empire/domain/economy/economy_config.dart';
import 'package:desi_business_empire/domain/economy/game_engine.dart';
import 'package:desi_business_empire/domain/economy/game_state.dart';
import 'package:desi_business_empire/domain/economy/settlement.dart';
import 'package:flutter_test/flutter_test.dart';

final config = EconomyConfig.parse(File('assets/config/economy_v0.json').readAsStringSync());
final engine = GameEngine(config);
final t0 = DateTime.utc(2026, 1, 1, 12);

DateTime at(Duration d) => t0.add(d);

StageState stall(GameState s) => s.stages['stall']!;
LineState samosa(GameState s) => stall(s).lines['samosa']!;

/// Stall with the given staff and stock, nothing cooking, nobody waiting.
GameState stallWith({
  int helpers = 0,
  int cooks = 0,
  int managers = 0,
  int stock = 0,
  int cashPkr = 500,
}) {
  final s = GameState.newGame(config, t0);
  return s.copyWith(cashPaisa: rupees(cashPkr)).withStage(
        'stall',
        stall(s).copyWith(
          staff: {
            StaffRole.helper: helpers,
            StaffRole.cook: cooks,
            StaffRole.manager: managers,
          },
          lines: {'samosa': LineState(stock: stock)},
        ),
      );
}

int ledgerSum(Settlement r) => r.entries.fold(0, (sum, e) => sum + e.deltaPaisa);

void main() {
  test('a clock moved backwards settles nothing', () {
    final s = stallWith(helpers: 1, cooks: 1, managers: 1, stock: 50);
    final r = engine.advanceTo(s, at(const Duration(hours: -2)), foreground: false);
    expect(r.clockWentBack, isTrue);
    expect(identical(r.state, s), isTrue);
    expect(r.entries, isEmpty);
  });

  test('under one second changes nothing and keeps the leftover', () {
    final s = stallWith(stock: 5);
    final r = engine.advanceTo(s, at(const Duration(milliseconds: 900)), foreground: true);
    expect(identical(r.state, s), isTrue);
  });

  test('offline without a manager team earns and costs nothing', () {
    final s = stallWith(helpers: 2, cooks: 1, stock: 100);
    final r = engine.advanceTo(s, at(const Duration(hours: 3)), foreground: false);
    expect(r.state.cashPaisa, s.cashPaisa);
    expect(r.stages, isEmpty);
    expect(samosa(r.state).stock, 100);
  });

  test('offline team sells only existing stock, then the shop closes', () {
    final s = stallWith(helpers: 2, cooks: 1, managers: 1, stock: 100);
    final r = engine.advanceTo(s, at(const Duration(hours: 3)), foreground: false);
    final sum = r.stages['stall']!;
    expect(sum.sold, 100);
    expect(sum.stockUsed, 100);
    expect(sum.revenuePaisa, 100 * 3000);
    expect(samosa(r.state).stock, 0);
    expect(samosa(r.state).ready, 0);
    // 2 helpers serve 12 a minute, so 100 items take a bit over 8 minutes.
    expect(sum.ranDryAfter!.inMinutes, inInclusiveRange(8, 10));
    // Rent + wages = Rs 14 a minute, charged only while open.
    final minutesOpen = sum.ranDryAfter!.inSeconds / 60;
    expect(sum.wagesPaisa + sum.rentPaisa, closeTo(1400 * minutesOpen, 1400));
    expect(r.state.cashPaisa - s.cashPaisa, ledgerSum(r));
    expect(r.state.cashPaisa - s.cashPaisa, sum.netPaisa);
  });

  test('offline time is capped at 4 hours', () {
    final s = stallWith(helpers: 2, cooks: 1, managers: 1, stock: 5000);
    final r = engine.advanceTo(s, at(const Duration(hours: 10)), foreground: false);
    expect(r.credited, const Duration(hours: 4));
    expect(r.capped, isTrue);
    expect(r.stages['stall']!.sold, inInclusiveRange(12 * 240 - 10, 12 * 240));
    expect(r.state.lastSettledAt, at(const Duration(hours: 10)));
  });

  test('foreground finishes batches and charges rent while stock is left', () {
    var s = stallWith(stock: 10);
    s = (engine.startBatch(s, 'stall', 'samosa', t0) as Success).state;
    final r = engine.advanceTo(s, at(const Duration(seconds: 60)), foreground: true);
    expect(samosa(r.state).ready, 8);
    expect(samosa(r.state).stock, 2);
    expect(r.stages['stall']!.revenuePaisa, 0); // no helper: player sells by tapping
    expect(r.stages['stall']!.rentPaisa, 200); // Rs 2 a minute
    expect(r.state.cashPaisa, s.cashPaisa - 200);
  });

  test('costs never take cash below zero', () {
    final s = stallWith(stock: 2, cashPkr: 0);
    final r = engine.advanceTo(s, at(const Duration(hours: 1)), foreground: true);
    expect(r.state.cashPaisa, 0);
  });

  test('settling twice for the same time pays once', () {
    final s = stallWith(helpers: 2, cooks: 1, managers: 1, stock: 200);
    final end = at(const Duration(minutes: 30));
    final first = engine.advanceTo(s, end, foreground: false);
    final again = engine.advanceTo(first.state, end, foreground: false);
    expect(again.entries, isEmpty);
    expect(again.state.cashPaisa, first.state.cashPaisa);
  });

  test('one long settlement equals the same time in two parts', () {
    final s = stallWith(helpers: 2, cooks: 1, managers: 1, stock: 250, cashPkr: 0);
    final whole = engine.advanceTo(s, at(const Duration(minutes: 40)), foreground: false);
    final part1 = engine.advanceTo(s, at(const Duration(minutes: 13, seconds: 7)), foreground: false);
    final part2 = engine.advanceTo(part1.state, at(const Duration(minutes: 40)), foreground: false);
    expect(part2.state.cashPaisa, whole.state.cashPaisa);
    expect(stall(part2.state).sold, stall(whole.state).sold);
    expect(samosa(part2.state).stock, samosa(whole.state).stock);
  });

  test('leftover milliseconds wait for the next settlement', () {
    final s = stallWith(stock: 5);
    final r = engine.advanceTo(s, at(const Duration(seconds: 2, milliseconds: 700)), foreground: true);
    expect(r.state.lastSettledAt, at(const Duration(seconds: 2)));
  });
}
