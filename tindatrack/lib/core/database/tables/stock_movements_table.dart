// Drift check constraints intentionally self-reference generated columns.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';
import 'package:tindatrack/core/database/tables/products_table.dart';

/// Persisted value for Stock In movements.
const String stockMovementTypeStockIn = 'stock_in';

/// Persisted value for Stock Out movements.
const String stockMovementTypeStockOut = 'stock_out';

/// Persisted reason for sold Stock Out movements.
const String stockOutReasonSold = 'sold';

/// Persisted reason for damaged Stock Out movements.
const String stockOutReasonDamaged = 'damaged';

/// Persisted reason for lost Stock Out movements.
const String stockOutReasonLost = 'lost';

/// Persisted reason for personal-use Stock Out movements.
const String stockOutReasonPersonalUse = 'personal_use';

/// Persisted reason for correction Stock Out movements.
const String stockOutReasonCorrection = 'correction';

/// Allowed persisted stock movement type values.
const List<String> stockMovementTypes = [
  stockMovementTypeStockIn,
  stockMovementTypeStockOut,
];

/// Allowed persisted Stock Out reason values.
const List<String> stockOutReasons = [
  stockOutReasonSold,
  stockOutReasonDamaged,
  stockOutReasonLost,
  stockOutReasonPersonalUse,
  stockOutReasonCorrection,
];

/// Persisted audit rows for local inventory quantity changes.
@TableIndex(
  name: 'stock_movements_product_created_at_idx',
  columns: {#productId, #createdAt},
)
@TableIndex(
  name: 'stock_movements_created_at_idx',
  columns: {#createdAt},
)
class StockMovements extends Table {
  /// ULID primary key.
  TextColumn get id => text()();

  /// Product identity at the time of movement.
  TextColumn get productId => text().references(Products, #id)();

  /// Persisted movement type: `stock_in` or `stock_out`.
  TextColumn get type => text().check(type.isIn(stockMovementTypes))();

  /// Positive quantity moved.
  IntColumn get quantity => integer().check(quantity.isBiggerThanValue(0))();

  /// Quantity before the movement.
  IntColumn get previousQuantity => integer().check(
    previousQuantity.isBiggerOrEqualValue(0),
  )();

  /// Quantity after the movement.
  IntColumn get newQuantity => integer().check(
    newQuantity.isBiggerOrEqualValue(0),
  )();

  /// Optional Stock Out reason.
  TextColumn get reason => text().nullable().check(
    reason.isNull() | reason.isIn(stockOutReasons),
  )();

  /// Optional user-entered note.
  TextColumn get note => text().nullable()();

  /// Product name copied at movement creation time.
  TextColumn get productNameSnapshot => text()();

  /// Product unit copied at movement creation time.
  TextColumn get unitSnapshot => text()();

  /// UTC creation instant.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
