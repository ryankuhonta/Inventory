import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tindatrack/app/providers.dart';
import 'package:tindatrack/core/database/daos/products_dao.dart';
import 'package:tindatrack/features/products/data/repositories/drift_products_repository.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/repositories/products_repository.dart';
import 'package:tindatrack/features/products/domain/usecases/add_product.dart';
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

/// Reactive active catalog for the currently applied product-list query.
final activeProductsProvider = StreamProvider<List<Product>>(
  (ref) => ref
      .watch(productRepositoryProvider)
      .watchActiveProducts(ref.watch(productListControllerProvider)),
);
