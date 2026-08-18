import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:zovi/core/utils/phone/phone_format.dart';

@immutable
final class CountryPhoneInputFormatter extends TextInputFormatter {
  const CountryPhoneInputFormatter(this.format);

  final PhoneFormat format;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = format.limitDigits(newValue.text);
    final formatted = format.formatDigits(digits);
    final selectionIndex = _resolveSelection(
      oldValue: oldValue,
      newValue: newValue,
      formatted: formatted,
      digits: digits,
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }

  int _resolveSelection({
    required TextEditingValue oldValue,
    required TextEditingValue newValue,
    required String formatted,
    required String digits,
  }) {
    if (formatted.isEmpty) return 0;

    final isDeleting = newValue.text.length < oldValue.text.length;

    if (isDeleting) {
      return formatted.length;
    }

    final digitCursor = _digitIndexBeforeCursor(
      newValue.text,
      newValue.selection.end,
    );
    final targetDigitIndex = digitCursor.clamp(0, digits.length);
    return _cursorForDigitIndex(formatted, targetDigitIndex);
  }

  int _digitIndexBeforeCursor(String text, int cursor) {
    var count = 0;
    final limit = cursor.clamp(0, text.length);
    for (var i = 0; i < limit; i++) {
      if (RegExp(r'\d').hasMatch(text[i])) count++;
    }
    return count;
  }

  int _cursorForDigitIndex(String formatted, int digitIndex) {
    if (digitIndex <= 0) return 0;

    var count = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (RegExp(r'\d').hasMatch(formatted[i])) {
        count++;
        if (count == digitIndex) return i + 1;
      }
    }
    return formatted.length;
  }
}
