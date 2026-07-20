/// Formats MVP money values for the fixed Philippine Peso context.
class CurrencyFormatter {
  /// Creates a formatter for a fixed currency context.
  const CurrencyFormatter({
    required this.currencyCode,
    required this.currencySymbol,
  });

  /// Creates the MVP Philippine Peso formatter.
  const CurrencyFormatter.php()
    : currencyCode = 'PHP',
      currencySymbol = '\u20B1';

  /// ISO-style currency code shown in Settings.
  final String currencyCode;

  /// Currency symbol used for compact price displays.
  final String currencySymbol;

  /// Formats a non-negative amount with two decimals and thousands separators.
  String format(num amount) {
    if (!amount.isFinite || amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'Must be non-negative.');
    }

    final fixed = amount.toStringAsFixed(2);
    final parts = fixed.split('.');
    final pesos = parts.first;
    final centavos = parts.last;
    final buffer = StringBuffer();

    for (var index = 0; index < pesos.length; index++) {
      if (index > 0 && (pesos.length - index) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(pesos[index]);
    }

    return '$currencySymbol$buffer.$centavos';
  }
}
