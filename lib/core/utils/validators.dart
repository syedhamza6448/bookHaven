class Validators {
  static String? email(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Please enter your email';
    final ok = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(value);
    return ok ? null : 'Enter a valid email address';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Please enter your password';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? fullName(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Please enter your full name';
    if (value.length < 3) return 'Name is too short';
    return null;
  }

  static String? newPassword(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'Please create a password';
    if (value.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
        !RegExp(r'\d').hasMatch(value)) {
      return 'Include at least one letter and one number';
    }
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() original) {
    return (String? v) {
      if (v == null || v.isEmpty) return 'Please confirm your password';
      if (v != original()) return 'Passwords do not match';
      return null;
    };
  }

  static String? otpCode(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Enter the code from your email';
    if (!RegExp(r'^\d{6,8}$').hasMatch(value)) return 'Enter the 6-digit code';
    return null;
  }

  static String? required(String? v, [String label = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  static String? phone(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Phone number is required';
    if (digits.length < 10 || digits.length > 15)
      return 'Enter a valid phone number';
    return null;
  }

  static String? cardNumber(String? v) {
    final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return 'Card number is required';
    if (d.length < 13 || d.length > 19) return 'Enter a valid card number';
    var sum = 0;
    var alt = false;
    for (var i = d.length - 1; i >= 0; i--) {
      var n = int.parse(d[i]);
      if (alt) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alt = !alt;
    }
    return sum % 10 == 0 ? null : 'Enter a valid card number';
  }

  static String? cardExpiry(String? v) {
    final m = RegExp(r'^(\d{2})/(\d{2})$').firstMatch((v ?? '').trim());
    if (m == null) return 'Use MM/YY';
    final month = int.parse(m.group(1)!);
    final year = 2000 + int.parse(m.group(2)!);
    if (month < 1 || month > 12) return 'Invalid month';
    final now = DateTime.now();
    if (year < now.year || (year == now.year && month < now.month))
      return 'Card has expired';
    return null;
  }

  static String? cardCvv(String? v) {
    final d = (v ?? '').trim();
    return RegExp(r'^\d{3,4}$').hasMatch(d) ? null : 'Invalid CVV';
  }
}
