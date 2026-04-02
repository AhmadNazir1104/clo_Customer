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

  const ShopModel({
    required this.shopId,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.phone,
    this.logoUrl,
    this.shopCode,
    required this.createdAt,
  });

  factory ShopModel.fromMap(String id, Map<String, dynamic> map) {
    return ShopModel(
      shopId: id,
      ownerId: map['ownerId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      logoUrl: map['logoUrl'] as String?,
      shopCode: map['shopCode'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
