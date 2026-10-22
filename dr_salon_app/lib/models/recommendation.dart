class StyleRecommendation {
  const StyleRecommendation({
    required this.id,
    required this.styleName,
    required this.category,
    required this.description,
    required this.imageUrl,
  });

  final String id;
  final String styleName;
  final String category;
  final String description;
  final String? imageUrl;

  factory StyleRecommendation.fromJson(Map<String, dynamic> json) {
    return StyleRecommendation(
      id: json['id'] as String,
      styleName: json['style_name'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String?,
    );
  }
}

class RecommendationResult {
  const RecommendationResult({
    required this.gender,
    required this.faceShape,
    required this.hairstyles,
    required this.beards,
  });

  final String gender;
  final String faceShape;
  final List<StyleRecommendation> hairstyles;
  final List<StyleRecommendation> beards;

  factory RecommendationResult.fromJson(Map<String, dynamic> json) {
    List<StyleRecommendation> readList(String key) {
      final raw = json[key];
      if (raw is! List) {
        return const [];
      }
      return raw
          .map((item) => StyleRecommendation.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return RecommendationResult(
      gender: json['gender'] as String,
      faceShape: json['face_shape'] as String,
      hairstyles: readList('hairstyles'),
      beards: readList('beards'),
    );
  }
}
