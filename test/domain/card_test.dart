import 'dart:io';

import 'package:desi_business_empire/core/money.dart';
import 'package:desi_business_empire/domain/economy/command_result.dart';
import 'package:desi_business_empire/domain/economy/config_validator.dart';
import 'package:desi_business_empire/domain/economy/economy_config.dart';
import 'package:desi_business_empire/domain/economy/game_engine.dart';
import 'package:desi_business_empire/domain/economy/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

final config = EconomyConfig.parse(
  File('assets/config/economy.json').readAsStringSync(),
);
final engine = GameEngine(config);
final t0 = DateTime.utc(2026, 1, 1, 12);

GameState withCash(int pkr) =>
    GameState.newGame(config, t0).copyWith(cashPaisa: rupees(pkr));

void main() {
  test('the card config is valid and has six cards', () {
    expect(validateConfig(config), isEmpty);
    expect(config.cards.map((c) => c.name), [
      'Bronze',
      'Silver',
      'Gold',
      'Platinum',
      'Diamond',
      'Americano Express',
    ]);
  });

  test('a new game holds the Bronze card', () {
    expect(engine.card(GameState.newGame(config, t0)).id, 'bronze');
  });

  test('the card follows net worth', () {
    expect(engine.card(withCash(499999)).id, 'bronze');
    expect(engine.card(withCash(500000)).id, 'silver');
    expect(engine.card(withCash(25000000)).id, 'gold');
    expect(engine.card(withCash(1000000000)).id, 'platinum');
    expect(engine.card(withCash(50000000000)).id, 'diamond');
    expect(engine.card(withCash(1000000000000)).id, 'americano');
  });

  test('tax due lowers net worth and can lower the card', () {
    final s = withCash(500000).copyWith(taxDuePaisa: rupees(1));
    expect(engine.card(s).id, 'bronze');
  });

  test('nextCard is null on the top card', () {
    expect(engine.nextCard(withCash(1000000000000)), isNull);
    expect(engine.nextCard(withCash(100))!.id, 'silver');
  });

  test('cardFor names the cheapest card that covers a price', () {
    expect(engine.cardFor(rupees(150000)).id, 'bronze');
    expect(engine.cardFor(rupees(220000)).id, 'silver');
    expect(engine.cardFor(rupees(500000000000)).id, 'americano');
  });

  test('a price above the card limit is refused even with the cash', () {
    // Rs 300K of cash is a Bronze card (limit Rs 200K); a rickshaw costs 220K.
    final s = withCash(300000);
    final f = engine.buyBusiness(s, 'rickshaw', t0) as Failure;
    expect(f.reason, FailReason.cardTooLow);
    expect(f.cardName, 'Silver');
  });

  test('buying within the limit works', () {
    final s = withCash(300000);
    expect(engine.buyBusiness(s, 'chaat', t0), isA<Success>());
    expect(engine.buyProperty(s, 'plot', t0), isA<Success>());
  });

  test('items obey the card too', () {
    // Rs 480K of cash is still Bronze; a cruiser bike costs Rs 450K.
    final bronze = withCash(480000);
    expect(
      (engine.buyItem(bronze, 'cruiserbike', t0) as Failure).reason,
      FailReason.cardTooLow,
    );
    // Rs 900K is Silver, which covers a Rs 800K car.
    expect(engine.buyItem(withCash(900000), 'car', t0), isA<Success>());
  });

  test('an upgrade above the card limit is refused', () {
    final b = config.business('rickshaw')!;
    final cost = engine.upgradeCost(b, 30);
    final s = withCash(0)
        .copyWith(cashPaisa: cost + rupees(1), businesses: {'rickshaw': 30});
    final limit = engine.card(s).limitPaisa;
    expect(cost, greaterThan(limit));
    final f = engine.upgradeBusiness(s, 'rickshaw', t0) as Failure;
    expect(f.reason, FailReason.cardTooLow);
  });

  test('owned things count toward net worth and so toward the card', () {
    final s = withCash(0).copyWith(lifestyle: {'jet'});
    expect(s.lifestyle.contains('jet'), isTrue);
    expect(engine.card(s).id, isNot('bronze'));
  });
}
