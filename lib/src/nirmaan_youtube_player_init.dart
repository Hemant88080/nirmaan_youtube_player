// lib/src/nirmaan_youtube_player_init.dart
//
// Single-line initialiser that works whether the host app uses GetX or not.
// Internally the package still uses GetX for state management (it is already
// a dependency), but the caller never has to know that.

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'services/nirmaan_download_service.dart';

/// One-call initialiser for the nirmaan_youtube_player package.
///
/// ```dart
/// // main.dart — no GetX knowledge required
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await NirmaanYoutubePlayer.initialize();
///   runApp(const MyApp());
/// }
/// ```
///
/// After this you can use:
/// • [buildPlatformYoutubePlayer] — the player widget
/// • [NirmaanYoutubePlayer.downloadService] — download / cancel / delete
/// • [NirmaanDownloadService.I] — same service via the legacy accessor
abstract class NirmaanYoutubePlayer {
  // Private constructor — this class is never instantiated.
  NirmaanYoutubePlayer._();

  static bool _initialized = false;

  // ── Main entry point ──────────────────────────────────────────────────────

  /// Initialises [GetStorage] and registers [NirmaanDownloadService].
  ///
  /// Safe to call multiple times — subsequent calls are no-ops.
  /// Must be awaited before calling [runApp].
  static Future<void> initialize() async {
    if (_initialized) return;

    // Initialise GetStorage (the package uses it to persist offline lectures).
    await GetStorage.init();

    // Register the download service with GetX's DI container.
    // GetX DI works completely independently of GetMaterialApp —
    // so this runs fine even in plain MaterialApp apps.
    if (!Get.isRegistered<NirmaanDownloadService>()) {
      Get.put(NirmaanDownloadService());
    }

    _initialized = true;
  }

  // ── Convenience accessors ─────────────────────────────────────────────────

  /// The offline download service singleton.
  ///
  /// Throws a [StateError] if [initialize] has not been called yet.
  static NirmaanDownloadService get downloadService {
    if (!_initialized) {
      throw StateError(
        'NirmaanYoutubePlayer.initialize() must be awaited before '
        'accessing downloadService.',
      );
    }
    return NirmaanDownloadService.I;
  }

  /// Whether [initialize] has already been called.
  static bool get isInitialized => _initialized;
}
