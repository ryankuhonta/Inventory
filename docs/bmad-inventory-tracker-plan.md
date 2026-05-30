# BMAD Plan: Android Inventory Tracker for Philippine Small Businesses

Project: Inventory Tracker Android App  
Target market: sari-sari stores, small retailers, home-based sellers, market stalls, and micro-businesses in the Philippines  
Preferred stack: Flutter, SQLite, Clean Architecture, Riverpod  
Status: MVP planning and implementation blueprint  

---

## PHASE 1 - ANALYSIS

### 1. Business Problem

Many sari-sari stores and small Philippine retailers track stock manually using notebooks, memory, or chat messages. This creates common operational problems:

- Store owners do not know which products are low in stock until customers ask.
- Manual records are easy to lose, duplicate, or forget during busy selling hours.
- Stock movement is hard to audit, especially when family members or helpers also manage the store.
- Owners often cannot tell which items move quickly or which cash is tied up in slow-moving inventory.
- Internet connectivity may be unstable, expensive, or unavailable, so the app must work offline.

The MVP should solve the daily operational pain first: "What products do I have, how many are left, and what changed today?"

### 2. Target Users

- Primary user: sari-sari store owner who manages products, buying, and selling.
- Secondary user: family member or store helper who records stock in and stock out.
- Tertiary future user: small business owner with multiple stores or cloud backup needs.

### 3. MVP Scope Only

The MVP includes:

- Offline product inventory management.
- Add, edit, archive, and search products.
- Record stock in and stock out transactions.
- Low-stock alerts based on per-product threshold.
- Dashboard summary for total products, low-stock items, and recent activity.
- Inventory history log.
- Local settings and backup/export placeholder.

The MVP excludes:

- Full POS checkout.
- Customer accounts.
- Supplier management.
- Barcode scanning.
- Cloud sync.
- Multi-user collaboration.
- Accounting, profit reports, and tax reports.

### 4. Assumptions And Constraints

- App runs on Android first; iOS is future-ready but not MVP.
- Users may own low-end Android phones with limited RAM and storage.
- Network access cannot be required for normal operation.
- Users may not be comfortable with technical language.
- Data should remain available even after app restarts and offline use.
- Product count in MVP is expected to be small to medium, roughly 50 to 3,000 items.
- Authentication is optional and future-ready; MVP can allow local-only usage.
- Flutter is acceptable for a fast cross-platform future path.

### 5. Future Scalable Features

- Cloud backup and sync across devices.
- Optional login with Google, phone number, or email.
- Barcode or QR scanning.
- Supplier and purchase order tracking.
- Sales/POS module.
- Profit and margin analytics.
- Multiple store branches.
- Staff roles and audit permissions.
- Receipt printing through Bluetooth printers.
- AdMob, freemium plans, and paid backup.
- AI restock suggestions based on movement history.

---

## PHASE 2 - PRODUCT REQUIREMENTS DOCUMENT (PRD)

### App Overview

The Inventory Tracker app is an offline-first Android mobile application that helps small Philippine businesses monitor product stock, record inventory movements, and identify low-stock items quickly. It uses simple language, fast screens, and local storage so store owners can use it reliably even without internet.

### User Personas

#### Persona 1: Aling Maria, Sari-Sari Store Owner

- Age: 45
- Device: low-end Android phone
- Pain: forgets exact stock counts and writes purchases in a notebook
- Goal: quickly know which items need restocking
- Needs: simple dashboard, large buttons, Taglish-friendly labels in the future

#### Persona 2: Jun, Store Helper

- Age: 22
- Device: shared family Android phone
- Pain: needs to record stock changes while serving customers
- Goal: record stock out quickly without changing product details
- Needs: fast search, minimal typing, clear confirmation messages

#### Persona 3: Bea, Home-Based Online Seller

- Age: 31
- Device: Android mid-range phone
- Pain: sells through Facebook and Messenger, stock changes often
- Goal: avoid overselling
- Needs: product list, stock movement history, future backup

### Core Features

