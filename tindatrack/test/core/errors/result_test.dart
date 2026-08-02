import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';

void main() {
  test('success carries a value', () {
    const result = Success<int>(42);

    expect(result.value, 42);
  });

  test('failure result carries a typed failure', () {
    const failure = PersistenceFailure();
    const result = FailureResult<int>(failure);

    expect(result.failure, same(failure));
  });
}
