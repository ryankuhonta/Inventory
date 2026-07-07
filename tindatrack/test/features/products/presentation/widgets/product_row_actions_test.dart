import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/theme/app_theme.dart';
import 'package:tindatrack/features/products/presentation/widgets/product_row_actions.dart';

void main() {
  const actionKey = ValueKey('product-edit-action-product-1');

  testWidgets('shows one product-keyed accessible Edit action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _ActionsHarness(
        onEdit: () {},
      ),
    );

    expect(find.byKey(actionKey), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byTooltip('Edit Rice'), findsOneWidget);
    expect(find.bySemanticsLabel('Edit Rice'), findsOneWidget);
    final semantics = tester.getSemantics(find.byKey(actionKey));
    expect(semantics.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(find.textContaining('Stock In'), findsNothing);
    expect(find.textContaining('Stock Out'), findsNothing);
    expect(find.textContaining('Archive'), findsNothing);
  });

  testWidgets('keeps a 48dp target and invokes Edit exactly once', (
    tester,
  ) async {
    var edits = 0;
    await tester.pumpWidget(
      _ActionsHarness(
        onEdit: () => edits++,
      ),
    );

    final size = tester.getSize(find.byKey(actionKey));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));

    await tester.tap(find.byKey(actionKey));
    expect(edits, 1);
  });

  testWidgets('stays mounted and disabled when callback is null', (
    tester,
  ) async {
    var edits = 0;
    await tester.pumpWidget(
      _ActionsHarness(
        onEdit: () => edits++,
      ),
    );
    final enabledSize = tester.getSize(find.byKey(actionKey));

    await tester.pumpWidget(const _ActionsHarness());

    expect(find.byKey(actionKey), findsOneWidget);
    expect(tester.getSize(find.byKey(actionKey)), enabledSize);
    expect(
      tester.widget<IconButton>(find.byKey(actionKey)).onPressed,
      isNull,
    );
    await tester.tap(find.byKey(actionKey));
    expect(edits, 0);
  });
}

final class _ActionsHarness extends StatelessWidget {
  const _ActionsHarness({this.onEdit});

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
            onEdit: onEdit,
          ),
        ),
      ),
    );
  }
}
