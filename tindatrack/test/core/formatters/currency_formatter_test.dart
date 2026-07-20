import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/formatters/currency_formatter.dart';

void main() {
  group('CurrencyFormatter.php', () {
    const formatter = CurrencyFormatter.php();

    test('exposes the MVP PHP context', () {
      expect(formatter.currencyCode, 'PHP');
      expect(formatter.currencySymbol, '\u20B1');
    });

    test('formats non-negative values with centavos and separators', () {
      expect(formatter.format(0), '\u20B10.00');
      expect(formatter.format(1), '\u20B11.00');
      expect(formatter.format(12.5), '\u20B112.50');
      expect(formatter.format(1234.56), '\u20B11,234.56');
      expect(formatter.format(1234567.8), '\u20B11,234,567.80');
    });

    test('rejects values that should not be displayed as product prices', () {
      expect(() => formatter.format(-0.01), throwsArgumentError);
      expect(() => formatter.format(double.nan), throwsArgumentError);
      expect(() => formatter.format(double.infinity), throwsArgumentError);
    });
  });
}
