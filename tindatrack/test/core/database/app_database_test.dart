import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('uses product catalog schema version 2', () {
    expect(database.schemaVersion, 2);
  });

  test('contains only the Story 2.1 products feature table', () async {
    final rows = await database.customSelect(
      '''
SELECT name FROM sqlite_master
WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
ORDER BY name
''',
    ).get();
    final names = rows.map((row) => row.read<String>('name')).toSet();

    expect(names, {'products'});
  });

  test('readiness probe opens and queries the database', () async {
    await expectLater(database.ensureReady(), completes);
  });
}
