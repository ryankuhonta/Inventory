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
      threshold: 5,
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
  DateTime createdAt,
) {
  return dao.insertMovement(
    StockMovementsCompanion.insert(
      id: id,
      productId: 'product-1',
      type: 'stock_in',
      quantity: 1,
      previousQuantity: 5,
      newQuantity: 6,
      productNameSnapshot: 'Rice',
      unitSnapshot: 'pcs',
      createdAt: createdAt,
    ),
  );
}
