// lib/main.dart
//
// Example app for nirmaan_youtube_player package.
//
// Demonstrates:
//  • NirmaanYoutubePlayer.initialize() — single-line setup, no GetX needed
//  • buildPlatformYoutubePlayer() — online YouTube playback
//  • Offline download with live progress
//  • Seamless online ↔ offline switch via localVideoPath
//  • Programmatic control via NirmaanYoutubeController
//
// The UI is plain Flutter — MaterialApp, StatefulWidget, StreamSubscription.
// Zero GetX imports in this file.

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:nirmaan_youtube_player/nirmaan_youtube_player.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Entry point
// ─────────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅  One line — no GetX, no GetStorage, no boilerplate needed.
  await NirmaanYoutubePlayer.initialize();

  runApp(const NirmaanPlayerExample());
}

// ─────────────────────────────────────────────────────────────────────────────
//  App
// ─────────────────────────────────────────────────────────────────────────────

class NirmaanPlayerExample extends StatelessWidget {
  const NirmaanPlayerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nirmaan Player Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff6C63FF)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Demo data
// ─────────────────────────────────────────────────────────────────────────────

class _DemoVideo {
  final String id;
  final String title;
  final String subtitle;
  final String youtubeUrl;
  final String thumbnailUrl;

  const _DemoVideo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.youtubeUrl,
    required this.thumbnailUrl,
  });
}

const _demoVideos = [
  _DemoVideo(
    id: '1',
    title: 'Flutter in 100 Seconds',
    subtitle: 'Fireship · YouTube',
    youtubeUrl: 'https://www.youtube.com/watch?v=lHhRhPV--G0',
    thumbnailUrl: 'https://img.youtube.com/vi/lHhRhPV--G0/hqdefault.jpg',
  ),
  _DemoVideo(
    id: '2',
    title: 'Dart in 100 Seconds',
    subtitle: 'Fireship · YouTube',
    youtubeUrl: 'https://www.youtube.com/watch?v=NF2Rb3HTAH8',
    thumbnailUrl: 'https://img.youtube.com/vi/NF2Rb3HTAH8/hqdefault.jpg',
  ),
  _DemoVideo(
    id: '3',
    title: 'Firebase in 100 Seconds',
    subtitle: 'Fireship · YouTube',
    youtubeUrl: 'https://www.youtube.com/watch?v=vAoB4VbhRzM',
    thumbnailUrl: 'https://img.youtube.com/vi/vAoB4VbhRzM/hqdefault.jpg',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
//  Home Screen
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _svc = NirmaanYoutubePlayer.downloadService;
  StreamSubscription? _downloadsSub;

  @override
  void initState() {
    super.initState();
    // Listen to download list changes so the "Downloaded" badge refreshes.
    _downloadsSub = _svc.downloads.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _downloadsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8FC),
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xff6C63FF),
            surfaceTintColor: const Color(0xff6C63FF),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff6C63FF), Color(0xff9D97FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'nirmaan_youtube_player',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Online · Offline · All platforms',
                          style: TextStyle(
                            color: Colors.white.withOpacity(.78),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Info card ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xffEEF0FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xffC7C4FF)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xff6C63FF),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Tap a video to play online.\n'
                            'Use the download button inside the player to save for offline.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xff4C46B6),
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Video list ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, i) {
                  final v = _demoVideos[i];
                  final isDownloaded = _svc.hasDownloadedSync(v.id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _VideoCard(
                      video: v,
                      isDownloaded: isDownloaded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(video: v),
                        ),
                      ),
                    ),
                  );
                },
                childCount: _demoVideos.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Video Card (home list)
// ─────────────────────────────────────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  final _DemoVideo video;
  final bool isDownloaded;
  final VoidCallback onTap;

  const _VideoCard({
    required this.video,
    required this.isDownloaded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            color: Colors.white,
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20),
                ),
                child: Image.network(
                  video.thumbnailUrl,
                  width: 120,
                  height: 82,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 120,
                    height: 82,
                    color: const Color(0xffEEF0FF),
                    child: const Icon(
                      Icons.play_circle_fill_rounded,
                      color: Color(0xff6C63FF),
                      size: 36,
                    ),
                  ),
                ),
              ),

              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        video.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xff94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isDownloaded)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(.12),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            '✓ Downloaded',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xff94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Player Screen
