import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tindatrack/app/providers.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';

/// Initializes the local services required before the app can be used.
final bootstrapProvider = FutureProvider<Result<void>>((ref) async {
  try {
    final database = ref.watch(databaseProvider);
    await database.ensureReady();
    return const Success<void>(null);
  } on Exception catch (error) {
    return FailureResult<void>(
      PersistenceFailure(debugMessage: error.toString()),
    );
  }
});
