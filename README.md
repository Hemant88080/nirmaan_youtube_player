# nirmaan_youtube_player

[![pub package](https://img.shields.io/pub/v/nirmaan_youtube_player.svg)](https://pub.dev/packages/nirmaan_youtube_player)
[![License](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](LICENSE)
[![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Windows%20%7C%20Web-4CAF50.svg)](#platform-support)

A Flutter package for presenting YouTube embeds and locally stored video in a consistent, branded player experience across Android, iOS, macOS, Windows, and web.

> **Use responsibly:** Only play or download video that you own or are explicitly authorised to use. This package does not grant rights to access, download, redistribute, or bypass restrictions for third-party content.

## Highlights

- One player API for Android, iOS, macOS, Windows, and web.
- YouTube IFrame playback with custom HTML-based controls.
- Local MP4 playback on Android, iOS, macOS, and Windows.
- Offline video manager for starting, cancelling, listing, and removing saved videos.
- Playback controls for play, pause, seek, mute, speed, fullscreen, and progress.
- `ValueNotifier`-based controller — no GetX knowledge is required in the host app.
- Customisable offline-player icons and HTML player appearance.
- Offline download metadata persisted with `GetStorage`.

## Platform support

| Capability | Android | iOS | macOS | Windows | Web |
|---|:---:|:---:|:---:|:---:|:---:|
| YouTube playback | ✅ | ✅ | ✅ | ✅ | ✅ |
| Local MP4 playback | ✅ | ✅ | ✅ | ✅ | ❌ |
| Offline download management | ✅ | ✅ | ✅ | ✅ | ❌ |
| Native / browser fullscreen | ✅ | ✅ | ✅ | ✅ | ✅ |
| Controller commands | ✅ | ✅ | ✅ | ✅ | ✅ |

## Installation

### From pub.dev

Use this after the package has been published:

```yaml
dependencies:
  nirmaan_youtube_player: ^1.0.0
```

### From GitHub

Use this while testing a branch or before a pub.dev release:

```yaml
dependencies:
  nirmaan_youtube_player:
    git:
      url: https://github.com/Hemant88080/nirmaan_youtube_player.git
      ref: main
```

### From a local path

```yaml
dependencies:
  nirmaan_youtube_player:
    path: ../nirmaan_youtube_player
```

Then fetch packages:

```bash
flutter pub get
```

## Quick start

### 1. Initialise once

Call `NirmaanYoutubePlayer.initialize()` before `runApp()`. It prepares local storage and the offline download service.

```dart
import 'package:flutter/material.dart';
import 'package:nirmaan_youtube_player/nirmaan_youtube_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NirmaanYoutubePlayer.initialize();

  runApp(const MyApp());
}
```

### 2. Display a video

```dart
class LessonPlayer extends StatefulWidget {
  const LessonPlayer({super.key});

  @override
  State<LessonPlayer> createState() => _LessonPlayerState();
}

class _LessonPlayerState extends State<LessonPlayer> {
  final NirmaanYoutubeController _controller = NirmaanYoutubeController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: buildPlatformYoutubePlayer(
        url: 'https://www.youtube.com/watch?v=YOUR_VIDEO_ID',
        controller: _controller,
        autoPlay: false,
      ),
    );
  }
}
```

Supported URL formats:

```text
https://www.youtube.com/watch?v=VIDEO_ID
https://youtu.be/VIDEO_ID
https://www.youtube.com/embed/VIDEO_ID
https://www.youtube.com/shorts/VIDEO_ID
```

## Complete example application

A ready-to-add example app is available in [`example/lib/main.dart`](example/lib/main.dart).

The example demonstrates:

1. package initialisation;
2. online YouTube playback;
3. play, pause, mute, seek, and playback-speed controls;
4. downloading an authorised video for offline use;
5. switching automatically between online and local playback.

To run the example locally:

```bash
cd example
flutter create .
flutter pub get
flutter run
```

After Flutter creates the platform folders, apply the platform configuration below.

## Offline workflow

### Download an authorised video

`NirmaanDownloadService` returns the local MP4 path when a download completes. The path can be stored in your own lesson model or passed directly to the player.

```dart
final service = NirmaanYoutubePlayer.downloadService;

final localPath = await service.downloadYoutubeVideo(
  youtubeUrl: 'https://www.youtube.com/watch?v=YOUR_VIDEO_ID',
  lectureId: 'lesson-42',
  lectureIdInt: 42,
  courseId: 7,
  title: 'Introduction',
  courseTitle: 'Flutter Foundations',
  thumbnailUrl: 'https://example.com/lesson-42-thumbnail.jpg',
  duration: '15:30',
  onProgress: (progress) {
    debugPrint('Download: ${(progress * 100).toStringAsFixed(0)}%');
  },
);

if (localPath != null) {
  debugPrint('Saved to: $localPath');
}
```

### Play a saved video

Pass the returned local path to `localVideoPath`. When a non-null path is supplied, the package uses its local HTML5 player instead of the online YouTube player.

```dart
buildPlatformYoutubePlayer(
  url: 'https://www.youtube.com/watch?v=YOUR_VIDEO_ID',
  controller: _controller,
  autoPlay: true,
  localVideoPath: localPath,
);
```

### Manage saved videos

```dart
final service = NirmaanYoutubePlayer.downloadService;

final isDownloaded = service.hasDownloadedSync('lesson-42');
final savedPath = await service.getLocalPath('lesson-42');

service.cancelDownload('lesson-42');
await service.deleteDownload('lesson-42');

final downloads = await service.getAllDownloads();
```

> Downloads are stored in the application documents directory. The exact file location is platform-dependent and should be treated as app-managed storage.

## Player controls

```dart
final controller = NirmaanYoutubeController();

await controller.play();
await controller.pause();
await controller.togglePlayPause();

await controller.mute();
await controller.unMute();
await controller.toggleMute();

await controller.seekTo(const Duration(seconds: 90));
await controller.seekForward10();
await controller.seekBackward10();
await controller.setPlaybackRate(1.5);
```

Listen for player state changes with `ValueListenableBuilder`:

```dart
ValueListenableBuilder<NirmaanYoutubeValue>(
  valueListenable: controller,
  builder: (context, value, child) {
    final label = value.isPlaying ? 'Playing' : 'Paused';
    return Text('$label • ${value.position.inSeconds}s');
  },
)
```

## Platform configuration

The package uses a local loopback HTTP server on native platforms to serve the player page and local MP4 content. Complete the relevant setup once in the host application.

### Android

Add internet access and permit the app to load content from the local server.

**`android/app/src/main/AndroidManifest.xml`**

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>

    <application
        android:name="${applicationName}"
        android:label="your_app"
        android:icon="@mipmap/ic_launcher"
        android:networkSecurityConfig="@xml/network_security_config"
        android:usesCleartextTraffic="true">
        <!-- existing application configuration -->
    </application>
</manifest>
```

**`android/app/src/main/res/xml/network_security_config.xml`**

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="false">127.0.0.1</domain>
        <domain includeSubdomains="false">localhost</domain>
    </domain-config>
</network-security-config>
```

Use an Android `minSdk` of **19 or higher**.

### iOS

Add the following inside the root `<dict>` of **`ios/Runner/Info.plist`**:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>

<key>io.flutter.embedded_views_preview</key>
<true/>
```

Use an iOS deployment target of **12.0 or higher**.

### macOS

Add local-network access in both **`macos/Runner/DebugProfile.entitlements`** and **`macos/Runner/Release.entitlements`**:

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
```

Also add this inside the root `<dict>` in **`macos/Runner/Info.plist`**:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

Use a macOS deployment target of **10.14 or higher**.

### Windows

No code configuration is required. The machine running the app must have the Microsoft Edge **WebView2 Runtime** available.

### Web

No extra configuration is needed for online playback. Local-file playback and download management are not supported in browsers.

## Customisation

### Offline-player icons

Replace any of the offline control icons using inline SVG or an image URL:

```dart
buildPlatformYoutubePlayer(
  url: 'https://www.youtube.com/watch?v=YOUR_VIDEO_ID',
  controller: _controller,
  autoPlay: false,
  offlineIcons: NirmaanPlayerIcons(
    play: NirmaanPlayerIcon.svg('<svg viewBox="0 0 24 24">...</svg>'),
    pause: NirmaanPlayerIcon.svg('<svg viewBox="0 0 24 24">...</svg>'),
    fullscreen: NirmaanPlayerIcon.image(
      'https://example.com/icons/fullscreen.png',
    ),
  ),
);
```

### Advanced HTML configuration

For full control over the HTML player output, use `NirmaanYoutubeHtmlConfig` with `buildNirmaanYoutubeHtml()`:

```dart
final html = buildNirmaanYoutubeHtml(
  NirmaanYoutubeHtmlConfig(
    videoId: 'YOUR_VIDEO_ID',
    autoPlay: false,
    sourceName: 'my-app',
    bridgeType: NirmaanYoutubeBridgeType.inAppWebView,
    fullscreenType: NirmaanYoutubeFullscreenType.nativeFlutter,
    brandText: 'My Academy',
    courseTitle: 'Flutter Foundations',
    showWatermark: true,
    watermarkText: 'INTERNAL USE',
    accentColor: '#FF6B6B',
    borderRadius: 12,
  ),
);
```

## Public API

| API | Purpose |
|---|---|
| `NirmaanYoutubePlayer.initialize()` | Initialises the package once before `runApp()`. |
| `NirmaanYoutubePlayer.downloadService` | Accesses the shared download service. |
| `buildPlatformYoutubePlayer(...)` | Builds the correct player implementation for the current platform. |
| `NirmaanYoutubeController` | Sends playback commands and exposes `NirmaanYoutubeValue`. |
| `NirmaanDownloadService` | Starts, tracks, cancels, lists, and removes offline downloads. |
| `OfflineLecture` | Model for persisted offline-video metadata. |
| `extractYoutubeVideoId(url)` | Extracts a YouTube video ID from a supported URL format. |
| `NirmaanPlayerIcons` | Replaces selected offline-player icons. |
| `NirmaanYoutubeHtmlConfig` | Configures the advanced HTML player builder. |

## Troubleshooting

### The player is blank on Android

Confirm that `INTERNET`, `usesCleartextTraffic`, and `network_security_config.xml` are present. Then run:

```bash
flutter clean
flutter pub get
flutter run
```

### The player is blank on iOS or macOS

Confirm that `NSAllowsLocalNetworking` is included in `Info.plist`. On macOS, also confirm that both client and server network entitlements are enabled.

### Windows shows a WebView2 error

Install or update the Microsoft Edge WebView2 Runtime, then restart the application.

### Offline playback does not start

Check that the local file still exists:

```dart
final path = await NirmaanYoutubePlayer.downloadService.getLocalPath('lesson-42');
debugPrint(path ?? 'File is not available');
```

### A download fails

Confirm that the URL is valid, the device has network access, and you are authorised to download the content. Availability may vary according to the source, the video's own restrictions, and the platform.

## Development

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
dart pub publish --dry-run
```

## Issues and contributions

Please report reproducible issues through the [GitHub issue tracker](https://github.com/Hemant88080/nirmaan_youtube_player/issues). Include the Flutter version, target platform, steps to reproduce, expected behaviour, and relevant logs.

## License

BSD 3-Clause License. See [LICENSE](LICENSE).