- Dashboard summary.
- Product list with search and low-stock indicators.
- Add/edit product details.
- Stock in transaction.
- Stock out transaction.
- Inventory history.
- Settings.
- Local database persistence.
- Low-stock alerts.

### Functional Requirements

| ID | Requirement | Priority |
| --- | --- | --- |
| FR-001 | User can view a dashboard with total products, low-stock count, and recent transactions. | Must |
| FR-002 | User can add a product with name, category, unit, price, quantity, and low-stock threshold. | Must |
| FR-003 | User can edit product details. | Must |
| FR-004 | User can archive a product without deleting its history. | Must |
| FR-005 | User can search products by name or category. | Must |
| FR-006 | User can record stock in with quantity and optional note. | Must |
| FR-007 | User can record stock out with quantity and optional note. | Must |
| FR-008 | App prevents stock out quantity greater than current stock. | Must |
| FR-009 | User can view inventory history sorted newest first. | Must |
| FR-010 | App highlights products at or below low-stock threshold. | Must |
| FR-011 | App stores all MVP data locally. | Must |
| FR-012 | User can view app settings and backup/export placeholder. | Should |

### Non-Functional Requirements

- Offline-first: all core flows must work without internet.
- Performance: product list should open quickly on low-end Android devices.
- Reliability: stock changes must be atomic to avoid mismatched product quantity and history.
- Usability: screens must use simple labels and obvious actions.
- Maintainability: code must use Clean Architecture and testable repositories.
- Security: local data should not be exposed through logs.
- Accessibility: text must be readable, tap targets should be at least 48dp.

### User Stories

- As a store owner, I want to add products so I can start tracking my inventory.
- As a store owner, I want to see low-stock products so I know what to buy.
- As a store helper, I want to record stock out quickly so inventory stays updated during sales.
- As a store owner, I want to review inventory history so I can audit stock changes.
- As a future premium user, I want cloud backup so I do not lose data when my phone is damaged.

### Acceptance Criteria

#### Add Product

- Given the user opens Add Product, when required fields are valid, then the app saves the product locally.
- Given the user leaves the product name empty, when saving, then the app shows a validation message.
- Given quantity or threshold is negative, when saving, then the app blocks the save.

#### Stock In

- Given a product exists, when user records stock in quantity 10, then product quantity increases by 10.
- Given stock in succeeds, then an inventory transaction is created.

#### Stock Out

- Given a product has quantity 5, when user attempts stock out quantity 6, then the app blocks the action.
- Given stock out succeeds, then product quantity decreases and a transaction is created.

#### Low Stock

- Given product quantity is equal to or below threshold, when displayed, then it shows a low-stock state.

### Edge Cases

- Product name duplicates: allow for MVP but warn later.
- Zero stock product: allowed and shown as out of stock.
- Negative quantity: never allowed.
- Very large quantity: validate against integer overflow and practical max.
- Product archived with history: hidden from active product list but retained in history.
- App closed during save: database transaction prevents partial stock update.
- Empty history: show friendly empty state.
- Search with no result: show clear no-result state.

### Monetization Ideas

- Free app with local inventory tracking.
- AdMob banner or native ads on non-critical screens only.
- One-time paid "Pro" unlock for backup/export, barcode scanning, and advanced reports.
- Subscription for cloud sync and multi-device access.
- Optional branded PDF/CSV reports.

### Risks And Limitations

- Users may expect POS features immediately; MVP must communicate inventory focus.
- Local-only storage risks data loss if phone is damaged.
- Manual stock input may still be forgotten during busy store hours.
- Low-end devices require careful package and animation choices.
- Monetization through ads must not interrupt stock recording workflows.

---

## PHASE 3 - SYSTEM ARCHITECTURE

### Architecture Overview

Use Flutter with Clean Architecture:

- Presentation layer: screens, widgets, Riverpod providers.
- Domain layer: entities, repository contracts, use cases.
- Data layer: SQLite database, models, data sources, repository implementations.

