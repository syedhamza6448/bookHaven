import 'package:intl/intl.dart';

final _money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

String formatPrice(double value) => _money.format(value);