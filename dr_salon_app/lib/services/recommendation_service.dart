import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/recommendation.dart';
import 'api_discovery.dart';
import 'api_exception.dart';
import 'network.dart';

class RecommendationService {
  RecommendationService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _fixedBaseUrl = baseUrl;

  final http.Client _client;
  final String? _fixedBaseUrl;

  String get baseUrl => _fixedBaseUrl ?? ApiConfig.baseUrl;

  Future<RecommendationResult> fetch({
    required String gender,
    required String faceShape,
  }) async {
    if (_fixedBaseUrl == null) {
      await ApiDiscovery.ensure();
      ApiConfig.setRuntimeOverride(ApiConfig.platformDefault);
    }
    final uri = Uri.parse('$baseUrl/recommendations').replace(
      queryParameters: {
        'gender': gender,
        'face_shape': faceShape,
      },
    );

    http.Response response;
    try {
      response = await _client.get(uri).timeout(ApiConfig.requestTimeout);
    } on TimeoutException {
      throw const ApiException('Style recommendations timed out. Please try again.');
    } on Object catch (error) {
      if (isUnreachable(error)) {
        throw ApiException(
          'Could not reach $baseUrl for recommendations. Check that the server is running.',
        );
      }
      rethrow;
    }

    final decoded = jsonDecode(response.body);
    final body = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    if (response.statusCode != 200) {
      final detail = body['detail'];
      throw ApiException(
        detail is String && detail.isNotEmpty
            ? detail
            : 'Could not load style recommendations.',
      );
    }
    try {
      return RecommendationResult.fromJson(body);
    } on Object {
      throw const ApiException('The server returned unexpected recommendations.');
    }
  }

  Future<Map<String, String>> styleImages() async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/style-images')).timeout(ApiConfig.requestTimeout);
      if (response.statusCode != 200) {
        return {};
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return {};
      }
      return decoded.map((key, value) => MapEntry(key.toString(), value.toString()));
    } catch (_) {
      return {};
    }
  }
}
