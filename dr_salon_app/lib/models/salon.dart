import '../config/api_config.dart';

class SalonService {
  const SalonService({
    required this.id,
    required this.name,
    required this.malePrice,
    required this.femalePrice,
    required this.duration,
    required this.category,
  });

  final String id;
  final String name;
  final double malePrice;
  final double femalePrice;
  final int duration;
  final String category;

  double priceFor(String gender) {
    final selected = gender == 'female' ? femalePrice : malePrice;
    if (selected > 0) {
      return selected;
    }
    return malePrice > 0 ? malePrice : femalePrice;
  }

  factory SalonService.fromJson(Map<String, dynamic> json) {
    return SalonService(
      id: json['id'] as String,
      name: json['name'] as String,
      malePrice: (json['male_price'] as num).toDouble(),
      femalePrice: (json['female_price'] as num).toDouble(),
      duration: json['duration'] as int,
      category: json['category'] as String,
    );
  }
}

class Salon {
  const Salon({
    required this.id,
    required this.name,
    required this.rating,
    required this.distance,
    required this.startingPrice,
    required this.image,
    required this.location,
    required this.description,
    required this.phone,
    required this.email,
    this.opensAt = '9 AM',
    required this.openUntil,
    required this.tags,
    required this.availableSlots,
    required this.services,
    this.ownerName,
    this.ownerImage,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.isDemo = false,
  });

  final String id;
  final String name;
  final double rating;
  final String distance;
  final double startingPrice;
  final String image;
  final String location;
  final String description;
  final String phone;
  final String email;
  final String opensAt;
  final String openUntil;
  final List<String> tags;
  final List<String> availableSlots;
  final List<SalonService> services;
  final String? ownerName;
  final String? ownerImage;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final bool isDemo;

  String get imageUrl => image.startsWith('/') ? '${ApiConfig.baseUrl}$image' : image;

  String? get ownerImageUrl {
    final path = ownerImage;
    if (path == null || path.isEmpty) {
      return null;
    }
    return path.startsWith('/') ? '${ApiConfig.baseUrl}$path' : path;
  }

  factory Salon.fromJson(Map<String, dynamic> json) {
    return Salon(
      id: json['id'] as String,
      name: json['name'] as String,
      rating: (json['rating'] as num).toDouble(),
      distance: json['distance'] as String,
      startingPrice: (json['starting_price'] as num).toDouble(),
      image: json['image'] as String,
      location: json['location'] as String,
      description: json['description'] as String,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      opensAt: json['opens_at'] as String? ?? '9 AM',
      openUntil: json['open_until'] as String? ?? '9 PM',
      tags: ((json['tags'] as List?) ?? const []).map((item) => item.toString()).toList(),
      availableSlots: ((json['available_slots'] as List?) ?? const []).map((item) => item.toString()).toList(),
      services: ((json['services'] as List?) ?? const [])
          .map((item) => SalonService.fromJson(item as Map<String, dynamic>))
          .toList(),
      ownerName: json['owner_name'] as String?,
      ownerImage: json['owner_image'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      isDemo: json['is_demo'] as bool? ?? false,
    );
  }
}

class DayStat {
  const DayStat({required this.date, required this.label, required this.bookings, required this.revenue});

  final String date;
  final String label;
  final int bookings;
  final double revenue;

  factory DayStat.fromJson(Map<String, dynamic> json) {
    return DayStat(
      date: json['date'] as String? ?? '',
      label: json['label'] as String? ?? '',
      bookings: (json['bookings'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
    );
  }
}

class OwnerStats {
  const OwnerStats({
    required this.todayBookings,
    required this.pending,
    required this.completed,
    required this.revenue,
    required this.weekTotal,
    required this.rating,
    required this.reviewCount,
    this.weekRevenue = 0,
    this.daily = const [],
  });

  final int todayBookings;
  final int pending;
  final int completed;
  final double revenue;
  final int weekTotal;
  final double rating;
  final int reviewCount;
  final double weekRevenue;
  final List<DayStat> daily;

  factory OwnerStats.fromJson(Map<String, dynamic> json) {
    return OwnerStats(
      todayBookings: json['today_bookings'] as int,
      pending: json['pending'] as int,
      completed: json['completed'] as int,
      revenue: (json['revenue'] as num).toDouble(),
      weekTotal: json['week_total'] as int,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['review_count'] as int,
      weekRevenue: (json['week_revenue'] as num?)?.toDouble() ?? 0,
      daily: ((json['daily'] as List?) ?? const []).map((item) => DayStat.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}
