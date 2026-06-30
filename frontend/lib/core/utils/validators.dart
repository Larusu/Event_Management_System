/// Client-side validation rules for the auth forms (sections 1.5.1 / 1.5.2).
///
/// Each method returns `null` when valid, or an error message string suitable
/// for use as a `TextFormField` validator result.
class Validators {
  const Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');

  /// 11 digits, starting with `09`.
  static final RegExp _contactRegex = RegExp(r'^09\d{9}$');

  static const int minPasswordLength = 8;

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < minPasswordLength) {
      return 'Password must be at least $minPasswordLength characters';
    }
    return null;
  }

  static String? name(String? value) {
    if ((value?.trim() ?? '').isEmpty) return 'This field is required';
    return null;
  }

  static String? contact(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Contact number is required';
    if (!_contactRegex.hasMatch(v)) {
      return 'Enter an 11-digit number starting with 09';
    }
    return null;
  }

  /// For the registration confirm-password field (never sent to the backend).
  static String? confirmPassword(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }
}
