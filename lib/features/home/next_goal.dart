import '../../core/labels.dart';
import '../../core/money.dart';
import '../../domain/economy/economy_config.dart';
import '../../domain/economy/game_engine.dart';
import '../../domain/economy/game_state.dart';

/// The one thing the player should do next, with progress when it has one.
/// A small stand-in until the goals system (batch 7).
class NextGoal {
  const NextGoal(this.title, {this.detail, this.have, this.need, this.route});

  final String title;
  final String? detail;
  final int? have;
  final int? need;

  /// Where tapping the card should go.
  final String? route;
}

NextGoal nextGoal(GameEngine engine, GameState s) {
  final config = engine.config;
  final starter = config.stages.first;
  final stall = s.stages[starter.id]!;
  final staffRoute = '/business/${starter.id}/staff';

  if (stall.staffCount(StaffRole.helper) == 0) {
    return NextGoal(
      'Pehla ${roleName(StaffRole.helper)} rakho',
      detail: 'Customers khud serve honge.',
      route: staffRoute,
    );
  }
  if (stall.staffCount(StaffRole.manager) == 0) {
    final need = starter.staff[StaffRole.manager]!.requiresSold;
    if (stall.sold < need) {
      return NextGoal(
        '$need items becho, phir Manager rakho',
        detail: 'Manager aane ke baad dukan aap ke baghair bhi chalegi.',
        have: stall.sold,
        need: need,
        route: '/business/${starter.id}',
      );
    }
    return NextGoal(
      'Manager rakho',
      detail: 'Helper aur Cook ke saath dukan offline bhi chalegi.',
      route: staffRoute,
    );
  }
  for (final def in config.stages) {
    if (s.stages.containsKey(def.id)) continue;
    final unmet = engine.missingRequirements(s, def.id);
    if (unmet.isNotEmpty) {
      final first = unmet.first;
      return NextGoal(
        '${def.name} ki taraf',
        detail: describeRequirement(first, config),
        have: first.have,
        need: first.need,
        route: '/expand/${def.id}',
      );
    }
    return NextGoal(
      '${def.name} kholo: ${formatRs(def.unlockCostPaisa)}',
      detail: 'Saari shartein poori hain.',
      have: s.cashPaisa ~/ paisaPerRupee,
      need: def.unlockCostPaisa ~/ paisaPerRupee,
      route: '/expand/${def.id}',
    );
  }
  return const NextGoal('Saare karobar khul gaye!');
}
