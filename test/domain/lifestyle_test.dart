import 'dart:convert';
import 'dart:io';

import 'package:desi_business_empire/core/money.dart';
import 'package:desi_business_empire/data/local/game_state_codec.dart';
import 'package:desi_business_empire/domain/economy/command_result.dart';
import 'package:desi_business_empire/domain/economy/economy_config.dart';
import 'package:desi_business_empire/domain/economy/game_engine.dart';
import 'package:desi_business_empire/domain/economy/game_state.dart';
import 'package:desi_business_empire/domain/economy/goals.dart';
import 'package:desi_business_empire/domain/economy/settlement.dart';
import 'package:flutter_test/flutter_test.dart';

final config = EconomyConfig.parse(File('assets/config/economy.json').readAsStringSync());
final engine = GameEngine(config);
final t0 = DateTime.utc(2026, 1, 1, 12);

/// Samosa thela level 1 (Rs 2/s) and one plot (Rs 45/s): Rs 47/s before bonus.
GameState owner({int cashPkr = 0}) => GameState.newGame(config, t0).copyWith(
  cashPaisa: rupees(cashPkr),
  businesses: {'samosa': 1},
  invested: {'samosa': 100000},
  properties: {'plot': 1},
);

void main() {
  test('config has 54 lifestyle items worth +124% together', () {
    expect(config.lifestyle.length, 54);
    expect(config.lifestyle.fold(0, (a, i) => a + i.incomeBonusPercent), 124);
    expect(config.lifestyle.where((i) => i.kind == 'vehicle').length, 23);
  });

  test('every item sits in a section and each section is sorted by price', () {
    for (final g in ['road', 'heli', 'plane', 'watches', 'jewellery', 'art', 'yachts']) {
      final items = config.lifestyle.where((i) => i.group == g).toList();
      expect(items, isNotEmpty, reason: g);
      for (var i = 1; i < items.length; i++) {
        expect(items[i].pricePaisa, greaterThan(items[i - 1].pricePaisa), reason: g);
      }
    }
    expect(
      config.lifestyle
          .where((i) => const {'luxury', 'watches', 'jewellery', 'art', 'yachts'}.contains(i.group))
          .every((i) => i.kind == 'luxury'),
      isTrue,
    );
    expect(config.lifestyle.where((i) => i.group == 'watches').length, 6);
    expect(config.lifestyle.where((i) => i.group == 'yachts').length, 7);
    expect(config.lifestyle.where((i) => i.group == 'jewellery').length, 9);
    expect(config.lifestyle.where((i) => i.group == 'art').length, 9);
  });

  test('buying an item costs its price and raises all income by its bonus', () {
    final f = engine.buyItem(owner(cashPkr: 10000), 'motorbike', t0) as Failure;
    expect(f.reason, FailReason.insufficientFunds);
    final s = (engine.buyItem(owner(cashPkr: 50000), 'motorbike', t0) as Success).state;
    expect(s.cashPaisa, 0);
    expect(engine.lifestyleBonusPercent(s), 2);
    expect(engine.baseIncomePerSec(s), rupees(47));
    expect(engine.incomePerSec(s), rupees(47) * 102 ~/ 100);
    expect((engine.buyItem(s, 'motorbike', t0) as Failure).reason, FailReason.alreadyOwned);
  });

  test('offline income includes the bonus', () {
    final s = owner().copyWith(lifestyle: {'motorbike', 'watch'});
    final r = engine.advanceTo(s, t0.add(const Duration(minutes: 10)), foreground: false);
    expect(r.earnedPaisa, rupees(47) * 105 ~/ 100 * 600);
  });

  test('selling returns 60% and removes the bonus', () {
    final s = owner().copyWith(lifestyle: {'car'});
    final r = engine.sellItem(s, 'car', t0) as Success;
    expect(r.state.cashPaisa, rupees(800000) * 60 ~/ 100);
    expect(engine.lifestyleBonusPercent(r.state), 0);
    expect((engine.sellItem(r.state, 'car', t0) as Failure).reason, FailReason.notOwned);
  });

  test('net worth counts item resale value', () {
    final plain = owner();
    final rich = plain.copyWith(lifestyle: {'watch'});
    expect(engine.netWorth(rich) - engine.netWorth(plain), rupees(500000) * 60 ~/ 100);
  });

  test('items survive a save round trip and count for goals', () {
    final s = owner().copyWith(lifestyle: {'motorbike'});
    final back = decodeGameState(jsonDecode(jsonEncode(encodeGameState(s))) as Map<String, Object?>, config);
    expect(back.lifestyle, {'motorbike'});
    expect(engine.goalStatus(back, config.goal('lifestyle1')!), GoalStatus.claimable);
  });
}
