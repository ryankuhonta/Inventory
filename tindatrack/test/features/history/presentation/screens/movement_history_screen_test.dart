import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/theme/app_theme.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/history/presentation/screens/movement_history_screen.dart';
import 'package:tindatrack/features/stock/domain/entities/create_stock_movement_input.dart';
import 'package:tindatrack/features/stock/domain/entities/record_stock_in_input.dart';
import 'package:tindatrack/features/stock/domain/entities/record_stock_out_input.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';
import 'package:tindatrack/features/stock/domain/repositories/stock_repository.dart';
import 'package:tindatrack/features/stock/presentation/providers/stock_providers.dart';

void main() {
  testWidgets('renders movement history newest first with row details', (
    tester,
  ) async {
    await _pumpHistory(
      tester,
      movements: [
        _movement(
          id: 'newer',
          type: StockMovementType.stockOut,
          quantity: 2,
          previousQuantity: 8,
          newQuantity: 6,
          reason: StockOutReason.damaged,
          productNameSnapshot: 'Coke 1L snapshot',
          unitSnapshot: 'bottle',
          note: 'broken bottle',
          createdAt: DateTime(2026, 7, 10, 12, 30),
        ),
        _movement(
          id: 'older',
          quantity: 3,
          previousQuantity: 5,
          newQuantity: 8,
          note: 'delivery',
          createdAt: DateTime(2026, 7, 10, 8, 15),
        ),
      ],
    );

    expect(find.byKey(const Key('history-screen')), findsOneWidget);
    expect(find.byKey(const Key('history-list')), findsOneWidget);
    expect(find.byKey(const Key('history-row-newer')), findsOneWidget);
    expect(find.byKey(const Key('history-row-older')), findsOneWidget);

    final newerTop = tester
        .getTopLeft(find.byKey(const Key('history-row-newer')))
        .dy;
    final olderTop = tester
        .getTopLeft(find.byKey(const Key('history-row-older')))
        .dy;
    expect(newerTop, lessThan(olderTop));

    expect(find.text('Stock Out'), findsOneWidget);
    expect(find.text('Stock In'), findsOneWidget);
    expect(find.text('Coke 1L snapshot'), findsOneWidget);
    expect(find.text('Rice'), findsOneWidget);
    expect(find.text('-2 bottle'), findsOneWidget);
    expect(find.text('+3 pcs'), findsOneWidget);
    expect(find.text('8 -> 6 bottle'), findsOneWidget);
    expect(find.text('5 -> 8 pcs'), findsOneWidget);
    expect(find.text('Jul 10, 2026 12:30'), findsOneWidget);
    expect(find.text('broken bottle'), findsOneWidget);
    expect(find.text('damaged'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('movement rows expose one clear screen-reader summary', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await _pumpHistory(
      tester,
      movements: [
        _movement(
          id: 'movement-a11y',
          type: StockMovementType.stockOut,
          quantity: 2,
          previousQuantity: 8,
          newQuantity: 6,
          productNameSnapshot: 'Coke 1L snapshot',
          unitSnapshot: 'bottle',
          note: 'broken bottle',
          createdAt: DateTime(2026, 7, 10, 12, 30),
        ),
      ],
    );

    expect(
      find.bySemanticsLabel(
        'Stock Out, Coke 1L snapshot, -2 bottle, quantity changed from 8 '
        'to 6 bottle, Jul 10, 2026 12:30, note: broken bottle',
      ),
      findsOneWidget,
    );

    semantics.dispose();
  });

  testWidgets('shows friendly empty state', (tester) async {
    await _pumpHistory(tester, movements: const []);

    expect(find.byKey(const Key('history-empty-state')), findsOneWidget);
    expect(find.text('Stock changes will appear here.'), findsOneWidget);
    expect(find.textContaining('error'), findsNothing);
  });

  testWidgets('shows friendly error without diagnostics', (tester) async {
    await _pumpHistory(
      tester,
      stream: Stream<List<StockMovement>>.error(
        Exception('PRIVATE_SQL_FAILURE'),
      ),
    );

    await tester.pump();

    expect(
      find.text("We couldn't load history. Please try again."),
      findsOneWidget,
    );
    expect(find.textContaining('PRIVATE_SQL_FAILURE'), findsNothing);
  });

  testWidgets('remains scrollable on small screens with many rows', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpHistory(
      tester,
      movements: List.generate(
        30,
        (index) => _movement(
          id: 'movement-$index',
          createdAt: DateTime(2026, 7, 10, 12, 30 - index),
          note: 'note $index',
        ),
      ),
    );

    expect(find.byType(ListView), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('history-row-movement-29')),
      400,
      scrollable: find.byType(Scrollable),
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHistory(
  WidgetTester tester, {
  List<StockMovement>? movements,
  Stream<List<StockMovement>>? stream,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        stockRepositoryProvider.overrideWithValue(
          _StockRepository(
            stream: stream ?? Stream.value(movements ?? const []),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const MovementHistoryScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _StockRepository implements StockRepository {
  const _StockRepository({required this.stream});

  final Stream<List<StockMovement>> stream;

  @override
  Future<Result<List<StockMovement>>> listMovementHistory({
    String? productId,
  }) => throw UnimplementedError();

  @override
  Future<Result<StockMovement>> recordMovementRow(
    CreateStockMovementInput input,
  ) => throw UnimplementedError();

  @override
  Future<Result<StockMovement>> recordStockIn(RecordStockInInput input) =>
      throw UnimplementedError();

  @override
  Future<Result<StockMovement>> recordStockOut(RecordStockOutInput input) =>
      throw UnimplementedError();

  @override
  Future<Result<List<String>>> listRecentNotes({
    required StockMovementType type,
    int limit = 8,
  }) async => const Success<List<String>>(<String>[]);
  @override
  Stream<List<StockMovement>> watchMovementHistory({String? productId}) =>
      stream;
}

StockMovement _movement({
  String id = 'movement-1',
  StockMovementType type = StockMovementType.stockIn,
  int quantity = 1,
  int previousQuantity = 4,
  int newQuantity = 5,
  StockOutReason? reason,
  String? note,
  String productNameSnapshot = 'Rice',
  String unitSnapshot = 'pcs',
  DateTime? createdAt,
}) {
  return StockMovement(
    id: id,
    productId: 'product-1',
    type: type,
    quantity: quantity,
    previousQuantity: previousQuantity,
    newQuantity: newQuantity,
    reason: reason,
    note: note,
    productNameSnapshot: productNameSnapshot,
    unitSnapshot: unitSnapshot,
    createdAt: createdAt ?? DateTime(2026, 7, 10, 12, 30),
  );
}
