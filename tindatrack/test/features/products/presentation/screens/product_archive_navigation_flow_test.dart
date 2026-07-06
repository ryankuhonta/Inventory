import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/providers.dart';
import 'package:tindatrack/app/router/app_router.dart';
import 'package:tindatrack/app/router/app_routes.dart';
import 'package:tindatrack/app/theme/app_theme.dart';
import 'package:tindatrack/core/database/app_database.dart';
import 'package:tindatrack/core/database/daos/products_dao.dart';
import 'package:tindatrack/core/id/id_generator.dart';
import 'package:tindatrack/core/time/clock.dart';

void main() {
  testWidgets(
    'real row archive preserves query and disappears through Drift',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final createdAt = DateTime.utc(2026, 7);
      await ProductsDao(database).insertProduct(
        ProductsCompanion.insert(
          id: 'product-1',
          name: 'Rice',
          unit: 'pcs',
          sellingPrice: 50,
          quantity: 1,
          lowStockThreshold: 2,
          barcode: const Value('123'),
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
      final router = createAppRouter(
        initialLocation: AppRoute.products.path,
        dashboardBuilder: (_, _) => const Scaffold(),
        historyBuilder: (_, _) => const Scaffold(),
        settingsBuilder: (_, _) => const Scaffold(),
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            idGeneratorProvider.overrideWithValue(const _FixedIdGenerator()),
            clockProvider.overrideWithValue(
              _FixedClock(DateTime.utc(2026, 7, 6, 8, 30)),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(
        find.byKey(const Key('product-search-field')),
        'rice',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(
        find.byKey(const ValueKey('product-filter-lowStock')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final row = find.byKey(const ValueKey('product-row-product-1'));
      expect(row, findsOneWidget);
      await tester.tap(row);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.ensureVisible(
        find.byKey(const Key('archive-product-button')),
      );
      await tester.tap(find.byKey(const Key('archive-product-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const Key('confirm-archive-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(router.routeInformationProvider.value.uri.path, '/products');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('product-search-field')))
            .controller
            ?.text,
        'rice',
      );
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const ValueKey('product-filter-lowStock')),
            )
            .selected,
        isTrue,
      );
      expect(row, findsNothing);
      expect(find.byKey(const Key('products-no-match-state')), findsOneWidget);
      expect(find.text('Product archived.'), findsOneWidget);

      final retained = await ProductsDao(database).getProductById('product-1');
      expect(retained, isNotNull);
      expect(retained?.isArchived, isTrue);
      expect(retained?.quantity, 1);
      expect(retained?.barcode, '123');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
}

final class _FixedIdGenerator implements IdGenerator {
  const _FixedIdGenerator();

  @override
  String generate() => 'unexpected';
}

final class _FixedClock implements Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
