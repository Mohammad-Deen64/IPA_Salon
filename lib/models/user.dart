import '../config/api_config.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.salonId,
    this.avatar = '',
  });

  final String id;
  final String email;
  final String name;
  final String phone;
  final String role;
  final String? salonId;
  final String avatar;

  bool get isOwner => role == 'owner';

  String? get avatarUrl {
    if (avatar.isEmpty) {
      return null;
    }
    return avatar.startsWith('/') ? '${ApiConfig.baseUrl}$avatar' : avatar;
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String,
      salonId: json['salon_id'] as String?,
      avatar: json['avatar'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'salon_id': salonId,
      'avatar': avatar,
    };
  }
}