// ─────────────────────────────────────────────────────────────────────────────

class PlayerScreen extends StatefulWidget {
  final _DemoVideo video;

  const PlayerScreen({super.key, required this.video});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  // ── Player controller (ValueNotifier — plain Dart, no GetX) ──────────────
  final _playerController = NirmaanYoutubeController();

  // ── Download service ──────────────────────────────────────────────────────
  final _svc = NirmaanYoutubePlayer.downloadService;
  StreamSubscription? _downloadsSub;
  StreamSubscription? _progressSub;
  StreamSubscription? _downloadingSub;

  // ── Local UI state ────────────────────────────────────────────────────────
  String? _localPath;
  bool _isDownloading = false;
  double _progress = 0.0;

  bool get _isDownloaded => _localPath != null;

  @override
  void initState() {
    super.initState();
    _checkLocalPath();

    // Listen to the service's reactive streams — no GetX in the UI needed.
    _downloadsSub = _svc.downloads.stream.listen((_) => _checkLocalPath());

    _progressSub = _svc.downloadProgress.stream.listen((_) {
      if (mounted) {
        setState(() {
          _progress = _svc.progressFor(widget.video.id);
        });
      }
    });

    _downloadingSub = _svc.downloading.stream.listen((_) {
      if (mounted) {
        setState(() {
          _isDownloading = _svc.isDownloading(widget.video.id);
        });
      }
    });
  }

  Future<void> _checkLocalPath() async {
    final path = await _svc.getLocalPath(widget.video.id);
    if (mounted && path != _localPath) {
      // ← only rebuild when value changes
      setState(() => _localPath = path);
    }
  }

  @override
  void dispose() {
    _downloadsSub?.cancel();
    _progressSub?.cancel();
    _downloadingSub?.cancel();
    _playerController.dispose();
    super.dispose();
  }

  // ── Download actions ──────────────────────────────────────────────────────

  Future<void> _startDownload() async {
    await _svc.downloadYoutubeVideo(
      youtubeUrl: widget.video.youtubeUrl,
      lectureId: widget.video.id,
      lectureIdInt: int.tryParse(widget.video.id) ?? 0,
      courseId: 0,
      title: widget.video.title,
      courseTitle: 'Demo',
      thumbnailUrl: widget.video.thumbnailUrl,
      duration: '--',
    );
  }

  void _cancelDownload() => _svc.cancelDownload(widget.video.id);

