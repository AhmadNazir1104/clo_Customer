import 'package:cloud_firestore/cloud_firestore.dart';

class ShopModel {
  final String shopId;
  final String ownerId;
  final String name;
  final String address;
  final String phone;
  final String? logoUrl;
  final String? shopCode;
  final DateTime createdAt;

  // ── Public profile fields (for Discover / Nearby / Top Tailors) ──────────
  final double? latitude;
  final double? longitude;
  final String city;
  final String area;
  final bool isPubliclyListed;
  final List<String> specialities;
  final String workingHours;
  final String workingDays;
  final double rating;
  final int totalRatings;
  final int totalOrders;
  final String? coverPhotoUrl;
  final String? description;
  final String? whatsappNumber;
  final bool isVerified;

  const ShopModel({
    required this.shopId,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.phone,
    this.logoUrl,
    this.shopCode,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.city = '',
    this.area = '',
    this.isPubliclyListed = false,
    this.specialities = const [],
    this.workingHours = '',
    this.workingDays = '',
    this.rating = 0.0,
    this.totalRatings = 0,
    this.totalOrders = 0,
    this.coverPhotoUrl,
    this.description,
    this.whatsappNumber,
    this.isVerified = false,
  });

  factory ShopModel.fromMap(String id, Map<String, dynamic> map) {
    final GeoPoint? geo = map['location'] as GeoPoint?;
    return ShopModel(
      shopId: id,
      ownerId: map['ownerId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      logoUrl: map['logoUrl'] as String?,
      shopCode: map['shopCode'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      latitude: geo?.latitude,
      longitude: geo?.longitude,
      city: map['city'] as String? ?? '',
      area: map['area'] as String? ?? '',
      isPubliclyListed: map['isPubliclyListed'] as bool? ?? false,
      specialities: List<String>.from(map['specialities'] ?? []),
      workingHours: map['workingHours'] as String? ?? '',
      workingDays: map['workingDays'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: (map['totalRatings'] as num?)?.toInt() ?? 0,
      totalOrders: (map['totalOrders'] as num?)?.toInt() ?? 0,
      coverPhotoUrl: map['coverPhotoUrl'] as String?,
      description: map['description'] as String?,
      whatsappNumber: map['whatsappNumber'] as String?,
      isVerified: map['isVerified'] as bool? ?? false,
    );
  }
}
