import 'package:desi_business_empire/data/local/app_database.dart';
import 'package:desi_business_empire/data/local/prefs_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late PrefsRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = PrefsRepository(db);
  });
  tearDown(() => db.close());

  test('starts empty, stores and overwrites values', () async {
    expect(await repo.loadAll(), isEmpty);
    await repo.set('businessName', 'Chaudhry Samosa Corner');
    await repo.set('tutorialStep', '2');
    await repo.set('tutorialStep', '3');
    expect(await repo.loadAll(), {
      'businessName': 'Chaudhry Samosa Corner',
      'tutorialStep': '3',
    });
  });
}
