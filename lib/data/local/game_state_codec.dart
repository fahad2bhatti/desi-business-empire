import '../../domain/economy/economy_config.dart';
import '../../domain/economy/game_state.dart';

/// Bump when the JSON shape changes, and add a migration in [decodeGameState].
const saveSchemaVersion = 1;

Map<String, Object?> encodeGameState(GameState s) => {
  'revision': s.revision,
  'cashPaisa': s.cashPaisa,
  'upgrades': s.upgrades,
  'lastSettledAt': s.lastSettledAt.toIso8601String(),
  'workReadyAt': s.workReadyAt?.toIso8601String(),
  'stages': {
    for (final e in s.stages.entries)
      e.key: {
        'sold': e.value.sold,
        'queue': e.value.queue,
        'queueCarry': e.value.queueCarry,
        'serveCarry': e.value.serveCarry,
        'costCarry': e.value.costCarry,
        'customersUpdatedAt': e.value.customersUpdatedAt.toIso8601String(),
        'staff': e.value.staff,
        'lines': {
          for (final l in e.value.lines.entries)
            l.key: {
              'stock': l.value.stock,
              'ready': l.value.ready,
              'batchSize': l.value.batchSize,
              'batchEndsAt': l.value.batchEndsAt?.toIso8601String(),
            },
        },
      },
  },
};

DateTime _time(Object? v) => DateTime.parse(v as String).toUtc();
int _int(Object? v) => (v as num).toInt();
Map<String, int> _intMap(Object? v) => {
  for (final e in (v as Map).entries) e.key as String: _int(e.value),
};

/// Throws [FormatException] when the save is broken or does not fit
/// [config]; the repository then falls back to a backup.
GameState decodeGameState(Map<String, Object?> j, EconomyConfig config) {
  final stages = <String, StageState>{};
  for (final e in (j['stages'] as Map).entries) {
    final id = e.key as String;
    final def = config.stage(id);
    if (def == null) throw FormatException('unknown stage $id');
    final st = e.value as Map;
    final lines = <String, LineState>{};
    for (final l in (st['lines'] as Map).entries) {
      if (def.line(l.key as String) == null) {
        throw FormatException('unknown line ${l.key}');
      }
      final lv = l.value as Map;
      final ends = lv['batchEndsAt'];
      lines[l.key as String] = LineState(
        stock: _int(lv['stock']),
        ready: _int(lv['ready']),
        batchSize: _int(lv['batchSize']),
        batchEndsAt: ends == null ? null : _time(ends),
      );
    }
    stages[id] = StageState(
      sold: _int(st['sold']),
      queue: _int(st['queue']),
      queueCarry: _int(st['queueCarry']),
      serveCarry: _int(st['serveCarry']),
      costCarry: _int(st['costCarry']),
      customersUpdatedAt: _time(st['customersUpdatedAt']),
      staff: _intMap(st['staff']),
      lines: lines,
    );
  }
  final work = j['workReadyAt'];
  final s = GameState(
    revision: _int(j['revision']),
    cashPaisa: _int(j['cashPaisa']),
    upgrades: _intMap(j['upgrades']),
    stages: stages,
    lastSettledAt: _time(j['lastSettledAt']),
    workReadyAt: work == null ? null : _time(work),
  );
  _checkInvariants(s, config);
  return s;
}

void _checkInvariants(GameState s, EconomyConfig config) {
  if (s.cashPaisa < 0) throw const FormatException('negative cash');
  if (!s.stages.containsKey(config.stages.first.id)) {
    throw const FormatException('starter business missing');
  }
  for (final st in s.stages.values) {
    if (st.sold < 0 || st.queue < 0) {
      throw const FormatException('negative counter');
    }
    for (final l in st.lines.values) {
      if (l.stock < 0 || l.ready < 0 || l.batchSize < 0) {
        throw const FormatException('negative items');
      }
    }
  }
  for (final e in s.upgrades.entries) {
    final u = config.upgrade(e.key);
    if (u == null || e.value < 0 || e.value > u.levels.length) {
      throw FormatException('bad upgrade ${e.key}');
    }
  }
}
