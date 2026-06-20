import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/id/ulid_generator.dart';

void main() {
  test('generates unique canonical ULID strings', () {
    const generator = UlidGenerator();
    final ids = List.generate(100, (_) => generator.generate());

    expect(ids.toSet(), hasLength(ids.length));
    for (final id in ids) {
      expect(id, matches(RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$')));
    }
  });
}
