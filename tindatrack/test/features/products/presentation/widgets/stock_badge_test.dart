import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/theme/app_colors.dart';
import 'package:tindatrack/app/theme/app_theme.dart';
import 'package:tindatrack/core/ui/app_dimensions.dart';
import 'package:tindatrack/features/products/domain/entities/product_stock_status.dart';
import 'package:tindatrack/features/products/presentation/widgets/stock_badge.dart';

void main() {
  testWidgets('low stock uses exact copy and approved warning tokens', (
    tester,
  ) async {
    await tester.pumpWidget(_app(ProductStockStatus.lowStock));

    expect(find.text('Low Stock'), findsOneWidget);
    expect(find.bySemanticsLabel('Low Stock'), findsOneWidget);
    _expectDecoration(
      tester,
      background: AppColors.warningSurface,
      foreground: AppColors.warning,
    );
  });

  testWidgets('out of stock uses exact copy and approved danger tokens', (
    tester,
  ) async {
    await tester.pumpWidget(_app(ProductStockStatus.outOfStock));

    expect(find.text('Out of Stock'), findsOneWidget);
    expect(find.bySemanticsLabel('Out of Stock'), findsOneWidget);
    _expectDecoration(
      tester,
      background: AppColors.dangerSurface,
      foreground: AppColors.danger,
    );
  });

  testWidgets('in-stock status renders no warning badge', (tester) async {
    await tester.pumpWidget(_app(ProductStockStatus.inStock));

    expect(find.byKey(const Key('stock-status-badge')), findsNothing);
    expect(find.text('Low Stock'), findsNothing);
    expect(find.text('Out of Stock'), findsNothing);
  });
}

Widget _app(ProductStockStatus status) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: StockBadge(status: status)),
  );
}

void _expectDecoration(
  WidgetTester tester, {
  required Color background,
  required Color foreground,
}) {
  final decorated = tester.widget<DecoratedBox>(
    find.byKey(const Key('stock-status-badge')),
  );
  final decoration = decorated.decoration as BoxDecoration;
  expect(decoration.color, background);
  expect(
    decoration.borderRadius,
    BorderRadius.circular(AppDimensions.statusPillRadius),
  );
  expect(
    tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(const Key('stock-status-badge')),
            matching: find.byType(Text),
          ),
        )
        .style
        ?.color,
    foreground,
  );
}
