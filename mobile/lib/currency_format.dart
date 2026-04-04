import 'package:intl/intl.dart';

/// App-wide fallback when profile / row has no currency (see migration 00005).
const String kDefaultCurrency = 'JPY';

String formatMoneyCents(int cents, String currencyCode) {
  final value = cents / 100.0;
  return NumberFormat.simpleCurrency(name: currencyCode).format(value);
}

/// Prefix for plain amount `TextField`s (symbol + space).
String currencyInputPrefix(String code) {
  switch (code) {
    case 'JPY':
      return '¥ ';
    case 'USD':
      return r'$ ';
    case 'EUR':
      return '€ ';
    case 'GBP':
      return '£ ';
    case 'INR':
      return '₹ ';
    default:
      return '$code ';
  }
}