The MVP uses SQLite through `drift` because it provides type-safe queries, migrations, transactions, and testability. Hive is fast, but relational transactions and history queries are cleaner with SQLite.

### Folder Structure

```text
lib/
  app/
    app.dart
    router.dart
    theme.dart
  core/
    constants/
      app_constants.dart
    database/
      app_database.dart
      tables.dart
    errors/
      app_failure.dart
    utils/
      currency_formatter.dart
      validators.dart
    widgets/
      app_empty_state.dart
      app_error_view.dart
      app_loading_view.dart
      primary_button.dart
  features/
    dashboard/
      presentation/
        dashboard_screen.dart
        dashboard_providers.dart
    products/
      data/
        datasources/product_local_data_source.dart
        models/product_model.dart
        repositories/product_repository_impl.dart
      domain/
        entities/product.dart
        repositories/product_repository.dart
        usecases/add_product.dart
        usecases/get_products.dart
        usecases/update_product.dart
      presentation/
        product_list_screen.dart
        product_form_screen.dart
        product_providers.dart
        widgets/product_tile.dart
    stock/
      data/
        datasources/stock_local_data_source.dart
        models/inventory_transaction_model.dart
        repositories/stock_repository_impl.dart
      domain/
        entities/inventory_transaction.dart
        repositories/stock_repository.dart
        usecases/record_stock_in.dart
        usecases/record_stock_out.dart
      presentation/
        stock_in_screen.dart
        stock_out_screen.dart
        inventory_history_screen.dart
        stock_providers.dart
    settings/
      presentation/settings_screen.dart
  main.dart
test/
```

### Database Schema

#### products

| Column | Type | Notes |
| --- | --- | --- |
| id | text | UUID primary key |
| name | text | required |
| category | text | optional |
| unit | text | default "pcs" |
| selling_price | real | non-negative |
| cost_price | real | optional, non-negative |
| quantity | integer | non-negative |
| low_stock_threshold | integer | non-negative |
| is_archived | integer | 0 or 1 |
| created_at | integer | epoch millis |
| updated_at | integer | epoch millis |

#### inventory_transactions

| Column | Type | Notes |
| --- | --- | --- |
| id | text | UUID primary key |
| product_id | text | foreign key products.id |
| type | text | stock_in or stock_out |
| quantity | integer | positive |
| previous_quantity | integer | snapshot before change |
| new_quantity | integer | snapshot after change |
| note | text | optional |
| created_at | integer | epoch millis |

### Data Flow

```text
Screen
  -> Riverpod Notifier / AsyncNotifier
  -> Use Case
  -> Repository Interface
  -> Repository Implementation
  -> Local Data Source
  -> SQLite Database
```

For stock changes:

```text
Stock In/Out Screen
  -> validate quantity
  -> database transaction
  -> read product
  -> compute new quantity
  -> update product quantity
  -> insert inventory transaction
  -> invalidate dashboard/product/history providers
```

### API-Ready Design

Prepare for future sync by:

- Using UUIDs instead of auto-increment IDs.
- Keeping `created_at` and `updated_at` fields.
- Avoiding direct database models in presentation.
- Keeping repository contracts independent of SQLite.
- Adding transaction history as an append-only sync-friendly log.
- Reserving future fields: `sync_status`, `deleted_at`, `remote_id`.

### Offline-First Capability

- SQLite is the source of truth.
- All reads and writes happen locally.
- Future cloud sync should run in background and never block inventory work.
- Conflicts should later resolve by product `updated_at` and transaction append logs.

### Security Considerations

- Do not log product data or notes in production.
- Use Android app sandbox storage.
- Future login should use secure token storage.
- Future backup should encrypt sensitive exports where practical.
- Add optional app lock/PIN in a later version.

### Backup Strategy

MVP:

- Settings screen includes "Backup and Export - Coming Soon".
- Database location remains app-private.

Future:

- Manual CSV export for products and history.
- Local database backup file with timestamp.
- Google Drive backup.
- Cloud sync service with account login.

---

