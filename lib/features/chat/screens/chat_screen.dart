import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:khayyat/features/auth/view_model/auth_provider.dart';
import 'package:khayyat/features/chat/view_model/chat_view_model.dart';
import 'package:khayyat/features/chat/widgets/voice_note_player.dart';
import 'package:khayyat/features/shop/view_model/shop_view_model.dart';
import 'package:khayyat/model/chat_message_model.dart';
import 'package:khayyat/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String shopId;

  const ChatScreen({super.key, required this.shopId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _recorder = AudioRecorder();

  bool _isSending = false;
  bool _isRecording = false;
  int _recordSeconds = 0;
  String? _recordingPath;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final phone = ref.read(currentPhoneProvider);
      ref
          .read(chatRepositoryProvider)
          .markOwnerMessagesRead(widget.shopId, phone);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _recordTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  // ── Send text ──────────────────────────────────────────────────────────────

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;
    final phone = ref.read(currentPhoneProvider);
    _textController.clear();
    setState(() => _isSending = true);
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendText(widget.shopId, phone, text);
    } catch (e) {
      if (mounted) _showError('Failed to send: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ── Camera ─────────────────────────────────────────────────────────────────

  Future<void> _pickAndSendImage() async {
    final photo = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 100);
    if (photo == null || !mounted) return;
    final phone = ref.read(currentPhoneProvider);
    setState(() => _isSending = true);
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendImage(widget.shopId, phone, File(photo.path));
    } catch (e) {
      if (mounted) _showError('Failed to send image: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ── Voice recording ────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) _showError('Microphone permission denied');
      return;
    }
    final tempDir = await getTemporaryDirectory();
    _recordingPath =
        '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 32000,
        sampleRate: 22050,
      ),
      path: _recordingPath!,
    );

    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
    });

    _recordTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordSeconds++);
    });
  }

  Future<void> _stopAndSendRecording() async {
    _recordTimer?.cancel();
    final path = await _recorder.stop();
    final duration = _recordSeconds;
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });

    if (path == null || duration < 1) return; // too short — discard

    final phone = ref.read(currentPhoneProvider);
    setState(() => _isSending = true);
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendVoice(widget.shopId, phone, path, duration);
    } catch (e) {
      if (mounted) _showError('Failed to send voice note: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    await _recorder.stop();
    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordSeconds = 0;
      });
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _fmtRecordingTime(int s) {
    final m = (s ~/ 60).toString();
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(currentPhoneProvider);
    final shopAsync = ref.watch(shopProvider(widget.shopId));
    final messagesAsync = ref.watch(
        chatMessagesProvider((shopId: widget.shopId, phone: phone)));

    final shopName =
        shopAsync.whenOrNull(data: (s) => s?.name) ?? '...';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: AppColors.dark),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.store,
                  color: AppColors.navy, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                shopName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.dark),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Messages ───────────────────────────────────────────────
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style:
                        const TextStyle(color: AppColors.gray)),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 56,
                            color: Color(0xFFD0D0D8)),
                        SizedBox(height: 12),
                        Text(
                          'No messages yet.\nSay hello to your tailor!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 15, color: AppColors.gray),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, i) =>
                      _MessageBubble(message: messages[i]),
                );
              },
            ),
          ),
          // ── Input bar ──────────────────────────────────────────────
          _isRecording ? _buildRecordingBar() : _buildInputBar(),
        ],
      ),
    );
  }

  // ── Input bar (normal) ─────────────────────────────────────────────────────

  Widget _buildInputBar() {
    final hasText = _textController.text.trim().isNotEmpty;

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Camera button
            IconButton(
              onPressed: _isSending ? null : _pickAndSendImage,
              icon: const Icon(Icons.camera_alt_outlined),
              color: AppColors.navy,
            ),
            // Text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: const Color(0xFFE0E0E8)),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization:
                      TextCapitalization.sentences,
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.dark),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle:
                        TextStyle(color: AppColors.gray),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Send button or mic button
            hasText
                ? _SendButton(
                    onTap: _isSending ? null : _sendText)
                : GestureDetector(
                    onLongPressStart: (_) => _startRecording(),
                    onLongPressEnd: (_) =>
                        _stopAndSendRecording(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.navy,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic,
                          color: AppColors.white, size: 22),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // ── Input bar (recording active) ───────────────────────────────────────────

  Widget _buildRecordingBar() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Cancel recording
            GestureDetector(
              onTap: _cancelRecording,
              child: const Icon(Icons.delete_outline,
                  color: AppColors.red, size: 28),
            ),
            const SizedBox(width: 12),
            // Pulsing dot + timer
            Expanded(
              child: Row(
                children: [
                  _PulsingDot(),
                  const SizedBox(width: 8),
                  Text(
                    'Recording  ${_fmtRecordingTime(_recordSeconds)}',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.red),
                  ),
                ],
              ),
            ),
            // Stop & send
            GestureDetector(
              onTap: _stopAndSendRecording,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.navy,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send,
                    color: AppColors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message bubble
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isOwner = message.isOwner;
    final timeStr =
        DateFormat('h:mm a').format(message.createdAt);

    return Align(
      alignment:
          isOwner ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
            maxWidth:
                MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isOwner
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            _bubbleContent(context),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                timeStr,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.gray),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubbleContent(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return _TextBubble(message: message);
      case MessageType.image:
        return _ImageBubble(message: message);
      case MessageType.voice:
        return _VoiceBubble(message: message);
    }
  }
}

