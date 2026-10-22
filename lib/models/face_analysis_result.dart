class FaceAnalysisResult {
  const FaceAnalysisResult({
    required this.predictedFaceShape,
    required this.modelProbability,
    required this.probabilities,
  });

  final String predictedFaceShape;
  final double modelProbability;
  final Map<String, double> probabilities;

  factory FaceAnalysisResult.fromJson(Map<String, dynamic> json) {
    final raw = json['probabilities'];
    if (raw is! Map) {
      throw const FormatException('Missing probabilities.');
    }
    final probabilities = <String, double>{};
    raw.forEach((key, value) {
      probabilities[key.toString()] = (value as num).toDouble();
    });
    return FaceAnalysisResult(
      predictedFaceShape: json['predicted_face_shape'] as String,
      modelProbability: (json['model_probability'] as num).toDouble(),
      probabilities: probabilities,
    );
  }
}
