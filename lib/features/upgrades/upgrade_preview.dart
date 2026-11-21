import '../../core/labels.dart';
import '../../core/money.dart';
import '../../domain/economy/economy_config.dart';
import '../../domain/economy/game_engine.dart';
import '../../domain/economy/game_state.dart';

/// What an upgrade changes, shown before buying.
class UpgradePreview {
  const UpgradePreview({
    required this.label,
    required this.before,
    required this.after,
    required this.level,
    required this.maxLevel,
    required this.nextCostPaisa,
  });

  final String label;
  final String before;

  /// `null` when the upgrade is already at its last level.
  final String? after;
  final int level;
  final int maxLevel;
  final int? nextCostPaisa;

  bool get isMaxed => after == null;
}

UpgradePreview previewUpgrade(GameEngine engine, GameState s, UpgradeDef u) {
  final def = engine.config.stage(u.stageId)!;
  final line = u.lineId == null ? null : def.line(u.lineId!);
  final level = s.upgradeLevel(u.id);
  final maxed = level >= u.levels.length;
  final next = maxed
      ? null
      : s.copyWith(upgrades: {...s.upgrades, u.id: level + 1});

  final (String label, String Function(GameState) show) = switch (u.effect) {
    UpgradeEffect.batch => (
      'Ek batch (${line!.name})',
      (GameState x) => '${engine.lineStats(x, def, line).batch}',
    ),
    UpgradeEffect.batchSeconds => (
      'Tayyari ka waqt (${line!.name})',
      (GameState x) => '${engine.lineStats(x, def, line).batchSeconds} sec',
    ),
    UpgradeEffect.price => (
      'Rate (${line!.name})',
      (GameState x) => formatRs(engine.lineStats(x, def, line).pricePaisa),
    ),
    UpgradeEffect.priceMult => (
      'Sab rates',
      (GameState x) {
        final l = x.upgradeLevel(u.id);
        return '×${formatNumber(l == 0 ? 1 : u.levels[l - 1].value)}';
      },
    ),
    UpgradeEffect.demandMult => (
      'Customers / minute',
      (GameState x) => formatNumber(engine.customersPerMin(x, def)),
    ),
    UpgradeEffect.storage => (
      'Saman ki jagah',
      (GameState x) => '${engine.storage(x, def)}',
    ),
  };

  return UpgradePreview(
    label: label,
    before: show(s),
    after: next == null ? null : show(next),
    level: level,
    maxLevel: u.levels.length,
    nextCostPaisa: maxed ? null : u.levels[level].costPaisa,
  );
}
