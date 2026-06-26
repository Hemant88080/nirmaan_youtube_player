# nirmaan_youtube_player

A cross-platform YouTube + offline video player package for Flutter.

**Platforms:** Android · iOS · macOS · Windows · Web

**Features:**
- YouTube IFrame player via `InAppWebView` (Android · iOS · macOS · Windows) or `<iframe>` (Web)
- Local HTTP server for DRM-free offline MP4 playback with full Range-header seeking support
- `NirmaanDownloadService` — download, cancel, delete, and list offline videos
- Custom glassmorphism player UI (pure HTML/JS) — brand text, watermark, swappable icons
- Fullscreen: native Flutter rotation (mobile) · `fullscreen_window` (Windows) · Browser API (Web)
- Double-tap seek, variable speed, mute, progress bar, keyboard shortcuts
- Seamless online ↔ offline switch via a single `localVideoPath` parameter
- `GetStorage` persistence for offline lecture metadata (no Hive, no code-gen)

---

## Table of contents

1. [Installation](#installation)
2. [Required platform setup](#required-platform-setup) ← **read this before running**
3. [Dart initialisation](#dart-initialisation)
4. [Playing a YouTube video](#playing-a-youtube-video)
5. [Downloading for offline](#downloading-for-offline)
6. [Offline playback](#offline-playback)
7. [Programmatic control](#programmatic-control)
8. [Customising the player UI](#customising-the-player-ui)
9. [API reference](#api-reference)
10. [Migration from custom_library/](#migration-from-custom_library)
11. [Publishing to GitHub](#publishing-to-github)

---

## Installation

### From GitHub (recommended while private)

```yaml
# pubspec.yaml in your app
dependencies:
  nirmaan_youtube_player:
    git:
      url: https://github.com/your-username/nirmaan_youtube_player.git
      ref: main        # or a release tag like v1.0.0
```

### Local path (during development)

```yaml
dependencies:
  nirmaan_youtube_player:
    path: ../nirmaan_youtube_player
```

Then run:
```bash
flutter pub get
```

---

## Required platform setup

> **These steps are mandatory. Skipping any of them will break the player or downloads on that platform.**

---

### Android

#### 1. `android/app/src/main/AndroidManifest.xml`

Add the INTERNET permission and reference the network security config **inside `<manifest>`** before `<application>`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- REQUIRED: allows all network access (WebView + download) -->
    <uses-permission android:name="android.permission.INTERNET"/>

    <application
        android:label="your_app"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:networkSecurityConfig="@xml/network_security_config"
        android:usesCleartextTraffic="true">

        <!-- rest of your application block -->
    </application>

</manifest>
```

> `android:usesCleartextTraffic="true"` is required so the Android WebView can connect to
> the local HTTP server on `127.0.0.1` that serves the player HTML and offline video.

#### 2. Create `android/app/src/main/res/xml/network_security_config.xml`

Create the `xml/` folder if it does not exist, then create the file:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <!-- Allow cleartext HTTP to the local video server (127.0.0.1 / localhost) -->
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="false">127.0.0.1</domain>
        <domain includeSubdomains="false">localhost</domain>
    </domain-config>
</network-security-config>
```

> Android API 28+ blocks all cleartext HTTP by default.
> This exception is scoped only to localhost — all external connections remain HTTPS-only.

#### 3. Minimum SDK

`flutter_inappwebview` requires **minSdkVersion 19** (API 19 / Android 4.4) or higher.
Check your `android/app/build.gradle.kts`:

```kotlin
defaultConfig {
    minSdk = 19   // or higher
}
```

---

### iOS

#### `ios/Runner/Info.plist`

Add these two keys anywhere inside the root `<dict>`:

```xml
<!-- Allow the WebView to load from the local HTTP server on 127.0.0.1 -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>

<!-- Required by flutter_inappwebview to render WebViews inline -->
<key>io.flutter.embedded_views_preview</key>
<true/>
```

> `NSAllowsLocalNetworking` permits HTTP only to `.local` hostnames and loopback
> addresses (127.0.0.1). All other external traffic continues to require HTTPS.

**Minimum deployment target:** iOS 12.0+  
Set in Xcode → Runner target → General → Minimum Deployments.

---

### macOS

macOS uses the App Sandbox, which blocks **all** outbound connections by default.
Two files must be updated.

#### 1. `macos/Runner/DebugProfile.entitlements`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    <!-- Bind the local HTTP server -->
    <key>com.apple.security.network.server</key>
    <true/>
    <!-- Allow outbound connections: YouTube API, CDN, download -->
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

#### 2. `macos/Runner/Release.entitlements`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <!-- Bind the local HTTP server -->
    <key>com.apple.security.network.server</key>
    <true/>
    <!-- Allow outbound connections: YouTube API, CDN, download -->
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

> Without `network.client` the macOS sandbox blocks the WKWebView from reaching
> `youtube.com` to load the IFrame API, and also blocks `youtube_explode_dart` and
> Dio from making any download requests.

#### 3. `macos/Runner/Info.plist`

Add inside the root `<dict>`:

```xml
<!-- Allow the WebView to load from the local HTTP server on 127.0.0.1 -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

**Minimum deployment target:** macOS 10.14+  
Set in Xcode → Runner target → General → Minimum Deployments.

---

### Windows

No special system configuration is required.

**WebView2 Runtime** must be installed on the user's machine.
- Windows 11 and up-to-date Windows 10 include WebView2 by default.
- For older Windows 10 setups, users need to install the
  [WebView2 Runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/).

`flutter_inappwebview` on Windows uses WebView2 (Microsoft Edge Chromium engine).
YouTube's IFrame API works in WebView2 without additional configuration.

---

### Web

No extra configuration required. The Web player uses an `<iframe>` with `srcdoc`
and communicates via `window.postMessage`. Offline download is **not** supported
on Web (no file system access).

---

## Dart initialisation

Call `NirmaanYoutubePlayer.initialize()` **once** in `main()`, before `runApp`.
It initialises GetStorage and registers the download service internally.
You do not need to import or use GetX in your own code.

```dart
import 'package:flutter/material.dart';
import 'package:nirmaan_youtube_player/nirmaan_youtube_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // One line — sets up GetStorage + NirmaanDownloadService internally.
  // No GetX knowledge required in your app code.
  await NirmaanYoutubePlayer.initialize();

  runApp(const MyApp());
}
```

---

## Playing a YouTube video

```dart
import 'package:flutter/material.dart';
import 'package:nirmaan_youtube_player/nirmaan_youtube_player.dart';

class MyPlayerScreen extends StatefulWidget {
  final String youtubeUrl;
  const MyPlayerScreen({super.key, required this.youtubeUrl});

  @override
  State<MyPlayerScreen> createState() => _MyPlayerScreenState();
}

class _MyPlayerScreenState extends State<MyPlayerScreen> {
  final _controller = NirmaanYoutubeController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AspectRatio(
        aspectRatio: 16 / 9,
        child: buildPlatformYoutubePlayer(
          url: widget.youtubeUrl,         // any youtube.com or youtu.be URL
          controller: _controller,
          autoPlay: true,
          onFullscreenChanged: (isFull) {
            // called when the user taps the fullscreen button
          },
        ),
      ),
    );
  }
}
```

Supported URL formats:
- `https://www.youtube.com/watch?v=VIDEO_ID`
- `https://youtu.be/VIDEO_ID`
- `https://www.youtube.com/embed/VIDEO_ID`
- `https://www.youtube.com/shorts/VIDEO_ID`

---

## Downloading for offline

Access the download service through `NirmaanYoutubePlayer.downloadService` after
`initialize()` has been called, or directly via `NirmaanDownloadService.I`.

```dart
final svc = NirmaanYoutubePlayer.downloadService;

// Start a download
await svc.downloadYoutubeVideo(
  youtubeUrl:   'https://youtu.be/VIDEO_ID',
  lectureId:    '42',          // string identifier
  lectureIdInt: 42,            // integer identifier (same value)
  courseId:     7,             // 0 is fine if you have no course concept
  title:        'Lecture 1 — Introduction',
  courseTitle:  'My Course',
  thumbnailUrl: 'https://img.youtube.com/vi/VIDEO_ID/hqdefault.jpg',
  duration:     '15:30',       // display string, not parsed
  onProgress:   (p) => print('${(p * 100).toInt()}%'),
);

// Track progress reactively (use in a StatefulWidget with StreamSubscription)
svc.downloadProgress.stream.listen((map) {
  final progress = svc.progressFor('42'); // 0.0 – 1.0
});
svc.downloading.stream.listen((_) {
  final active = svc.isDownloading('42');
});

// Check if a video is already downloaded
final bool ready = svc.hasDownloadedSync('42');
final String? path = await svc.getLocalPath('42');

// Cancel an in-progress download
svc.cancelDownload('42');

// Delete a downloaded video
await svc.deleteDownload('42');

// Delete every downloaded video
await svc.deleteAllDownloads();

// List all downloads
final List<OfflineLecture> all = await svc.getAllDownloads();
```

> Downloads are saved to `getApplicationDocumentsDirectory()` — no storage
> permission is required on Android or iOS for this path.

---

## Offline playback

Pass the local file path returned by `getLocalPath()` to `buildPlatformYoutubePlayer`.
When `localVideoPath` is non-null the player automatically switches to an HTML5
`<video>` element served through the local HTTP server instead of the YouTube IFrame.
Removing the path (setting it back to `null`) switches back to online mode.

```dart
final String? localPath = await svc.getLocalPath('42');

buildPlatformYoutubePlayer(
  url: 'https://youtu.be/VIDEO_ID',   // still required (used in online mode)
  controller: _controller,
  autoPlay: true,
  localVideoPath: localPath,           // null → online   non-null → offline
)
```

> The player reloads automatically when `localVideoPath` changes,
> so you can download and switch without rebuilding the entire screen.

---

## Programmatic control

`NirmaanYoutubeController` is a plain `ValueNotifier<NirmaanYoutubeValue>`.
It works with both online YouTube and offline HTML5 playback.

```dart
final controller = NirmaanYoutubeController();

// Commands
await controller.play();
await controller.pause();
await controller.togglePlayPause();
await controller.mute();
await controller.unMute();
await controller.toggleMute();
await controller.seekTo(const Duration(seconds: 90));
await controller.seekForward10();   // +10 s
await controller.seekBackward10();  // -10 s
await controller.setPlaybackRate(1.5);

// Read current state
final NirmaanYoutubeValue v = controller.value;
print(v.isPlaying);      // bool
print(v.isMuted);        // bool
print(v.isReady);        // bool
print(v.position);       // Duration
print(v.duration);       // Duration
print(v.playbackRate);   // double

// React to state changes in a widget
ValueListenableBuilder<NirmaanYoutubeValue>(
  valueListenable: controller,
  builder: (context, value, _) {
    return Text(value.isPlaying ? 'Playing' : 'Paused');
  },
)
```

---

## Customising the player UI

### Brand and watermark

```dart
// The brand text shown in the top-left pill defaults to 'Nirmaan Academy'.
// Pass topLeftSlotHtml or configure NirmaanYoutubeHtmlConfig directly
// if you are building the HTML yourself via buildNirmaanYoutubeHtml().

buildNirmaanYoutubeHtml(
  NirmaanYoutubeHtmlConfig(
    videoId:      'VIDEO_ID',
    autoPlay:     true,
    sourceName:   'my-app',
    bridgeType:   NirmaanYoutubeBridgeType.inAppWebView,
    fullscreenType: NirmaanYoutubeFullscreenType.nativeFlutter,
    brandText:    'My Academy',
    courseTitle:  'Course Name',
    showWatermark: true,
    watermarkText: 'CONFIDENTIAL',
    accentColor:  '#FF6B6B',
    borderRadius: 12,
  ),
);
```

### Swappable icons

Both the online and offline players support custom icons via `NirmaanPlayerIcons`.
Each slot accepts either an inline SVG string or an image URL:

```dart
buildPlatformYoutubePlayer(
  url: 'https://youtu.be/VIDEO_ID',
  controller: _controller,
  autoPlay: true,
  offlineIcons: NirmaanPlayerIcons(
    play:           NirmaanPlayerIcon.svg('<svg viewBox="0 0 24 24">...</svg>'),
    pause:          NirmaanPlayerIcon.image('https://cdn.example.com/pause.png'),
    rewind:         NirmaanPlayerIcon.svg('<svg>...</svg>'),
    forward:        NirmaanPlayerIcon.svg('<svg>...</svg>'),
    mute:           NirmaanPlayerIcon.svg('<svg>...</svg>'),
    volume:         NirmaanPlayerIcon.svg('<svg>...</svg>'),
    fullscreen:     NirmaanPlayerIcon.svg('<svg>...</svg>'),
    exitFullscreen: NirmaanPlayerIcon.svg('<svg>...</svg>'),
  ),
)
```

### Custom CSS / JS injection

```dart
NirmaanYoutubeHtmlConfig(
  // ... other params ...
  customCss: '''
    #brandPill { display: none; }
    #progressBar { background: #FF6B6B; }
  ''',
  customJs: '''
    console.log('Player ready');
  ''',
)
```

---

## API reference

| Export | Description |
|---|---|
| `NirmaanYoutubePlayer.initialize()` | One-call setup — call once in `main()` before `runApp()` |
| `NirmaanYoutubePlayer.downloadService` | Returns the `NirmaanDownloadService` singleton |
| `buildPlatformYoutubePlayer(...)` | Main widget builder — picks the right implementation per platform |
| `NirmaanYoutubeController` | `ValueNotifier`-based controller for play / pause / seek / speed |
| `NirmaanYoutubeValue` | Immutable state snapshot (`isPlaying`, `position`, `duration`, …) |
| `NirmaanYoutubeHtmlConfig` | Full config for the HTML player (brand, colours, visibility flags, …) |
| `buildNirmaanYoutubeHtml(config)` | Builds the complete player HTML string (advanced use) |
| `NirmaanYoutubeBridgeType` | `inAppWebView` (IO) · `webPostMessage` (Web) |
| `NirmaanYoutubeFullscreenType` | `nativeFlutter` (IO) · `browser` (Web) |
| `NirmaanYoutubeFitMode` | `contain` (default) · `cover` |
| `NirmaanPlayerIcons` | Full swappable icon set for both online and offline players |
| `NirmaanPlayerIcon.svg(svgString)` | Icon from inline SVG markup |
| `NirmaanPlayerIcon.image(url)` | Icon from image URL |
| `NirmaanDownloadService` | GetxService — download / cancel / delete / list offline videos |
| `YoutubeDownloadService` | Typedef alias for `NirmaanDownloadService` (backward compat) |
| `OfflineLecture` | Plain-Dart model persisted in GetStorage |
| `extractYoutubeVideoId(url)` | Extracts the 11-char video ID from any YouTube URL format |

---

## Platform support matrix

| Feature | Android | iOS | macOS | Windows | Web |
|---|:---:|:---:|:---:|:---:|:---:|
| Online YouTube playback | ✅ | ✅ | ✅ | ✅ | ✅ |
| Offline MP4 download | ✅ | ✅ | ✅ | ✅ | ❌ |
| Offline MP4 playback | ✅ | ✅ | ✅ | ✅ | ❌ |
| Fullscreen (native) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Double-tap seek | ✅ | ✅ | ✅ | ✅ | ✅ |
| Keyboard shortcuts | — | — | ✅ | ✅ | ✅ |

---

## Migration from `custom_library/`

Replace all scattered imports with a single package import:

```dart
// BEFORE
import 'package:yourapp/custom_library/youtube_video_player/youtube_player_platform.dart';
import 'package:yourapp/screens/student/lecture_player/services/youtube_download_service.dart';
import 'package:yourapp/screens/student/lecture_player/models/offline_lectures.dart';
import 'package:yourapp/custom_library/youtube_video_player/controller/nirmaan_youtube_controller.dart';
import 'package:yourapp/custom_library/youtube_video_player/parser/youtube_url_parser.dart';

// AFTER — one import covers everything
import 'package:nirmaan_youtube_player/nirmaan_youtube_player.dart';
```

`YoutubeDownloadService` is aliased to `NirmaanDownloadService`, so existing
references like `YoutubeDownloadService.I` continue to compile without changes.

Replace the old manual GetX init:
```dart
// BEFORE
await GetStorage.init();
Get.put(YoutubeDownloadService());

// AFTER
await NirmaanYoutubePlayer.initialize();
```

---

## Publishing to GitHub

```bash
cd nirmaan_youtube_player
git init
git add .
git commit -m "chore: initial package release v1.0.0"
git remote add origin https://github.com/your-username/nirmaan_youtube_player.git
git branch -M main
git push -u origin main
git tag v1.0.0
git push origin v1.0.0
```

Reference in any Flutter app:
```yaml
dependencies:
  nirmaan_youtube_player:
    git:
      url: https://github.com/your-username/nirmaan_youtube_player.git
      ref: v1.0.0
```

---

## Troubleshooting

### YouTube video is black / won't load (macOS)
Both entitlement files must have `com.apple.security.network.client: true`.
The Debug and Release entitlements are separate files — update both.

### YouTube video is black / won't load (Android)
Ensure `<uses-permission android:name="android.permission.INTERNET"/>` is in
`AndroidManifest.xml` and `minSdkVersion` is 19 or higher.

### Local server fails / offline player shows a blank screen (iOS / macOS)
Add `NSAllowsLocalNetworking: true` under `NSAppTransportSecurity` in `Info.plist`.
This lets the WKWebView load from `http://127.0.0.1`.

### Download always fails or returns null
- Check network permissions for your platform (see platform setup above).
- Some YouTube videos restrict muxed streams; the package automatically falls back
  to the best available video-only stream.
- `youtube_explode_dart` requires a valid internet connection to resolve stream URLs.

### Windows player shows "Windows player only" text
This message appears when `Platform.isWindows` is `false`, which should never
happen in a normal Windows build. If you see it, the `dart.library.io` conditional
export may not have resolved correctly — clean the build with `flutter clean`.

### WebView2 not found (Windows)
Instruct the user to install the
[WebView2 Evergreen Runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/).
Windows 11 includes it by default; older Windows 10 machines may not.

---

## License

MIT — see [LICENSE](LICENSE)
