import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khayyat/model/customer_model.dart';
import 'package:khayyat/model/measurement_entry_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Customer document for a shop (used by owner-added measurements section).
final customerDocProvider =
    StreamProvider.family<CustomerModel?, ({String shopId, String phone})>(
  (ref, args) {
    return FirebaseFirestore.instance
        .doc('shops/${args.shopId}/customers/${args.phone}')
        .snapshots()
        .map((snap) => snap.exists && snap.data() != null
            ? CustomerModel.fromMap(snap.id, args.shopId, snap.data()!)
            : null);
  },
);

/// Customer's PRIVATE measurements — stored under users/{uid}/measurements.
/// These are owned by the customer and invisible to shops unless shared.
final myMeasurementsProvider =
    StreamProvider<List<MeasurementEntry>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('users/$uid/measurements')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => MeasurementEntry.fromMap(d.id, d.data()))
          .toList());
});

/// Measurements added by the OWNER for this customer in a specific shop.
/// Filters out any customer-added shadow copies so they don't show twice.
final shopOwnerMeasurementsProvider =
    StreamProvider.family<List<MeasurementEntry>, ({String shopId, String phone})>(
  (ref, args) {
    return FirebaseFirestore.instance
        .collection('shops/${args.shopId}/customers/${args.phone}/measurements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MeasurementEntry.fromMap(d.id, d.data()))
            .where((e) => !e.isAddedByCustomer) // hide customer shadow copies
            .toList());
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Mutations
// ─────────────────────────────────────────────────────────────────────────────

/// Saves a new measurement entry to the customer's PRIVATE storage.
/// Does NOT write to any shop path. Returns the new entry id.
Future<String> saveMyMeasurement({
  required String name,
  String? note,
  required Map<String, double> numericFields,
  required Map<String, String> textFields,
  required Map<String, String> customFields,
}) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final ref = await FirebaseFirestore.instance
      .collection('users/$uid/measurements')
      .add({
    'name': name,
    if (note != null && note.isNotEmpty) 'note': note,
    'numericFields': numericFields,
    'textFields': textFields,
    'customFields': customFields,
    'addedBy': 'customer',
    'sharedWith': [],
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
  return ref.id;
}

/// Shares a private measurement entry with a shop.
/// Writes a shadow copy to shops/{shopId}/customers/{phone}/measurements/{entryId}
/// and adds shopId to the private entry's sharedWith array.
Future<void> shareWithShop({
  required MeasurementEntry entry,
  required String shopId,
  required String phone,
}) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final db = FirebaseFirestore.instance;
  final batch = db.batch();

  // Shadow copy in the shop path (owner app reads from here)
  final shopRef = db.doc(
      'shops/$shopId/customers/$phone/measurements/${entry.id}');
  batch.set(shopRef, {
    'name': entry.name,
    if (entry.note != null && entry.note!.isNotEmpty) 'note': entry.note,
    'numericFields': entry.numericFields,
    'textFields': entry.textFields,
    'customFields': entry.customFields,
    'addedBy': 'customer',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  // Mark as shared in private storage
  final privateRef = db.doc('users/$uid/measurements/${entry.id}');
  batch.update(privateRef, {
    'sharedWith': FieldValue.arrayUnion([shopId]),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  await batch.commit();
  debugPrint('[Measurements] Shared "${entry.name}" with shop $shopId');
}

/// Revokes a shop's access to a shared measurement.
/// Deletes the shadow copy from the shop path and removes shopId from sharedWith.
Future<void> revokeFromShop({
  required String entryId,
  required String shopId,
  required String phone,
}) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final db = FirebaseFirestore.instance;
  final batch = db.batch();

  // Delete shadow copy from shop path
  final shopRef = db.doc(
      'shops/$shopId/customers/$phone/measurements/$entryId');
  batch.delete(shopRef);

  // Remove shopId from sharedWith
  final privateRef = db.doc('users/$uid/measurements/$entryId');
  batch.update(privateRef, {
    'sharedWith': FieldValue.arrayRemove([shopId]),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  await batch.commit();
  debugPrint('[Measurements] Revoked access for shop $shopId on entry $entryId');
}

/// Deletes a private measurement entry and all its shop shadow copies.
Future<void> deleteMyMeasurement({
  required MeasurementEntry entry,
  required String phone,
}) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final db = FirebaseFirestore.instance;
  final batch = db.batch();

  // Delete all shadow copies first
  for (final shopId in entry.sharedWith) {
    final shopRef = db.doc(
        'shops/$shopId/customers/$phone/measurements/${entry.id}');
    batch.delete(shopRef);
  }

  // Delete private entry
  final privateRef = db.doc('users/$uid/measurements/${entry.id}');
  batch.delete(privateRef);

  await batch.commit();
}
