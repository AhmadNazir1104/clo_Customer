import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khayyat/utils/phone_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'auth_state.dart';
import 'auth_view_model.dart';
import 'linked_shops_provider.dart';

// ── Firebase instance providers ─────────────────────────────────────────────
final firebaseAuthProvider     = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);
final firestoreProvider        = Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);
final firebaseStorageProvider  = Provider<FirebaseStorage>((_) => FirebaseStorage.instance);

// ── Auth notifier ────────────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    auth:     ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    storage:  ref.watch(firebaseStorageProvider),
    onLinkShops: (phone) => ref.read(linkedShopsProvider.notifier).loadAndLink(
      phone,
      ref.read(firestoreProvider),
    ),
  );
});

// ── Current user's phone in LOCAL format (03001234567) ──────────────────────
// Firebase Auth returns E.164 (+923001234567) but Firestore docs use local format.
final currentPhoneProvider = Provider<String>((_) {
  final e164 = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
  return normalizeToLocal(e164);
});
