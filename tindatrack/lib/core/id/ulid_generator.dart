import 'package:tindatrack/core/id/id_generator.dart';
import 'package:ulid/ulid.dart';

/// Generates canonical ULID strings for future entity creation boundaries.
final class UlidGenerator implements IdGenerator {
  /// Creates a ULID generator.
  const UlidGenerator();

  @override
  String generate() => Ulid().toString().toUpperCase();
}
