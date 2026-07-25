import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/theme/app_theme.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_low_stock_preview_item.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_recent_activity_item.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:tindatrack/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:tindatrack/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:tindatrack/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:tindatrack/features/history/presentation/screens/movement_history_screen.dart';
import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/entities/product_list_query.dart';
import 'package:tindatrack/features/products/domain/entities/update_product_input.dart';
import 'package:tindatrack/features/products/domain/repositories/products_repository.dart';
import 'package:tindatrack/features/products/domain/usecases/get_product.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';
import 'package:tindatrack/features/products/presentation/screens/add_product_screen.dart';
import 'package:tindatrack/features/products/presentation/screens/edit_product_screen.dart';
import 'package:tindatrack/features/products/presentation/screens/product_list_screen.dart';
import 'package:tindatrack/features/settings/presentation/screens/settings_screen.dart';
import 'package:tindatrack/features/stock/domain/entities/create_stock_movement_input.dart';
import 'package:tindatrack/features/stock/domain/entities/record_stock_in_input.dart';
import 'package:tindatrack/features/stock/domain/entities/record_stock_out_input.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';
import 'package:tindatrack/features/stock/domain/repositories/stock_repository.dart';
import 'package:tindatrack/features/stock/presentation/providers/stock_providers.dart';
import 'package:tindatrack/features/stock/presentation/screens/stock_in_screen.dart';
import 'package:tindatrack/features/stock/presentation/screens/stock_out_screen.dart';

void main() {
  testWidgets('MVP visible screen copy avoids forbidden terms', (tester) async {
    final scenarios = <_MvpScreenScenario>[
      _MvpScreenScenario(
        name: 'Dashboard',
        child: const DashboardScreen(),
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(
            _DashboardRepository(),
          ),
        ],
      ),
      _MvpScreenScenario(
        name: 'Products',
        child: const ProductListScreen(),
        overrides: [
          productRepositoryProvider.overrideWithValue(_ProductRepository()),
        ],
      ),
      const _MvpScreenScenario(name: 'Add Product', child: AddProductScreen()),
      _MvpScreenScenario(
        name: 'Edit Product',
        child: const EditProductScreen(productId: 'product-1'),
        overrides: [
          getProductProvider.overrideWithValue(
            GetProduct(_ProductRepository()),
          ),
        ],
      ),
      _MvpScreenScenario(
        name: 'Stock In',
        child: const StockInScreen(productId: 'product-1'),
        overrides: [
          getProductProvider.overrideWithValue(
            GetProduct(_ProductRepository()),
          ),
          stockRepositoryProvider.overrideWithValue(_StockRepository()),
        ],
      ),
      _MvpScreenScenario(
        name: 'Stock Out',
        child: const StockOutScreen(productId: 'product-1'),
        overrides: [
          getProductProvider.overrideWithValue(
            GetProduct(_ProductRepository()),
          ),
          stockRepositoryProvider.overrideWithValue(_StockRepository()),
        ],
      ),
      _MvpScreenScenario(
        name: 'History',
        child: const MovementHistoryScreen(),
        overrides: [
          stockRepositoryProvider.overrideWithValue(_StockRepository()),
        ],
      ),
      const _MvpScreenScenario(name: 'Settings', child: SettingsScreen()),
    ];

    for (final scenario in scenarios) {
      await tester.pumpWidget(
        ProviderScope(
          key: ValueKey(scenario.name),
          overrides: scenario.overrides,
          child: MaterialApp(theme: AppTheme.light, home: scenario.child),
        ),
      );
      await tester.pumpAndSettle();

      final visibleCopy = _visibleText(tester).join(' ').toLowerCase();
      for (final rule in _forbiddenRules) {
        expect(
          rule.pattern.hasMatch(visibleCopy),
          isFalse,
          reason:
              '${scenario.name} should not expose "${rule.label}" in MVP '
              'visible copy. Visible copy: $visibleCopy',
        );
      }
    }
  });
}

Iterable<String> _visibleText(WidgetTester tester) sync* {
  for (final element in find.byType(Text).evaluate()) {
    final widget = element.widget as Text;
    final text = widget.data ?? widget.textSpan?.toPlainText();
    if (text != null && text.trim().isNotEmpty) {
      yield text.trim();
    }
  }
}