## PHASE 4 - UI/UX DESIGN

### Design Principles

- Fast first, beautiful second.
- Use clear language: "Stock In", "Stock Out", "Low Stock", "History".
- Minimize required typing.
- Keep primary actions reachable with one hand.
- Use large tap targets and readable contrast.
- Avoid clutter, heavy animations, and dense dashboards.

### Screen List

1. Splash Screen
2. Login Screen (future-ready, optional)
3. Dashboard
4. Product List
5. Add/Edit Product
6. Stock In Screen
7. Stock Out Screen
8. Inventory History
9. Settings

### Navigation Flow

```text
Splash
  -> Dashboard

Dashboard
  -> Product List
  -> Low Stock filtered Product List
  -> Inventory History
  -> Settings

Product List
  -> Add Product
  -> Edit Product
  -> Stock In
  -> Stock Out

Settings
  -> Future Login
  -> Backup placeholder
```

### UX Recommendations

- Use bottom navigation for Dashboard, Products, History, Settings.
- Put "Add Product" as a floating action button on Product List.
- Allow Stock In and Stock Out from product rows.
- Show low-stock count as a dashboard card.
- Use confirmation snackbars after stock changes.
- Use warning color only for low-stock and validation issues.
- Avoid modal-heavy flows for common stock recording.

### Wireframe Descriptions

#### Splash Screen

- App logo/name centered.
- Lightweight loading indicator.
- Automatically routes to Dashboard after initialization.

#### Login Screen Future-Ready

- Not shown by default in MVP.
- Simple local intro screen later for backup/login.
- Buttons: Continue Offline, Sign In for Backup.

#### Dashboard

- Top greeting: "Inventory Today".
- Summary cards: Products, Low Stock, Stock Changes Today.
- Low-stock preview list.
- Recent activity list.

#### Product List

- Search field at top.
- Filter chips: All, Low Stock, Out of Stock.
- Product rows show name, category, quantity, and stock status.
- Row actions: Stock In, Stock Out, Edit.

#### Add/Edit Product

- Form fields: name, category, unit, selling price, cost price, quantity, low-stock threshold.
- Save button fixed at bottom.
- Inline validation.

#### Stock In Screen

- Product name and current quantity.
- Quantity input.
- Optional note.
- Save button.

#### Stock Out Screen

- Product name and current quantity.
- Quantity input.
- Optional note.
- Shows warning if quantity exceeds current stock.

#### Inventory History

- Date-grouped transaction list.
- Each row shows type, product, quantity, previous/new quantity, note, time.
- Empty state when no history.

#### Settings

- Business name placeholder.
- Currency: PHP.
- Backup/export placeholder.
- App version.

### Visual Style

- Minimalist Material 3.
- Light theme first.
- White/off-white background.
- Green primary color for positive inventory action.
- Amber/red accents for low-stock warnings.
- Compact cards with small radius and no heavy shadows.

---

## PHASE 5 - DEVELOPMENT PLAN

### Epics

| Epic | Description | Priority |
| --- | --- | --- |
| E1 | Project foundation and architecture | P0 |
| E2 | Local database and repositories | P0 |
| E3 | Product management CRUD | P0 |
| E4 | Stock movement and history | P0 |
| E5 | Dashboard and low-stock alerts | P0 |
| E6 | Settings and future-ready backup | P1 |
| E7 | Testing and release readiness | P0 |

### Sprint Plan

#### Sprint 1 - Foundation

- Create Flutter project.
- Add dependencies.
- Set up theme, router, folder structure.
- Add database tables and migrations.
- Add core reusable widgets.

#### Sprint 2 - Product CRUD

- Implement product entity, model, repository, use cases.
- Build product list.
- Build add/edit product form.
- Add validation, loading, and error states.

#### Sprint 3 - Stock Movement

- Implement inventory transaction entity/model.
- Implement stock in/out use cases with database transactions.
- Build stock in/out screens.
- Build inventory history screen.

#### Sprint 4 - Dashboard And Polish

