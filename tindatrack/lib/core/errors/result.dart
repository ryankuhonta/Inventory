import 'package:tindatrack/core/errors/app_failure.dart';

/// Canonical typed outcome for operations that can fail.
sealed class Result<T> {
  const Result();
}

/// Successful operation result.
final class Success<T> extends Result<T> {
  /// Creates a successful result containing [value].
  const Success(this.value);

  /// The successful value.
  final T value;
}

/// Failed operation result.
final class FailureResult<T> extends Result<T> {
  /// Creates a failed result containing [failure].
  const FailureResult(this.failure);

  /// The typed application failure.
  final AppFailure failure;
}
