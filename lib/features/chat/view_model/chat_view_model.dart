import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:libaas/features/chat/repository/chat_repository.dart';
import 'package:libaas/model/chat_message_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (_) => ChatRepository(),
);

/// Real-time messages for one shop ↔ customer conversation.
final chatMessagesProvider = StreamProvider.family<List<ChatMessage>,
    ({String shopId, String phone})>(
  (ref, args) => ref
      .watch(chatRepositoryProvider)
      .messagesStream(args.shopId, args.phone),
);

/// Chat metadata doc (last message preview) for one shop.
final chatMetaProvider = StreamProvider.family<Map<String, dynamic>?,
    ({String shopId, String phone})>(
  (ref, args) => ref
      .watch(chatRepositoryProvider)
      .chatMetaStream(args.shopId, args.phone),
);

/// URL of the voice note currently playing — null means none.
/// Used to ensure only one voice note plays at a time.
final playingVoiceUrlProvider = StateProvider<String?>((ref) => null);
