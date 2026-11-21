import 'dart:io';

import 'package:desi_business_empire/domain/economy/economy_config.dart';
import 'package:desi_business_empire/domain/economy/game_engine.dart';
import 'package:desi_business_empire/domain/economy/game_state.dart';
import 'package:desi_business_empire/features/upgrades/upgrade_preview.dart';
import 'package:flutter_test/flutter_test.dart';

final config = EconomyConfig.parse(
  File('assets/config/economy_v0.json').readAsStringSync(),
);
final engine = GameEngine(config);
final s0 = GameState.newGame(config, DateTime.utc(2026));

UpgradePreview preview(String id, [GameState? s]) =>
    previewUpgrade(engine, s ?? s0, config.upgrade(id)!);

void main() {
  test('price upgrade shows the new rate and its cost', () {
    final p = preview('masala');
    expect(p.label, 'Rate (Samosa)');
    expect(p.before, 'Rs 30');
    expect(p.after, 'Rs 35');
    expect(p.nextCostPaisa, 80000);
    expect(p.level, 0);
    expect(p.maxLevel, 2);
  });

  test('batch, time, customers and storage previews', () {
    expect([preview('kadhai').before, preview('kadhai').after], ['8', '15']);
    expect(
      [preview('burner').before, preview('burner').after],
      ['30 sec', '16 sec'],
    );
    expect([preview('board').before, preview('board').after], ['14', '17.5']);
    expect(
      [preview('godown').before, preview('godown').after],
      ['300', '1000'],
    );
  });

  test('multiplier preview starts at x1', () {
    final p = preview('chutney');
    expect([p.before, p.after], ['×1', '×1.1']);
  });

  test('a maxed upgrade has no next value or cost', () {
    final p = preview('kadhai', s0.copyWith(upgrades: {'kadhai': 3}));
    expect(p.isMaxed, isTrue);
    expect(p.before, '30');
    expect(p.nextCostPaisa, isNull);
  });
}
