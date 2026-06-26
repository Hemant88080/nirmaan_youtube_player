/// Nirmaan YouTube Player
///
/// Cross-platform YouTube + offline video player for Flutter.
/// Platforms: Android · iOS · macOS · Windows · Web
///
/// ## Quick start (no GetX knowledge needed)
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await NirmaanYoutubePlayer.initialize();   // ← one line, that's it
///   runApp(const MyApp());
/// }
///
/// // In your widget:
/// buildPlatformYoutubePlayer(
///   url: 'https://youtu.be/dQw4w9WgXcQ',
///   controller: NirmaanYoutubeController(),
///   autoPlay: true,
/// )
/// ```
library nirmaan_youtube_player;

// ── One-line initialiser ──────────────────────────────────────────────────────
// NirmaanYoutubePlayer.initialize() sets up everything internally.
export 'src/nirmaan_youtube_player_init.dart';

// ── Player controller & value ─────────────────────────────────────────────────
export 'src/controller/nirmaan_youtube_controller.dart';

// ── HTML config, builder, and enums ──────────────────────────────────────────
export 'src/html/nirmaan_youtube_html.dart';

// ── Swappable icon set ────────────────────────────────────────────────────────
export 'src/html/nirmaan_player_icons.dart';

// ── Offline data model ────────────────────────────────────────────────────────
export 'src/models/offline_lecture.dart';

// ── URL utility ───────────────────────────────────────────────────────────────
export 'src/parser/youtube_url_parser.dart';

// ── Download service (+ YoutubeDownloadService typedef for compat) ────────────
export 'src/services/nirmaan_download_service.dart';

// ── buildPlatformYoutubePlayer (platform-conditional) ────────────────────────
//    Web   → iframe + postMessage
//    IO    → InAppWebView + local HTTP server (Mobile / macOS / Windows)
//    Other → stub (black screen)
export 'src/player/nirmaan_player.dart';
