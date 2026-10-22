import 'dart:io';

import 'package:dr_salon_app/services/api_exception.dart';
import 'package:dr_salon_app/services/face_analysis_service.dart';
import 'package:dr_salon_app/services/recommendation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

const _faceImage = r'D:\FYP_Stuff\face_dataset\training_set\Heart\heart (1).jpg';

void main() {
  final client = http.Client();
  const host = 'http://127.0.0.1:8000';
  final analysis = FaceAnalysisService(client: client, baseUrl: host);
  final recommendations = RecommendationService(client: client, baseUrl: host);

  tearDownAll(client.close);

  test('male image returns a detected shape plus hairstyles and beards', () async {
    final result = await analysis.analyze(File(_faceImage));
    expect(result.predictedFaceShape, isNotEmpty);
    expect(result.probabilities.keys, containsAll(['Heart', 'Oblong', 'Oval', 'Round', 'Square']));
    final styles = await recommendations.fetch(
      gender: 'male',
      faceShape: result.predictedFaceShape,
    );
    expect(styles.faceShape, result.predictedFaceShape);
    expect(styles.hairstyles, isNotEmpty);
    expect(styles.beards, isNotEmpty);
  });

  test('female image returns hairstyles and no beards', () async {
    final result = await analysis.analyze(File(_faceImage));
    final styles = await recommendations.fetch(
      gender: 'female',
      faceShape: result.predictedFaceShape,
    );
    expect(styles.hairstyles, isNotEmpty);
    expect(styles.beards, isEmpty);
  });

  test('no-face image returns a user-facing error', () async {
    final blank = File('${Directory.systemTemp.path}\\dr_salon_blank.jpg');
    blank.writeAsBytesSync(_tinyJpeg);
    expect(
      () => analysis.analyze(blank),
      throwsA(isA<ApiException>().having((error) => error.message, 'message', contains('No face'))),
    );
  });

  test('unreachable server returns a user-facing error', () async {
    final offline = FaceAnalysisService(client: _FailingClient());
    expect(
      () => offline.analyze(File(_faceImage)),
      throwsA(isA<ApiException>().having((error) => error.message, 'message', contains('Could not reach'))),
    );
  });
}

class _FailingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw const SocketException('Connection refused');
  }
}

final _tinyJpeg = <int>[
  0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x00, 0x00, 0x01,
  0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43, 0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08,
  0x07, 0x07, 0x07, 0x09, 0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
  0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20, 0x24, 0x2E, 0x27, 0x20,
  0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29, 0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27,
  0x39, 0x3D, 0x38, 0x32, 0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
  0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x09, 0xFF, 0xC4, 0x00, 0x14,
  0x10, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F, 0x00, 0x7F, 0xFF, 0xD9,
];