// ── Text bubble ───────────────────────────────────────────────────────────────

class _TextBubble extends StatelessWidget {
  final ChatMessage message;
  const _TextBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isOwner = message.isOwner;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isOwner ? AppColors.white : AppColors.navy,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isOwner ? 4 : 18),
          bottomRight: Radius.circular(isOwner ? 18 : 4),
        ),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 4,
              offset: Offset(0, 1)),
        ],
      ),
      child: Text(
        message.text ?? '',
        style: TextStyle(
            fontSize: 15,
            color:
                isOwner ? AppColors.dark : AppColors.white,
            height: 1.4),
      ),
    );
  }
}

// ── Image bubble ──────────────────────────────────────────────────────────────

class _ImageBubble extends StatelessWidget {
  final ChatMessage message;
  const _ImageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final url = message.mediaUrl ?? '';
    return GestureDetector(
      onTap: () => _showFullScreen(context, url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 220,
          height: 220,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 220,
            height: 220,
            color: const Color(0xFFE8E8F0),
            child: const Center(
                child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            width: 220,
            height: 220,
            color: const Color(0xFFE8E8F0),
            child: const Icon(Icons.broken_image_outlined,
                color: AppColors.gray, size: 48),
          ),
        ),
      ),
    );
  }

  void _showFullScreen(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Voice bubble ──────────────────────────────────────────────────────────────

class _VoiceBubble extends StatelessWidget {
  final ChatMessage message;
  const _VoiceBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isOwner = message.isOwner;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isOwner ? AppColors.white : AppColors.navy,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isOwner ? 4 : 18),
          bottomRight: Radius.circular(isOwner ? 18 : 4),
        ),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 4,
              offset: Offset(0, 1)),
        ],
      ),
      child: VoiceNotePlayer(
        url: message.mediaUrl ?? '',
        durationSeconds: message.duration ?? 0,
        isOwner: isOwner,
      ),
    );
  }
}

// ── Send button ───────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _SendButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: onTap == null
              ? AppColors.navy.withValues(alpha: 0.5)
              : AppColors.navy,
          shape: BoxShape.circle,
        ),
        child:
            const Icon(Icons.send, color: AppColors.white, size: 20),
      ),
    );
  }
}

// ── Pulsing red dot (recording indicator) ─────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Opacity(
        opacity: _anim.value,
        child: const CircleAvatar(
            radius: 6, backgroundColor: AppColors.red),
      ),
    );
  }
}