- Dashboard summaries.
- Low-stock alerts.
- Empty states.
- Manual QA pass.
- Unit/widget tests.
- Play Store prep.

### Development Task Priorities

- P0: app compiles, local database works, product CRUD works, stock movement is atomic.
- P1: dashboard summaries, settings, polish.
- P2: backup/export, login placeholder, analytics.

---

## PHASE 6 - IMPLEMENTATION

This section provides a production-ready implementation blueprint. The next BMAD step should scaffold these files into a Flutter project after approval.

### Step 1 - pubspec.yaml Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  go_router: ^14.6.2
  drift: ^2.22.1
  sqlite3_flutter_libs: ^0.5.26
  path_provider: ^2.1.5
  path: ^1.9.0
  uuid: ^4.5.1
  intl: ^0.20.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.13
  drift_dev: ^2.22.1
  mocktail: ^1.0.4
  very_good_analysis: ^6.0.0
```

### Step 2 - Database Tables

```dart
// lib/core/database/tables.dart
import 'package:drift/drift.dart';

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get category => text().nullable()();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  RealColumn get sellingPrice => real().withDefault(const Constant(0))();
  RealColumn get costPrice => real().nullable()();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  IntColumn get lowStockThreshold => integer().withDefault(const Constant(5))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class InventoryTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get type => text()();
  IntColumn get quantity => integer()();
  IntColumn get previousQuantity => integer()();
  IntColumn get newQuantity => integer()();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### Step 3 - App Database

```dart
// lib/core/database/app_database.dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Products, InventoryTransactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'inventory_tracker.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
```

### Step 4 - Domain Entities

```dart
// lib/features/products/domain/entities/product.dart
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.lowStockThreshold,
    required this.sellingPrice,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.costPrice,
    this.isArchived = false,
  });

  final String id;
  final String name;
  final String? category;
  final String unit;
  final int quantity;
  final int lowStockThreshold;
  final double sellingPrice;
  final double? costPrice;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isLowStock => quantity <= lowStockThreshold;
  bool get isOutOfStock => quantity == 0;
}
```

```dart
// lib/features/stock/domain/entities/inventory_transaction.dart
enum InventoryTransactionType { stockIn, stockOut }

class InventoryTransaction {
  const InventoryTransaction({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.previousQuantity,
    required this.newQuantity,
    required this.createdAt,
    this.note,
    this.productName,
  });

  final String id;
  final String productId;
  final InventoryTransactionType type;
  final int quantity;
  final int previousQuantity;
  final int newQuantity;
  final String? note;
  final String? productName;
  final DateTime createdAt;
}
```

### Step 5 - Repository Contracts

```dart
// lib/features/products/domain/repositories/product_repository.dart
import '../entities/product.dart';

abstract class ProductRepository {
  Stream<List<Product>> watchProducts({String query = '', bool lowStockOnly = false});
  Future<Product?> getProductById(String id);
  Future<void> addProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> archiveProduct(String id);
}
```

```dart
// lib/features/stock/domain/repositories/stock_repository.dart
import '../entities/inventory_transaction.dart';

abstract class StockRepository {
  Stream<List<InventoryTransaction>> watchHistory();
  Future<void> recordStockIn({required String productId, required int quantity, String? note});
  Future<void> recordStockOut({required String productId, required int quantity, String? note});
}
```

### Step 6 - Stock Repository Transaction Logic

