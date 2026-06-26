// lib/src/player/nirmaan_player_io.dart
//
// IO router: picks the Windows or mobile/macOS player at runtime
// based on Platform.isWindows.

import 'dart:io';

import 'package:flutter/material.dart';

import '../controller/nirmaan_youtube_controller.dart';
import '../html/nirmaan_player_icons.dart';
import 'nirmaan_player_mobile_macos.dart' as mobile_macos_player;
import 'nirmaan_player_windows.dart' as windows_player;

Widget buildPlatformYoutubePlayer({
  required String url,
  required NirmaanYoutubeController controller,
  required bool autoPlay,
  ValueChanged<bool>? onFullscreenChanged,
  String? localVideoPath,
  NirmaanPlayerIcons offlineIcons = const NirmaanPlayerIcons(),
}) {
  if (Platform.isWindows) {
    return windows_player.buildPlatformYoutubePlayer(
      url: url,
      controller: controller,
      autoPlay: autoPlay,
      onFullscreenChanged: onFullscreenChanged,
      localVideoPath: localVideoPath,
      offlineIcons: offlineIcons,
    );
  }

  return mobile_macos_player.buildPlatformYoutubePlayer(
    url: url,
    controller: controller,
    autoPlay: autoPlay,
    onFullscreenChanged: onFullscreenChanged,
    localVideoPath: localVideoPath,
    offlineIcons: offlineIcons,
  );
}
