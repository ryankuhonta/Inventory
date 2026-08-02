// Drift check constraints intentionally self-reference generated columns.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

/// Persisted product catalog rows owned by the products feature.
@TableIndex(
  name: 'products_active_name_idx',
  columns: {#isArchived, #name},
)
class Products extends Table {
  /// ULID primary key.
  TextColumn get id => text()();

  /// Product display name.
  TextColumn get name => text()();

  /// Optional product category.
  TextColumn get category => text().nullable()();

  /// Required unit of measure.
  TextColumn get unit => text()();

  /// Non-negative selling price.
  RealColumn get sellingPrice =>
      real().check(sellingPrice.isBiggerOrEqualValue(0))();

  /// Non-negative initial on-hand quantity.
  IntColumn get quantity => integer().check(quantity.isBiggerOrEqualValue(0))();

  /// Non-negative low-stock threshold.
  IntColumn get lowStockThreshold =>
      integer().check(lowStockThreshold.isBiggerOrEqualValue(0))();

  /// Optional globally unique normalized barcode.
  TextColumn get barcode => text().nullable().unique()();

  /// Soft-archive flag, false for newly inserted products.
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  /// UTC creation instant.
  DateTimeColumn get createdAt => dateTime()();

  /// UTC latest-update instant.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
