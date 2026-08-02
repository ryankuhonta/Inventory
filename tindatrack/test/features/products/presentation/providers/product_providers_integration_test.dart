import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/providers.dart';
import 'package:tindatrack/core/database/app_database.dart' show AppDatabase;
import 'package:tindatrack/core/database/daos/products_dao.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/core/id/id_generator.dart';
import 'package:tindatrack/core/time/clock.dart';
import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';

void main() {
  test('provider-composed Add Product persists normalized values', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer.test(
      overrides: [
        databaseProvider.overrideWithValue(database),
        idGeneratorProvider.overrideWithValue(const _FixedIdGenerator()),
        clockProvider.overrideWithValue(
          _FixedClock(DateTime.utc(2026, 6, 29, 6, 30)),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await database.close();
    });

    final result = await container.read(addProductProvider)(
      const CreateProductInput(
        name: '  Rice  ',
        category: '   ',
        unit: '  pcs ',
        sellingPrice: 0,
        quantity: 0,
        lowStockThreshold: 0,
      ),
    );
    final rows = await ProductsDao(database).watchActiveProducts().first;

    expect(result, isA<Success<Product>>());
    expect(rows, hasLength(1));
    expect(rows.single.id, 'fixed-id');
    expect(rows.single.name, 'Rice');
    expect(rows.single.category, isNull);
    expect(rows.single.unit, 'pcs');
    expect(rows.single.sellingPrice, 0);
    expect(rows.single.quantity, 0);
    expect(rows.single.lowStockThreshold, 0);
    expect(rows.single.barcode, isNull);
    expect(rows.single.createdAt.toUtc(), DateTime.utc(2026, 6, 29, 6, 30));
  });

  test(
    'provider-composed Add Product allows duplicate product names',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final container = ProviderContainer.test(
        overrides: [
          databaseProvider.overrideWithValue(database),
          idGeneratorProvider.overrideWithValue(_SequenceIdGenerator()),
          clockProvider.overrideWithValue(
            _FixedClock(DateTime.utc(2026, 6, 29, 6, 30)),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await database.close();
      });

      final addProduct = container.read(addProductProvider);
      final first = await addProduct(
        const CreateProductInput(
          name: ' Rice ',
          unit: 'pcs',
          sellingPrice: 10,
          quantity: 1,
          lowStockThreshold: 0,
        ),
      );
      final second = await addProduct(
        const CreateProductInput(
          name: 'Rice',
          unit: 'kg',
          sellingPrice: 20,
          quantity: 2,
          lowStockThreshold: 1,
        ),
      );
      final rows = await ProductsDao(database).watchActiveProducts().first;

      expect(first, isA<Success<Product>>());
      expect(second, isA<Success<Product>>());
      expect(rows, hasLength(2));
      expect(rows.map((product) => product.name), everyElement('Rice'));
    },
  );

  test(
    'real repository stream emits after provider-composed Add Product',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final container = ProviderContainer.test(
        overrides: [
          databaseProvider.overrideWithValue(database),
          idGeneratorProvider.overrideWithValue(const _FixedIdGenerator()),
          clockProvider.overrideWithValue(
            _FixedClock(DateTime.utc(2026, 6, 30, 6, 30)),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await database.close();
      });
      final updated = Completer<List<Product>>();
      final subscription = container.listen(
        activeProductsProvider,
        (_, next) {
          if (next case AsyncData(:final value) when value.isNotEmpty) {
            updated.complete(value);
          }
        },
      );
      addTearDown(subscription.close);

      expect(await container.read(activeProductsProvider.future), isEmpty);
      final result = await container.read(addProductProvider)(
        const CreateProductInput(
          name: 'Rice',
          unit: 'pcs',
          sellingPrice: 0,
          quantity: 4,
          lowStockThreshold: 1,
        ),
      );
      final products = await updated.future;

      expect(result, isA<Success<Product>>());
      expect(products.single.name, 'Rice');
      expect(products.single.quantity, 4);
    },
  );
}

final class _FixedIdGenerator implements IdGenerator {
  const _FixedIdGenerator();

  @override
  String generate() => 'fixed-id';
}

final class _SequenceIdGenerator implements IdGenerator {
  var _next = 0;

  @override
  String generate() {
    _next++;
    return 'fixed-id-$_next';
  }
}

final class _FixedClock implements Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
