import 'package:intl/intl.dart';

/// App-wide fallback when profile / row has no currency (see migration 00005).
const String kDefaultCurrency = 'JPY';

String formatMoneyCents(int cents, String currencyCode) {
  final value = cents / 100.0;
  return NumberFormat.simpleCurrency(name: currencyCode).format(value);
}
