import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libaas/features/auth/view_model/auth_provider.dart';
import 'package:libaas/features/auth/view_model/linked_shops_provider.dart';
import 'package:libaas/model/order_model.dart';

/// Orders for a customer in one shop, realtime.
final ordersProvider =
    StreamProvider.family<List<OrderModel>, ({String shopId, String phone})>(
  (ref, args) {
    return FirebaseFirestore.instance
        .collection('shops/${args.shopId}/orders')
        .where('customerPhone', isEqualTo: args.phone)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => OrderModel.fromMap(d.id, args.shopId, d.data()))
            .toList());
  },
);

/// Combined orders across ALL linked shops.
final allOrdersProvider = Provider<AsyncValue<List<OrderModel>>>((ref) {
  final linked = ref.watch(linkedShopsProvider);
  final phone  = ref.watch(currentPhoneProvider);

  if (linked.isLoading) return const AsyncValue.loading();
  if (phone.isEmpty)    return const AsyncValue.data([]);

  final allOrders = <OrderModel>[];
  var hasLoading  = false;
  Object? error;

  for (final shopId in linked.shopIds) {
    final async = ref.watch(ordersProvider((shopId: shopId, phone: phone)));
    async.when(
      data:    (orders) => allOrders.addAll(orders),
      loading: ()       => hasLoading = true,
      error:   (e, _)   => error = e,
    );
  }

  if (error != null)  return AsyncValue.error(error!, StackTrace.current);
  if (hasLoading)     return const AsyncValue.loading();

  allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return AsyncValue.data(allOrders);
});
