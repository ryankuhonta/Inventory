/// Supplies the current time through an injectable boundary.
// The interface is intentionally injectable despite having one operation.
// ignore: one_member_abstracts
abstract interface class Clock {
  /// Returns the current instant represented in UTC.
  DateTime now();
}

/// Production clock backed by the device system clock.
final class SystemClock implements Clock {
  /// Creates the production UTC clock.
  const SystemClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}