```dart
// lib/features/stock/data/repositories/stock_repository_impl.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/repositories/stock_repository.dart';

class StockRepositoryImpl implements StockRepository {
  StockRepositoryImpl(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  @override
  Future<void> recordStockIn({
    required String productId,
    required int quantity,
    String? note,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be greater than zero.');
    }

    await _db.transaction(() async {
      final product = await (_db.select(_db.products)..where((p) => p.id.equals(productId))).getSingleOrNull();
      if (product == null) {
        throw StateError('Product not found.');
      }

      final newQuantity = product.quantity + quantity;
      final now = DateTime.now().millisecondsSinceEpoch;

      await (_db.update(_db.products)..where((p) => p.id.equals(productId))).write(
        ProductsCompanion(quantity: Value(newQuantity), updatedAt: Value(now)),
      );

      await _db.into(_db.inventoryTransactions).insert(
        InventoryTransactionsCompanion.insert(
          id: _uuid.v4(),
          productId: productId,
          type: 'stock_in',
          quantity: quantity,
          previousQuantity: product.quantity,
          newQuantity: newQuantity,
          createdAt: now,
          note: Value(note),
        ),
      );
    });
  }

  @override
  Future<void> recordStockOut({
    required String productId,
    required int quantity,
    String? note,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be greater than zero.');
    }

    await _db.transaction(() async {
      final product = await (_db.select(_db.products)..where((p) => p.id.equals(productId))).getSingleOrNull();
      if (product == null) {
        throw StateError('Product not found.');
      }
      if (quantity > product.quantity) {
        throw StateError('Not enough stock available.');
      }

      final newQuantity = product.quantity - quantity;
      final now = DateTime.now().millisecondsSinceEpoch;

      await (_db.update(_db.products)..where((p) => p.id.equals(productId))).write(
        ProductsCompanion(quantity: Value(newQuantity), updatedAt: Value(now)),
      );

      await _db.into(_db.inventoryTransactions).insert(
        InventoryTransactionsCompanion.insert(
          id: _uuid.v4(),
          productId: productId,
          type: 'stock_out',
          quantity: quantity,
          previousQuantity: product.quantity,
          newQuantity: newQuantity,
          createdAt: now,
          note: Value(note),
        ),
      );
    });
  }
}
```

### Step 7 - Riverpod Providers

```dart
// lib/core/database/database_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
```

```dart
// lib/features/products/presentation/product_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/repositories/product_repository_impl.dart';
import '../domain/entities/product.dart';
import '../domain/repositories/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(ref.watch(databaseProvider));
});

final productSearchProvider = StateProvider<String>((ref) => '');

final productsProvider = StreamProvider<List<Product>>((ref) {
  final query = ref.watch(productSearchProvider);
  return ref.watch(productRepositoryProvider).watchProducts(query: query);
});

final lowStockProductsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).watchProducts(lowStockOnly: true);
});
```

### Step 8 - Navigation

```dart
// lib/app/router.dart
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/products/presentation/product_form_screen.dart';
import '../features/products/presentation/product_list_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/stock/presentation/inventory_history_screen.dart';
import '../features/stock/presentation/stock_in_screen.dart';
import '../features/stock/presentation/stock_out_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
    GoRoute(path: '/products', builder: (_, __) => const ProductListScreen()),
    GoRoute(path: '/products/new', builder: (_, __) => const ProductFormScreen()),
    GoRoute(path: '/products/:id/edit', builder: (_, state) => ProductFormScreen(productId: state.pathParameters['id'])),
    GoRoute(path: '/products/:id/stock-in', builder: (_, state) => StockInScreen(productId: state.pathParameters['id']!)),
    GoRoute(path: '/products/:id/stock-out', builder: (_, state) => StockOutScreen(productId: state.pathParameters['id']!)),
    GoRoute(path: '/history', builder: (_, __) => const InventoryHistoryScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
);
```

### Step 9 - UI Screen Pattern

