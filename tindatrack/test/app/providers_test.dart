import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/providers.dart';
import 'package:tindatrack/core/database/app_database.dart';
import 'package:tindatrack/core/id/id_generator.dart';
import 'package:tindatrack/core/time/clock.dart';

void main() {
  test('cross-cutting providers support deterministic overrides', () {
    final instant = DateTime.utc(2026, 6, 20);
    final container = ProviderContainer.test(
      overrides: [
        idGeneratorProvider.overrideWithValue(const _FakeIdGenerator()),
        clockProvider.overrideWithValue(_FakeClock(instant)),
      ],
    );

    expect(container.read(idGeneratorProvider).generate(), 'fixed-id');
    expect(container.read(clockProvider).now(), instant);
  });

  test(
    'database provider is lazy and completes resource closure on disposal',
    () async {
      final database = _TrackingDatabase();
      var creationCount = 0;
      final container = ProviderContainer.test(
        overrides: [
          databaseProvider.overrideWith(
            (ref) => createManagedDatabase(ref, () {
              creationCount++;
              return database;
            }),
          ),
        ],
      );

      expect(creationCount, 0);
      expect(container.read(databaseProvider), same(database));
      expect(creationCount, 1);

      container.dispose();

      await database.closed;
      expect(database.wasClosed, isTrue);
    },
  );

  test('managed database close is shared across lifecycle callers', () async {
    final database = _TrackingDatabase();

    await Future.wait([
      closeManagedDatabase(database),
      closeManagedDatabase(database),
    ]);

    expect(database.closeCalls, 1);
  });
}

final class _FakeIdGenerator implements IdGenerator {
  const _FakeIdGenerator();

  @override
  String generate() => 'fixed-id';
}

final class _FakeClock implements Clock {
  const _FakeClock(this._instant);

  final DateTime _instant;

  @override
  DateTime now() => _instant;
}

final class _TrackingDatabase extends AppDatabase {
  _TrackingDatabase() : super(NativeDatabase.memory());

  bool wasClosed = false;
  int closeCalls = 0;
  final _closed = Completer<void>();

  Future<void> get closed => _closed.future;

  @override
  Future<void> close() async {
    closeCalls++;
    await super.close();
    wasClosed = true;
    _closed.complete();
  }
}
