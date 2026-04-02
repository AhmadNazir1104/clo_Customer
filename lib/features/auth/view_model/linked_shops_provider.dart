import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

class LinkedShopsState {
  final List<String> shopIds;
  final bool isLoading;
  final String? error; // exposed so the UI can show what went wrong

  const LinkedShopsState({
    this.shopIds = const [],
    this.isLoading = false,
    this.error,
  });

  LinkedShopsState copyWith({
    List<String>? shopIds,
    bool? isLoading,
    String? error,
  }) {
    return LinkedShopsState(
      shopIds: shopIds ?? this.shopIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LinkedShopsNotifier extends StateNotifier<LinkedShopsState> {
  LinkedShopsNotifier() : super(const LinkedShopsState());

  /// Finds all shops this customer belongs to via a collectionGroup query,
  /// updates verificationStatus to 'app_linked', and stores shopIds locally.
  ///
  /// Phone must be in LOCAL format (03001234567) — not E.164.
  ///
  /// Note: requires a Firestore single-field collection-group index on
  /// customers.phone (scope: Collection group). Firebase will print a URL
  /// in the console/logs to create it on first failed run.
  Future<void> loadAndLink(String phone, FirebaseFirestore firestore) async {
    if (phone.isEmpty || state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Single-field filter only — avoids composite index requirement.
      // isRemovedFromShop is filtered in-memory below.
      final snap = await firestore
          .collectionGroup('customers')
          .where('phone', isEqualTo: phone)
          .get();

      final shopIds = <String>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        // Skip customers removed from shop
        if (data['isRemovedFromShop'] == true) continue;

        final shopId = doc.reference.parent.parent?.id;
        if (shopId != null && shopId.isNotEmpty) {
          shopIds.add(shopId);
          // Upgrade verificationStatus — fire-and-forget
          doc.reference
              .update({'verificationStatus': 'app_linked'})
              .ignore();
        }
      }

      debugPrint('[LinkedShops] found ${shopIds.length} shop(s) for $phone');
      state = LinkedShopsState(shopIds: shopIds, isLoading: false);
    } catch (e) {
      debugPrint('[LinkedShops] ERROR: $e');
      state = LinkedShopsState(
        shopIds: state.shopIds, // keep any previous results
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clear() => state = const LinkedShopsState();
}

final linkedShopsProvider =
    StateNotifierProvider<LinkedShopsNotifier, LinkedShopsState>(
  (_) => LinkedShopsNotifier(),
);
