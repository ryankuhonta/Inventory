/// Canonical primary route identities for TindaTrack.
enum AppRoute {
  /// Dashboard branch root.
  dashboard(path: '/dashboard', label: 'Dashboard'),

  /// Products branch root.
  products(path: '/products', label: 'Products'),

  /// Inventory history branch root.
  history(path: '/history', label: 'History'),

  /// Settings branch root.
  settings(path: '/settings', label: 'Settings');

  const AppRoute({required this.path, required this.label});

  /// Absolute path for this branch root.
  final String path;

  /// User-visible navigation label.
  final String label;
}
