import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tindatrack/app/router/app_routes.dart';
import 'package:tindatrack/app/theme/app_theme.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/entities/product_list_query.dart';
import 'package:tindatrack/features/products/domain/entities/update_product_input.dart';
import 'package:tindatrack/features/products/domain/repositories/products_repository.dart';
import 'package:tindatrack/features/products/domain/usecases/archive_product.dart';
import 'package:tindatrack/features/products/domain/usecases/get_product.dart';
import 'package:tindatrack/features/products/domain/usecases/update_product.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';
import 'package:tindatrack/features/products/presentation/screens/edit_product_screen.dart';

void main() {
  testWidgets('archive is a labeled secondary destructive action', (
    tester,
  ) async {
    await _pumpEdit(tester, _Repository());

    final finder = find.byKey(const Key('archive-product-button'));
    expect(finder, findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Archive'), findsOneWidget);
    expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
    final button = tester.widget<OutlinedButton>(finder);
    final foreground = button.style?.foregroundColor?.resolve({});
    expect(foreground, AppTheme.light.colorScheme.error);
  });

  testWidgets('confirmation reassures, and cancel or barrier does nothing', (
    tester,
  ) async {
    final repository = _Repository();
    await _pumpEdit(tester, repository);

    await tester.ensureVisible(
      find.byKey(const Key('archive-product-button')),
    );
    await tester.tap(find.byKey(const Key('archive-product-button')));
    await tester.pumpAndSettle();
    expect(find.text('Archive product?'), findsOneWidget);
    expect(find.textContaining('Archive Rice?'), findsOneWidget);
    expect(
      find.textContaining(
        'This product will be hidden from your active list. '
        'Its inventory history will still be available.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('cancel-archive-button')));
    await tester.pumpAndSettle();
    expect(repository.archiveCalls, 0);

    await tester.ensureVisible(
      find.byKey(const Key('archive-product-button')),
    );
    await tester.tap(find.byKey(const Key('archive-product-button')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(4, 300));
    await tester.pumpAndSettle();
    expect(find.text('Archive product?'), findsNothing);
    expect(repository.archiveCalls, 0);
  });

  testWidgets(
    'system back cancels accessibly and preserves edited form values',
    (tester) async {
      final semantics = tester.ensureSemantics();

      final repository = _Repository();
      await _pumpEdit(tester, repository);
      await tester.enterText(
        find.byKey(const Key('edit-product-name-field')),
        'Edited Rice',
      );

      await tester.ensureVisible(
        find.byKey(const Key('archive-product-button')),
      );
      await tester.tap(find.byKey(const Key('archive-product-button')));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Archive product confirmation'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('cancel-archive-button')),
          matching: find.bySemanticsLabel('Cancel'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('confirm-archive-button')),
          matching: find.bySemanticsLabel('Archive'),
        ),
        findsOneWidget,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(repository.archiveCalls, 0);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('edit-product-name-field')),
            )
            .controller
            ?.text,
        'Edited Rice',
      );
      semantics.dispose();
    },
  );

  testWidgets('confirmed archive shows feedback and returns to Products', (
    tester,
  ) async {
    final repository = _Repository();
    await _pumpEdit(tester, repository);

    await _confirmArchive(tester);
    await tester.pumpAndSettle();

    expect(repository.archiveCalls, 1);
    expect(repository.lastArchivedId, 'product-1');
    expect(find.byKey(const Key('products-return-screen')), findsOneWidget);
    expect(find.text('Product archived.'), findsOneWidget);
  });

  testWidgets('pending archive locks form, actions, and back navigation', (
    tester,
  ) async {
    final pending = Completer<Result<void>>();
    final repository = _Repository(onArchive: (_) => pending.future);
    await _pumpEdit(tester, repository);

    await _confirmArchive(tester);
    await tester.pump();
    await tester.pageBack();
    await tester.pump();

    expect(find.byKey(const Key('edit-product-screen')), findsOneWidget);
    expect(find.text('Archiving...'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('archive-product-button')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('save-product-changes-button')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('edit-product-name-field')),
          )
          .enabled,
      isFalse,
    );

    pending.complete(const Success<void>(null));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('products-return-screen')), findsOneWidget);
  });

  testWidgets('archive progress has one screen-reader announcement', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final pending = Completer<Result<void>>();
    await _pumpEdit(
      tester,
      _Repository(onArchive: (_) => pending.future),
    );

    await _confirmArchive(tester);
    await tester.pump();

    expect(find.bySemanticsLabel('Archiving product'), findsOneWidget);
    expect(find.bySemanticsLabel('Archiving...'), findsNothing);

    pending.complete(const Success<void>(null));
    await tester.pumpAndSettle();
    semantics.dispose();
  });

  testWidgets('archive failure stays recoverable without diagnostics', (
    tester,
  ) async {
    final repository = _Repository(
      onArchive: (_) async => const FailureResult<void>(
        PersistenceFailure(debugMessage: 'SQLITE_PRIVATE'),
      ),
    );
    await _pumpEdit(tester, repository);

    await _confirmArchive(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edit-product-screen')), findsOneWidget);
    expect(
      find.text("We couldn't archive this product. Please try again."),
      findsOneWidget,
    );
    expect(find.textContaining('SQLITE_PRIVATE'), findsNothing);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('archive-product-button')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('confirmation actions stay reachable for a long scaled name', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repository = _Repository(
      productName: List<String>.filled(20, 'Extra long product name').join(' '),
    );
    await _pumpEdit(tester, repository);

    await tester.ensureVisible(
      find.byKey(const Key('archive-product-button')),
    );
    await tester.tap(find.byKey(const Key('archive-product-button')));
    await tester.pumpAndSettle();

    final confirm = find.byKey(const Key('confirm-archive-button'));
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(confirm, findsOneWidget);
    expect(tester.getBottomRight(confirm).dy, lessThanOrEqualTo(640));
    expect(tester.takeException(), isNull);

    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(repository.archiveCalls, 1);
  });
}

Future<void> _confirmArchive(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('archive-product-button')));
  await tester.ensureVisible(
    find.byKey(const Key('archive-product-button')),
  );
  await tester.tap(find.byKey(const Key('archive-product-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('confirm-archive-button')));
}

Future<void> _pumpEdit(
  WidgetTester tester,
  _Repository repository,
) async {
  final router = GoRouter(
    initialLocation: '/products/product-1/edit',
    routes: [
      GoRoute(
        path: '/products',
        name: AppRoute.products.name,
        builder: (_, _) => const Scaffold(key: Key('products-return-screen')),
        routes: [
          GoRoute(
            path: ':productId/edit',
            name: ProductRoute.editProduct.name,
            builder: (_, state) => EditProductScreen(
              productId: state.pathParameters['productId']!,
            ),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        archiveProductProvider.overrideWithValue(ArchiveProduct(repository)),
        getProductProvider.overrideWithValue(GetProduct(repository)),
        updateProductProvider.overrideWithValue(UpdateProduct(repository)),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _Repository implements ProductRepository {
  _Repository({this.onArchive, this.productName = 'Rice'});

  final Future<Result<void>> Function(String id)? onArchive;
  final String productName;
  int archiveCalls = 0;
  String? lastArchivedId;

  @override
  Future<Result<void>> archiveProduct(String id) {
    archiveCalls++;
    lastArchivedId = id;
    return onArchive?.call(id) ??
        Future<Result<void>>.value(const Success<void>(null));
  }

  @override
  Future<Result<Product>> createProduct(CreateProductInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Product>> getProduct(String id) async {
    return Success<Product>(_product(productName));
  }

  @override
  Future<Result<Product>> updateProduct(
    String id,
    UpdateProductInput input,
  ) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Product>> watchActiveProducts(ProductListQuery query) {
    return const Stream<List<Product>>.empty();
  }

  @override
  Future<Result<void>> restoreProduct(String id) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Product>> watchArchivedProducts() {
    throw UnimplementedError();
  }
}

Product _product([String name = 'Rice']) {
  return Product(
    id: 'product-1',
    name: name,
    category: 'Staples',
    unit: 'pcs',
    sellingPrice: 50,
    quantity: 8,
    lowStockThreshold: 2,
    barcode: '123',
    isArchived: false,
    createdAt: DateTime.utc(2026, 7),
    updatedAt: DateTime.utc(2026, 7),
  );
}
