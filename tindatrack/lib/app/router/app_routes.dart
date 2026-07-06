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

/// Secondary routes owned by the Products branch.
enum ProductRoute {
  /// Add Product form.
  addProduct(
    path: '/products/add',
    segment: 'add',
    label: 'Add Product',
  ),

  /// Edit Product form for one stable product identity.
  editProduct(
    path: '/products/:productId/edit',
    segment: ':productId/edit',
    label: 'Edit Product',
  );

  const ProductRoute({
    required this.path,
    required this.segment,
    required this.label,
  });

  /// Absolute path for direct navigation and deep links.
  final String path;

  /// Relative child segment under the Products branch.
  final String segment;

  /// User-visible screen label.
  final String label;
}
