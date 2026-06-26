import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import '../controller/nirmaan_youtube_controller.dart';
import '../html/nirmaan_player_icons.dart';
import '../parser/youtube_url_parser.dart';
import '../html/nirmaan_youtube_html.dart';

Widget buildPlatformYoutubePlayer({
  required String url,
  required NirmaanYoutubeController controller,
  required bool autoPlay,
  ValueChanged<bool>? onFullscreenChanged,
  String? localVideoPath,
  NirmaanPlayerIcons offlineIcons = const NirmaanPlayerIcons(),
}) {
  return _NirmaanYoutubePlayerWeb(
    url: url,
    controller: controller,
    autoPlay: autoPlay,
    onFullscreenChanged: onFullscreenChanged,
  );
}

class _NirmaanYoutubePlayerWeb extends StatefulWidget {
  final String url;
  final NirmaanYoutubeController controller;
  final bool autoPlay;
  final ValueChanged<bool>? onFullscreenChanged;

  const _NirmaanYoutubePlayerWeb({
    required this.url,
    required this.controller,
    required this.autoPlay,
    this.onFullscreenChanged,
  });

  @override
  State<_NirmaanYoutubePlayerWeb> createState() =>
      _NirmaanYoutubePlayerWebState();
}

class _NirmaanYoutubePlayerWebState extends State<_NirmaanYoutubePlayerWeb> {
  late final String _viewType;
  late final html.IFrameElement _iframe;

  StreamSubscription<html.MessageEvent>? _messageSub;

  @override
  void initState() {
    super.initState();

    final videoId = extractYoutubeVideoId(widget.url);

    _viewType = 'nirmaan-youtube-web-${DateTime.now().microsecondsSinceEpoch}';

    _iframe = html.IFrameElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = '0'
      ..style.display = 'block'
      ..style.backgroundColor = '#000'
      ..allow =
          'autoplay; encrypted-media; fullscreen; picture-in-picture; clipboard-write'
      ..setAttribute('allowfullscreen', 'true')
      ..setAttribute('webkitallowfullscreen', 'true')
      ..setAttribute('mozallowfullscreen', 'true')
      ..setAttribute(
        'srcdoc',
        _buildHtml(videoId: videoId, autoPlay: widget.autoPlay),
      );

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iframe,
    );

    widget.controller.bind(
      play: _play,
      pause: _pause,
      mute: _mute,
      unMute: _unMute,
      seekTo: _seekTo,
      setPlaybackRate: _setPlaybackRate,
    );

    _listenMessages();
  }

  String _buildHtml({required String videoId, required bool autoPlay}) {
    return buildNirmaanYoutubeHtml(
      NirmaanYoutubeHtmlConfig(
        videoId: videoId,
        autoPlay: autoPlay,
        sourceName: 'nirmaan-youtube-web',
        bridgeType: NirmaanYoutubeBridgeType.webPostMessage,
        fullscreenType: NirmaanYoutubeFullscreenType.browser,

        brandText: 'Nirmaan Academy',
        courseTitle: '',
        watermarkText: 'Nirmaan Academy',

        showTopBar: true,
        showBrand: true,
        showWatermark: false,
        showCenterPlayButton: true,
        showSeekButtons: true,
        showBottomControls: true,
        showProgressBar: true,
        showDuration: true,
        showMuteButton: true,
        showSpeedButton: true,
        showFullscreenButton: true,

        fitMode: NirmaanYoutubeFitMode.contain,
        accentColor: '#6C63FF',
        borderRadius: 16,

        customCss: '''
          html, body, #root {
            width: 100%;
            height: 100%;
            min-width: 100%;
            min-height: 100%;
            background: #000;
          }

          #root {
            border-radius: 16px;
          }

          #root.is-fullscreen {
            border-radius: 0;
          }
        ''',
      ),
    );
  }

  void _listenMessages() {
    _messageSub = html.window.onMessage.listen((event) {
      dynamic data = event.data;

      try {
        if (data is String) {
          data = jsonDecode(data);
        }

        if (data is! Map) return;
        if (data['source'] != 'nirmaan-youtube-web') return;

        final position = _readDuration(
          data,
          secondsKey: 'positionSeconds',
          millisecondsKey: 'position',
        );

        final duration = _readDuration(
          data,
          secondsKey: 'durationSeconds',
          millisecondsKey: 'duration',
        );

        widget.controller.updateValue(
          widget.controller.value.copyWith(
            isReady: data['isReady'] == true,
            isPlaying: data['isPlaying'] == true,
            isMuted: data['isMuted'] == true,
            position: position,
            duration: duration,
            playbackRate: _readDouble(data['playbackRate'], fallback: 1.0),
          ),
        );

        final fullscreenValue = data['isFullscreen'];
        if (fullscreenValue is bool) {
          widget.onFullscreenChanged?.call(fullscreenValue);
        }
      } catch (_) {}
    });
  }

  Duration _readDuration(
    Map data, {
    required String secondsKey,
    required String millisecondsKey,
  }) {
    final secondsValue = data[secondsKey];

    if (secondsValue is num) {
      return Duration(milliseconds: (secondsValue * 1000).round());
    }

    final millisecondsValue = data[millisecondsKey];

    if (millisecondsValue is num) {
      return Duration(milliseconds: millisecondsValue.round());
    }

    return Duration.zero;
  }

  double _readDouble(dynamic value, {required double fallback}) {
    if (value is num) return value.toDouble();
    return fallback;
  }

  void _sendToPlayer(Map<String, dynamic> data) {
    final message = jsonEncode({'source': 'nirmaan-parent', ...data});

    _iframe.contentWindow?.postMessage(message, '*');
  }

  Future<void> _play() async {
    _sendToPlayer({'command': 'play'});
  }

  Future<void> _pause() async {
    _sendToPlayer({'command': 'pause'});
  }

  Future<void> _mute() async {
    _sendToPlayer({'command': 'mute'});
  }

  Future<void> _unMute() async {
    _sendToPlayer({'command': 'unMute'});
  }

  Future<void> _seekTo(Duration position) async {
    _sendToPlayer({
      'command': 'seekTo',
      'seconds': position.inMilliseconds / 1000,
    });
  }

  Future<void> _setPlaybackRate(double rate) async {
    _sendToPlayer({'command': 'setPlaybackRate', 'rate': rate});
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _iframe.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
