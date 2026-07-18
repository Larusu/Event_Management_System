/// Cloudinary configuration loaded from environment variables.
class CloudinaryConfig {
  CloudinaryConfig._();

  static String? _cloudName;
  static String? _apiKey;
  static String? _apiSecret;
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static String get cloudName {
    if (_cloudName == null || _cloudName!.isEmpty) {
      throw StateError('CLOUDINARY_CLOUD_NAME not configured.');
    }
    return _cloudName!;
  }

  static String get apiKey {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw StateError('CLOUDINARY_API_KEY not configured.');
    }
    return _apiKey!;
  }

  static String get apiSecret {
    if (_apiSecret == null || _apiSecret!.isEmpty) {
      throw StateError('CLOUDINARY_API_SECRET not configured.');
    }
    return _apiSecret!;
  }

  /// Initializes Cloudinary credentials from the given environment map.
  static void initialize(Map<String, String?> envMap) {
    _cloudName = envMap['CLOUDINARY_CLOUD_NAME'];
    _apiKey = envMap['CLOUDINARY_API_KEY'];
    _apiSecret = envMap['CLOUDINARY_API_SECRET'];
    _initialized = true;
  }
}
