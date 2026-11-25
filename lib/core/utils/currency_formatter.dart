import 'package:intl/intl.dart';

class CurrencyFormatter {
  const CurrencyFormatter._();

  static final NumberFormat _idrFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _plainNumberFormat = NumberFormat.decimalPattern('id_ID');

  static String formatRupiah(num amount) {
    return _idrFormat.format(amount.round());
  }

  static String formatPlain(num amount) {
    return _plainNumberFormat.format(amount.round());
  }

  static String formatCompactRupiah(num amount) {
    if (amount >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)} M';
    }
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)} Jt';
    }
    if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)} Rb';
    }
    return formatRupiah(amount);
  }
}
