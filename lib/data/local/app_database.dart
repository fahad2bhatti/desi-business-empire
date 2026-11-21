import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// One row per save slot: `main` plus two rotating backups.
class SaveSlots extends Table {
  TextColumn get slot => text()();
  IntColumn get schemaVersion => integer()();
  IntColumn get configVersion => integer()();
  IntColumn get revision => integer()();
  TextColumn get data => text()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {slot};
}

/// Every money movement. (revision, idx) is unique, so the same command
/// can never be written twice.
class LedgerRows extends Table {
  IntColumn get revision => integer()();
  IntColumn get idx => integer()();
  TextColumn get type => text()();
  IntColumn get deltaPaisa => integer()();
  TextColumn get reason => text()();
  DateTimeColumn get at => dateTime()();

  @override
  Set<Column> get primaryKey => {revision, idx};
}

@DriftDatabase(tables: [SaveSlots, LedgerRows])
class AppDatabase extends _$AppDatabase {
  /// Pass an executor in tests (e.g. `NativeDatabase.memory()`).
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'desi_business_empire'));

  @override
  int get schemaVersion => 1;
}
