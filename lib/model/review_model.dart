import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String customerId;
  final String customerName;
  final int rating;
  final String? comment;
  final String? orderId;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.rating,
    this.comment,
    this.orderId,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(String id, Map<String, dynamic> map) {
    return ReviewModel(
      id: id,
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? 'Customer',
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: map['comment'] as String?,
      orderId: map['orderId'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
