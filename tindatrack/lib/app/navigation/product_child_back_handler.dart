/// Handles Back for the currently mounted Products child flow.
typedef ProductChildBackHandler = Future<void> Function();

/// App-owned bridge used when Android Back is intercepted above child routes.
final productChildBackRegistry = ProductChildBackRegistry();

/// Stores the active Products child Back callback while that child is mounted.
final class ProductChildBackRegistry {
  /// The registered child Back callback, when a Products child flow is active.
  ProductChildBackHandler? handler;

  /// Clears [handlerToRemove] only if it is still the active callback.
  void unregister(ProductChildBackHandler handlerToRemove) {
    if (identical(handler, handlerToRemove)) {
      handler = null;
    }
  }
}
