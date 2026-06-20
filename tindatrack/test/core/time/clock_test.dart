import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/time/clock.dart';

void main() {
  test('system clock always returns UTC', () {
    expect(const SystemClock().now().isUtc, isTrue);
  });

  test('clock contract supports deterministic fakes', () {
    final instant = DateTime.utc(2026, 6, 20, 12, 30);
    final clock = _FakeClock(instant);

    expect(clock.now(), instant);
  });
}

final class _FakeClock implements Clock {
  const _FakeClock(this._instant);

  final DateTime _instant;

  @override
  DateTime now() => _instant;
}
