import 'dart:typed_data';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../app_state.dart';
import '../widgets/widgets.dart' as app_widgets;

/// Dummy URLs for testing content viewer.
class ContentViewerDummyUrls {
  static const String pdf =
      'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
  /// Direct MP4 URL; avoids 403 from Google's sample bucket on ExoPlayer.
  static const String video =
      'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4';
}

/// Unified content viewer for PDF and video. Saves/resumes position via SharedPreferences.
class ContentViewerScreen extends StatefulWidget {
  const ContentViewerScreen({
    super.key,
    required this.contentType,
    required this.title,
    required this.url,
    this.thumbnailUrl,
    this.contentId,
  });

  /// 'pdf' or 'video'
  final String contentType;
  final String title;
  final String url;
  final String? thumbnailUrl;
  /// Optional; used for position key. If null, derived from title + url.
  final String? contentId;

  @override
  State<ContentViewerScreen> createState() => _ContentViewerScreenState();
}

class _ContentViewerScreenState extends State<ContentViewerScreen> {
  String get _positionKey {
    final id = (widget.contentId ?? _defaultContentId).replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    return 'content_${id}_position';
  }

  String get _defaultContentId =>
      '${widget.title}_${widget.url}'.hashCode.toRadixString(16);

  bool _loading = true;
  String? _error;
  PdfControllerPinch? _pdfController;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  int _pdfCurrentPage = 1;
  int _pdfPagesCount = 1;
  Duration _videoPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initContent();
  }

  Future<void> _initContent() async {
    if (widget.contentType == 'pdf') {
      await _initPdf();
    } else if (widget.contentType == 'video') {
      await _initVideo();
    } else {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unsupported content type: ${widget.contentType}';
        });
      }
    }
  }

  Future<void> _initPdf() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPage = prefs.getInt(_positionKey) ?? 1;

      final bytes = await http.readBytes(Uri.parse(widget.url));
      final document = await PdfDocument.openData(Uint8List.fromList(bytes));

      if (!mounted) return;
      final pageCount = document.pagesCount;
      final controller = PdfControllerPinch(
        document: Future.value(document),
        initialPage: savedPage.clamp(1, pageCount),
      );
      if (!mounted) return;
      setState(() {
        _pdfController = controller;
        _pdfCurrentPage = savedPage.clamp(1, pageCount);
        _pdfPagesCount = pageCount;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('PDF load error: $e $st');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _initVideo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMs = prefs.getInt(_positionKey);
      final initialPosition =
          savedMs != null ? Duration(milliseconds: savedMs) : Duration.zero;

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        httpHeaders: const {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
        },
      );
      await controller.initialize();
      if (!mounted) return;
      if (initialPosition.inMilliseconds > 0) {
        await controller.seekTo(initialPosition);
      }
      await controller.play();
      if (!mounted) return;

      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        startAt: initialPosition,
        playbackSpeeds: const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
      );

      controller.addListener(_onVideoPositionChanged);
      if (mounted) {
        setState(() {
          _videoController = controller;
          _chewieController = chewie;
          _videoPosition = controller.value.position;
          _videoDuration = controller.value.duration;
          _loading = false;
        });
      }
    } catch (e, st) {
      debugPrint('Video load error: $e $st');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _onVideoPositionChanged() {
    if (_videoController == null || !mounted) return;
    setState(() {
      _videoPosition = _videoController!.value.position;
      _videoDuration = _videoController!.value.duration;
    });
  }

  Future<void> _savePosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (widget.contentType == 'pdf' && _pdfController != null) {
        await prefs.setInt(_positionKey, _pdfCurrentPage);
      } else if (widget.contentType == 'video' &&
          _videoController != null &&
          _videoController!.value.isInitialized) {
        await prefs.setInt(
            _positionKey, _videoController!.value.position.inMilliseconds);
      }
    } catch (e) {
      debugPrint('Save position error: $e');
    }
  }

  @override
  void dispose() {
    _savePosition();
    _pdfController?.dispose();
    _chewieController?.dispose();
    _videoController?.removeListener(_onVideoPositionChanged);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: app_widgets.CustomAppBar(
        title: widget.title,
        showBackButton: true,
        actions: [
          // Night mode toggle placeholder
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: colors.onSurface,
            ),
            onPressed: () {
              themeModeNotifier.value =
                  themeModeNotifier.value == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: app_widgets.MySafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildBody(colors, isDark),
            ),
            if (!_loading && _error == null) _buildProgressBar(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme colors, bool isDark) {
    if (_loading) {
      return const Center(child: app_widgets.LoadingWidget());
    }
    if (_error != null) {
      return app_widgets.EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Loading failed',
        subtitle: _error,
        buttonText: 'Go back',
        onButtonPressed: () => Navigator.of(context).pop(),
      );
    }
    if (widget.contentType == 'pdf' && _pdfController != null) {
      final pdfView = PdfViewPinch(
        controller: _pdfController!,
        onPageChanged: (page) {
          setState(() => _pdfCurrentPage = page);
        },
        builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) => const Center(child: app_widgets.LoadingWidget()),
          pageLoaderBuilder: (_) => const Center(child: app_widgets.LoadingWidget()),
          errorBuilder: (_, Exception error) => Center(
            child: app_widgets.EmptyState(
              icon: Icons.picture_as_pdf_rounded,
              title: 'Could not load PDF',
              subtitle: error.toString(),
            ),
          ),
        ),
      );
      if (isDark) {
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            -1, 0, 0, 0, 255,
            0, -1, 0, 0, 255,
            0, 0, -1, 0, 255,
            0, 0, 0, 1, 0,
          ]),
          child: pdfView,
        );
      }
      return pdfView;
    }
    if (widget.contentType == 'video' && _chewieController != null) {
      return Chewie(controller: _chewieController!);
    }
    return app_widgets.EmptyState(
      icon: Icons.help_outline_rounded,
      title: 'Unsupported type',
      subtitle: 'Content type "${widget.contentType}" is not supported.',
      buttonText: 'Go back',
      onButtonPressed: () => Navigator.of(context).pop(),
    );
  }

  Widget _buildProgressBar(ColorScheme colors) {
    double value = 0;
    String label = '';
    if (widget.contentType == 'pdf' && _pdfPagesCount > 0) {
      value = _pdfCurrentPage / _pdfPagesCount;
      label = 'Page $_pdfCurrentPage of $_pdfPagesCount';
    } else if (widget.contentType == 'video' &&
        _videoDuration.inMilliseconds > 0) {
      value = _videoPosition.inMilliseconds / _videoDuration.inMilliseconds;
      label =
          '${_formatDuration(_videoPosition)} / ${_formatDuration(_videoDuration)}';
    } else {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          app_widgets.Caption(label),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
