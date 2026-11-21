import 'dart:convert';
import 'dart:io';

import 'package:desi_business_empire/data/local/app_database.dart';
import 'package:desi_business_empire/data/local/game_state_codec.dart';
import 'package:desi_business_empire/data/local/save_repository.dart';
import 'package:desi_business_empire/domain/economy/command_result.dart';
import 'package:desi_business_empire/domain/economy/economy_config.dart';
import 'package:desi_business_empire/domain/economy/game_engine.dart';
import 'package:desi_business_empire/domain/economy/game_state.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

final config = EconomyConfig.parse(
  File('assets/config/economy_v0.json').readAsStringSync(),
);
final engine = GameEngine(config);
final t0 = DateTime.utc(2026, 1, 1, 12);

void main() {
  late AppDatabase db;
  late SaveRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = SaveRepository(db);
  });
  tearDown(() => db.close());

  Future<void> writeRaw(String slot, String data, {int revision = 1}) => db
      .into(db.saveSlots)
      .insertOnConflictUpdate(
        SaveSlotsCompanion.insert(
          slot: slot,
          schemaVersion: saveSchemaVersion,
          configVersion: 1,
          revision: revision,
          data: data,
          savedAt: t0,
        ),
      );

  test('codec round trip keeps every field', () {
    var s = GameState.newGame(config, t0);
    s = (engine.buyStock(s, 'stall', 'samosa', 10, t0) as Success).state;
    s = (engine.startBatch(s, 'stall', 'samosa', t0) as Success).state;
    s = (engine.doWork(s, t0) as Success).state;
    final json = jsonEncode(encodeGameState(s));
    final back = decodeGameState(
      jsonDecode(json) as Map<String, Object?>,
      config,
    );
    expect(jsonEncode(encodeGameState(back)), json);
    expect(
      back.stages['stall']!.lines['samosa']!.batchEndsAt,
      t0.add(const Duration(seconds: 30)),
    );
  });

  test('codec rejects saves that break invariants', () {
    final map = encodeGameState(GameState.newGame(config, t0));
    map['cashPaisa'] = -1;
    expect(() => decodeGameState(map, config), throwsFormatException);
  });

  test('no save yet loads as null', () async {
    expect(await repo.load(config), isNull);
  });

  test(
    'commit stores state and ledger in one go, and refuses old revisions',
    () async {
      final fresh = GameState.newGame(config, t0);
      await repo.replaceMain(fresh, config.version);
      final r = engine.buyStock(fresh, 'stall', 'samosa', 10, t0) as Success;
      await repo.commit(r.state, r.entries, config.version);

      final loaded = await repo.load(config);
      expect(loaded!.state.revision, 1);
      expect(loaded.state.cashPaisa, 50000 - 12000);
      expect(loaded.restoredFromBackup, isFalse);
      final ledger = await repo.recentLedger();
      expect(ledger.single.deltaPaisa, -12000);

      await expectLater(
        repo.commit(r.state, r.entries, config.version),
        throwsA(isA<StaleSaveException>()),
      );
      expect(
        (await repo.recentLedger()).length,
        1,
        reason: 'failed commit must not add rows',
      );
    },
  );

  test('a broken main save falls back to the newest good backup', () async {
    final s = GameState.newGame(config, t0);
    await repo.replaceMain(s, config.version);
    await repo.backup();
    await writeRaw(SaveRepository.mainSlot, '{not json', revision: 9);
    final loaded = await repo.load(config);
    expect(loaded!.restoredFromBackup, isTrue);
    expect(loaded.state.cashPaisa, s.cashPaisa);
  });

  test('when every slot is broken it says so instead of wiping', () async {
    await writeRaw(SaveRepository.mainSlot, '{}');
    await writeRaw(SaveRepository.backupSlots[0], 'x');
    await expectLater(repo.load(config), throwsA(isA<SaveCorruptException>()));
    final rows = await db.select(db.saveSlots).get();
    expect(rows.length, 2, reason: 'nothing deleted');
  });

  test('backup rotates main -> backup_1 -> backup_2', () async {
    final s0 = GameState.newGame(config, t0);
    await repo.replaceMain(s0, config.version);
    await repo.backup();
    final s1 = (engine.doWork(s0, t0) as Success).state;
    await repo.commit(s1, const [], config.version);
    await repo.backup();
    final rows = {
      for (final r in await db.select(db.saveSlots).get()) r.slot: r.revision,
    };
    expect(rows, {'main': 1, 'backup_1': 1, 'backup_2': 0});
  });

  test('resetTo wipes slots and ledger and starts fresh', () async {
    final s = GameState.newGame(config, t0);
    await repo.replaceMain(s, config.version);
    final r = engine.doWork(s, t0) as Success;
    await repo.commit(r.state, r.entries, config.version);
    await repo.resetTo(GameState.newGame(config, t0), config.version);
    expect((await repo.load(config))!.state.revision, 0);
    expect(await repo.recentLedger(), isEmpty);
  });

  test('ledgerSince and pruneLedger work on time', () async {
    final s = GameState.newGame(config, t0);
    await repo.replaceMain(s, config.version);
    final a = engine.doWork(s, t0) as Success;
    await repo.commit(a.state, a.entries, config.version);
    final later = t0.add(const Duration(hours: 3));
    final b = engine.doWork(a.state, later) as Success;
    await repo.commit(b.state, b.entries, config.version);

    expect(
      (await repo.ledgerSince(t0.add(const Duration(hours: 1)))).length,
      1,
    );
    expect(await repo.pruneLedger(t0.add(const Duration(hours: 1))), 1);
    expect((await repo.recentLedger()).single.revision, 2);
  });
}
