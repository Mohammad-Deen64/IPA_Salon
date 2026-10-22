import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/face_analysis_result.dart';
import 'api_discovery.dart';
import 'api_exception.dart';
import 'network.dart';

class FaceAnalysisService {
  FaceAnalysisService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _fixedBaseUrl = baseUrl;

  final http.Client _client;
  final String? _fixedBaseUrl;

  String get baseUrl => _fixedBaseUrl ?? ApiConfig.baseUrl;

  Future<void> ping() async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await _client
            .get(Uri.parse('$baseUrl/health'))
            .timeout(ApiConfig.healthTimeout);
        if (response.statusCode == 200 && response.body.contains('"ok"')) {
          return;
        }
        lastError = 'HTTP ${response.statusCode}';
      } on Object catch (error) {
        lastError = error;
        if (!isUnreachable(error) && error is! TimeoutException) {
          rethrow;
        }
      }
    }
    throw ApiException(_offlineMessage(lastError));
  }

  Future<FaceAnalysisResult> analyze(File image) async {
    if (_fixedBaseUrl == null) {
      await ApiDiscovery.ensure();
      ApiConfig.setRuntimeOverride(ApiConfig.platformDefault);
    }
    await ping();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/analyze-face'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    http.StreamedResponse streamed;
    try {
      streamed = await _client.send(request).timeout(ApiConfig.analyzeTimeout);
    } on TimeoutException {
      throw const ApiException(
        'Face analysis timed out. Wait a moment and try again with a clearer photo.',
      );
    } on Object catch (error) {
      if (isUnreachable(error)) {
        throw ApiException(_offlineMessage(error));
      }
      rethrow;
    }

    final response = await http.Response.fromStream(streamed);
    final body = _decode(response.body);
    if (response.statusCode != 200) {
      throw ApiException(_detail(body, response.statusCode));
    }
    try {
      return FaceAnalysisResult.fromJson(body);
    } on Object {
      throw const ApiException('The server returned an unexpected analysis result.');
    }
  }

  String _offlineMessage(Object? error) {
    return 'Could not reach $baseUrl. Check phone internet and try Analyze again. (${error ?? 'offline'})';
  }

  Map<String, dynamic> _decode(String raw) {
    if (raw.isEmpty) {
      return {};
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return {};
  }

  String _detail(Map<String, dynamic> body, int status) {
    final detail = body['detail'];
    if (detail is String && detail.isNotEmpty) {
      return detail;
    }
    if (status == 422) {
      return 'No face detected. Please upload a clear face image.';
    }
    return 'Face analysis failed. Please try again.';
  }
}
