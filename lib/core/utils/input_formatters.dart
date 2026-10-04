import 'package:flutter/services.dart';

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var d = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 16) d = d.substring(0, 16);
    final buf = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
    }
    final s = buf.toString();
    return TextEditingValue(
      text: s,
      selection: TextSelection.collapsed(offset: s.length),
    );
  }
}

class ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var d = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 4) d = d.substring(0, 4);
    final s = d.length > 2 ? '${d.substring(0, 2)}/${d.substring(2)}' : d;
    return TextEditingValue(
      text: s,
      selection: TextSelection.collapsed(offset: s.length),
    );
  }
}
