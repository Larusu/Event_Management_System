/// Validation logic for authentication request fields.
class AuthValidationService {
  static const String _emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  /// Validate email format.
  /// Returns null if valid, error message if invalid.
  static String? validateEmail(String email) {
    if (email.isEmpty) {
      return 'Email is required';
    }

    final trimmed = email.trim().toLowerCase();

    if (!RegExp(_emailPattern).hasMatch(trimmed)) {
      return 'Invalid email format';
    }

    if (trimmed.contains(' ')) {
      return 'Email cannot contain spaces';
    }

    return null;
  }

  /// Validate password.
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }

    return null;
  }

  /// Validate name fields (first name / last name).
  static String? validateName(String name, String fieldName) {
    if (name.isEmpty) {
      return '$fieldName is required';
    }

    if (name.trim().isEmpty) {
      return '$fieldName cannot be empty or whitespace only';
    }

    return null;
  }

  /// Validate contact number.
  static String? validateContactNumber(String contactNumber) {
    if (contactNumber.isEmpty) {
      return 'Contact number is required';
    }

    final trimmed = contactNumber.trim();
    if (trimmed.isEmpty) {
      return 'Contact number cannot be empty or whitespace only';
    }

    if (!RegExp(r'^09\d{9}$').hasMatch(trimmed)) {
      return 'Contact number must be 11 digits starting with 09';
    }

    return null;
  }
}

/// Validation logic for event fields.
/// Validation logic for event fields.
class EventValidationService {
  /// Validates PATCH request body against existing event.
  /// Returns null if valid, error message if invalid.
  static String? validateEventPatch(
    Map<String, dynamic> body,
    Map<String, dynamic> existingEvent,
  ) {
    final date = body['date'] as String?;
    if (date != null && date.isNotEmpty) {
      final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      if (!datePattern.hasMatch(date)) {
        return 'Invalid date format. Use YYYY-MM-DD.';
      }

      final today = DateTime.now().toUtc().toIso8601String().split('T').first;
      if (date.compareTo(today) < 0) {
        return 'Date cannot be in the past';
      }
    }

    final eventMode = body['event_mode'] as String?;
    final location = body['location'] as String?;
    final streamLink = body['stream_link'] as String?;

    if (eventMode == 'online') {
      if (streamLink == null || streamLink.isEmpty) {
        return 'Stream link is required for online events';
      }
    }

    if (eventMode == 'offline') {
      if (location == null || location.isEmpty) {
        return 'Location is required for offline events';
      }
    }

    return null;
  }
}
