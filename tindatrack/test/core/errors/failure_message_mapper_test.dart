import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/failure_message_mapper.dart';

void main() {
  const mapper = FailureMessageMapper();

  test('maps persistence failures without leaking technical details', () {
    const technicalDetail = 'SQLITE_CONSTRAINT products.name';
    const failure = PersistenceFailure(debugMessage: technicalDetail);

    final message = mapper.toMessage(failure);

    expect(message, "We couldn't access your saved data. Please try again.");
    expect(message, isNot(contains(technicalDetail)));
  });

  test('maps unexpected failures without leaking technical details', () {
    const technicalDetail = 'StateError: impossible branch';
    const failure = UnexpectedFailure(debugMessage: technicalDetail);

    final message = mapper.toMessage(failure);

    expect(message, 'Something unexpected happened. Please try again.');
    expect(message, isNot(contains(technicalDetail)));
  });

  test('feature-owned failures can extend the shared failure foundation', () {
    const failure = _FeatureFailure();

    expect(
      mapper.toMessage(failure),
      'Something unexpected happened. Please try again.',
    );
  });
}

final class _FeatureFailure extends AppFailure {
  const _FeatureFailure();
}
