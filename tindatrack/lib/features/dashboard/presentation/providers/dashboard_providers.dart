import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tindatrack/app/providers.dart';
import 'package:tindatrack/features/dashboard/data/repositories/drift_dashboard_repository.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:tindatrack/features/dashboard/domain/repositories/dashboard_repository.dart';

/// Read-only dashboard repository composed from the app database.
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DriftDashboardRepository(ref.watch(databaseProvider)),
);

/// Live summary counts for the Dashboard tab.
final dashboardSummaryProvider = StreamProvider<DashboardSummary>(
  (ref) => ref
      .watch(dashboardRepositoryProvider)
      .watchSummary(localNow: ref.watch(clockProvider).now().toLocal()),
);
