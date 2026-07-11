import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/theme/app_theme.dart';
import 'package:tindatrack/features/products/presentation/widgets/product_row_actions.dart';

void main() {
  const stockInKey = ValueKey('product-stock-in-action-product-1');
  const stockOutKey = ValueKey('product-stock-out-action-product-1');
  const editKey = ValueKey('product-edit-action-product-1');

  testWidgets(
    'shows product-keyed accessible Stock In, Stock Out, and Edit actions',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        _ActionsHarness(
          onStockIn: () {},
          onStockOut: () {},
          onEdit: () {},
        ),
      );

      expect(find.byKey(stockInKey), findsOneWidget);
      expect(find.byKey(stockOutKey), findsOneWidget);
      expect(find.byKey(editKey), findsOneWidget);
      expect(find.byIcon(Icons.add_box_outlined), findsOneWidget);
      expect(
        find.byIcon(Icons.indeterminate_check_box_outlined),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byTooltip('Stock In Rice'), findsOneWidget);
      expect(find.byTooltip('Stock Out Rice'), findsOneWidget);
      expect(find.byTooltip('Edit Rice'), findsOneWidget);
      expect(find.bySemanticsLabel('Stock In Rice'), findsOneWidget);
      expect(find.bySemanticsLabel('Stock Out Rice'), findsOneWidget);
      expect(find.bySemanticsLabel('Edit Rice'), findsOneWidget);

      for (final key in [stockInKey, stockOutKey, editKey]) {
        final semantics = tester.getSemantics(find.byKey(key));
        expect(
          semantics.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
        );
      }
      expect(find.textContaining('Archive'), findsNothing);
    },
  );

  testWidgets('keeps 48dp targets and invokes each action independently', (
    tester,
  ) async {
    var stockIns = 0;
    var stockOuts = 0;
    var edits = 0;
    await tester.pumpWidget(
      _ActionsHarness(
        onStockIn: () => stockIns++,
        onStockOut: () => stockOuts++,
        onEdit: () => edits++,
      ),
    );

    for (final key in [stockInKey, stockOutKey, editKey]) {
      final size = tester.getSize(find.byKey(key));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }

    await tester.tap(find.byKey(stockInKey));
    await tester.tap(find.byKey(stockOutKey));
    await tester.tap(find.byKey(editKey));

    expect(stockIns, 1);
    expect(stockOuts, 1);
    expect(edits, 1);
  });

  testWidgets(
    'stays mounted and disables all actions when callbacks are null',
    (
      tester,
    ) async {
      var stockIns = 0;
      var stockOuts = 0;
      var edits = 0;
      await tester.pumpWidget(
        _ActionsHarness(
          onStockIn: () => stockIns++,
          onStockOut: () => stockOuts++,
          onEdit: () => edits++,
        ),
      );
      final enabledSizes = {
        for (final key in [stockInKey, stockOutKey, editKey])
          key: tester.getSize(find.byKey(key)),
      };

      await tester.pumpWidget(const _ActionsHarness());

      for (final key in [stockInKey, stockOutKey, editKey]) {
        expect(find.byKey(key), findsOneWidget);
        expect(tester.getSize(find.byKey(key)), enabledSizes[key]);
        final button = find.descendant(
          of: find.byKey(key),
          matching: find.byType(IconButton),
        );
        expect(tester.widget<IconButton>(button).onPressed, isNull);
        await tester.tap(find.byKey(key));
      }
      expect(stockIns, 0);
      expect(stockOuts, 0);
      expect(edits, 0);
    },
  );
}

final class _ActionsHarness extends StatelessWidget {
  const _ActionsHarness({this.onStockIn, this.onStockOut, this.onEdit});

  final VoidCallback? onStockIn;
  final VoidCallback? onStockOut;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: ProductRowActions(
            productId: 'product-1',
            productName: 'Rice',
            onStockIn: onStockIn,
            onStockOut: onStockOut,
            onEdit: onEdit,
          ),
        ),
      ),
    );
  }
}
