/// Base type for shared, feature-independent failures.
///
/// Feature modules may define their own `final`, `base`, or `sealed` failure
/// types while reusing the shared result and presentation foundations.
abstract base class AppFailure {
  /// Creates an application failure.
  const AppFailure({this.debugMessage});

  /// Optional diagnostic context that must never be shown directly to users.
  final String? debugMessage;
}

/// A local persistence operation could not be completed.
final class PersistenceFailure extends AppFailure {
  /// Creates a persistence failure.
  const PersistenceFailure({super.debugMessage});
}

/// An unclassified operation failed unexpectedly.
final class UnexpectedFailure extends AppFailure {
  /// Creates an unexpected failure.
  const UnexpectedFailure({super.debugMessage});
}
