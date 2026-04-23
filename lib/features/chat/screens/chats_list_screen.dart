import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libaas/features/auth/view_model/auth_provider.dart';
import 'package:libaas/features/auth/view_model/linked_shops_provider.dart';
import 'package:libaas/features/chat/view_model/chat_view_model.dart';
import 'package:libaas/features/shop/view_model/shop_view_model.dart';
import 'package:libaas/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ChatsListScreen extends ConsumerWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linked = ref.watch(linkedShopsProvider);
    final phone  = ref.watch(currentPhoneProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Chats',
          style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: AppColors.dark),
        ),
      ),
      body: linked.isLoading
          ? const Center(child: CircularProgressIndicator())
          : linked.shopIds.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 64, color: Color(0xFFD0D0D8)),
                      SizedBox(height: 16),
                      Text(
                        'No shops linked yet',
                        style: TextStyle(
                            fontSize: 16, color: AppColors.gray),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    for (final shopId in linked.shopIds)
                      _ChatTile(shopId: shopId, phone: phone),
                  ],
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ChatTile extends ConsumerWidget {
  final String shopId;
  final String phone;

  const _ChatTile({required this.shopId, required this.phone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopProvider(shopId));
    final metaAsync = ref.watch(
        chatMetaProvider((shopId: shopId, phone: phone)));

    final shopName =
        shopAsync.whenOrNull(data: (s) => s?.name) ?? '...';
    final meta = metaAsync.whenOrNull(data: (m) => m);

    String lastMessage = 'Tap to start a conversation';
    String? timeStr;

    if (meta != null) {
      lastMessage = meta['lastMessage'] as String? ?? '';
      final rawTs = meta['lastMessageAt'];
      if (rawTs != null) {
        try {
          final dt = (rawTs as Timestamp).toDate();
          final now = DateTime.now();
          final isToday = dt.year == now.year &&
              dt.month == now.month &&
              dt.day == now.day;
          timeStr = isToday
              ? DateFormat('h:mm a').format(dt)
              : DateFormat('d MMM').format(dt);
        } catch (_) {}
      }
    }

    return GestureDetector(
      onTap: () => context.push('/chat/$shopId'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 6,
                offset: Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Shop icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.store,
                  color: AppColors.navy, size: 22),
            ),
            const SizedBox(width: 12),
            // Name + last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shopName,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.gray),
                  ),
                ],
              ),
            ),
            // Time + chevron
            if (timeStr != null) ...[
              const SizedBox(width: 8),
              Text(
                timeStr,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.gray),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                color: AppColors.gray, size: 18),
          ],
        ),
      ),
    );
  }
}
