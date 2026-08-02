import 'package:tindatrack/core/errors/app_failure.dart';

/// Maps typed failures to stable, Filipino-friendly user messages.
final class FailureMessageMapper {
  /// Creates a failure message mapper.
  const FailureMessageMapper();

  /// Returns safe presentation copy without exposing technical diagnostics.
  String toMessage(AppFailure failure) {
    return switch (failure) {
      PersistenceFailure() =>
        "We couldn't access your saved data. Please try again.",
      UnexpectedFailure() => 'Something unexpected happened. Please try again.',
      _ => 'Something unexpected happened. Please try again.',
    };
  }
}
