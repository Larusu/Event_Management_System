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
class EventValidationService {
  static final _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final _timePattern = RegExp(r'^\d{2}:\d{2}$');

  /// Validates a full event creation body.
  /// Returns null if valid, error message if invalid.
  static String? validateCreateEvent(Map<String, dynamic> body) {
    // --- Required string fields ---
    const requiredStrings = [
      'title',
      'description',
      'cover_image_url',
      'date',
      'start_time',
      'end_time',
      'event_mode',
      'host_name',
    ];

    for (final field in requiredStrings) {
      final value = body[field];
      if (value == null || (value is String && value.trim().isEmpty)) {
        return 'Missing required field: $field';
      }
    }

    // --- Required arrays (non-empty) ---
    final contactEmails = body['contact_emails'];
    if (contactEmails is! List || contactEmails.isEmpty) {
      return 'contact_emails must be a non-empty list.';
    }

    final tags = body['tags'];
    if (tags is! List || tags.isEmpty) {
      return 'tags must be a non-empty list.';
    }

    // --- Required integer ---
    final slotsTotal = body['slots_total'];
    if (slotsTotal is! int || slotsTotal <= 0) {
      return 'slots_total must be a positive integer.';
    }

    // --- Date format + today-or-future ---
    final date = body['date'] as String;
    if (!_datePattern.hasMatch(date)) {
      return 'Invalid date format. Use YYYY-MM-DD.';
    }

    final today = DateTime.now()
        .toUtc()
        .toIso8601String()
        .split('T')
        .first;
    if (date.compareTo(today) < 0) {
      return 'Event date must be today or in the future.';
    }

    // --- Time format + end after start ---
    final startTime = body['start_time'] as String;
    final endTime = body['end_time'] as String;

    if (!_timePattern.hasMatch(startTime)) {
      return 'Invalid start_time format. Use HH:mm (24-hour).';
    }
    if (!_timePattern.hasMatch(endTime)) {
      return 'Invalid end_time format. Use HH:mm (24-hour).';
    }

    if (endTime.compareTo(startTime) <= 0) {
      return 'end_time must be after start_time.';
    }

    // --- Mode / location / stream consistency ---
    final eventMode = body['event_mode'] as String;
    if (eventMode != 'online' && eventMode != 'offline') {
      return 'event_mode must be "online" or "offline".';
    }

    if (eventMode == 'online') {
      final streamLink = body['stream_link'];
      if (streamLink is! String || streamLink.trim().isEmpty) {
        return 'stream_link is required for online events.';
      }
    }

    if (eventMode == 'offline') {
      final location = body['location'];
      if (location is! String || location.trim().isEmpty) {
        return 'location is required for offline events.';
      }
    }

    return null;
  }

  /// Validates PATCH request body against existing event.
  /// Returns null if valid, error message if invalid.
  static String? validateEventPatch(
    Map<String, dynamic> body,
    Map<String, dynamic> existingEvent,
  ) {
    final date = body['date'] as String?;
    if (date != null && date.isNotEmpty) {
      if (!_datePattern.hasMatch(date)) {
        return 'Invalid date format. Use YYYY-MM-DD.';
      }

      final today = DateTime.now()
          .toUtc()
          .toIso8601String()
          .split('T')
          .first;
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
