import 'app_database.dart';

/// Small key/value store for settings and tutorial progress.
class PrefsRepository {
  PrefsRepository(this._db);

  final AppDatabase _db;

  Future<Map<String, String>> loadAll() async {
    final rows = await _db.select(_db.prefs).get();
    return {for (final r in rows) r.prefKey: r.prefValue};
  }

  Future<void> set(String key, String value) => _db
      .into(_db.prefs)
      .insertOnConflictUpdate(
        PrefsCompanion.insert(prefKey: key, prefValue: value),
      );
}
