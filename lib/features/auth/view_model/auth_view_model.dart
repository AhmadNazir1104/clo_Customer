import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khayyat/utils/phone_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'auth_state.dart';

typedef LinkShopsCallback = Future<void> Function(String phone);

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final LinkShopsCallback _onLinkShops;

  String? _verificationId;

  AuthNotifier({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required LinkShopsCallback onLinkShops,
  })  : _auth = auth,
        _firestore = firestore,
        _storage = storage,
        _onLinkShops = onLinkShops,
        super(const AuthInitial());

  // ── STEP 1: Send OTP ────────────────────────────────────────────────────
  Future<void> sendOtp(String phoneNumber) async {
    state = const AuthLoading();
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential, phoneNumber);
        },
        verificationFailed: (FirebaseAuthException e) {
          state = AuthError(message: _mapError(e.code));
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          state = OtpSent(
            phoneNumber: phoneNumber,
            verificationId: verificationId,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (_) {
      state = const AuthError(message: 'Something went wrong. Please try again.');
    }
  }

  // ── STEP 2: Verify OTP ──────────────────────────────────────────────────
  Future<void> verifyOtp({
    required String otp,
    required String phoneNumber,
  }) async {
    if (_verificationId == null) {
      state = const AuthError(message: 'Session expired. Please resend OTP.');
      return;
    }
    state = const AuthLoading();
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await _signInWithCredential(credential, phoneNumber);
    } on FirebaseAuthException catch (e) {
      state = AuthError(message: _mapError(e.code));
    } catch (_) {
      state = const AuthError(message: 'Invalid OTP. Please try again.');
    }
  }

  // ── Internal: sign in & route ───────────────────────────────────────────
  Future<void> _signInWithCredential(
    PhoneAuthCredential credential,
    String phoneNumber,
  ) async {
    final userCredential = await _auth.signInWithCredential(credential);
    final uid       = userCredential.user!.uid;
    final rawPhone  = userCredential.user!.phoneNumber ?? phoneNumber;
    // Normalise to local format (03001234567) — matches Firestore doc IDs
    final localPhone = normalizeToLocal(rawPhone);

    final doc     = await _firestore.collection('users').doc(uid).get();
    final hasName = doc.data()?['name'] != null;

    if (hasName) {
      unawaited(_onLinkShops(localPhone));
      state = AuthExistingUser(uid: uid);
    } else {
      state = AuthNewUser(uid: uid, phoneNumber: localPhone);
    }
  }

  // ── STEP 3: Save profile (new user) ─────────────────────────────────────
  Future<void> saveUserProfile({
    required String name,
    required String city,
    required String phone,
    File? profilePhoto,
  }) async {
    state = const AuthLoading();
    try {
      final uid = _auth.currentUser!.uid;
      String? photoUrl;

      if (profilePhoto != null) {
        final ref = _storage.ref().child('profile_photos/$uid.jpg');
        await ref.putFile(profilePhoto);
        photoUrl = await ref.getDownloadURL();
      }

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name.trim(),
        'phone': phone,
        'city': city.trim(),
        'photoUrl': photoUrl,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });

      unawaited(_onLinkShops(phone));
      state = const AccountSetupSuccess();
    } catch (_) {
      state = const AuthError(
          message: 'Failed to save profile. Please try again.');
    }
  }

  Future<void> resendOtp(String phoneNumber) async {
    _verificationId = null;
    await sendOtp(phoneNumber);
  }

  void reset() => state = const AuthInitial();

  Future<void> logout() async {
    state = const AuthLoading();
    try {
      await _auth.signOut();
      state = const AuthInitial();
    } catch (_) {
      state = const AuthError(message: 'Failed to log out. Please try again.');
    }
  }

  String _mapError(String code) => switch (code) {
        'invalid-phone-number'      => 'Invalid phone number format.',
        'too-many-requests'         => 'Too many attempts. Please try again later.',
        'invalid-verification-code' => 'Wrong OTP. Please check and try again.',
        'session-expired'           => 'OTP expired. Please request a new one.',
        'network-request-failed'    => 'No internet connection.',
        _                           => 'Authentication failed. Please try again.',
      };
}
