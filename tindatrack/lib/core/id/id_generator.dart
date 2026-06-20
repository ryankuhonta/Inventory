/// Generates project-wide string identifiers.
// The interface is intentionally injectable despite having one operation.
// ignore: one_member_abstracts
abstract interface class IdGenerator {
  /// Returns a new canonical identifier.
  String generate();
}
