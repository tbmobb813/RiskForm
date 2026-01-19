import 'package:flutter_riverpod/legacy.dart';

/// Data source selector for dashboard backtest results display.
enum DashboardDataSource { local, cloud, both }

/// Provider for the current dashboard data source selection.
final dashboardDataSourceProvider =
    StateNotifierProvider<DashboardDataSourceNotifier, DashboardDataSource>(
  (ref) => DashboardDataSourceNotifier(),
);

/// Notifier for managing the dashboard data source state.
class DashboardDataSourceNotifier extends StateNotifier<DashboardDataSource> {
  DashboardDataSourceNotifier() : super(DashboardDataSource.local);

  void setSource(DashboardDataSource source) {
    state = source;
  }

  void setLocal() => state = DashboardDataSource.local;
  void setCloud() => state = DashboardDataSource.cloud;
  void setBoth() => state = DashboardDataSource.both;
}
