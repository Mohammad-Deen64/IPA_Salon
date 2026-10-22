/// Base URL for the FastAPI AI service (face analysis / recommendations).
///
/// Auth, chat, and salons use Firestore. This URL is only for AI Style Finder.
class ApiConfig {
  static const definedUrl = String.fromEnvironment('API_BASE_URL');

  static String? _runtimeOverride;

  static const analyzeTimeout = Duration(seconds: 180);
  static const requestTimeout = Duration(seconds: 45);
  static const healthTimeout = Duration(seconds: 90);
  static const probeTimeout = Duration(seconds: 90);

  static String get platformDefault =>
      'https://dr-salon-ai-api.onrender.com';

  static String get baseUrl {
    final runtime = _runtimeOverride?.trim();
    if (runtime != null && runtime.isNotEmpty) {
      return normalize(runtime);
    }
    if (definedUrl.trim().isNotEmpty) {
      return normalize(definedUrl);
    }
    return normalize(platformDefault);
  }

  static String? get runtimeOverride => _runtimeOverride;

  static void setRuntimeOverride(String? url) {
    final trimmed = url?.trim();
    _runtimeOverride = (trimmed == null || trimmed.isEmpty) ? null : normalize(trimmed);
  }

  static String normalize(String url) {
    var value = url.trim();
    if (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
