import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:tindatrack/app/providers.dart';
import 'package:tindatrack/core/database/daos/products_dao.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/data/repositories/drift_products_repository.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/repositories/products_repository.dart';
import 'package:tindatrack/features/products/domain/usecases/add_product.dart';
import 'package:tindatrack/features/products/domain/usecases/archive_product.dart';
import 'package:tindatrack/features/products/domain/usecases/get_product.dart';
import 'package:tindatrack/features/products/domain/usecases/restore_product.dart';
import 'package:tindatrack/features/products/domain/usecases/update_product.dart';
import 'package:tindatrack/features/products/presentation/controllers/product_list_controller.dart';

/// Persistence-only product DAO composed from the app database.
final productsDaoProvider = Provider<ProductsDao>(
  (ref) => ProductsDao(ref.watch(databaseProvider)),
);

/// Canonical product repository for the products feature.
final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => DriftProductsRepository(
    dao: ref.watch(productsDaoProvider),
    idGenerator: ref.watch(idGeneratorProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Validated Add Product application boundary.
final addProductProvider = Provider<AddProduct>(
  (ref) => AddProduct(ref.watch(productRepositoryProvider)),
);

/// Product archive boundary for Edit Product.
final archiveProductProvider = Provider<ArchiveProduct>(
  (ref) => ArchiveProduct(ref.watch(productRepositoryProvider)),
);

/// Product restore boundary for archived products.
final restoreProductProvider = Provider<RestoreProduct>(
  (ref) => RestoreProduct(ref.watch(productRepositoryProvider)),
);

/// Product lookup boundary for edit screens.
final getProductProvider = Provider<GetProduct>(
  (ref) => GetProduct(ref.watch(productRepositoryProvider)),
);

/// Validated metadata update boundary.
final updateProductProvider = Provider<UpdateProduct>(
  (ref) => UpdateProduct(ref.watch(productRepositoryProvider)),
);

/// One edit target loaded by stable route identity.
final FutureProviderFamily<Result<Product>, String> productByIdProvider =
    FutureProvider.autoDispose.family<Result<Product>, String>(
      (ref, productId) => ref.watch(getProductProvider)(productId),
    );

/// Reactive active catalog for the currently applied product-list query.
final activeProductsProvider = StreamProvider<List<Product>>(
  (ref) => ref
      .watch(productRepositoryProvider)
      .watchActiveProducts(ref.watch(productListControllerProvider)),
);

/// Reactive archived catalog for restore workflows.
final archivedProductsProvider = StreamProvider<List<Product>>(
  (ref) => ref.watch(productRepositoryProvider).watchArchivedProducts(),
);
