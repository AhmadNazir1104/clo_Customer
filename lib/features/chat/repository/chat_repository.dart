import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:khayyat/model/chat_message_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  static const _uuid = Uuid();

  ChatRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // ── Path helpers ──────────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _chatDoc(
          String shopId, String phone) =>
      _firestore
          .collection('shops')
          .doc(shopId)
          .collection('chats')
          .doc(phone);

  CollectionReference<Map<String, dynamic>> _messagesCol(
          String shopId, String phone) =>
      _chatDoc(shopId, phone).collection('messages');

  // ── Streams ───────────────────────────────────────────────────────────────

  Stream<List<ChatMessage>> messagesStream(String shopId, String phone) {
    return _messagesCol(shopId, phone)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatMessage.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<Map<String, dynamic>?> chatMetaStream(
      String shopId, String phone) {
    return _chatDoc(shopId, phone)
        .snapshots()
        .map((snap) => snap.exists ? snap.data() : null);
  }

  // ── Send text ─────────────────────────────────────────────────────────────

  Future<void> sendText(
      String shopId, String phone, String text) async {
    await _messagesCol(shopId, phone).add({
      'senderRole': 'customer',
      'type': 'text',
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
    await _updateChatMeta(shopId, phone,
        lastMessage: text.trim(), type: 'text');
  }

  // ── Send image (compress → upload → Firestore) ────────────────────────────

  Future<void> sendImage(
      String shopId, String phone, File imageFile) async {
    final id = _uuid.v4();
    final tempDir = await getTemporaryDirectory();
    final outputPath = '${tempDir.path}/$id.jpg';

    final compressed = await FlutterImageCompress.compressAndGetFile(
      imageFile.absolute.path,
      outputPath,
      minWidth: 800,
      minHeight: 800,
      quality: 65,
      format: CompressFormat.jpeg,
    );
    if (compressed == null) throw Exception('Image compression failed');

    final ref =
        _storage.ref('chat_media/$shopId/$phone/images/$id.jpg');
    await ref.putFile(File(compressed.path));
    final url = await ref.getDownloadURL();

    await _messagesCol(shopId, phone).add({
      'senderRole': 'customer',
      'type': 'image',
      'mediaUrl': url,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
    await _updateChatMeta(shopId, phone,
        lastMessage: '📷 Photo', type: 'image');
  }

  // ── Send voice ────────────────────────────────────────────────────────────

  Future<void> sendVoice(
    String shopId,
    String phone,
    String filePath,
    int durationSeconds,
  ) async {
    final id = _uuid.v4();

    final ref =
        _storage.ref('chat_media/$shopId/$phone/voice/$id.m4a');
    await ref.putFile(File(filePath));
    final url = await ref.getDownloadURL();

    await _messagesCol(shopId, phone).add({
      'senderRole': 'customer',
      'type': 'voice',
      'mediaUrl': url,
      'duration': durationSeconds,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
    await _updateChatMeta(shopId, phone,
        lastMessage: '🎤 Voice note', type: 'voice');
  }

  // ── Mark owner messages as read ───────────────────────────────────────────

  Future<void> markOwnerMessagesRead(
      String shopId, String phone) async {
    try {
      final snap = await _messagesCol(shopId, phone)
          .where('senderRole', isEqualTo: 'owner')
          .where('read', isEqualTo: false)
          .get();
      if (snap.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
      await _chatDoc(shopId, phone)
          .set({'customerUnread': 0}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[ChatRepository] markRead error: $e');
    }
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _updateChatMeta(
    String shopId,
    String phone, {
    required String lastMessage,
    required String type,
  }) async {
    await _chatDoc(shopId, phone).set({
      'customerPhone': phone,
      'lastMessage': lastMessage,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageType': type,
      'ownerUnread': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }
}
