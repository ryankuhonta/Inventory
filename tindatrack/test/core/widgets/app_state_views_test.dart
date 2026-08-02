import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/theme/app_theme.dart';
import 'package:tindatrack/core/widgets/app_empty_state.dart';
import 'package:tindatrack/core/widgets/app_error_view.dart';
import 'package:tindatrack/core/widgets/app_loading_view.dart';

void main() {
  testWidgets('loading view exposes title, message, progress, and semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpState(
      tester,
      const AppLoadingView(
        title: 'TindaTrack',
        message: 'Offline inventory tracker',
        semanticsLabel: 'Loading inventory',
      ),
    );
    expect(find.text('TindaTrack'), findsOneWidget);
    expect(find.text('Offline inventory tracker'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Loading inventory'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('empty state supports no action or a paired action', (
    tester,
  ) async {
    await _pumpState(tester, const AppEmptyState(title: 'No items yet'));
    expect(find.text('No items yet'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    var calls = 0;
    await _pumpState(
      tester,
      AppEmptyState(
        title: 'No products yet',
        message: 'Add your first product when you are ready.',
        actionLabel: 'Add product',
        onAction: () => calls++,
      ),
    );
    await tester.tap(find.text('Add product'));
    expect(calls, 1);
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets(
    'error state has visible non-color cues and a disableable action',
    (tester) async {
      await _pumpState(
        tester,
        const AppErrorView(message: 'Please try again.'),
      );
      expect(find.byType(FilledButton), findsNothing);

      var calls = 0;
      await _pumpState(
        tester,
        AppErrorView(
          message: 'Please try again.',
          actionLabel: 'Retry',
          onAction: () => calls++,
          isActionEnabled: false,
        ),
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Please try again.'), findsOneWidget);
      final disabled = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Retry'),
      );
      expect(disabled.onPressed, isNull);
      await _pumpState(
        tester,
        AppErrorView(
          message: 'Please try again.',
          actionLabel: 'Retry',
          onAction: () => calls++,
        ),
      );
      await tester.tap(find.text('Retry'));
      expect(calls, 1);
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(48),
      );
    },
  );

  test('optional action label and callback are an invariant pair', () {
    expect(
      () => AppEmptyState(title: 'Empty', actionLabel: 'Act'),
      throwsAssertionError,
    );
    expect(
      () => AppEmptyState(title: 'Empty', onAction: () {}),
      throwsAssertionError,
    );
    expect(
      () => AppErrorView(message: 'Error', actionLabel: 'Retry'),
      throwsAssertionError,
    );
    expect(
      () => AppErrorView(message: 'Error', onAction: () {}),
      throwsAssertionError,
    );
  });

  testWidgets('state views pass contrast and Android tap-target guidelines', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpState(
      tester,
      const AppLoadingView(title: 'Loading', message: 'Please wait.'),
    );
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    await _pumpState(
      tester,
      AppEmptyState(
        title: 'No items yet',
        message: 'Add one when you are ready.',
        actionLabel: 'Add item',
        onAction: () {},
      ),
    );
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

    await _pumpState(
      tester,
      AppErrorView(
        message: 'Your saved data is unavailable.',
        actionLabel: 'Retry',
        onAction: () {},
      ),
    );
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantics.dispose();
  });

  for (final state in <Widget>[
    const AppLoadingView(title: 'Loading', message: 'Please wait.'),
    AppEmptyState(
      title: 'Nothing here yet',
      message: 'You can add an item when you are ready.',
      actionLabel: 'Add item',
      onAction: () {},
    ),
    AppErrorView(
      message: 'We could not load your saved information. Please try again.',
      actionLabel: 'Retry',
      onAction: () {},
    ),
  ]) {
    testWidgets(
      '${state.runtimeType} does not overflow at 360x640 and 2x text',
      (tester) async {
        tester.view
          ..physicalSize = const Size(360, 640)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _pumpState(tester, state, textScaler: const TextScaler.linear(2));
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _pumpState(
  WidgetTester tester,
  Widget state, {
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(body: state),
      ),
    ),
  );
}
