import 'dart:async';
import 'dart:io';

import 'package:dr_salon_app/models/face_analysis_result.dart';
import 'package:dr_salon_app/models/recommendation.dart';
import 'package:dr_salon_app/screens/ai_style_screen.dart';
import 'package:dr_salon_app/services/api_exception.dart';
import 'package:dr_salon_app/services/face_analysis_service.dart';
import 'package:dr_salon_app/services/recommendation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  testWidgets('loading state is shown while analysis is in progress', (tester) async {
    final held = _HeldAnalysis();
    final image = File('${Directory.systemTemp.path}\\dr_salon_widget.jpg')..writeAsBytesSync(const [0x00]);
    await tester.pumpWidget(
      MaterialApp(
        home: AiStyleScreen(
          analysisService: held,
          recommendationService: _UnusedRecommendations(),
          initialImage: image,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Server'), findsNothing);
    final button = tester.widget<ElevatedButton>(find.byKey(const Key('analyze-button')));
    expect(button.onPressed, isNotNull);
    button.onPressed!();
    await tester.pump();
    expect(find.text('Analyzing Your Face'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    held.completeError(const ApiException('stopped'));
    await tester.pump();
    expect(find.text('stopped'), findsOneWidget);
  });
}

class _NoopClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError();
  }
}

class _HeldAnalysis extends FaceAnalysisService {
  _HeldAnalysis() : super(client: _NoopClient());

  final _gate = Completer<FaceAnalysisResult>();

  void completeError(Object error) {
    if (!_gate.isCompleted) {
      _gate.completeError(error);
    }
  }

  @override
  Future<FaceAnalysisResult> analyze(File image) => _gate.future;
}

class _UnusedRecommendations extends RecommendationService {
  _UnusedRecommendations() : super(client: _NoopClient());

  @override
  Future<RecommendationResult> fetch({
    required String gender,
    required String faceShape,
  }) {
    throw UnimplementedError();
  }
}
