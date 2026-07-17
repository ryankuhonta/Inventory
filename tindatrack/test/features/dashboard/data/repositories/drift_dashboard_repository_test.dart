import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/database/app_database.dart';
import 'package:tindatrack/core/database/daos/products_dao.dart';
import 'package:tindatrack/core/database/daos/stock_movements_dao.dart';
import 'package:tindatrack/features/dashboard/data/repositories/drift_dashboard_repository.dart';

void main() {
  late AppDatabase database;
  late ProductsDao productsDao;
  late StockMovementsDao stockMovementsDao;
  late DriftDashboardRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    productsDao = ProductsDao(database);
    stockMovementsDao = StockMovementsDao(database);
    repository = DriftDashboardRepository(database);
  });

  tearDown(() => database.close());

  test('summary counts active products and excludes archived rows', () async {
    final localNow = DateTime(2026, 7, 11, 9);
    await _insertProduct(productsDao, 'active-1', 'Rice');
    await _insertProduct(productsDao, 'active-2', 'Soap');
    await _insertProduct(productsDao, 'archived', 'Hidden', archived: true);

    final summary = await repository.watchSummary(localNow: localNow).first;

    expect(summary.totalActiveProducts, 2);
  });

  test('summary counts every active product needing stock attention', () async {
    final localNow = DateTime(2026, 7, 11, 9);
    await _insertProduct(
      productsDao,
      'zero',
      'Zero',
      quantity: 0,
      threshold: 0,
    );
    await _insertProduct(
      productsDao,
      'below',
      'Below',
      quantity: 1,
      threshold: 2,
    );
    await _insertProduct(
      productsDao,
      'equal',
      'Equal',
      quantity: 2,
      threshold: 2,
    );
    await _insertProduct(
      productsDao,
      'above',
      'Above',
      quantity: 3,
      threshold: 2,
    );
    await _insertProduct(
      productsDao,
      'archived-low',
      'Archived Low',
      quantity: 0,
      archived: true,
    );

    final summary = await repository.watchSummary(localNow: localNow).first;

    expect(summary.lowStockProducts, 3);
  });

  test('summary counts stock changes in the current local day', () async {
    final localNow = DateTime(2026, 7, 11, 9);
    final localStart = DateTime(localNow.year, localNow.month, localNow.day);
    final localEnd = DateTime(localNow.year, localNow.month, localNow.day + 1);
    await _insertProduct(productsDao, 'product-1', 'Rice');
    await _insertMovement(
      stockMovementsDao,
      'before',
      localStart.subtract(const Duration(milliseconds: 1)).toUtc(),
    );
    await _insertMovement(
      stockMovementsDao,
      'start',
      localStart.toUtc(),
    );
    await _insertMovement(
      stockMovementsDao,
      'inside',
      localStart.add(const Duration(hours: 12)).toUtc(),
    );
    await _insertMovement(
      stockMovementsDao,
      'end',
      localEnd.toUtc(),
    );

    final summary = await repository.watchSummary(localNow: localNow).first;

    expect(summary.stockChangesToday, 2);
  });

  test(
    'summary uses a local-day window instead of a UTC calendar day',
    () async {
      final localNow = DateTime(2026, 7, 11, 9);
      final localOffset = DateTime(2026, 7, 11).timeZoneOffset;
      if (localOffset == Duration.zero) {
        markTestSkipped(
          'Requires a non-UTC local timezone to prove conversion.',
        );
        return;
      }

      final localStart = DateTime(localNow.year, localNow.month, localNow.day);
      final localEnd = DateTime(
        localNow.year,
        localNow.month,
        localNow.day + 1,
      );
      final movementInsideLocalDay = localOffset.isNegative
          ? localEnd.subtract(const Duration(minutes: 30)).toUtc()
          : localStart.add(const Duration(minutes: 30)).toUtc();
      await _insertProduct(productsDao, 'product-1', 'Rice');
      await _insertMovement(
        stockMovementsDao,
        'inside-local-day-different-utc-day',
        movementInsideLocalDay,
      );

      final summary = await repository.watchSummary(localNow: localNow).first;

      expect(summary.stockChangesToday, 1);
      expect(movementInsideLocalDay.day, isNot(localNow.toUtc().day));
    },
  );

  test(
    'low-stock preview includes attention rows, excludes others, '
    'and limits output',
    () async {
      await _insertProduct(
        productsDao,
        'out-z',
        'Zesto',
        quantity: 0,
        threshold: 5,
      );
      await _insertProduct(
        productsDao,
        'out-a',
        'Apple Juice',
        quantity: 0,
        threshold: 2,
      );
      await _insertProduct(
        productsDao,
        'low-a',
        'Bread',
        quantity: 2,
        threshold: 3,
      );
      await _insertProduct(
        productsDao,
        'low-b',
        'Coffee',
        quantity: 1,
      );
      await _insertProduct(
        productsDao,
        'ok',
        'Rice',
        quantity: 10,
        threshold: 2,
      );
      await _insertProduct(
        productsDao,
        'archived-low',
        'Hidden',
        quantity: 0,
        threshold: 5,
        archived: true,
      );

      final preview = await repository.watchLowStockPreview().first;

      expect(
        preview.map((item) => item.id),
        ['out-a', 'out-z', 'low-a'],
      );
      expect(preview.map((item) => item.name), [
        'Apple Juice',
        'Zesto',
        'Bread',
      ]);
      expect(preview.map((item) => item.quantity), [0, 0, 2]);
      expect(preview.map((item) => item.unit), ['pcs', 'pcs', 'pcs']);
      expect(preview.map((item) => item.status.name), [
        'outOfStock',
        'outOfStock',
        'lowStock',
      ]);
    },
  );

  test(
    'low-stock preview clamps custom limits and uses stable tie-breaks',
    () async {
      await _insertProduct(
        productsDao,
        'out-b',
        'Same Name',
        quantity: 0,
        threshold: 5,
      );
      await _insertProduct(
        productsDao,
        'out-a',
        'Same Name',
        quantity: 0,
        threshold: 5,
      );
      await _insertProduct(
        productsDao,
        'low-a',
        'Bread',
        quantity: 1,
        threshold: 2,
      );
      await _insertProduct(
        productsDao,
        'low-b',
        'Coffee',
        quantity: 1,
        threshold: 2,
      );

      final limited = await repository.watchLowStockPreview(limit: 2).first;
      final negative = await repository.watchLowStockPreview(limit: -1).first;
      final oversized = await repository.watchLowStockPreview(limit: 99).first;

      expect(limited.map((item) => item.id), ['out-a', 'out-b']);
      expect(negative, isEmpty);
      expect(oversized, hasLength(3));
    },
  );

  test(
    'low-stock preview stream re-emits from focused table watches',
    () async {
      final stream = repository.watchLowStockPreview();
      final emissions = StreamIterator(stream);
      addTearDown(emissions.cancel);

      expect(await emissions.moveNext(), isTrue);
      expect(emissions.current, isEmpty);

      await _insertProduct(
        productsDao,
        'low-1',
        'Rice',
        quantity: 1,
        threshold: 2,
      );

      expect(await emissions.moveNext(), isTrue);
      expect(emissions.current.map((item) => item.id), ['low-1']);
    },
  );

  test(
    'recent activity preview orders newest first and limits output',
    () async {
      await _insertProduct(productsDao, 'product-1', 'Rice');
      final sameInstant = DateTime.utc(2026, 7, 11, 9);
      await _insertMovement(
        stockMovementsDao,
        'old',
        sameInstant.subtract(const Duration(minutes: 1)),
      );
      await _insertMovement(stockMovementsDao, 'tie-a', sameInstant);
      await _insertMovement(stockMovementsDao, 'tie-b', sameInstant);
      await _insertMovement(
        stockMovementsDao,
        'new',
        sameInstant.add(const Duration(minutes: 1)),
      );

      final preview = await repository.watchRecentActivityPreview().first;

      expect(preview.map((item) => item.id), ['new', 'tie-b', 'tie-a']);
    },
  );

  test(
    'recent activity preview clamps custom limits',
    () async {
      await _insertProduct(productsDao, 'product-1', 'Rice');
      final instant = DateTime.utc(2026, 7, 11, 9);
      await _insertMovement(stockMovementsDao, 'one', instant);
      await _insertMovement(
        stockMovementsDao,
        'two',
        instant.add(const Duration(minutes: 1)),
      );
      await _insertMovement(
        stockMovementsDao,
        'three',
        instant.add(const Duration(minutes: 2)),
      );
      await _insertMovement(
        stockMovementsDao,
        'four',
        instant.add(const Duration(minutes: 3)),
      );

      final limited = await repository
          .watchRecentActivityPreview(limit: 2)
          .first;
      final negative = await repository
          .watchRecentActivityPreview(limit: -1)
          .first;
      final oversized = await repository
          .watchRecentActivityPreview(limit: 99)
          .first;

      expect(limited.map((item) => item.id), ['four', 'three']);
      expect(negative, isEmpty);
      expect(oversized, hasLength(3));
    },
  );

  test(
    'recent activity preview maps movement fields and optional notes',
    () async {
      final createdAt = DateTime.utc(2026, 7, 11, 9, 30);
      await _insertProduct(productsDao, 'product-1', 'Rice');
      await _insertMovement(
        stockMovementsDao,
        'stock-out-1',
        createdAt,
        type: 'stock_out',
        quantity: 4,
        previousQuantity: 9,
        newQuantity: 5,
        productNameSnapshot: 'Bigas snapshot',
        unitSnapshot: 'sacks',
        note: 'Customer order',
      );

      final preview = await repository.watchRecentActivityPreview().first;
      final item = preview.single;

      expect(item.id, 'stock-out-1');
      expect(item.type.name, 'stockOut');
      expect(item.quantity, 4);
      expect(item.productNameSnapshot, 'Bigas snapshot');
      expect(item.unitSnapshot, 'sacks');
      expect(item.note, 'Customer order');
      expect(item.createdAt, createdAt);
    },
  );

  test(
    'recent activity preview stream re-emits from movement watches',
    () async {
      await _insertProduct(productsDao, 'product-1', 'Rice');
      final stream = repository.watchRecentActivityPreview();
      final emissions = StreamIterator(stream);
      addTearDown(emissions.cancel);

      expect(await emissions.moveNext(), isTrue);
      expect(emissions.current, isEmpty);

      await _insertMovement(
        stockMovementsDao,
        'movement-1',
        DateTime.utc(2026, 7, 11, 9),
      );

      expect(await emissions.moveNext(), isTrue);
      expect(emissions.current.map((item) => item.id), ['movement-1']);
    },
  );

  test('summary stream re-emits from focused table watches', () async {
    final localNow = DateTime(2026, 7, 11, 9);
    final stream = repository.watchSummary(localNow: localNow);
    final emissions = StreamIterator(stream);
    addTearDown(emissions.cancel);

    expect(await emissions.moveNext(), isTrue);
    expect(emissions.current.totalActiveProducts, 0);

    await _insertProduct(productsDao, 'product-1', 'Rice');

    expect(await emissions.moveNext(), isTrue);
    expect(emissions.current.totalActiveProducts, 1);
  });
}

Future<void> _insertProduct(
  ProductsDao dao,
  String id,
  String name, {
  int quantity = 5,
  int threshold = 1,
  bool archived = false,
}) {
  final instant = DateTime.utc(2026, 7);
  return dao.insertProduct(
    ProductsCompanion.insert(
      id: id,
      name: name,
      unit: 'pcs',
      sellingPrice: 10,
      quantity: quantity,
      lowStockThreshold: threshold,
      isArchived: Value(archived),
      createdAt: instant,
      updatedAt: instant,
    ),
  );
}

Future<void> _insertMovement(
  StockMovementsDao dao,
  String id,
  DateTime createdAt, {
  String type = 'stock_in',
  int quantity = 1,
  int previousQuantity = 5,
  int newQuantity = 6,
  String productNameSnapshot = 'Rice',
  String unitSnapshot = 'pcs',
  String? note,
}) {
  return dao.insertMovement(
    StockMovementsCompanion.insert(
      id: id,
      productId: 'product-1',
      type: type,
      quantity: quantity,
      previousQuantity: previousQuantity,
      newQuantity: newQuantity,
      note: Value(note),
      productNameSnapshot: productNameSnapshot,
      unitSnapshot: unitSnapshot,
      createdAt: createdAt,
    ),
  );
}
