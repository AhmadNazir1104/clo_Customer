import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:khayyat/model/review_model.dart';
import 'package:khayyat/model/shop_model.dart';

// ── DiscoverShop — shop + optional distance ───────────────────────────────────
class DiscoverShop {
  final ShopModel shop;
  final double? distanceKm;

  const DiscoverShop({required this.shop, this.distanceKm});
}

// ── Haversine formula — distance between two GPS points in km ─────────────────
double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  return R * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _rad(double deg) => deg * pi / 180;

// ── All publicly listed shops stream ─────────────────────────────────────────
final _publicShopsStreamProvider = StreamProvider<List<ShopModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('shops')
      .where('isPubliclyListed', isEqualTo: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => ShopModel.fromMap(d.id, d.data()))
          .toList());
});

// ── Customer GPS location ─────────────────────────────────────────────────────
final customerLocationProvider = FutureProvider<Position?>((ref) async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
  } catch (_) {
    return null;
  }
});

// ── Nearby tailors — shops sorted by distance from customer ───────────────────
final nearbyTailorsProvider = Provider<AsyncValue<List<DiscoverShop>>>((ref) {
  final shopsAsync   = ref.watch(_publicShopsStreamProvider);
  final locationAsync = ref.watch(customerLocationProvider);

  return shopsAsync.when(
    loading: () => const AsyncValue.loading(),
    error:   (e, st) => AsyncValue.error(e, st),
    data:    (shops) => locationAsync.when(
      loading: () => const AsyncValue.loading(),
      error:   (error, stack) => AsyncValue.data(
        shops.map((s) => DiscoverShop(shop: s)).toList(),
      ),
      data: (position) {
        final list = shops.map((s) {
          double? dist;
          if (position != null && s.latitude != null && s.longitude != null) {
            dist = haversineKm(
              position.latitude, position.longitude,
              s.latitude!, s.longitude!,
            );
          }
          return DiscoverShop(shop: s, distanceKm: dist);
        }).toList()
          ..sort((a, b) {
            if (a.distanceKm == null && b.distanceKm == null) return 0;
            if (a.distanceKm == null) return 1;
            if (b.distanceKm == null) return -1;
            return a.distanceKm!.compareTo(b.distanceKm!);
          });
        return AsyncValue.data(list);
      },
    ),
  );
});

// ── Top tailors — shops sorted by rating then totalOrders ────────────────────
final topTailorsProvider = Provider<AsyncValue<List<DiscoverShop>>>((ref) {
  return ref.watch(_publicShopsStreamProvider).whenData((shops) {
    final sorted = [...shops]
      ..sort((a, b) {
        final r = b.rating.compareTo(a.rating);
        return r != 0 ? r : b.totalOrders.compareTo(a.totalOrders);
      });
    return sorted.map((s) => DiscoverShop(shop: s)).toList();
  });
});

// ── Reviews for a specific shop ───────────────────────────────────────────────
final shopReviewsProvider =
    StreamProvider.family<List<ReviewModel>, String>((ref, shopId) {
  return FirebaseFirestore.instance
      .collection('shops')
      .doc(shopId)
      .collection('reviews')
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => ReviewModel.fromMap(d.id, d.data())).toList());
});
