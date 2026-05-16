/// LIBASS Data Models — mirrors the Flask backend models.
library models;

class WardrobeItem {
  final String id;
  final String userId;
  final String imagePath;
  final String name;
  final String category;
  final String specificType;
  final String color;
  final String pattern;
  final String fit;
  final String occasion;
  final String season;

  WardrobeItem({
    required this.id,
    required this.userId,
    required this.imagePath,
    required this.name,
    this.category = 'top',
    this.specificType = 'Unknown',
    this.color = 'unknown',
    this.pattern = 'solid',
    this.fit = 'regular',
    this.occasion = 'casual',
    this.season = 'all',
  });

  factory WardrobeItem.fromJson(Map<String, dynamic> json) => WardrobeItem(
        id: (json['id'] ?? '').toString(),
        userId: (json['user_id'] ?? '').toString(),
        imagePath: json['image_path'] ?? '',
        name: json['name'] ?? 'Unknown',
        category: json['category'] ?? 'top',
        specificType: json['specific_type'] ?? 'Unknown',
        color: json['color'] ?? 'unknown',
        pattern: json['pattern'] ?? 'solid',
        fit: json['fit'] ?? 'regular',
        occasion: json['occasion'] ?? 'casual',
        season: json['season'] ?? 'all',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'image_path': imagePath,
        'name': name,
        'category': category,
        'specific_type': specificType,
        'color': color,
        'pattern': pattern,
        'fit': fit,
        'occasion': occasion,
        'season': season,
      };
}

class OutfitSuggestion {
  final String outfitId;
  final List<OutfitItem> items;
  final String occasion;
  final String reasoning;
  final double score;
  bool isLiked;

  OutfitSuggestion({
    required this.outfitId,
    required this.items,
    required this.occasion,
    required this.reasoning,
    required this.score,
    this.isLiked = false,
  });

  factory OutfitSuggestion.fromJson(Map<String, dynamic> json) =>
      OutfitSuggestion(
        outfitId: (json['outfit_id'] ?? '').toString(),
        items: (json['items'] as List?)
                ?.map((i) => OutfitItem.fromJson(i as Map<String, dynamic>))
                .toList() ??
            [],
        occasion: json['occasion'] ?? 'casual',
        reasoning: json['reasoning'] ?? '',
        score: (json['body_shape_score'] ?? 5.0).toDouble(),
      );
}

class OutfitItem {
  final String id;
  final String imagePath;
  final String name;

  OutfitItem({
    required this.id,
    required this.imagePath,
    required this.name,
  });

  factory OutfitItem.fromJson(Map<String, dynamic> json) => OutfitItem(
        id: (json['id'] ?? '').toString(),
        imagePath: json['image_path'] ?? '',
        name: json['name'] ?? '',
      );
}

class WeatherData {
  final int temperatureF;
  final int temperatureC;
  final int? highC;
  final int? lowC;
  final String condition;
  String? city;

  WeatherData({
    required this.temperatureF,
    required this.temperatureC,
    this.highC,
    this.lowC,
    required this.condition,
    this.city,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) => WeatherData(
        temperatureF: json['temperature_f'] ?? 72,
        temperatureC: json['temperature_c'] ?? 22,
        highC: json['high_c'],
        lowC: json['low_c'],
        condition: json['condition'] ?? 'Clear',
        city: json['city'],
      );
}

class OutfitRating {
  final String id;
  final String imagePath;
  final double score;
  final String feedback;
  final List<RatingImprovement> improvements;

  OutfitRating({
    required this.id,
    required this.imagePath,
    required this.score,
    required this.feedback,
    required this.improvements,
  });

  factory OutfitRating.fromJson(Map<String, dynamic> json) => OutfitRating(
        id: (json['id'] ?? '').toString(),
        imagePath: json['image_path'] ?? '',
        score: (json['score'] ?? 7.0).toDouble(),
        feedback: json['feedback'] ?? '',
        improvements: (json['improvements'] as List?)
                ?.map((i) => RatingImprovement.fromJson(i as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class RatingImprovement {
  final String title;
  final String detail;

  RatingImprovement({required this.title, required this.detail});

  factory RatingImprovement.fromJson(Map<String, dynamic> json) =>
      RatingImprovement(
        title: json['title'] ?? '',
        detail: json['detail'] ?? '',
      );
}
