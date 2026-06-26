// lib/src/player/nirmaan_player_stub.dart
//
// Stub used on unsupported platforms.
// Returns a plain black container so the app doesn't crash.

import 'package:flutter/material.dart';

import '../controller/nirmaan_youtube_controller.dart';
import '../html/nirmaan_player_icons.dart';

Widget buildPlatformYoutubePlayer({
  required String url,
  required NirmaanYoutubeController controller,
  required bool autoPlay,
  ValueChanged<bool>? onFullscreenChanged,
  String? localVideoPath,
  NirmaanPlayerIcons offlineIcons = const NirmaanPlayerIcons(),
}) {
  return const ColoredBox(
    color: Colors.black,
    child: Center(
      child: Text(
        'Unsupported platform',
        style: TextStyle(color: Colors.white),
      ),
    ),
  );
}
