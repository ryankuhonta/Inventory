import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/entities/product_list_query.dart';
import 'package:tindatrack/features/products/domain/entities/update_product_input.dart';
import 'package:tindatrack/features/products/domain/failures/product_failure.dart';
import 'package:tindatrack/features/products/domain/repositories/products_repository.dart';
import 'package:tindatrack/features/products/domain/usecases/archive_product.dart';

void main() {
  late _RecordingRepository repository;
  late ArchiveProduct archiveProduct;

  setUp(() {
    repository = _RecordingRepository();
    archiveProduct = ArchiveProduct(repository);
  });

  test('delegates archive by stable product ID', () async {
    final result = await archiveProduct('product-1');

    expect(result, isA<Success<void>>());
    expect(repository.archiveCalls, 1);
    expect(repository.lastArchivedId, 'product-1');
  });

  for (final failure in <AppFailure>[
    const ProductNotFoundFailure(),
    const ArchivedProductFailure(),
    const PersistenceFailure(debugMessage: 'private'),
  ]) {
    test('passes ${failure.runtimeType} through unchanged', () async {
      repository.archiveResult = FailureResult<void>(failure);

      final result = await archiveProduct('product-1');

      expect((result as FailureResult<void>).failure, same(failure));
    });
  }
}

final class _RecordingRepository implements ProductRepository {
  Result<void> archiveResult = const Success<void>(null);
  int archiveCalls = 0;
  String? lastArchivedId;

  @override
  Future<Result<void>> archiveProduct(String id) async {
    archiveCalls++;
    lastArchivedId = id;
    return archiveResult;
  }

  @override
  Future<Result<Product>> createProduct(CreateProductInput input) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<Product>> getProduct(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<Product>> updateProduct(
    String id,
    UpdateProductInput input,
  ) async {
    throw UnimplementedError();
  }

  @override
  Stream<List<Product>> watchActiveProducts(ProductListQuery query) {
    return const Stream<List<Product>>.empty();
  }
}
