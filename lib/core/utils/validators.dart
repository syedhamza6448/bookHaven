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
}
