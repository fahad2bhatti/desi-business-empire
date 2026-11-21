import 'dart:convert';
import 'dart:io';

import 'package:desi_business_empire/domain/economy/config_validator.dart';
import 'package:desi_business_empire/domain/economy/economy_config.dart';
import 'package:flutter_test/flutter_test.dart';

const _path = 'assets/config/economy_v0.json';

Map<String, Object?> _raw() =>
    jsonDecode(File(_path).readAsStringSync()) as Map<String, Object?>;

List<String> _validate(Map<String, Object?> raw) =>
    validateConfig(EconomyConfig.fromJson(raw));

Map<String, Object?> _stage(Map<String, Object?> raw, int i) =>
    (raw['stages'] as List)[i] as Map<String, Object?>;

void main() {
  test('shipped economy config is valid', () {
    expect(_validate(_raw()), isEmpty);
  });

  test('parses money into paisa', () {
    final c = EconomyConfig.fromJson(_raw());
    expect(c.startCashPaisa, 50000);
    expect(c.stage('stall')!.line('samosa')!.pricePaisa, 3000);
    expect(c.stage('takeaway')!.unlockCostPaisa, 1000000);
    expect(c.upgrade('masala')!.levels.first.costPaisa, 80000);
  });

  test('catches line shares that do not add up to 1', () {
    final raw = _raw();
    final line =
        (_stage(raw, 1)['lines'] as List).first as Map<String, Object?>;
    line['share'] = 0.9;
    expect(_validate(raw), contains(startsWith('stage takeaway: line shares')));
  });

  test('catches a price that is not above cost', () {
    final raw = _raw();
    final line =
        (_stage(raw, 0)['lines'] as List).first as Map<String, Object?>;
    line['price'] = 10;
    expect(
      _validate(raw),
      contains('stage stall line samosa: price must be above cost'),
    );
  });

  test('catches requirements on unknown upgrades and later stages', () {
    final raw = _raw();
    final req = _stage(raw, 1)['requirements'] as Map<String, Object?>;
    (req['upgrades'] as Map)['missing'] = 1;
    (req['sold'] as Map)['restaurant'] = 5;
    final errors = _validate(raw);
    expect(
      errors,
      contains('stage takeaway: requirement on unknown upgrade missing'),
    );
    expect(
      errors,
      contains(
        'stage takeaway: sold requirement on unknown/later stage restaurant',
      ),
    );
  });

  test('catches an upgrade that points at a missing line', () {
    final raw = _raw();
    final up = (raw['upgrades'] as List).first as Map<String, Object?>;
    up['line'] = 'nope';
    expect(_validate(raw), contains('upgrade kadhai: needs a valid line'));
  });

  test('catches negative and zero values', () {
    final raw = _raw();
    final up = (raw['upgrades'] as List).first as Map<String, Object?>;
    ((up['levels'] as List).first as Map)['cost'] = 0;
    _stage(raw, 0)['rentPerMin'] = -1;
    final errors = _validate(raw);
    expect(errors, contains('upgrade kadhai: level cost must be > 0'));
    expect(errors, contains('stage stall: negative rent'));
  });
}
