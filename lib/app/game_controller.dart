import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
import '../data/local/app_database.dart';
import '../data/local/save_repository.dart';
import '../domain/economy/command_result.dart';
import '../domain/economy/config_validator.dart';
import '../domain/economy/economy_config.dart';
import '../domain/economy/game_engine.dart';
import '../domain/economy/game_state.dart';
import '../domain/economy/settlement.dart';

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final saveRepositoryProvider = Provider<SaveRepository>(
  (ref) => SaveRepository(ref.watch(databaseProvider)),
);

final economyConfigProvider = FutureProvider<EconomyConfig>((ref) async {
  final config = EconomyConfig.parse(
    await rootBundle.loadString('assets/config/economy.json'),
  );
  final errors = validateConfig(config);
  if (errors.isNotEmpty) {
    throw StateError('Economy config invalid: ${errors.join('; ')}');
  }
  return config;
});

final gameControllerProvider =
    AsyncNotifierProvider<GameController, GameSession>(GameController.new);

/// What the UI needs besides the save itself.
class GameSession {
  const GameSession({
    required this.state,
    this.offline,
    this.saveFailed = false,
    this.restoredFromBackup = false,
  });

  final GameState state;

  /// An offline settlement waiting to be acknowledged. Its money is already
  /// in [state]; closing the sheet never pays again.
  final Settlement? offline;

  /// A write failed: economic actions stay blocked until a retry works.
  final bool saveFailed;
  final bool restoredFromBackup;

  GameSession copyWith({
    GameState? state,
    Settlement? offline,
    bool? saveFailed,
  }) => GameSession(
    state: state ?? this.state,
    offline: offline ?? this.offline,
    saveFailed: saveFailed ?? this.saveFailed,
    restoredFromBackup: restoredFromBackup,
  );

  GameSession withoutOffline() => GameSession(
    state: state,
    saveFailed: saveFailed,
    restoredFromBackup: restoredFromBackup,
  );
}

class SaveBlockedException implements Exception {
  const SaveBlockedException();
}

/// Owns the save: every economic change goes engine -> database -> UI,
/// one at a time, and the UI only sees a change after it is stored. The one
/// exception is the once-a-second income tick, which shows at once and is
/// stored with the next write (see [_flushEvery]).
class GameController extends AsyncNotifier<GameSession> {
  static const _backupEvery = Duration(minutes: 5);

  /// Income ticks run in memory every second; the database gets them in one
  /// write this often (and at once on every purchase, pause and resume). A
  /// crash loses nothing: the stored time is older, so the next start
  /// settles the gap again.
  static const _flushEvery = Duration(seconds: 15);
  static const _keepLedger = Duration(days: 2);

  late EconomyConfig _config;
  late GameEngine engine;
  late SaveRepository _repo;
  late Clock _clock;
  Timer? _ticker;
  AppLifecycleListener? _lifecycle;
  DateTime? _lastBackup;
  DateTime? _lastFlush;
  // Ledger entries earned by ticks that are not stored yet.
  final List<LedgerEntry> _pending = [];
  Future<void> _queue = Future.value();

  @override
  Future<GameSession> build() async {
    ref.onDispose(_stop);
    _pending.clear();
    _lastFlush = null;
    _repo = ref.watch(saveRepositoryProvider);
    _clock = ref.watch(clockProvider);
    _config = await ref.watch(economyConfigProvider.future);
    engine = GameEngine(_config);

    final now = _clock.nowUtc();
    final loaded = await _repo.load(_config); // throws SaveCorruptException
    var s = loaded?.state;
    if (s == null) {
      s = GameState.newGame(_config, now);
      // Also clears backups and ledger left by an older game version.
      await _repo.resetTo(s, _config.version);
    } else if (loaded!.restoredFromBackup) {
      await _repo.replaceMain(s, _config.version);
    }

    // Time since the app was last open is settled once, here.
    final r = engine.advanceTo(s, now, foreground: false);
    if (!identical(r.state, s)) {
      await _repo.commit(r.state, r.entries, _config.version);
    }

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _lifecycle = AppLifecycleListener(onPause: _onPause, onResume: _onResume);
    return GameSession(
      state: r.state,
      offline: _worthShowing(r) ? r : null,
      restoredFromBackup: loaded?.restoredFromBackup ?? false,
    );
  }

