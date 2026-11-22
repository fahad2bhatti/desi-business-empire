import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/economy/command_result.dart';
import '../../domain/economy/economy_config.dart';
import '../../domain/economy/game_state.dart';
import 'app_database.dart';
import 'game_state_codec.dart';

/// No slot could be read. The UI must offer an explicit reset; the save is
/// never wiped silently.
class SaveCorruptException implements Exception {
  const SaveCorruptException();
}

/// A write tried to go back to (or repeat) an older revision.
class StaleSaveException implements Exception {
  const StaleSaveException(this.stored, this.attempted);

  final int stored;
  final int attempted;

  @override
  String toString() =>
      'StaleSaveException(stored: $stored, attempted: $attempted)';
}

class LoadedSave {
  const LoadedSave(this.state, {required this.restoredFromBackup});

  final GameState state;
  final bool restoredFromBackup;
}

class SaveRepository {
  SaveRepository(this._db);

  final AppDatabase _db;

  static const mainSlot = 'main';
  static const backupSlots = ['backup_1', 'backup_2'];

  Future<SaveSlot?> _row(String slot) => (_db.select(
    _db.saveSlots,
  )..where((t) => t.slot.equals(slot))).getSingleOrNull();

  /// `null` means there is no save yet (new player).
  Future<LoadedSave?> load(EconomyConfig config) async {
    final main = await _row(mainSlot);
    if (main == null) return null;
    // An older game version: start fresh (founder decision, 2026-11-21).
    if (main.schemaVersion < saveSchemaVersion) return null;
    final state = _decode(main, config);
    if (state != null) return LoadedSave(state, restoredFromBackup: false);
    for (final slot in backupSlots) {
      final row = await _row(slot);
      final backup = row == null ? null : _decode(row, config);
      if (backup != null) return LoadedSave(backup, restoredFromBackup: true);
    }
    throw const SaveCorruptException();
  }

  GameState? _decode(SaveSlot row, EconomyConfig config) {
    if (row.schemaVersion != saveSchemaVersion) {
      return null; // no migrations yet
    }
    try {
      return decodeGameState(
        jsonDecode(row.data) as Map<String, Object?>,
        config,
      );
    } on Object {
      return null;
    }
  }

  /// Writes the new state and its ledger entries in one transaction.
  /// Throws [StaleSaveException] if the stored revision is not older.
  Future<void> commit(
    GameState s,
    List<LedgerEntry> entries,
    int configVersion,
  ) => _db.transaction(() async {
    final stored = await _row(mainSlot);
    if (stored != null && stored.revision >= s.revision) {
      throw StaleSaveException(stored.revision, s.revision);
    }
    await _db
        .into(_db.saveSlots)
        .insertOnConflictUpdate(_slot(mainSlot, s, configVersion));
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      await _db
          .into(_db.ledgerRows)
          .insert(
            LedgerRowsCompanion.insert(
              revision: s.revision,
              idx: i,
              type: e.type.name,
              deltaPaisa: e.deltaPaisa,
              reason: e.reason,
              at: e.at,
            ),
          );
    }
  });

  /// Overwrites the main slot without the revision check. Only for a fresh
  /// game or a state restored from a backup.
  Future<void> replaceMain(
    GameState s,
    int configVersion, {
    bool clearLedger = false,
  }) => _db.transaction(() async {
    if (clearLedger) await _db.delete(_db.ledgerRows).go();
    await _db
        .into(_db.saveSlots)
        .insertOnConflictUpdate(_slot(mainSlot, s, configVersion));
  });

  /// Copies main -> backup_1 -> backup_2 (oldest dropped).
  Future<void> backup() => _db.transaction(() async {
    final main = await _row(mainSlot);
    if (main == null) return;
    final first = await _row(backupSlots[0]);
    if (first != null) {
      await _db
          .into(_db.saveSlots)
          .insertOnConflictUpdate(first.copyWith(slot: backupSlots[1]));
    }
    await _db
        .into(_db.saveSlots)
        .insertOnConflictUpdate(main.copyWith(slot: backupSlots[0]));
  });

  /// Wipes everything and starts over. Only after the player confirms.
  Future<void> resetTo(GameState fresh, int configVersion) =>
      _db.transaction(() async {
        await _db.delete(_db.saveSlots).go();
        await _db.delete(_db.ledgerRows).go();
        await _db
            .into(_db.saveSlots)
            .insertOnConflictUpdate(_slot(mainSlot, fresh, configVersion));
      });

  Future<List<LedgerRow>> recentLedger({int limit = 50}) =>
      (_db.select(_db.ledgerRows)
            ..orderBy([
              (t) => OrderingTerm.desc(t.revision),
              (t) => OrderingTerm.desc(t.idx),
            ])
            ..limit(limit))
          .get();

  Future<List<LedgerRow>> ledgerSince(DateTime since) => (_db.select(
    _db.ledgerRows,
  )..where((t) => t.at.isBiggerOrEqualValue(since))).get();

  /// Buys, sells, rewards and tax, newest first: everything except the
  /// per-second income and Work taps.
  Future<List<LedgerRow>> transactions({int limit = 200}) =>
      (_db.select(_db.ledgerRows)
            ..where((t) => t.type.isNotIn(_noisyTypes))
            ..orderBy([
              (t) => OrderingTerm.desc(t.revision),
              (t) => OrderingTerm.desc(t.idx),
            ])
            ..limit(limit))
          .get();

  /// Keeps the ledger small: the foreground tick writes a few rows a second.
  /// Only income and Work rows are pruned; transactions are kept.
  Future<int> pruneLedger(DateTime before) =>
      (_db.delete(_db.ledgerRows)..where(
            (t) => t.at.isSmallerThanValue(before) & t.type.isIn(_noisyTypes),
          ))
          .go();

  static final _noisyTypes = [LedgerType.income.name, LedgerType.work.name];

  SaveSlotsCompanion _slot(String slot, GameState s, int configVersion) =>
      SaveSlotsCompanion.insert(
        slot: slot,
        schemaVersion: saveSchemaVersion,
        configVersion: configVersion,
        revision: s.revision,
        data: jsonEncode(encodeGameState(s)),
        savedAt: s.lastSettledAt,
      );
}