const _forbiddenLabels = [
  'entity',
  'inventory mutation',
  'database',
  'sql',
  'drift',
  'exception',
  'stack trace',
  'remote api',
  'login',
  'cloud sync',
  'ad',
  'premium',
  'subscribe',
  'pos',
  'barcode scanner',
  'accounting',
];

final List<_ForbiddenRule> _forbiddenRules = _forbiddenLabels
    .map((label) => _ForbiddenRule(label, _forbiddenPattern(label)))
    .toList(growable: false);

RegExp _forbiddenPattern(String label) {
  if (label == 'ad') {
    return RegExp('(?<![a-z0-9])ads?(?![a-z0-9])');
  }
  final escaped = RegExp.escape(label).replaceAll(r'\ ', r'\s+');
  return RegExp('(?<![a-z0-9])$escaped(?![a-z0-9])');
}

final class _ForbiddenRule {
  const _ForbiddenRule(this.label, this.pattern);

  final String label;
  final RegExp pattern;
}

final class _MvpScreenScenario {
  const _MvpScreenScenario({
    required this.name,
    required this.child,
    this.overrides = const [],
  });

  final String name;
  final Widget child;
  final List<Override> overrides;
}

final class _DashboardRepository implements DashboardRepository {
  @override
  Stream<List<DashboardLowStockPreviewItem>> watchLowStockPreview({
    int limit = dashboardLowStockPreviewLimit,
  }) => Stream.value(const []);

  @override
  Stream<List<DashboardRecentActivityItem>> watchRecentActivityPreview({
    int limit = dashboardRecentActivityPreviewLimit,
  }) => Stream.value(const []);

  @override
  Stream<DashboardSummary> watchSummary({required DateTime localNow}) {
    return Stream.value(
      const DashboardSummary(
        totalActiveProducts: 1,
        lowStockProducts: 0,
        stockChangesToday: 0,
      ),
    );
  }
}

final class _ProductRepository implements ProductRepository {
  @override
  Future<Result<void>> archiveProduct(String id) async {
    return const Success<void>(null);
  }

  @override
  Future<Result<Product>> createProduct(CreateProductInput input) async {
    return Success<Product>(_product());
  }

  @override
  Future<Result<Product>> getProduct(String id) async {
    return Success<Product>(_product());
  }

  @override
  Future<Result<Product>> updateProduct(
    String id,
    UpdateProductInput input,
  ) async {
    return Success<Product>(_product());
  }

  @override
  Stream<List<Product>> watchActiveProducts(ProductListQuery query) {
    return Stream.value([_product()]);
  }
}

final class _StockRepository implements StockRepository {
  @override
  Future<Result<List<StockMovement>>> listMovementHistory({
    String? productId,
  }) async {
    return Success<List<StockMovement>>([_movement()]);
  }

  @override
  Future<Result<StockMovement>> recordMovementRow(
    CreateStockMovementInput input,
  ) async {
    return Success<StockMovement>(_movement());
  }

  @override
  Future<Result<StockMovement>> recordStockIn(RecordStockInInput input) async {
    return Success<StockMovement>(_movement());
  }

  @override
  Future<Result<StockMovement>> recordStockOut(
    RecordStockOutInput input,
  ) async {
    return Success<StockMovement>(_movement(type: StockMovementType.stockOut));
  }

  @override
  Stream<List<StockMovement>> watchMovementHistory({String? productId}) {
    return Stream.value([_movement()]);
  }
}

Product _product() {
  return Product(
    id: 'product-1',
    name: 'Rice',
    category: 'Staples',
    unit: 'pcs',
    sellingPrice: 50,
    quantity: 5,
    lowStockThreshold: 2,
    barcode: null,
    isArchived: false,
    createdAt: DateTime.utc(2026, 7),
    updatedAt: DateTime.utc(2026, 7),
  );
}

StockMovement _movement({StockMovementType type = StockMovementType.stockIn}) {
  return StockMovement(
    id: 'movement-1',
    productId: 'product-1',
    type: type,
    quantity: 3,
    previousQuantity: 5,
    newQuantity: type == StockMovementType.stockIn ? 8 : 2,
    reason: null,
    note: 'delivery',
    productNameSnapshot: 'Rice',
    unitSnapshot: 'pcs',
    createdAt: DateTime.utc(2026, 7, 9, 10, 30),
  );
}
