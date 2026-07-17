import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tindatrack/app/providers.dart';
import 'package:tindatrack/features/dashboard/data/repositories/drift_dashboard_repository.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_low_stock_preview_item.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_recent_activity_item.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:tindatrack/features/dashboard/domain/repositories/dashboard_repository.dart';

/// Read-only dashboard repository composed from the app database.
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DriftDashboardRepository(ref.watch(databaseProvider)),
);

/// Live summary counts for the Dashboard tab.
final dashboardSummaryProvider = StreamProvider<DashboardSummary>((ref) {
  final localNow = ref.watch(clockProvider).now().toLocal();
  final nextLocalMidnight = DateTime(
    localNow.year,
    localNow.month,
    localNow.day + 1,
  );
  final refresh = Timer(
    nextLocalMidnight.difference(localNow),
    ref.invalidateSelf,
  );
  ref.onDispose(refresh.cancel);

  return ref
      .watch(dashboardRepositoryProvider)
      .watchSummary(localNow: localNow);
});

/// Compact active products that need restocking on the Dashboard.
final dashboardLowStockPreviewProvider =
    StreamProvider<List<DashboardLowStockPreviewItem>>((ref) {
      return ref.watch(dashboardRepositoryProvider).watchLowStockPreview();
    });

/// Compact recent stock movements shown on the Dashboard.
final dashboardRecentActivityPreviewProvider =
    StreamProvider<List<DashboardRecentActivityItem>>((ref) {
      return ref
          .watch(dashboardRepositoryProvider)
          .watchRecentActivityPreview();
    });
