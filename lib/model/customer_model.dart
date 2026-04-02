import 'package:cloud_firestore/cloud_firestore.dart';

enum CustomerVerificationStatus {
  pending,
  shopVerified,
  appLinked;

  static CustomerVerificationStatus fromString(String? value) =>
      switch (value) {
        'shop_verified' => shopVerified,
        'app_linked'    => appLinked,
        _               => pending,
      };
}

class MeasurementModel {
  final Map<String, double> shirt;
  final Map<String, double> shalwarKameez;
  final Map<String, double> pant;
  final Map<String, double> suit;
  final Map<String, double> sherwani;
  final Map<String, Map<String, String>> customFields;

  const MeasurementModel({
    required this.shirt,
    required this.shalwarKameez,
    required this.pant,
    required this.suit,
    required this.sherwani,
    required this.customFields,
  });

  factory MeasurementModel.empty() => const MeasurementModel(
        shirt: {},
        shalwarKameez: {},
        pant: {},
        suit: {},
        sherwani: {},
        customFields: {},
      );

  factory MeasurementModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return MeasurementModel.empty();

    Map<String, double> toDoubleMap(dynamic raw) {
      if (raw is! Map) return {};
      return raw.map((k, v) => MapEntry(k.toString(), (v as num?)?.toDouble() ?? 0.0));
    }

    Map<String, Map<String, String>> toCustomFields(dynamic raw) {
      if (raw is! Map) return {};
      return raw.map((typeName, fields) {
        final inner = fields is Map
            ? fields.map((k, v) => MapEntry(k.toString(), v.toString()))
            : <String, String>{};
        return MapEntry(typeName.toString(), inner);
      });
    }

    return MeasurementModel(
      shirt: toDoubleMap(map['shirt']),
      shalwarKameez: toDoubleMap(map['shalwarKameez']),
      pant: toDoubleMap(map['pant']),
      suit: toDoubleMap(map['suit']),
      sherwani: toDoubleMap(map['sherwani']),
      customFields: toCustomFields(map['customFields']),
    );
  }
}

class CustomerModel {
  final String customerId;
  final String shopId;
  final String name;
  final String phone;
  final String? address;
  final String? city;
  final String? notes;
  final String? photoUrl;
  final MeasurementModel measurements;
  final DateTime createdAt;
  final CustomerVerificationStatus verificationStatus;
  final bool isRemovedFromShop;
  // Computed — not in Firestore
  final int totalOrders;
  final double totalDues;

  const CustomerModel({
    required this.customerId,
    required this.shopId,
    required this.name,
    required this.phone,
    this.address,
    this.city,
    this.notes,
    this.photoUrl,
    required this.measurements,
    required this.createdAt,
    required this.verificationStatus,
    required this.isRemovedFromShop,
    this.totalOrders = 0,
    this.totalDues = 0,
  });

  factory CustomerModel.fromMap(String id, String shopId, Map<String, dynamic> map) {
    return CustomerModel(
      customerId: id,
      shopId: shopId,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? id,
      address: map['address'] as String?,
      city: map['city'] as String?,
      notes: map['notes'] as String?,
      photoUrl: map['photoUrl'] as String?,
      measurements: MeasurementModel.fromMap(map['measurements'] as Map<String, dynamic>?),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verificationStatus: CustomerVerificationStatus.fromString(map['verificationStatus'] as String?),
      isRemovedFromShop: map['isRemovedFromShop'] as bool? ?? false,
    );
  }
}
