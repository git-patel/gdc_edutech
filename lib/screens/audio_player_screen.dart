import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../services/local_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/widgets.dart';

/// Dummy audio URL for chapter audio.
const String kDummyAudioUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

/// Full-screen audio player: cover, seek, play/pause, speed, resume from saved position.
class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({
    super.key,
    required this.audioUrl,
    required this.title,
    required this.chapterId,
    this.thumbnailUrl,
  });

  final String audioUrl;
  final String title;
  final String chapterId;
  final String? thumbnailUrl;

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer _player = AudioPlayer();
  double _speed = 1.0;
  static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final savedMs = await LocalStorage.getAudioPosition(widget.chapterId);
      await _player.setUrl(widget.audioUrl);
      if (savedMs != null && savedMs > 0) {
        await _player.seek(Duration(milliseconds: savedMs));
      }
      await _player.setSpeed(_speed);
      final dur = _player.duration;
      if (dur != null && mounted) {
        LocalStorage.saveAudioDuration(widget.chapterId, dur.inMilliseconds);
      }
    } catch (e) {
      debugPrint('AudioPlayer init error: $e');
    }
    _player.durationStream.listen((dur) {
      if (dur != null) {
        LocalStorage.saveAudioDuration(widget.chapterId, dur.inMilliseconds);
      }
    });
  }

  @override
  void dispose() {
    _savePosition();
    _player.dispose();
    super.dispose();
  }

  Future<void> _savePosition() async {
    final pos = _player.position;
    await LocalStorage.saveAudioPosition(widget.chapterId, pos.inMilliseconds);
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '0:00';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title,
        showBackButton: true,
      ),
      body: MySafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Cover / thumbnail
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.thumbnailUrl!,
                        width: double.infinity,
                        height: 280,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _coverPlaceholder(colors),
                        errorWidget: (context, url, e) => _coverPlaceholder(colors),
                      )
                    : _coverPlaceholder(colors),
              ),
            ),
            const SizedBox(height: 32),
            // Time + slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (context, posSnap) {
                  final position = posSnap.data ?? Duration.zero;
                  return StreamBuilder<Duration?>(
                    stream: _player.durationStream,
                    builder: (context, durSnap) {
                      final duration = durSnap.data ?? Duration.zero;
                      final totalMs = duration.inMilliseconds;
                      final value = totalMs > 0
                          ? (position.inMilliseconds / totalMs).clamp(0.0, 1.0)
                          : 0.0;
                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: colors.primary,
                              inactiveTrackColor: colors.surfaceContainerHighest,
                              thumbColor: colors.primary,
                            ),
                            child: Slider(
                              value: value,
                              onChanged: totalMs > 0
                                  ? (v) {
                                      final ms = (v * totalMs).round();
                                      _player.seek(Duration(milliseconds: ms));
                                    }
                                  : null,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                BodySmall(_formatDuration(position), style: TextStyle(color: colors.captionColor)),
                                BodySmall(_formatDuration(duration), style: TextStyle(color: colors.captionColor)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Play / Pause (large)
            StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snap) {
                final state = snap.data;
                final playing = state?.playing ?? false;
                final processing = state?.processingState == ProcessingState.loading ||
                    state?.processingState == ProcessingState.buffering;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: processing
                        ? null
                        : () async {
                            if (playing) {
                              await _savePosition();
                              _player.pause();
                            } else {
                              _player.play();
                            }
                          },
                    borderRadius: BorderRadius.circular(48),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        processing ? Icons.hourglass_empty_rounded : (playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        size: 48,
                        color: colors.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            // Speed dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BodySmall('Speed', style: TextStyle(color: colors.captionColor)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.dividerColor),
                    ),
                    child: DropdownButton<double>(
                      value: _speed,
                      underline: const SizedBox.shrink(),
                      borderRadius: BorderRadius.circular(12),
                      items: _speeds.map((s) => DropdownMenuItem(value: s, child: BodyText('${s}x'))).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _speed = v);
                          _player.setSpeed(v);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverPlaceholder(ColorScheme colors) {
    return Container(
      width: double.infinity,
      height: 280,
      color: colors.primaryContainer.withValues(alpha: 0.5),
      child: Icon(Icons.music_note_rounded, size: 80, color: colors.primary),
    );
  }
}
