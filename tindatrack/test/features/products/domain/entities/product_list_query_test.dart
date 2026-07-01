import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/features/products/domain/entities/product_list_query.dart';

void main() {
  group('ProductListQuery', () {
    test('normalizes trimmed and blank search text', () {
      expect(ProductListQuery(searchText: '  rice  ').searchText, 'rice');
      expect(ProductListQuery(searchText: ' \n\t ').searchText, isEmpty);
    });

    test('default query is empty search with all stock', () {
      const query = ProductListQuery.defaultQuery();

      expect(query.searchText, isEmpty);
      expect(query.stockFilter, ProductStockFilter.all);
      expect(query.isDefault, isTrue);
    });

    test('effective query equality and hash behavior are stable', () {
      final first = ProductListQuery(searchText: '  rice ');
      final second = ProductListQuery(searchText: 'rice');
      final differentAsciiCase = ProductListQuery(searchText: 'RICE');

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, differentAsciiCase);
      expect(first.hashCode, differentAsciiCase.hashCode);
      expect(
        ProductListQuery(searchText: 'É'),
        isNot(ProductListQuery(searchText: 'é')),
      );
      expect(
        ProductListQuery(
          searchText: 'rice',
          stockFilter: ProductStockFilter.lowStock,
        ),
        isNot(second),
      );
    });

    test('stock filter identities remain mutually exclusive', () {
      expect(
        ProductStockFilter.values,
        [
          ProductStockFilter.all,
          ProductStockFilter.lowStock,
          ProductStockFilter.outOfStock,
        ],
      );
      expect(ProductStockFilter.lowStock, isNot(ProductStockFilter.outOfStock));
    });
  });
}
