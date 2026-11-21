import 'dart:io';

import 'package:desi_business_empire/domain/economy/economy_config.dart';
import 'package:desi_business_empire/domain/economy/game_engine.dart';
import 'package:desi_business_empire/domain/economy/game_state.dart';
import 'package:desi_business_empire/features/home/next_goal.dart';
import 'package:flutter_test/flutter_test.dart';

final config = EconomyConfig.parse(
  File('assets/config/economy_v0.json').readAsStringSync(),
);
final engine = GameEngine(config);
final s0 = GameState.newGame(config, DateTime.utc(2026));

GameState stall(
  GameState s, {
  int sold = 0,
  Map<String, int> staff = const {},
}) =>
    s.withStage('stall', s.stages['stall']!.copyWith(sold: sold, staff: staff));

void main() {
  test('new player: hire the first helper', () {
    final g = nextGoal(engine, s0);
    expect(g.title, contains('Helper'));
    expect(g.route, '/business/stall/staff');
  });

  test('then sell towards the manager requirement', () {
    final g = nextGoal(
      engine,
      stall(s0, sold: 120, staff: {StaffRole.helper: 1}),
    );
    expect(g.have, 120);
    expect(g.need, 200);
  });

  test('then hire the manager once sales are enough', () {
    final g = nextGoal(
      engine,
      stall(s0, sold: 200, staff: {StaffRole.helper: 1}),
    );
    expect(g.title, 'Manager rakho');
  });

  test('then points at the first unmet takeaway requirement', () {
    final g = nextGoal(
      engine,
      stall(s0, sold: 250, staff: {StaffRole.helper: 1, StaffRole.manager: 1}),
    );
    expect(g.title, 'Takeaway Shop ki taraf');
    expect(g.detail, 'Samosa Stall par 300 items becho');
    expect([g.have, g.need], [250, 300]);
    expect(g.route, '/expand/takeaway');
  });

  test('when everything is met it asks to open the takeaway', () {
    var s = s0.copyWith(upgrades: {'kadhai': 2}, cashPaisa: 400000);
    s = stall(s, sold: 300, staff: {StaffRole.helper: 1, StaffRole.manager: 1});
    final g = nextGoal(engine, s);
    expect(g.title, 'Takeaway Shop kholo: Rs 10,000');
    expect([g.have, g.need], [4000, 10000]);
    expect(g.route, '/expand/takeaway');
  });
}
