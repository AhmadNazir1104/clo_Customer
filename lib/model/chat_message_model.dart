import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, voice }

enum SenderRole { owner, customer }

class ChatMessage {
  final String id;
  final SenderRole senderRole;
  final MessageType type;
  final String? text;
  final String? mediaUrl;
  final int? duration; // voice duration in seconds
  final DateTime createdAt;
  final bool read;

  const ChatMessage({
    required this.id,
    required this.senderRole,
    required this.type,
    this.text,
    this.mediaUrl,
    this.duration,
    required this.createdAt,
    required this.read,
  });

  bool get isOwner => senderRole == SenderRole.owner;

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    final typeStr = map['type'] as String? ?? 'text';
    return ChatMessage(
      id: id,
      senderRole: (map['senderRole'] as String?) == 'owner'
          ? SenderRole.owner
          : SenderRole.customer,
      type: switch (typeStr) {
        'image' => MessageType.image,
        'voice' => MessageType.voice,
        _ => MessageType.text,
      },
      text: map['text'] as String?,
      mediaUrl: map['mediaUrl'] as String?,
      duration: (map['duration'] as num?)?.toInt(),
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: map['read'] as bool? ?? false,
    );
  }
}
