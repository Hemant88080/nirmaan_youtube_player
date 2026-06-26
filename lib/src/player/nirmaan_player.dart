// lib/src/player/nirmaan_player.dart
//
// Conditional export — Dart picks the right implementation at compile time.
//   dart.library.html  → Web (iframe + postMessage)
//   dart.library.io    → Mobile / macOS / Windows (InAppWebView + local HTTP server)
//   fallback           → Stub (unsupported platform)
//
// All three implementations expose the SAME top-level function:
//
//   Widget buildPlatformYoutubePlayer({
//     required String url,
//     required NirmaanYoutubeController controller,
//     required bool autoPlay,
//     ValueChanged<bool>? onFullscreenChanged,
//     String? localVideoPath,          // null → online YouTube, set → offline MP4
//     NirmaanPlayerIcons offlineIcons, // override any icon in the offline player
//   })

export 'nirmaan_player_stub.dart'
    if (dart.library.html) 'nirmaan_player_web.dart'
    if (dart.library.io) 'nirmaan_player_io.dart';

export '../html/nirmaan_player_icons.dart';