  /// Runs one engine command at the current time. Returns the [Failure]
  /// (nothing changed) or `null` on success. Throws if saving failed; the
  /// UI then shows the retry banner.
  Future<Failure?> run(
    CommandResult Function(GameState s, DateTime now) command,
  ) => _serial(() async {
    final cur = state.requireValue;
    if (cur.saveFailed) throw const SaveBlockedException();
    final now = _clock.nowUtc();
    try {
      final settled = engine.advanceTo(cur.state, now, foreground: true);
      if (!identical(settled.state, cur.state) || _pending.isNotEmpty) {
        await _repo.commit(
          settled.state,
          _mergedIncome([..._pending, ...settled.entries]),
          _config.version,
        );
        _pending.clear();
        _lastFlush = now;
      }
      final result = command(settled.state, now);
      switch (result) {
        case final Failure failure:
          state = AsyncData(cur.copyWith(state: settled.state));
          return failure;
        case final Success ok:
          await _repo.commit(ok.state, ok.entries, _config.version);
          state = AsyncData(cur.copyWith(state: ok.state));
          return null;
      }
    } catch (_) {
      state = AsyncData(cur.copyWith(saveFailed: true));
      rethrow;
    }
  });

  void acknowledgeOffline() {
    final cur = state.value;
    if (cur != null) state = AsyncData(cur.withoutOffline());
  }

  /// Reloads the stored save after a failed write, so memory and disk agree.
  Future<void> retrySave() => _serial(() async {
    final loaded = await _repo.load(_config);
    final cur = state.value;
    if (loaded == null || cur == null) return;
    _pending.clear();
    state = AsyncData(GameSession(state: loaded.state, offline: cur.offline));
  });

  /// Destroys the save. Call only after the player confirmed.
  Future<void> resetGame() async {
    await _serial(() async {
      final config = await ref.read(economyConfigProvider.future);
      await ref
          .read(saveRepositoryProvider)
          .resetTo(
            GameState.newGame(config, ref.read(clockProvider).nowUtc()),
            config.version,
          );
    });
    ref.invalidateSelf();
  }

  // ---------- time ----------

  /// Moves the game on in memory every second. The database gets the
  /// result every [_flushEvery], or at once when [flush] is set.
  Future<void> _tick({bool flush = false}) => _serial(() async {
    final cur = state.value;
    if (cur == null || cur.saveFailed) return;
    final now = _clock.nowUtc();
    final r = engine.advanceTo(cur.state, now, foreground: true);
    var next = cur;
    if (!identical(r.state, cur.state)) {
      _pending.addAll(r.entries);
      next = cur.copyWith(state: r.state);
      state = AsyncData(next);
    }
    final last = _lastFlush;
    final due = flush || last == null || now.difference(last) >= _flushEvery;
    if (!due || _pending.isEmpty) return;
    try {
      await _repo.commit(next.state, _mergedIncome(_pending), _config.version);
      _pending.clear();
      _lastFlush = now;
      final lastBackup = _lastBackup;
      if (lastBackup == null || now.difference(lastBackup) >= _backupEvery) {
        await _repo.backup();
        await _repo.pruneLedger(now.subtract(_keepLedger));
        _lastBackup = now;
      }
    } catch (_) {
      state = AsyncData(next.copyWith(saveFailed: true));
    }
  });

  /// Folds the per-second income entries into one ledger row.
  List<LedgerEntry> _mergedIncome(List<LedgerEntry> entries) {
    var sum = 0;
    DateTime? at;
    final rest = <LedgerEntry>[];
    for (final e in entries) {
      if (e.type == LedgerType.income && e.reason == 'income') {
        sum += e.deltaPaisa;
        at = e.at;
      } else {
        rest.add(e);
      }
    }
    return [
      if (at != null)
        LedgerEntry(
          type: LedgerType.income,
          deltaPaisa: sum,
          reason: 'income',
          at: at,
        ),
      ...rest,
    ];
  }

  void _onPause() {
    _ticker?.cancel();
    _ticker = null;
    _tick(flush: true).then((_) => _serial(_repo.backup)).ignore();
  }

  void _onResume() {
    _serial(() async {
      final cur = state.value;
      if (cur == null || cur.saveFailed) return;
      final now = _clock.nowUtc();
      final r = engine.advanceTo(cur.state, now, foreground: false);
      if (identical(r.state, cur.state) && _pending.isEmpty) return;
      try {
        await _repo.commit(
          r.state,
          _mergedIncome([..._pending, ...r.entries]),
          _config.version,
        );
        _pending.clear();
        _lastFlush = now;
        state = AsyncData(
          cur.copyWith(state: r.state, offline: _worthShowing(r) ? r : null),
        );
      } catch (_) {
        state = AsyncData(cur.copyWith(saveFailed: true));
      }
    }).ignore();
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  bool _worthShowing(Settlement r) =>
      r.credited >= const Duration(minutes: 1) && r.earnedPaisa > 0;

  void _stop() {
    _ticker?.cancel();
    _ticker = null;
    _lifecycle?.dispose();
    _lifecycle = null;
  }

  /// One economic operation at a time.
  Future<T> _serial<T>(Future<T> Function() task) {
    final result = _queue.then((_) => task());
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}
