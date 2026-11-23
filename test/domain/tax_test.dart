import 'dart:convert';
import 'dart:io';

import 'package:desi_business_empire/core/money.dart';
import 'package:desi_business_empire/data/local/game_state_codec.dart';
import 'package:desi_business_empire/domain/economy/command_result.dart';
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

void main() {
  test('slabs pick the right percent for the amount', () {
    expect(TaxConfig.percentFor(config.tax.incomeSlabs, rupees(500)), 0);
    expect(TaxConfig.percentFor(config.tax.incomeSlabs, rupees(150000)), 10);
    expect(TaxConfig.percentFor(config.tax.purchaseSlabs, rupees(2000000)), 1);
  });

  test('buying something big adds purchase tax to what is due', () {
    final price = config.item('jet')!.pricePaisa;
    final s = GameState.newGame(config, t0).copyWith(cashPaisa: price * 3);
    final r = engine.buyItem(s, 'jet', t0) as Success;
    final pct = engine.purchaseTaxPercent(price);
    expect(pct, greaterThan(0));
    expect(r.state.taxDuePaisa, price * pct ~/ 100);
    expect(r.state.cashPaisa, price * 2);
  });

  test('cheap purchases owe no tax', () {
    final s = GameState.newGame(config, t0).copyWith(cashPaisa: rupees(100000));
    final r = engine.buyItem(s, 'motorbike', t0) as Success;
    expect(r.state.taxDuePaisa, 0);
  });

  test('filing a return pays what is due and starts a new period', () {
    final s = GameState.newGame(
      config,
      t0,
    ).copyWith(cashPaisa: rupees(5000), taxDuePaisa: rupees(1200));
    final later = t0.add(const Duration(hours: 30));
    final r = engine.fileTaxReturn(s, later) as Success;
    expect(r.state.cashPaisa, rupees(3800));
    expect(r.state.taxDuePaisa, 0);
    expect(r.state.taxPaidPaisa, rupees(1200));
    expect(r.state.taxPeriodStart, later);
    expect(r.state.taxMissed, 0);
    expect(r.entries.single.type, LedgerType.tax);
  });

  test('a return with too little cash fails and changes nothing', () {
    final s = GameState.newGame(
      config,
      t0,
    ).copyWith(cashPaisa: rupees(100), taxDuePaisa: rupees(1200));
    final f = engine.fileTaxReturn(s, t0) as Failure;
    expect(f.reason, FailReason.insufficientFunds);
  });

  test('a missed deadline adds the late fee and moves the deadline on', () {
    final s = GameState.newGame(config, t0).copyWith(taxDuePaisa: rupees(1000));
    final r = engine.advanceTo(
      s,
      t0.add(const Duration(hours: 61)),
      foreground: true,
    );
    final p = config.tax.latePenaltyPercent;
    expect(r.state.taxDuePaisa, rupees(1000) + rupees(1000) * p ~/ 100);
    expect(r.state.taxMissed, 1);
    expect(r.state.taxPeriodStart, t0.add(const Duration(hours: 60)));
  });

  test('tax fields survive a save round trip', () {
    final s = GameState.newGame(config, t0).copyWith(
      taxDuePaisa: rupees(77),
      taxPaidPaisa: rupees(900),
      taxMissed: 2,
      taxPeriodStart: t0.add(const Duration(hours: 60)),
    );
    final json = jsonEncode(encodeGameState(s));
    final back = decodeGameState(
      jsonDecode(json) as Map<String, Object?>,
      config,
    );
    expect(back.taxDuePaisa, rupees(77));
    expect(back.taxPaidPaisa, rupees(900));
    expect(back.taxMissed, 2);
    expect(back.taxPeriodStart, t0.add(const Duration(hours: 60)));
  });

  test('old saves without tax fields load with nothing due', () {
    final j = encodeGameState(GameState.newGame(config, t0))
      ..remove('taxDuePaisa')
      ..remove('taxPaidPaisa')
      ..remove('taxPeriodStart')
      ..remove('taxMissed');
    final s = decodeGameState(j, config);
    expect(s.taxDuePaisa, 0);
    expect(engine.taxDeadline(s), t0.add(const Duration(hours: 60)));
  });
}
