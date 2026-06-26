// custom_library/youtube_video_player/html/nirmaan_player_icons.dart
//
// Swappable icon set for BOTH the online YouTube player and the offline player.
//
// Each icon can be either:
//   • an inline SVG string  (default — matches the current hardcoded UI), OR
//   • an image (asset path that you expose over the local server, or a URL)
//
// If you pass nothing, you get the EXACT same icons as today. Override only
// the ones you want to change. The UI layout, sizes, and colours are untouched.

/// A single swappable icon. Provide ONE of [svg] or [imageUrl].
/// If both are null, the player falls back to its built-in default for that slot.
class NirmaanPlayerIcon {
  /// Inline SVG markup, e.g. '<svg viewBox="0 0 24 24" fill="currentColor">...</svg>'.
  /// Uses `fill="currentColor"` so it inherits the button's text colour.
  final String? svg;

  /// Image URL or local-server path, e.g.
  /// 'http://127.0.0.1:PORT/icons/play.png' or 'https://cdn.site/play.svg'.
  /// When set, an <img> tag is rendered instead of inline SVG.
  final String? imageUrl;

  const NirmaanPlayerIcon.svg(this.svg) : imageUrl = null;
  const NirmaanPlayerIcon.image(this.imageUrl) : svg = null;

  /// Internal: produce the HTML markup for this icon.
  /// [fallbackSvg] is the player's built-in default used when this icon is null.
  String toHtml(String fallbackSvg) {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      // Image icon — width/height:100% so it fills the button like the SVG did.
      return '<img src="$imageUrl" '
          'style="width:100%;height:100%;object-fit:contain;display:block;" '
          'draggable="false" oncontextmenu="return false" />';
    }
    if (svg != null && svg!.trim().isNotEmpty) {
      return svg!;
    }
    return fallbackSvg;
  }
}

/// The full set of swappable icons for a player.
/// Every field is optional — omit to keep the current default icon.
class NirmaanPlayerIcons {
  final NirmaanPlayerIcon? play;
  final NirmaanPlayerIcon? pause;
  final NirmaanPlayerIcon? rewind; // back / seek-backward
  final NirmaanPlayerIcon? forward; // seek-forward
  final NirmaanPlayerIcon? mute; // shown when muted
  final NirmaanPlayerIcon? volume; // shown when unmuted
  final NirmaanPlayerIcon? fullscreen; // enter fullscreen
  final NirmaanPlayerIcon? exitFullscreen;

  /// Optional brand logo image shown in the top bar instead of the brand dot.
  /// Asset/URL string. Null = keep the existing brand dot + text.
  final String? brandImageUrl;

  const NirmaanPlayerIcons({
    this.play,
    this.pause,
    this.rewind,
    this.forward,
    this.mute,
    this.volume,
    this.fullscreen,
    this.exitFullscreen,
    this.brandImageUrl,
  });

  // ── Built-in defaults — the EXACT SVGs used in the current hardcoded HTML ──
  static const String defPlay =
      '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>';
  static const String defPause =
      '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M6 5h4v14H6V5zm8 0h4v14h-4V5z"/></svg>';
  static const String defRewind =
      '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M11 18V6l-8.5 6L11 18zm.5-6l8.5 6V6l-8.5 6z"/></svg>';
  static const String defForward =
      '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M13 6v12l8.5-6L13 6zM12.5 12L4 6v12l8.5-6z"/></svg>';
  static const String defMute =
      '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M16.5 12c0-1.77-1-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zM19 12c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.62 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73L16.25 17 17.52 15.73 4.27 3zM12 4L9.91 6.09 12 8.18V4z"/></svg>';
  static const String defVolume =
      '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1-3.29-2.5-4.03v8.05c1.5-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"/></svg>';
  static const String defFullscreen =
      '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M5 5h6v2H7v4H5V5zm12 2h-4V5h6v6h-2V7zM7 13v4h4v2H5v-6h2zm12 0v6h-6v-2h4v-4h2z"/></svg>';
  static const String defExitFullscreen =
      '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M7 7H3V5h6v6H7V7zm10 0v4h-2V5h6v2h-4zM7 17v-4h2v6H3v-2h4zm10 0h4v2h-6v-6h2v4z"/></svg>';

  // ── Resolved HTML for each slot (used by the HTML builders) ────────────────
  String get playHtml =>
      (play ?? const NirmaanPlayerIcon.svg(defPlay)).toHtml(defPlay);
  String get pauseHtml =>
      (pause ?? const NirmaanPlayerIcon.svg(defPause)).toHtml(defPause);
  String get rewindHtml =>
      (rewind ?? const NirmaanPlayerIcon.svg(defRewind)).toHtml(defRewind);
  String get forwardHtml =>
      (forward ?? const NirmaanPlayerIcon.svg(defForward)).toHtml(defForward);
  String get muteHtml =>
      (mute ?? const NirmaanPlayerIcon.svg(defMute)).toHtml(defMute);
  String get volumeHtml =>
      (volume ?? const NirmaanPlayerIcon.svg(defVolume)).toHtml(defVolume);
  String get fullscreenHtml =>
      (fullscreen ?? const NirmaanPlayerIcon.svg(defFullscreen)).toHtml(
        defFullscreen,
      );
  String get exitFullscreenHtml =>
      (exitFullscreen ?? const NirmaanPlayerIcon.svg(defExitFullscreen)).toHtml(
        defExitFullscreen,
      );
}
