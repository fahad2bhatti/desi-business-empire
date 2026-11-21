import 'dart:convert';

import '../../core/money.dart';

/// Staff role keys used in the config and in saves.
abstract final class StaffRole {
  static const helper = 'helper';
  static const cook = 'cook';
  static const manager = 'manager';
  static const all = [helper, cook, manager];
}

enum UpgradeEffect { batch, batchSeconds, price, priceMult, demandMult, storage }

/// Effects that change one item line; the rest change the whole stage.
const lineEffects = {
  UpgradeEffect.batch,
  UpgradeEffect.batchSeconds,
  UpgradeEffect.price,
};

int _int(Object? v) => (v as num).toInt();
double _double(Object? v) => (v as num).toDouble();

Map<String, int> _intMap(Object? v) => {
      for (final e in ((v ?? const <String, Object?>{}) as Map).entries)
        e.key as String: _int(e.value),
    };

class LineDef {
  const LineDef({
    required this.id,
    required this.name,
    required this.costPaisa,
    required this.pricePaisa,
    required this.batch,
    required this.batchSeconds,
    required this.share,
  });

  final String id;
  final String name;
  final int costPaisa;
  final int pricePaisa;
  final int batch;
  final int batchSeconds;
  final double share;

  factory LineDef.fromJson(Map<String, Object?> j) => LineDef(
        id: j['id'] as String,
        name: j['name'] as String,
        costPaisa: rupees(_int(j['cost'])),
        pricePaisa: rupees(_int(j['price'])),
        batch: _int(j['batch']),
        batchSeconds: _int(j['batchSeconds']),
        share: _double(j['share']),
      );
}

class StaffDef {
  const StaffDef({
    required this.hirePaisa,
    required this.wagePaisaPerMin,
    required this.max,
    this.servePerMin = 0,
    this.requiresSold = 0,
  });

  final int hirePaisa;
  final int wagePaisaPerMin;
  final int max;
  final int servePerMin;
  final int requiresSold;

  factory StaffDef.fromJson(Map<String, Object?> j) => StaffDef(
        hirePaisa: rupees(_int(j['hire'])),
        wagePaisaPerMin: rupees(_int(j['wagePerMin'])),
        max: _int(j['max'] ?? 1),
        servePerMin: _int(j['servePerMin'] ?? 0),
        requiresSold: _int(j['requiresSold'] ?? 0),
      );
}

class Requirements {
  const Requirements({
    this.sold = const {},
    this.upgrades = const {},
    this.staff = const {},
  });

  /// stageId -> items sold there.
  final Map<String, int> sold;

  /// upgradeId -> minimum level.
  final Map<String, int> upgrades;

  /// stageId -> role -> minimum count.
  final Map<String, Map<String, int>> staff;

  factory Requirements.fromJson(Map<String, Object?>? j) {
    if (j == null) return const Requirements();
    final staff = (j['staff'] ?? const <String, Object?>{}) as Map;
    return Requirements(
      sold: _intMap(j['sold']),
      upgrades: _intMap(j['upgrades']),
      staff: {for (final e in staff.entries) e.key as String: _intMap(e.value)},
    );
  }
}

class StageDef {
  const StageDef({
    required this.id,
    required this.name,
    required this.unlockCostPaisa,
    required this.requirements,
    required this.rentPaisaPerMin,
    required this.customersPerMin,
    required this.storage,
    required this.lines,
    required this.staff,
  });

  final String id;
  final String name;
  final int unlockCostPaisa;
  final Requirements requirements;
  final int rentPaisaPerMin;
  final double customersPerMin;
  final int storage;
  final List<LineDef> lines;
  final Map<String, StaffDef> staff;

  LineDef? line(String id) {
    for (final l in lines) {
      if (l.id == id) return l;
    }
    return null;
  }

  factory StageDef.fromJson(Map<String, Object?> j) {
    final staff = (j['staff'] ?? const <String, Object?>{}) as Map;
    return StageDef(
      id: j['id'] as String,
      name: j['name'] as String,
      unlockCostPaisa: rupees(_int(j['unlockCost'])),
      requirements:
          Requirements.fromJson(j['requirements'] as Map<String, Object?>?),
      rentPaisaPerMin: rupees(_int(j['rentPerMin'])),
      customersPerMin: _double(j['customersPerMin']),
      storage: _int(j['storage']),
      lines: [
        for (final l in (j['lines'] as List))
          LineDef.fromJson(l as Map<String, Object?>),
      ],
      staff: {
        for (final e in staff.entries)
          e.key as String: StaffDef.fromJson(e.value as Map<String, Object?>),
      },
    );
  }
}

class UpgradeLevel {
  const UpgradeLevel({required this.costPaisa, required this.value});

  final int costPaisa;

  /// Meaning depends on the effect. For [UpgradeEffect.price] it is whole PKR.
  final double value;
}

class UpgradeDef {
  const UpgradeDef({
    required this.id,
    required this.stageId,
    required this.name,
    required this.effect,
    required this.lineId,
    required this.levels,
  });

  final String id;
  final String stageId;
  final String name;
  final UpgradeEffect effect;
  final String? lineId;
  final List<UpgradeLevel> levels;

  factory UpgradeDef.fromJson(Map<String, Object?> j) => UpgradeDef(
        id: j['id'] as String,
        stageId: j['stage'] as String,
        name: j['name'] as String,
        effect: UpgradeEffect.values.byName(j['effect'] as String),
        lineId: j['line'] as String?,
        levels: [
          for (final l in (j['levels'] as List).cast<Map<String, Object?>>())
            UpgradeLevel(
              costPaisa: rupees(_int(l['cost'])),
              value: _double(l['value']),
            ),
        ],
      );
}

class EconomyConfig {
  const EconomyConfig({
    required this.version,
    required this.startCashPaisa,
    required this.offlineCapMinutes,
    required this.maxQueue,
    required this.recoveryPayPaisa,
    required this.recoveryCooldown,
    required this.stages,
    required this.upgrades,
  });

  final int version;
  final int startCashPaisa;
  final int offlineCapMinutes;
  final int maxQueue;
  final int recoveryPayPaisa;
  final Duration recoveryCooldown;

  /// In progression order: index 0 is the starter business.
  final List<StageDef> stages;
  final List<UpgradeDef> upgrades;

  StageDef? stage(String id) {
    for (final s in stages) {
      if (s.id == id) return s;
    }
    return null;
  }

  UpgradeDef? upgrade(String id) {
    for (final u in upgrades) {
      if (u.id == id) return u;
    }
    return null;
  }

  factory EconomyConfig.fromJson(Map<String, Object?> j) {
    final recovery = j['recovery'] as Map<String, Object?>;
    return EconomyConfig(
      version: _int(j['version']),
      startCashPaisa: rupees(_int(j['startCash'])),
      offlineCapMinutes: _int(j['offlineCapMinutes']),
      maxQueue: _int(j['maxQueue']),
      recoveryPayPaisa: rupees(_int(recovery['pay'])),
      recoveryCooldown: Duration(seconds: _int(recovery['cooldownSeconds'])),
      stages: [
        for (final s in (j['stages'] as List))
          StageDef.fromJson(s as Map<String, Object?>),
      ],
      upgrades: [
        for (final u in (j['upgrades'] as List))
          UpgradeDef.fromJson(u as Map<String, Object?>),
      ],
    );
  }

  static EconomyConfig parse(String source) =>
      EconomyConfig.fromJson(jsonDecode(source) as Map<String, Object?>);
}