  Future<void> _deleteDownload() async {
    await _svc.deleteDownload(widget.video.id);
    if (mounted) setState(() => _localPath = null);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8FC),
      body: Column(
        children: [
          // ── Video surface ───────────────────────────────────────────────
          _buildPlayerSurface(),

          // ── Info + controls ─────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusRow(),
                  const SizedBox(height: 14),
                  Text(
                    widget.video.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.video.subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xff64748B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDownloadCard(),
                  const SizedBox(height: 20),
                  _buildPlayerControls(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Player surface ────────────────────────────────────────────────────────

  Widget _buildPlayerSurface() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(
        color: Colors.black, // black while player loads
        child: Stack(
          fit: StackFit.expand, // ← KEY FIX: forces player to fill full area
          children: [
            buildPlatformYoutubePlayer(
              url: widget.video.youtubeUrl,
              controller: _playerController,
              autoPlay: true,
              localVideoPath: _localPath,
            ),
            // Positioned children are NOT affected by StackFit.expand
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Status row ────────────────────────────────────────────────────────────

  Widget _buildStatusRow() {
    return Wrap(
      spacing: 8,
      children: [
        _Chip(label: 'YOUTUBE', color: Colors.red),
        if (_isDownloaded)
          _Chip(label: '✓ OFFLINE', color: Colors.green)
        else if (_isDownloading)
          _Chip(label: 'DOWNLOADING…', color: const Color(0xff6C63FF)),
      ],
    );
  }

  // ── Download card ─────────────────────────────────────────────────────────

  Widget _buildDownloadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: _isDownloaded
                      ? Colors.green.withOpacity(.12)
                      : const Color(0xffEEF0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isDownloaded
                      ? Icons.check_circle_rounded
                      : Icons.download_for_offline_rounded,
                  color: _isDownloaded
                      ? Colors.green.shade600
                      : const Color(0xff6C63FF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isDownloaded
                          ? 'Saved for Offline'
                          : _isDownloading
                          ? 'Downloading…'
                          : 'Download for Offline',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isDownloaded
                          ? 'Playing from device storage when offline mode active'
                          : _isDownloading
                          ? 'You can still watch online while downloading'
                          : 'Save to watch without internet connection',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Progress bar
          if (_isDownloading) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 7,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(Color(0xff6C63FF)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(_progress * 100).toStringAsFixed(0)}%  —  '
                  'Do not close the app',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              if (!_isDownloaded && !_isDownloading)
                Expanded(
                  child: _ActionButton(
                    icon: Icons.download_rounded,
                    label: 'Download',
                    color: const Color(0xff6C63FF),
                    onTap: _startDownload,
                  ),
                ),
              if (_isDownloading)
                Expanded(
                  child: _ActionButton(
                    icon: Icons.cancel_rounded,
                    label: 'Cancel',
                    color: Colors.orange.shade600,
                    onTap: _cancelDownload,
                  ),
                ),
              if (_isDownloaded) ...[
                Expanded(
                  child: _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: Colors.red.shade400,
                    onTap: _deleteDownload,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Player control buttons ────────────────────────────────────────────────
  // Demonstrates using NirmaanYoutubeController programmatically.

  Widget _buildPlayerControls() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Programmatic Control',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'NirmaanYoutubeController  (ValueNotifier)',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ValueListenableBuilder<NirmaanYoutubeValue>(
            valueListenable: _playerController,
            builder: (_, value, __) {
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CtrlBtn(
                        icon: Icons.replay_10_rounded,
                        label: '−10s',
                        onTap: _playerController.seekBackward10,
                      ),
                      _CtrlBtn(
                        icon: value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        label: value.isPlaying ? 'Pause' : 'Play',
                        primary: true,
                        onTap: _playerController.togglePlayPause,
                      ),
                      _CtrlBtn(
                        icon: Icons.forward_10_rounded,
                        label: '+10s',
                        onTap: _playerController.seekForward10,
                      ),
                      _CtrlBtn(
                        icon: value.isMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        label: value.isMuted ? 'Unmute' : 'Mute',
                        onTap: _playerController.toggleMute,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // State display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffF7F8FC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StateItem(
                          label: 'Position',
                          value: _fmtDuration(value.position),
                        ),
                        _StateItem(
                          label: 'Duration',
                          value: _fmtDuration(value.duration),
                        ),
                        _StateItem(
                          label: 'Speed',
                          value: '${value.playbackRate}x',
                        ),
                        _StateItem(
                          label: 'Ready',
                          value: value.isReady ? 'Yes' : 'No',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reusable small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(.10),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final Future<void> Function() onTap;

  const _CtrlBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xff6C63FF);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: primary ? 52 : 44,
            height: primary ? 52 : 44,
            decoration: BoxDecoration(
              color: primary ? color : color.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: primary ? Colors.white : color,
              size: primary ? 28 : 22,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StateItem extends StatelessWidget {
  final String label;
  final String value;

  const _StateItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xff6C63FF),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xff94A3B8)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _fmtDuration(Duration d) {
  if (d == Duration.zero) return '--:--';
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (d.inHours > 0) return '${d.inHours}:$m:$s';
  return '$m:$s';
}
