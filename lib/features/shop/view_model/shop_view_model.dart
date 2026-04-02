import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clocustomer/model/shop_model.dart';

final shopProvider = StreamProvider.family<ShopModel?, String>((ref, shopId) {
  return FirebaseFirestore.instance
      .doc('shops/$shopId')
      .snapshots()
      .map((snap) => snap.exists && snap.data() != null
          ? ShopModel.fromMap(snap.id, snap.data()!)
          : null);
});
