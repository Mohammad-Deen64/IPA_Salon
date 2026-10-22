import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Ensures the AI API base URL is the Render cloud host.
class ApiDiscovery {
  static bool _ready = false;
  static Future<void>? _inflight;

  static Future<void> ensure() {
    if (_ready && ApiConfig.runtimeOverride == ApiConfig.platformDefault) {
      return Future.value();
    }
    return _inflight ??= _probe().whenComplete(() => _inflight = null);
  }

  static Future<T> sendWithRecovery<T>(Future<T> Function() send) async {
    await ensure();
    try {
      return await send();
    } catch (_) {
      _ready = false;
      ApiConfig.setRuntimeOverride(null);
      await ensure();
      return send();
    }
  }

  static void markReadyForTest() {
    ApiConfig.setRuntimeOverride(ApiConfig.platformDefault);
    _ready = true;
  }

  static void resetForTest() {
    _ready = false;
    _inflight = null;
    ApiConfig.setRuntimeOverride(null);
  }

  static Future<void> _probe() async {
    final url = ApiConfig.normalize(ApiConfig.platformDefault);
    // Always use the cloud host. Retry health while Free Render wakes up.
    for (var attempt = 0; attempt < 4; attempt++) {
      if (await _healthy(url)) {
        ApiConfig.setRuntimeOverride(url);
        _ready = true;
        return;
      }
    }
    ApiConfig.setRuntimeOverride(url);
    _ready = true;
  }

  static Future<bool> _healthy(String url) async {
    try {
      final response = await http.get(Uri.parse('$url/health')).timeout(ApiConfig.probeTimeout);
      return response.statusCode == 200 && response.body.contains('"ok"');
    } catch (_) {
      return false;
    }
  }
}
