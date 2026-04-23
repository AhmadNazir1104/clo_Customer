import 'package:audioplayers/audioplayers.dart';
import 'package:libaas/features/chat/view_model/chat_view_model.dart';
import 'package:libaas/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VoiceNotePlayer extends ConsumerStatefulWidget {
  final String url;
  final int durationSeconds;
  final bool isOwner;

  const VoiceNotePlayer({
    super.key,
    required this.url,
    required this.durationSeconds,
    required this.isOwner,
  });

  @override
  ConsumerState<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends ConsumerState<VoiceNotePlayer> {
  late final AudioPlayer _player;
  Duration _position = Duration.zero;
  late Duration _total;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _total = Duration(seconds: widget.durationSeconds.clamp(1, 3600));

    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _total = dur);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => _position = Duration.zero);
        if (ref.read(playingVoiceUrlProvider) == widget.url) {
          ref.read(playingVoiceUrlProvider.notifier).state = null;
        }
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final playing = ref.read(playingVoiceUrlProvider);
    if (playing == widget.url) {
      await _player.pause();
      ref.read(playingVoiceUrlProvider.notifier).state = null;
    } else {
      if (mounted) setState(() => _isLoading = true);
      ref.read(playingVoiceUrlProvider.notifier).state = widget.url;
      await _player.play(UrlSource(widget.url));
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // When another voice note starts playing, stop this one
    ref.listen<String?>(playingVoiceUrlProvider, (prev, next) {
      if (prev == widget.url && next != widget.url) {
        _player.stop();
        if (mounted) setState(() => _position = Duration.zero);
      }
    });

    final isPlaying =
        ref.watch(playingVoiceUrlProvider) == widget.url;
    final totalSecs =
        _total.inSeconds == 0 ? 1 : _total.inSeconds;
    final sliderVal =
        (_position.inSeconds / totalSecs).clamp(0.0, 1.0);

    // Colours flip depending on who sent the message
    final iconColor =
        widget.isOwner ? AppColors.navy : AppColors.white;
    final trackActive =
        widget.isOwner ? AppColors.navy : AppColors.white;
    final trackInactive = widget.isOwner
        ? AppColors.navy.withValues(alpha: 0.22)
        : AppColors.white.withValues(alpha: 0.38);
    final timeColor =
        widget.isOwner ? AppColors.gray : AppColors.white.withValues(alpha: 0.8);

    return SizedBox(
      width: 210,
      child: Row(
        children: [
          // Play / Pause / Loading button
          GestureDetector(
            onTap: _isLoading ? null : _togglePlay,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: trackActive.withValues(alpha: 0.15),
              ),
              child: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(9),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: trackActive),
                    )
                  : Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: iconColor,
                      size: 22,
                    ),
            ),
          ),
          const SizedBox(width: 4),
          // Slider + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 11),
                    activeTrackColor: trackActive,
                    inactiveTrackColor: trackInactive,
                    thumbColor: trackActive,
                    overlayColor: trackActive.withValues(alpha: 0.18),
                  ),
                  child: Slider(
                    value: sliderVal,
                    onChanged: (v) async {
                      final seekTo =
                          Duration(seconds: (v * totalSecs).round());
                      await _player.seek(seekTo);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    isPlaying ? _fmt(_position) : _fmt(_total),
                    style: TextStyle(fontSize: 10, color: timeColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
