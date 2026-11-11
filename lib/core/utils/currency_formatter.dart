import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static final NumberFormat _compactFormatter = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 0,
  );

  static String format(num? amount, {String currency = 'USD'}) {
    if (amount == null) return '\$0.00';
    if (currency == 'USD') {
      return _formatter.format(amount);
    }
    return '$currency ${_formatter.format(amount).replaceAll('\$', '')}';
  }

  static String formatCompact(num? amount) {
    if (amount == null) return '\$0';
    return _compactFormatter.format(amount);
  }
}
