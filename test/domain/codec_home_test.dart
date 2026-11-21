import 'dart:io';

import 'package:desi_business_empire/data/local/game_state_codec.dart';
import 'package:desi_business_empire/domain/economy/economy_config.dart';
import 'package:desi_business_empire/domain/economy/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

final config = EconomyConfig.parse(
  File('assets/config/economy.json').readAsStringSync(),
);
final t0 = DateTime.utc(2026, 1, 1, 12);

void main() {
  test('homeLevel round-trips through the codec', () {
    final s = GameState.newGame(config, t0).copyWith(homeLevel: 2);
    final decoded = decodeGameState(encodeGameState(s), config);
    expect(decoded.homeLevel, 2);
  });

  test('a save without homeLevel decodes to 0', () {
    final j = encodeGameState(GameState.newGame(config, t0))
      ..remove('homeLevel');
    expect(decodeGameState(j, config).homeLevel, 0);
  });
}