```dart
// lib/features/products/presentation/product_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'product_providers.dart';
import 'widgets/product_tile.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/products/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search products',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => ref.read(productSearchProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: products.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('No products yet.'));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) => ProductTile(product: items[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Something went wrong: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Step 10 - Validation Rules

```dart
// lib/core/utils/validators.dart
class Validators {
  static String? requiredText(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  static String? nonNegativeInt(String? value, String label) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null) {
      return 'Enter a valid number.';
    }
    if (parsed < 0) {
      return '$label cannot be negative.';
    }
    return null;
  }

  static String? positiveInt(String? value, String label) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null) {
      return 'Enter a valid number.';
    }
    if (parsed <= 0) {
      return '$label must be greater than zero.';
    }
    return null;
  }
}
```

### Implementation Notes

- Keep business rules in use cases and repositories, not widgets.
- Keep database transactions around stock in/out.
- Use `AsyncValue` for loading, data, and error states.
- Avoid hardcoded currency logic; centralize PHP formatting.
- Archive products instead of deleting them.
- Generate Drift code with `dart run build_runner build --delete-conflicting-outputs`.

---

## PHASE 7 - TESTING

### Unit Test Strategy

- Test validators for empty, invalid, negative, and valid inputs.
- Test product repository add/update/archive behavior with in-memory SQLite.
- Test stock in increases quantity and creates history.
- Test stock out decreases quantity and creates history.
- Test stock out fails when requested quantity exceeds available stock.
- Test low-stock computed property.

### Widget Test Strategy

- Product list shows empty state when no products exist.
- Product list shows loading state while provider loads.
- Product form blocks save when required fields are missing.
- Stock out screen shows validation when quantity is too high.
- Dashboard displays low-stock count.

### Manual QA Checklist

- Install fresh app and open dashboard.
- Add product with valid values.
- Try adding product with empty name.
- Try negative quantity and threshold.
- Edit product details.
- Record stock in.
- Record stock out.
- Attempt stock out greater than available stock.
- Confirm low-stock badge appears at threshold.
- Confirm history shows correct previous and new quantities.
- Close and reopen app; confirm data remains.
- Turn off internet; confirm all core actions still work.
- Test on small screen and low-end Android device.

### Common Bug Prevention Checklist

- Never update product quantity without inserting history.
- Never insert history if product quantity update fails.
- Never allow negative stock.
- Do not delete product history when archiving products.
- Do not block UI during database operations.
- Do not show raw exception messages to end users in release builds.
- Avoid rebuilding full lists unnecessarily.

---

## PHASE 8 - PLAY STORE READINESS

### App Name Suggestions

- TindaTrack
- SariStock
- Bantay Inventory
- Tindahan Tracker
- Simple Stock PH

Recommended MVP name: **TindaTrack**

### Package Naming

Suggested package:

```text
com.yourcompany.tindatrack
```

If solo developer:

```text
com.rkuhonta.tindatrack
```

### Store Description

Short description:

```text
Offline inventory tracker for sari-sari stores and small businesses.
```

Long description:

```text
TindaTrack helps small businesses, sari-sari stores, and home-based sellers track product stock quickly and reliably. Add products, record stock in and stock out, view inventory history, and spot low-stock items before they run out.

Designed for everyday store operations, TindaTrack works offline and stays lightweight for Android phones commonly used by small business owners.
```

### Privacy Policy Requirements

For MVP local-only mode, the privacy policy should state:

- The app stores inventory data locally on the user's device.
- The app does not require account registration for offline use.
- The app does not upload product or inventory data to a server in MVP.
- If ads are added, AdMob may collect advertising identifiers and diagnostics.
- If cloud backup is added later, explain what data is synced and how users can delete it.

### Play Store Checklist

- App icon.
- Feature graphic.
- Screenshots for common Android phone sizes.
- Privacy policy URL.
- Data safety form.
- Content rating questionnaire.
- Target SDK compliance.
- Signed release build.
- App bundle build.
- Crash-free smoke test.
- Offline functionality verified.
- No debug banners or test keys.

### AdMob Integration Plan

- Do not show ads during Add Product, Edit Product, Stock In, or Stock Out.
- Consider banner ads only on Dashboard, History, or Settings.
- Add consent flow if required by target regions.
- Use test ad units during development.
- Keep an ad-free paid upgrade path.

---

## BMAD Next Step Recommendation

Do not start coding until the MVP scope, architecture, and UX are accepted. After approval, proceed in this order:

1. Scaffold Flutter project.
2. Add dependencies and folder structure.
3. Implement database and repositories.
4. Build product CRUD.
5. Build stock movement.
6. Build dashboard/history/settings.
7. Add tests and release checklist.
