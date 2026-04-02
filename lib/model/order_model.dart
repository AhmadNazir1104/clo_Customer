import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  inProgress,
  ready,
  delivered,
  cancelled;

  static OrderStatus fromString(String? value) => switch (value) {
        'in_progress' => inProgress,
        'ready'       => ready,
        'delivered'   => delivered,
        'cancelled'   => cancelled,
        _             => pending,
      };
}

enum FabricSource {
  customer,
  shop;

  static FabricSource fromString(String? value) =>
      value == 'shop' ? shop : customer;
}

enum PaymentMethod {
  cash,
  easypaisa,
  jazzcash;

  static PaymentMethod fromString(String? value) => switch (value) {
        'easypaisa' => easypaisa,
        'jazzcash'  => jazzcash,
        _           => cash,
      };
}

class PaymentEntry {
  final String id;
  final double amount;
  final PaymentMethod method;
  final String? note;
  final DateTime paidAt;

  const PaymentEntry({
    required this.id,
    required this.amount,
    required this.method,
    this.note,
    required this.paidAt,
  });

  factory PaymentEntry.fromMap(Map<String, dynamic> map) {
    return PaymentEntry(
      id: map['id'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      method: PaymentMethod.fromString(map['method'] as String?),
      note: map['note'] as String?,
      paidAt: (map['paidAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class OrderItemModel {
  final String name;
  final int quantity;
  final double price;

  const OrderItemModel({
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      name: map['name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class OrderModel {
  final String orderId;
  final String orderNumber;
  final String shopId;
  final String customerPhone;
  final String customerName;
  final String? assignedStaffId;
  final String? assignedStaffName;
  final List<OrderItemModel> items;
  final Map<String, dynamic> measurements;
  final OrderStatus status;
  final DateTime dueDate;
  final FabricSource fabricSource;
  final List<String> photoUrls;
  final String? notes;
  final double totalAmount;
  final double advancePaid;
  final PaymentMethod paymentMethod;
  final List<PaymentEntry> additionalPayments;
  final DateTime createdAt;

  const OrderModel({
    required this.orderId,
    required this.orderNumber,
    required this.shopId,
    required this.customerPhone,
    required this.customerName,
    this.assignedStaffId,
    this.assignedStaffName,
    required this.items,
    required this.measurements,
    required this.status,
    required this.dueDate,
    required this.fabricSource,
    required this.photoUrls,
    this.notes,
    required this.totalAmount,
    required this.advancePaid,
    required this.paymentMethod,
    required this.additionalPayments,
    required this.createdAt,
  });

  double get totalPaid =>
      advancePaid + additionalPayments.fold(0.0, (a, p) => a + p.amount);
  double get remainingDue => (totalAmount - totalPaid).clamp(0.0, double.infinity);
  bool get isFullyPaid => remainingDue == 0;
  bool get isOverdue =>
      remainingDue > 0 && status == OrderStatus.delivered;

  factory OrderModel.fromMap(String id, String shopId, Map<String, dynamic> map) {
    final rawItems = map['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(OrderItemModel.fromMap)
            .toList()
        : <OrderItemModel>[];

    final rawPayments = map['additionalPayments'];
    final additionalPayments = rawPayments is List
        ? rawPayments
            .whereType<Map<String, dynamic>>()
            .map(PaymentEntry.fromMap)
            .toList()
        : <PaymentEntry>[];

    final rawPhotos = map['photoUrls'];
    final photoUrls = rawPhotos is List
        ? rawPhotos.map((e) => e.toString()).toList()
        : <String>[];

    return OrderModel(
      orderId: id,
      orderNumber: map['orderNumber'] as String? ?? '',
      shopId: shopId,
      customerPhone: map['customerPhone'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      assignedStaffId: map['assignedStaffId'] as String?,
      assignedStaffName: map['assignedStaffName'] as String?,
      items: items,
      measurements: map['measurements'] as Map<String, dynamic>? ?? {},
      status: OrderStatus.fromString(map['status'] as String?),
      dueDate: (map['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fabricSource: FabricSource.fromString(map['fabricSource'] as String?),
      photoUrls: photoUrls,
      notes: map['notes'] as String?,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      advancePaid: (map['advancePaid'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.fromString(map['paymentMethod'] as String?),
      additionalPayments: additionalPayments,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
