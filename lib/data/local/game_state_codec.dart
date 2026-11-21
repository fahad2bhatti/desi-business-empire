import '../../domain/economy/economy_config.dart';
import '../../domain/economy/game_state.dart';

/// Version 2: idle tycoon (businesses with levels, property units).
/// Version 1 saves (the old stall game) are not migrated; the founder chose
/// a fresh start.
const saveSchemaVersion = 2;

Map<String, Object?> encodeGameState(GameState s) => {
  'revision': s.revision,
  'cashPaisa': s.cashPaisa,
  'lastSettledAt': s.lastSettledAt.toIso8601String(),
  'businesses': s.businesses,
  'invested': s.invested,
  'properties': s.properties,
  'totalEarnedPaisa': s.totalEarnedPaisa,
  'taps': s.taps,
};

int _int(Object? v) => (v as num).toInt();
Map<String, int> _intMap(Object? v) => {
  for (final e in (v as Map).entries) e.key as String: _int(e.value),
};

/// Throws [FormatException] when the save is broken or does not fit
/// [config]; the repository then falls back to a backup.
GameState decodeGameState(Map<String, Object?> j, EconomyConfig config) {
  final s = GameState(
    revision: _int(j['revision']),
    cashPaisa: _int(j['cashPaisa']),
    lastSettledAt: DateTime.parse(j['lastSettledAt'] as String).toUtc(),
    businesses: _intMap(j['businesses']),
    invested: _intMap(j['invested']),
    properties: _intMap(j['properties']),
    totalEarnedPaisa: _int(j['totalEarnedPaisa']),
    taps: _int(j['taps']),
  );
  if (s.cashPaisa < 0 || s.totalEarnedPaisa < 0 || s.taps < 0) {
    throw const FormatException('negative counter');
  }
  for (final e in s.businesses.entries) {
    if (config.business(e.key) == null ||
        e.value < 1 ||
        e.value > config.maxLevel) {
      throw FormatException('bad business ${e.key}');
    }
  }
  for (final e in s.properties.entries) {
    final p = config.property(e.key);
    if (p == null || e.value < 1 || e.value > p.maxOwned) {
      throw FormatException('bad property ${e.key}');
    }
  }
  return s;
}
