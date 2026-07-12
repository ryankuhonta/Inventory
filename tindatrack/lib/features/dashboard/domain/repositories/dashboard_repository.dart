// Repository contracts intentionally remain interfaces even when a story starts
// with a single read method.
// ignore_for_file: one_member_abstracts

import 'package:tindatrack/features/dashboard/domain/entities/dashboard_summary.dart';

/// Read-only dashboard data boundary.
abstract interface class DashboardRepository {
  /// Watches dashboard counts for the local day containing [localNow].
  Stream<DashboardSummary> watchSummary({
    required DateTime localNow,
  });
}
