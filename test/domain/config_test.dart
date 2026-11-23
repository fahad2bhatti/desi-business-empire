import 'dart:convert';
import 'dart:io';

import 'package:desi_business_empire/domain/economy/config_validator.dart';
import 'package:desi_business_empire/domain/economy/economy_config.dart';
import 'package:flutter_test/flutter_test.dart';

const _path = 'assets/config/economy.json';

Map<String, Object?> _raw() =>
    jsonDecode(File(_path).readAsStringSync()) as Map<String, Object?>;

List<String> _validate(Map<String, Object?> raw) =>
    validateConfig(EconomyConfig.fromJson(raw));

Map<String, Object?> _item(Map<String, Object?> raw, String list, int i) =>
    (raw[list] as List)[i] as Map<String, Object?>;

void main() {
  test('shipped economy config is valid', () {
    expect(_validate(_raw()), isEmpty);
  });

  test('parses money into paisa', () {
    final c = EconomyConfig.fromJson(_raw());
    expect(c.startCashPaisa, 50000);
    expect(c.workPayPaisa, 2500);
    expect(c.business('samosa')!.pricePaisa, 100000);
    expect(c.business('samosa')!.incomePaisaPerSec, 200);
    expect(c.property('plot')!.rentPaisaPerSec, 4500);
    expect(c.businesses.length, 16);
    expect(c.categories.map((x) => x.id), [
      'street',
      'transport',
      'shops',
      'companies',
    ]);
    expect(c.homes.first.pricePaisa, 0);
    expect(c.properties.length, 6);
  });

  test('catches an unknown category and zero income', () {
    final raw = _raw();
    _item(raw, 'businesses', 0)['category'] = 'space';
    _item(raw, 'businesses', 1)['incomePerSecond'] = 0;
    final errors = _validate(raw);
    expect(errors, contains('business samosa: unknown category space'));
    expect(errors, contains('business chai: income must be > 0'));
  });

  test('catches duplicate ids across businesses and property', () {
    final raw = _raw();
    _item(raw, 'properties', 0)['id'] = 'samosa';
    expect(_validate(raw), contains('property samosa: duplicate id'));
  });

  test('catches milestones out of order and bad refunds', () {
    final raw = _raw();
    _item(raw, 'milestones', 1)['level'] = 10;
    raw['businessSellRefund'] = 1.5;
    final errors = _validate(raw);
    expect(errors, contains('milestone levels must ascend (at 10)'));
    expect(errors, contains('businessSellRefund must be in (0, 1]'));
  });

  test(
    'catches goals that point at a missing business or impossible counts',
    () {
      final raw = _raw();
      final goals = raw['goals'] as List;
      (goals.firstWhere((g) => (g as Map)['id'] == 'samosa10')
              as Map)['business'] =
          'pizza';
      (goals.firstWhere((g) => (g as Map)['id'] == 'own12') as Map)['target'] =
          17;
      final errors = _validate(raw);
      expect(errors, contains('goal samosa10: needs a valid business'));
      expect(errors, contains('goal own12: more businesses than exist'));
    },
  );

  test('catches a home ladder that does not climb', () {
    final raw = _raw();
    _item(raw, 'homes', 2)['price'] = 1;
    _item(raw, 'homes', 0)['incomeBonusPercent'] = 1;
    final errors = _validate(raw);
    expect(errors, contains('home cottage: must cost more than flat'));
    expect(
      errors,
      contains('home room: the first home must be free with no bonus'),
    );
  });
}
