// lib/custom_library/youtube_video_player/nirmaan_youtube_html.dart

import 'dart:convert';

import 'nirmaan_player_icons.dart';

enum NirmaanYoutubeBridgeType { inAppWebView, webPostMessage }

enum NirmaanYoutubeFullscreenType { nativeFlutter, browser }

enum NirmaanYoutubeFitMode { contain, cover }

class NirmaanYoutubeHtmlConfig {
  final String videoId;
  final bool autoPlay;

  /// Example:
  /// nirmaan-youtube-web
  /// nirmaan-youtube-windows
  /// nirmaan-youtube-mobile-macos
  final String sourceName;

  final NirmaanYoutubeBridgeType bridgeType;
  final NirmaanYoutubeFullscreenType fullscreenType;

  /// Video display mode.
  /// contain = safe YouTube default, no crop.
  /// cover = tries to fill more screen area.
  final NirmaanYoutubeFitMode fitMode;

  /// Branding / labels.
  final String brandText;
  final String courseTitle;
  final String watermarkText;

  /// Slots where you can inject simple HTML.
  final String topLeftSlotHtml;
  final String topRightSlotHtml;
  final String bottomLeftSlotHtml;
  final String bottomRightSlotHtml;

  /// UI visibility controls.
  final bool showTopBar;
  final bool showBrand;
  final bool showWatermark;
  final bool showCenterPlayButton;
  final bool showSeekButtons;
  final bool showBottomControls;
  final bool showProgressBar;
  final bool showDuration;
  final bool showMuteButton;
  final bool showSpeedButton;
  final bool showFullscreenButton;
  final bool showDoubleTapSeekOverlay;

  /// Behaviour.
  final int autoHideControlsMs;
  final int seekStepSeconds;
  final bool enableKeyboardShortcuts;
  final bool enableDoubleTapSeek;
  final bool enableTapToToggleControls;

  /// Styling.
  final String accentColor;
  final String backgroundColor;
  final String controlsBackgroundColor;
  final String textColor;
  final String mutedTextColor;
  final double borderRadius;

  /// Advanced injection.
  final String customCss;
  final String customJs;

  /// Swappable icons (SVG or image). Defaults reproduce the current UI exactly.
  final NirmaanPlayerIcons icons;

  const NirmaanYoutubeHtmlConfig({
    required this.videoId,
    required this.autoPlay,
    required this.sourceName,
    required this.bridgeType,
    required this.fullscreenType,
    this.fitMode = NirmaanYoutubeFitMode.contain,
    this.brandText = 'Nirmaan Academy',
    this.courseTitle = '',
    this.watermarkText = '',
    this.topLeftSlotHtml = '',
    this.topRightSlotHtml = '',
    this.bottomLeftSlotHtml = '',
    this.bottomRightSlotHtml = '',
    this.showTopBar = true,
    this.showBrand = true,
    this.showWatermark = false,
    this.showCenterPlayButton = true,
    this.showSeekButtons = true,
    this.showBottomControls = true,
    this.showProgressBar = true,
    this.showDuration = true,
    this.showMuteButton = true,
    this.showSpeedButton = true,
    this.showFullscreenButton = true,
    this.showDoubleTapSeekOverlay = true,
    this.autoHideControlsMs = 3000,
    this.seekStepSeconds = 10,
    this.enableKeyboardShortcuts = true,
    this.enableDoubleTapSeek = true,
    this.enableTapToToggleControls = true,
    this.accentColor = '#6C63FF',
    this.backgroundColor = '#000000',
    this.controlsBackgroundColor = 'rgba(10,10,14,0.72)',
    this.textColor = '#FFFFFF',
    this.mutedTextColor = 'rgba(255,255,255,0.72)',
    this.borderRadius = 0,
    this.customCss = '',
    this.customJs = '',
    this.icons = const NirmaanPlayerIcons(),
  });
}

String buildNirmaanYoutubeHtml(NirmaanYoutubeHtmlConfig config) {
  final encodedVideoId = jsonEncode(config.videoId);
  final encodedAutoPlay = config.autoPlay ? 'true' : 'false';
  final encodedSource = jsonEncode(config.sourceName);
  final encodedBrandText = jsonEncode(config.brandText);

  // Swappable icon HTML — each is SVG (default) or <img>. jsonEncode keeps it
  // a safe single-line JS string literal.
  final iconPlay = jsonEncode(config.icons.playHtml);
  final iconPause = jsonEncode(config.icons.pauseHtml);
  final iconRewind = jsonEncode(config.icons.rewindHtml);
  final iconForward = jsonEncode(config.icons.forwardHtml);
  final iconMute = jsonEncode(config.icons.muteHtml);
  final iconVolume = jsonEncode(config.icons.volumeHtml);
  final iconFullscreen = jsonEncode(config.icons.fullscreenHtml);
  final iconExitFullscreen = jsonEncode(config.icons.exitFullscreenHtml);
  final encodedCourseTitle = jsonEncode(config.courseTitle);
  final encodedWatermarkText = jsonEncode(config.watermarkText);

  final fitMode = config.fitMode == NirmaanYoutubeFitMode.cover
      ? 'cover'
      : 'contain';

  final showTopBar = config.showTopBar ? 'true' : 'false';
  final showBrand = config.showBrand ? 'true' : 'false';
  final showWatermark = config.showWatermark ? 'true' : 'false';
  final showCenterPlayButton = config.showCenterPlayButton ? 'true' : 'false';
  final showSeekButtons = config.showSeekButtons ? 'true' : 'false';
  final showBottomControls = config.showBottomControls ? 'true' : 'false';
  final showProgressBar = config.showProgressBar ? 'true' : 'false';
  final showDuration = config.showDuration ? 'true' : 'false';
  final showMuteButton = config.showMuteButton ? 'true' : 'false';
  final showSpeedButton = config.showSpeedButton ? 'true' : 'false';
  final showFullscreenButton = config.showFullscreenButton ? 'true' : 'false';
  final showDoubleTapSeekOverlay = config.showDoubleTapSeekOverlay
      ? 'true'
      : 'false';
  final enableKeyboardShortcuts = config.enableKeyboardShortcuts
      ? 'true'
      : 'false';
  final enableDoubleTapSeek = config.enableDoubleTapSeek ? 'true' : 'false';
  final enableTapToToggleControls = config.enableTapToToggleControls
      ? 'true'
      : 'false';

  final topLeftSlotHtml = config.topLeftSlotHtml.trim().isEmpty
      ? ''
      : config.topLeftSlotHtml;
  final topRightSlotHtml = config.topRightSlotHtml.trim().isEmpty
      ? ''
      : config.topRightSlotHtml;
  final bottomLeftSlotHtml = config.bottomLeftSlotHtml.trim().isEmpty
      ? ''
      : config.bottomLeftSlotHtml;
  final bottomRightSlotHtml = config.bottomRightSlotHtml.trim().isEmpty
      ? ''
      : config.bottomRightSlotHtml;

  final sendStateJs = config.bridgeType == NirmaanYoutubeBridgeType.inAppWebView
      ? '''
        function sendToFlutter(data) {
          try {
            data.source = SOURCE_NAME;
            if (window.flutter_inappwebview) {
              window.flutter_inappwebview.callHandler(
                'nirmaanState',
                JSON.stringify(data)
              );
            }
          } catch (e) {}
        }
      '''
      : '''
        function sendToFlutter(data) {
          try {
            data.source = SOURCE_NAME;
            parent.postMessage(JSON.stringify(data), '*');
          } catch (e) {}
        }
      ''';

  final receiveCommandJs =
      config.bridgeType == NirmaanYoutubeBridgeType.inAppWebView
      ? '''
        window.nirmaanCommand = function(data) {
          handleCommand(data);
        };
      '''
      : '''
        window.addEventListener('message', function(event) {
          var data = event.data;

          try {
            if (typeof data === 'string') {
              data = JSON.parse(data);
            }

            if (!data || data.source !== 'nirmaan-parent') return;

            handleCommand(data);
          } catch (e) {}
        });
      ''';

  final fullscreenJs =
      config.fullscreenType == NirmaanYoutubeFullscreenType.nativeFlutter
      ? '''
        function requestFullscreenToggle() {
          try {
            if (window.flutter_inappwebview) {
              window.flutter_inappwebview.callHandler(
                'nirmaanFullscreen',
                'toggle'
              );
            }
          } catch (e) {}
        }

        window.nirmaanSetFullscreen = function(isFullscreen) {
          state.isFullscreen = !!isFullscreen;
          root.classList.toggle('is-fullscreen', state.isFullscreen);
          fullscreenBtn.innerHTML = state.isFullscreen ? ICON_EXIT_FULLSCREEN : ICON_FULLSCREEN;
          showControlsTemp();
        };
      '''
      : '''
        function isBrowserFullscreen() {
          return document.fullscreenElement === root ||
                 document.webkitFullscreenElement === root ||
                 document.msFullscreenElement === root;
        }

        function enterBrowserFullscreen() {
          if (root.requestFullscreen) {
            root.requestFullscreen();
          } else if (root.webkitRequestFullscreen) {
            root.webkitRequestFullscreen();
          } else if (root.msRequestFullscreen) {
            root.msRequestFullscreen();
          }
        }

        function exitBrowserFullscreen() {
          if (document.exitFullscreen) {
            document.exitFullscreen();
          } else if (document.webkitExitFullscreen) {
            document.webkitExitFullscreen();
          } else if (document.msExitFullscreen) {
            document.msExitFullscreen();
          }
        }

        function requestFullscreenToggle() {
          if (isBrowserFullscreen()) {
            exitBrowserFullscreen();
          } else {
            enterBrowserFullscreen();
          }
        }

        function updateFullscreenButton() {
          state.isFullscreen = isBrowserFullscreen();
          root.classList.toggle('is-fullscreen', state.isFullscreen);
          fullscreenBtn.innerHTML = state.isFullscreen ? ICON_EXIT_FULLSCREEN : ICON_FULLSCREEN;
          sendState();
          showControlsTemp();
        }

        document.addEventListener('fullscreenchange', updateFullscreenButton);
        document.addEventListener('webkitfullscreenchange', updateFullscreenButton);
        document.addEventListener('msfullscreenchange', updateFullscreenButton);
      ''';

  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="referrer" content="strict-origin-when-cross-origin">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">

  <style>
    :root {
      --accent: ${config.accentColor};
      --bg: ${config.backgroundColor};
      --control-bg: ${config.controlsBackgroundColor};
      --text: ${config.textColor};
      --muted-text: ${config.mutedTextColor};
      --radius: ${config.borderRadius}px;
      --safe-top: env(safe-area-inset-top, 0px);
      --safe-bottom: env(safe-area-inset-bottom, 0px);
      --safe-left: env(safe-area-inset-left, 0px);
      --safe-right: env(safe-area-inset-right, 0px);
    }

    * {
      box-sizing: border-box;
      -webkit-tap-highlight-color: transparent;
    }

    html,
    body {
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100%;
      min-width: 100%;
      min-height: 100%;
      background: var(--bg);
      overflow: hidden;
      font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
      user-select: none;
      -webkit-user-select: none;
      touch-action: manipulation;
    }

    body {
      position: fixed;
      inset: 0;
    }

    #root {
      position: fixed;
      inset: 0;
      width: 100vw;
      height: 100vh;
      background: var(--bg);
      overflow: hidden;
      border-radius: var(--radius);
      color: var(--text);
    }

    #root.is-fullscreen {
      border-radius: 0;
    }

    #playerWrap {
      position: absolute;
      inset: 0;
      z-index: 1;
      overflow: hidden;
      background: #000;
    }

    #player {
      position: absolute;
      inset: 0;
      width: 100%;
      height: 100%;
      background: #000;
    }

    #player iframe {
      width: 100% !important;
      height: 100% !important;
      border: 0 !important;
      pointer-events: none !important;
      background: #000 !important;
    }

    #root.fit-cover #player {
      width: 100vw;
      height: 56.25vw;
      min-height: 100vh;
      min-width: 177.78vh;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
    }

    #tapLayer {
      position: absolute;
      inset: 0;
      z-index: 6;
      display: flex;
    }

    .tapZone {
      flex: 1;
      height: 100%;
    }

    #shadeLayer {
      position: absolute;
      inset: 0;
      z-index: 4;
      pointer-events: none;
      background:
        linear-gradient(to bottom, rgba(0,0,0,.58), transparent 28%, transparent 58%, rgba(0,0,0,.78)),
        radial-gradient(circle at center, rgba(0,0,0,.05), rgba(0,0,0,.28));
      opacity: 1;
      transition: opacity .22s ease;
    }

    #topBar {
      position: absolute;
      left: 0;
      right: 0;
      top: 0;
      z-index: 12;
      padding: calc(12px + var(--safe-top)) calc(14px + var(--safe-right)) 26px calc(14px + var(--safe-left));
      display: flex;
      align-items: flex-start;
      justify-content: space-between;
      gap: 12px;
      pointer-events: none;
      transition: opacity .22s ease, transform .22s ease;
    }

    .topGroup {
      min-width: 0;
      display: flex;
      align-items: center;
      gap: 10px;
      pointer-events: auto;
    }

    #brandPill {
      min-width: 0;
      max-width: min(60vw, 520px);
      padding: 8px 12px;
      border-radius: 999px;
      background: rgba(0,0,0,.45);
      border: 1px solid rgba(255,255,255,.13);
      backdrop-filter: blur(14px);
      -webkit-backdrop-filter: blur(14px);
      display: flex;
      align-items: center;
      gap: 8px;
      box-shadow: 0 10px 35px rgba(0,0,0,.18);
    }

    #brandDot {
      width: 8px;
      height: 8px;
      border-radius: 99px;
      background: var(--accent);
      flex: 0 0 auto;
      box-shadow: 0 0 0 4px rgba(108,99,255,.18);
    }

    #brandTextWrap {
      min-width: 0;
      display: flex;
      flex-direction: column;
      gap: 1px;
    }

    #brandText {
      color: var(--text);
      font-size: 12px;
      line-height: 1.15;
      font-weight: 900;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    #courseTitle {
      display: none;
      color: var(--muted-text);
      font-size: 10.5px;
      line-height: 1.15;
      font-weight: 700;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    #courseTitle.has-title {
      display: block;
    }

    .slot {
      min-width: 0;
      color: var(--text);
      font-size: 12px;
      font-weight: 800;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    #centerPlay {
      position: absolute;
      left: 50%;
      top: 50%;
      z-index: 11;
      transform: translate(-50%, -50%) scale(1);
      width: clamp(58px, 12vw, 88px);
      height: clamp(58px, 12vw, 88px);
      border-radius: 999px;
      border: 1px solid rgba(255,255,255,.18);
      background: rgba(0,0,0,.52);
      backdrop-filter: blur(18px);
      -webkit-backdrop-filter: blur(18px);
      display: grid;
      place-items: center;
      color: var(--text);
      cursor: pointer;
      pointer-events: auto;
      transition: opacity .2s ease, transform .2s ease, background .2s ease;
      box-shadow: 0 18px 55px rgba(0,0,0,.38);
    }

    #centerPlay:active {
      transform: translate(-50%, -50%) scale(.96);
    }

    #centerPlay svg {
      width: 46%;
      height: 46%;
    }

    #seekToast {
      position: absolute;
      left: 50%;
      top: 50%;
      z-index: 13;
      transform: translate(-50%, -50%);
      padding: 10px 16px;
      border-radius: 999px;
      color: var(--text);
      background: rgba(0,0,0,.72);
      border: 1px solid rgba(255,255,255,.14);
      font-size: 13px;
      font-weight: 900;
      opacity: 0;
      pointer-events: none;
      transition: opacity .16s ease, transform .16s ease;
      backdrop-filter: blur(14px);
      -webkit-backdrop-filter: blur(14px);
    }

    #seekToast.show {
      opacity: 1;
      transform: translate(-50%, -50%) scale(1.03);
    }

    #bottomBar {
      position: absolute;
      left: 0;
      right: 0;
      bottom: 0;
      z-index: 12;
      padding: 18px calc(14px + var(--safe-right)) calc(12px + var(--safe-bottom)) calc(14px + var(--safe-left));
      pointer-events: none;
      transition: opacity .22s ease, transform .22s ease;
    }

    #bottomPanel {
      width: 100%;
      max-width: 1180px;
      margin: 0 auto;
      padding: 10px 12px 11px;
      border-radius: 22px;
      background: var(--control-bg);
      border: 1px solid rgba(255,255,255,.12);
      box-shadow: 0 16px 55px rgba(0,0,0,.30);
      backdrop-filter: blur(18px);
      -webkit-backdrop-filter: blur(18px);
      pointer-events: auto;
    }

    #progressWrap {
      width: 100%;
      height: 18px;
      display: flex;
      align-items: center;
      cursor: pointer;
      touch-action: none;
    }

    #progressTrack {
      position: relative;
      width: 100%;
      height: 4px;
      border-radius: 99px;
      background: rgba(255,255,255,.25);
      overflow: hidden;
    }

    #bufferBar,
    #progressBar {
      position: absolute;
      left: 0;
      top: 0;
      bottom: 0;
      width: 0%;
      border-radius: inherit;
    }

    #bufferBar {
      background: rgba(255,255,255,.34);
    }

    #progressBar {
      background: var(--accent);
    }

    #progressKnob {
      position: absolute;
      top: 50%;
      left: 0%;
      width: 12px;
      height: 12px;
      border-radius: 99px;
      background: #fff;
      transform: translate(-50%, -50%) scale(0);
      box-shadow: 0 0 0 5px rgba(108,99,255,.20);
      transition: transform .16s ease;
    }

    #progressWrap:hover #progressKnob,
    #progressWrap.dragging #progressKnob {
      transform: translate(-50%, -50%) scale(1);
    }

    #controlsRow {
      min-height: 38px;
      display: flex;
      align-items: center;
      gap: 7px;
      margin-top: 3px;
    }

    .controlBtn {
      width: 38px;
      height: 38px;
      border: 0;
      outline: 0;
      border-radius: 999px;
      display: inline-grid;
      place-items: center;
      color: var(--text);
      background: rgba(255,255,255,.08);
      cursor: pointer;
      transition: background .16s ease, transform .16s ease;
      flex: 0 0 auto;
    }

    .controlBtn:hover {
      background: rgba(255,255,255,.16);
    }

    .controlBtn:active {
      transform: scale(.94);
    }

    .controlBtn.primary {
      width: 42px;
      height: 42px;
      background: var(--accent);
      color: white;
      box-shadow: 0 12px 26px rgba(108,99,255,.30);
    }

    .controlBtn svg {
      width: 19px;
      height: 19px;
      display: block;
    }

    .controlBtn.primary svg {
      width: 22px;
      height: 22px;
    }

    #timeText {
      color: var(--text);
      font-size: 12px;
      font-weight: 800;
      white-space: nowrap;
      min-width: 92px;
      letter-spacing: .1px;
    }

    #leftControls,
    #rightControls {
      display: flex;
      align-items: center;
      gap: 7px;
      min-width: 0;
    }

    #rightControls {
      margin-left: auto;
    }

    #speedMenuWrap {
      position: relative;
      flex: 0 0 auto;
    }

    #speedBtn {
      min-width: 54px;
      width: auto;
      padding: 0 11px;
      font-size: 12px;
      font-weight: 900;
    }

    #speedMenu {
      position: absolute;
      right: 0;
      bottom: 48px;
      width: 96px;
      padding: 6px;
      border-radius: 16px;
      background: rgba(13,13,18,.94);
      border: 1px solid rgba(255,255,255,.12);
      box-shadow: 0 16px 45px rgba(0,0,0,.35);
      display: none;
      backdrop-filter: blur(18px);
      -webkit-backdrop-filter: blur(18px);
    }

    #speedMenu.show {
      display: block;
    }

    .speedItem {
      width: 100%;
      height: 32px;
      border: 0;
      outline: 0;
      border-radius: 11px;
      background: transparent;
      color: var(--text);
      cursor: pointer;
      font-size: 12px;
      font-weight: 800;
      text-align: left;
      padding: 0 10px;
    }

    .speedItem.active,
    .speedItem:hover {
      background: rgba(108,99,255,.20);
      color: white;
    }

    #watermark {
      position: absolute;
      right: calc(18px + var(--safe-right));
      top: 50%;
      z-index: 3;
      transform: translateY(-50%);
      color: rgba(255,255,255,.18);
      font-size: clamp(12px, 2vw, 18px);
      font-weight: 900;
      letter-spacing: .08em;
      text-transform: uppercase;
      pointer-events: none;
      white-space: nowrap;
    }

    #loadingLayer {
      position: absolute;
      inset: 0;
      z-index: 20;
      display: grid;
      place-items: center;
      background: #000;
      color: white;
      transition: opacity .24s ease;
      pointer-events: none;
    }

    #loader {
      width: 42px;
      height: 42px;
      border-radius: 99px;
      border: 3px solid rgba(255,255,255,.20);
      border-top-color: var(--accent);
      animation: spin .82s linear infinite;
    }

    @keyframes spin {
      to { transform: rotate(360deg); }
    }

    #root.controls-hidden #shadeLayer {
      opacity: 0;
    }

    #root.controls-hidden #topBar {
      opacity: 0;
      transform: translateY(-10px);
      pointer-events: none;
    }

    #root.controls-hidden #bottomBar {
      opacity: 0;
      transform: translateY(12px);
      pointer-events: none;
    }

    #root.controls-hidden #centerPlay {
      opacity: 0;
      pointer-events: none;
      transform: translate(-50%, -50%) scale(.92);
    }

    .hidden-by-config {
      display: none !important;
    }

    @media (max-width: 720px) {
      #topBar {
        padding-top: calc(10px + var(--safe-top));
        padding-left: calc(10px + var(--safe-left));
        padding-right: calc(10px + var(--safe-right));
      }

      #brandPill {
        max-width: 70vw;
        padding: 7px 10px;
      }

      #brandText {
        font-size: 11px;
      }

      #courseTitle {
        font-size: 9.5px;
      }

      #bottomBar {
        padding-left: calc(8px + var(--safe-left));
        padding-right: calc(8px + var(--safe-right));
        padding-bottom: calc(8px + var(--safe-bottom));
      }

      #bottomPanel {
        padding: 8px 9px 9px;
        border-radius: 18px;
      }

      #controlsRow {
        gap: 5px;
      }

      .controlBtn {
        width: 34px;
        height: 34px;
      }

      .controlBtn.primary {
        width: 38px;
        height: 38px;
      }

      #timeText {
        min-width: auto;
        font-size: 11px;
      }

      #speedBtn {
        min-width: 48px;
        padding: 0 8px;
      }

      #rewindBtn,
      #forwardBtn {
        display: none;
      }
    }

    @media (max-width: 430px) {
      #brandPill {
        max-width: 58vw;
      }

      #timeText {
        display: none;
      }

      #muteBtn {
        display: none;
      }

      #bottomLeftSlot,
      #bottomRightSlot {
        display: none;
      }
    }

    @media (orientation: landscape) and (max-height: 430px) {
      #topBar {
        padding-top: calc(7px + var(--safe-top));
        padding-bottom: 10px;
      }

      #bottomBar {
        padding-bottom: calc(6px + var(--safe-bottom));
      }

      #bottomPanel {
        padding: 6px 8px 7px;
        border-radius: 16px;
      }

      #controlsRow {
        min-height: 32px;
      }

      .controlBtn {
        width: 32px;
        height: 32px;
      }

      .controlBtn.primary {
        width: 36px;
        height: 36px;
      }

      #centerPlay {
        width: 58px;
        height: 58px;
      }
    }

    ${config.customCss}
  </style>
</head>

<body>
  <div id="root" class="fit-$fitMode">
    <div id="playerWrap">
      <div id="player"></div>
    </div>

    <div id="shadeLayer"></div>

    <div id="watermark"></div>

    <div id="topBar">
      <div class="topGroup">
        <div id="brandPill">
          <span id="brandDot"></span>
          <span id="brandTextWrap">
            <span id="brandText"></span>
            <span id="courseTitle"></span>
          </span>
        </div>
        <div id="topLeftSlot" class="slot">$topLeftSlotHtml</div>
      </div>

      <div class="topGroup">
        <div id="topRightSlot" class="slot">$topRightSlotHtml</div>
      </div>
    </div>

    <button id="centerPlay" type="button" aria-label="Play or pause"></button>

    <div id="seekToast"></div>

    <div id="tapLayer">
      <div id="tapLeft" class="tapZone"></div>
      <div id="tapCenter" class="tapZone"></div>
      <div id="tapRight" class="tapZone"></div>
    </div>

    <div id="bottomBar">
      <div id="bottomPanel">
        <div id="progressWrap">
          <div id="progressTrack">
            <div id="bufferBar"></div>
            <div id="progressBar"></div>
            <div id="progressKnob"></div>
          </div>
        </div>

        <div id="controlsRow">
          <div id="leftControls">
            <button id="rewindBtn" class="controlBtn" type="button" aria-label="Back"></button>
            <button id="playBtn" class="controlBtn primary" type="button" aria-label="Play or pause"></button>
            <button id="forwardBtn" class="controlBtn" type="button" aria-label="Forward"></button>
            <span id="timeText">00:00 / 00:00</span>
            <div id="bottomLeftSlot" class="slot">$bottomLeftSlotHtml</div>
          </div>

          <div id="rightControls">
            <div id="bottomRightSlot" class="slot">$bottomRightSlotHtml</div>
            <button id="muteBtn" class="controlBtn" type="button" aria-label="Mute"></button>

            <div id="speedMenuWrap">
              <button id="speedBtn" class="controlBtn" type="button">1x</button>
              <div id="speedMenu">
                <button class="speedItem active" data-speed="1">1x</button>
                <button class="speedItem" data-speed="1.25">1.25x</button>
                <button class="speedItem" data-speed="1.5">1.5x</button>
                <button class="speedItem" data-speed="2">2x</button>
                <button class="speedItem" data-speed="3">3x</button>
              </div>
            </div>

            <button id="fullscreenBtn" class="controlBtn" type="button" aria-label="Fullscreen"></button>
          </div>
        </div>
      </div>
    </div>

    <div id="loadingLayer">
      <div id="loader"></div>
    </div>
  </div>

  <script>
    var VIDEO_ID = $encodedVideoId;
    var AUTO_PLAY = $encodedAutoPlay;
    var SOURCE_NAME = $encodedSource;

    var BRAND_TEXT = $encodedBrandText;
    var COURSE_TITLE = $encodedCourseTitle;
    var WATERMARK_TEXT = $encodedWatermarkText;

    var SHOW_TOP_BAR = $showTopBar;
    var SHOW_BRAND = $showBrand;
    var SHOW_WATERMARK = $showWatermark;
    var SHOW_CENTER_PLAY = $showCenterPlayButton;
    var SHOW_SEEK_BUTTONS = $showSeekButtons;
    var SHOW_BOTTOM_CONTROLS = $showBottomControls;
    var SHOW_PROGRESS = $showProgressBar;
    var SHOW_DURATION = $showDuration;
    var SHOW_MUTE = $showMuteButton;
    var SHOW_SPEED = $showSpeedButton;
    var SHOW_FULLSCREEN = $showFullscreenButton;
    var SHOW_DOUBLE_TAP_TOAST = $showDoubleTapSeekOverlay;

    var AUTO_HIDE_MS = ${config.autoHideControlsMs};
    var SEEK_STEP = ${config.seekStepSeconds};
    var ENABLE_KEYBOARD = $enableKeyboardShortcuts;
    var ENABLE_DOUBLE_TAP = $enableDoubleTapSeek;
    var ENABLE_TAP_TOGGLE = $enableTapToToggleControls;

    var root = document.getElementById('root');
    var playerWrap = document.getElementById('playerWrap');
    var loadingLayer = document.getElementById('loadingLayer');
    var topBar = document.getElementById('topBar');
    var brandPill = document.getElementById('brandPill');
    var brandText = document.getElementById('brandText');
    var courseTitle = document.getElementById('courseTitle');
    var watermark = document.getElementById('watermark');
    var centerPlay = document.getElementById('centerPlay');
    var playBtn = document.getElementById('playBtn');
    var rewindBtn = document.getElementById('rewindBtn');
    var forwardBtn = document.getElementById('forwardBtn');
    var muteBtn = document.getElementById('muteBtn');
    var speedBtn = document.getElementById('speedBtn');
    var speedMenu = document.getElementById('speedMenu');
    var fullscreenBtn = document.getElementById('fullscreenBtn');
    var bottomBar = document.getElementById('bottomBar');
    var progressWrap = document.getElementById('progressWrap');
    var progressTrack = document.getElementById('progressTrack');
    var progressBar = document.getElementById('progressBar');
    var bufferBar = document.getElementById('bufferBar');
    var progressKnob = document.getElementById('progressKnob');
    var timeText = document.getElementById('timeText');
    var seekToast = document.getElementById('seekToast');
    var tapLeft = document.getElementById('tapLeft');
    var tapCenter = document.getElementById('tapCenter');
    var tapRight = document.getElementById('tapRight');

    var ICON_PLAY = $iconPlay;
    var ICON_PAUSE = $iconPause;
    var ICON_REWIND = $iconRewind;
    var ICON_FORWARD = $iconForward;
    var ICON_MUTE = $iconMute;
    var ICON_VOLUME = $iconVolume;
    var ICON_FULLSCREEN = $iconFullscreen;
    var ICON_EXIT_FULLSCREEN = $iconExitFullscreen;

    var player = null;
    var hideTimer = null;
    var progressTimer = null;
    var seekToastTimer = null;
    var isDragging = false;
    var lastTapAt = 0;

    var state = {
      isReady: false,
      isPlaying: false,
      isMuted: false,
      isFullscreen: false,
      position: 0,
      duration: 0,
      playbackRate: 1,
      loadedFraction: 0
    };

    $sendStateJs

    $receiveCommandJs

    $fullscreenJs

    function applyConfigVisibility() {
      rewindBtn.innerHTML = ICON_REWIND;
      forwardBtn.innerHTML = ICON_FORWARD;
      brandText.textContent = BRAND_TEXT || 'Nirmaan Academy';

      if (COURSE_TITLE && COURSE_TITLE.trim().length > 0) {
        courseTitle.textContent = COURSE_TITLE;
        courseTitle.classList.add('has-title');
      }

      if (WATERMARK_TEXT && WATERMARK_TEXT.trim().length > 0) {
        watermark.textContent = WATERMARK_TEXT;
      }

      if (!SHOW_TOP_BAR) topBar.classList.add('hidden-by-config');
      if (!SHOW_BRAND) brandPill.classList.add('hidden-by-config');
      if (!SHOW_WATERMARK) watermark.classList.add('hidden-by-config');
      if (!SHOW_CENTER_PLAY) centerPlay.classList.add('hidden-by-config');
      if (!SHOW_SEEK_BUTTONS) {
        rewindBtn.classList.add('hidden-by-config');
        forwardBtn.classList.add('hidden-by-config');
      }
      if (!SHOW_BOTTOM_CONTROLS) bottomBar.classList.add('hidden-by-config');
      if (!SHOW_PROGRESS) progressWrap.classList.add('hidden-by-config');
      if (!SHOW_DURATION) timeText.classList.add('hidden-by-config');
      if (!SHOW_MUTE) muteBtn.classList.add('hidden-by-config');
      if (!SHOW_SPEED) document.getElementById('speedMenuWrap').classList.add('hidden-by-config');
      if (!SHOW_FULLSCREEN) fullscreenBtn.classList.add('hidden-by-config');
    }

    function formatTime(seconds) {
      seconds = Math.max(0, Math.floor(seconds || 0));

      var h = Math.floor(seconds / 3600);
      var m = Math.floor((seconds % 3600) / 60);
      var s = seconds % 60;

      function pad(v) {
        return v < 10 ? '0' + v : '' + v;
      }

      if (h > 0) {
        return h + ':' + pad(m) + ':' + pad(s);
      }

      return pad(m) + ':' + pad(s);
    }

    function sendState() {
      sendToFlutter({
        event: 'state',
        isReady: state.isReady,
        isPlaying: state.isPlaying,
        isMuted: state.isMuted,
        isFullscreen: state.isFullscreen,
        positionSeconds: Math.floor(state.position || 0),
        durationSeconds: Math.floor(state.duration || 0),
        playbackRate: state.playbackRate || 1
      });
    }

    function updateUi() {
      playBtn.innerHTML = state.isPlaying ? ICON_PAUSE : ICON_PLAY;
      centerPlay.innerHTML = state.isPlaying ? ICON_PAUSE : ICON_PLAY;
      muteBtn.innerHTML = state.isMuted ? ICON_MUTE : ICON_VOLUME;
      fullscreenBtn.innerHTML = state.isFullscreen ? ICON_EXIT_FULLSCREEN : ICON_FULLSCREEN;

      var duration = state.duration || 0;
      var position = state.position || 0;
      var loadedFraction = state.loadedFraction || 0;

      var percent = duration > 0 ? Math.max(0, Math.min(100, (position / duration) * 100)) : 0;
      var loadedPercent = Math.max(0, Math.min(100, loadedFraction * 100));

      progressBar.style.width = percent + '%';
      progressKnob.style.left = percent + '%';
      bufferBar.style.width = loadedPercent + '%';

      timeText.textContent = formatTime(position) + ' / ' + formatTime(duration);
      speedBtn.textContent = formatSpeed(state.playbackRate || 1) + 'x';

      var items = document.querySelectorAll('.speedItem');
      for (var i = 0; i < items.length; i++) {
        var speed = parseFloat(items[i].getAttribute('data-speed'));
        if (Math.abs(speed - state.playbackRate) < 0.01) {
          items[i].classList.add('active');
        } else {
          items[i].classList.remove('active');
        }
      }
    }

    function formatSpeed(speed) {
      speed = Number(speed || 1);
      return Number.isInteger(speed) ? String(speed) : String(speed);
    }

    function showControlsTemp() {
      root.classList.remove('controls-hidden');

      if (hideTimer) {
        clearTimeout(hideTimer);
      }

      if (!state.isPlaying) return;

      hideTimer = setTimeout(function() {
        if (state.isPlaying && !isDragging && !speedMenu.classList.contains('show')) {
          root.classList.add('controls-hidden');
        }
      }, AUTO_HIDE_MS);
    }

    function forceShowControls() {
      root.classList.remove('controls-hidden');
      if (hideTimer) clearTimeout(hideTimer);
    }

    function hideLoading() {
      loadingLayer.style.opacity = '0';
      setTimeout(function() {
        loadingLayer.style.display = 'none';
      }, 280);
    }

    function playVideo() {
      if (!player || !state.isReady) return;
      player.playVideo();
      state.isPlaying = true;
      updateUi();
      showControlsTemp();
      sendState();
    }

    function pauseVideo() {
      if (!player || !state.isReady) return;
      player.pauseVideo();
      state.isPlaying = false;
      updateUi();
      forceShowControls();
      sendState();
    }

    function togglePlay() {
      if (state.isPlaying) {
        pauseVideo();
      } else {
        playVideo();
      }
    }

    function seekBy(seconds) {
      if (!player || !state.isReady) return;

      var current = Number(player.getCurrentTime() || 0);
      var duration = Number(player.getDuration() || 0);
      var target = current + seconds;

      if (target < 0) target = 0;
      if (duration > 0 && target > duration) target = duration;

      player.seekTo(target, true);
      state.position = target;
      updateUi();
      showSeekToast(seconds > 0 ? '+' + seconds + ' sec' : seconds + ' sec');
      showControlsTemp();
      sendState();
    }

    function seekToSeconds(seconds) {
      if (!player || !state.isReady) return;

      seconds = Number(seconds || 0);

      if (seconds < 0) seconds = 0;

      var duration = Number(player.getDuration() || 0);
      if (duration > 0 && seconds > duration) seconds = duration;

      player.seekTo(seconds, true);
      state.position = seconds;
      updateUi();
      showControlsTemp();
      sendState();
    }

    function setPlaybackRate(rate) {
      if (!player || !state.isReady) return;

      rate = Number(rate || 1);
      player.setPlaybackRate(rate);
      state.playbackRate = rate;
      speedMenu.classList.remove('show');
      updateUi();
      showControlsTemp();
      sendState();
    }

    function toggleMute() {
      if (!player || !state.isReady) return;

      if (state.isMuted) {
        player.unMute();
        state.isMuted = false;
      } else {
        player.mute();
        state.isMuted = true;
      }

      updateUi();
      showControlsTemp();
      sendState();
    }

    function showSeekToast(text) {
      if (!SHOW_DOUBLE_TAP_TOAST) return;

      seekToast.textContent = text;
      seekToast.classList.add('show');

      if (seekToastTimer) clearTimeout(seekToastTimer);

      seekToastTimer = setTimeout(function() {
        seekToast.classList.remove('show');
      }, 620);
    }

    function handleCommand(data) {
      try {
        if (typeof data === 'string') {
          data = JSON.parse(data);
        }

        if (!data) return;

var command = data.command || data.type || data.action;

if (command === 'play') {
  playVideo();
  return;
}

if (command === 'pause') {
  pauseVideo();
  return;
}

if (command === 'toggle') {
  togglePlay();
  return;
}

if (command === 'mute') {
  if (player && state.isReady) {
    player.mute();
    state.isMuted = true;
    updateUi();
    sendState();
  }
  return;
}

if (command === 'unMute' || command === 'unmute') {
  if (player && state.isReady) {
    player.unMute();
    state.isMuted = false;
    updateUi();
    sendState();
  }
  return;
}

if (command === 'seekTo' || command === 'seek') {
  var seconds = data.seconds;

  if (seconds === undefined && data.positionSeconds !== undefined) {
    seconds = data.positionSeconds;
  }

  if (seconds === undefined && data.milliseconds !== undefined) {
    seconds = Number(data.milliseconds) / 1000;
  }

  seekToSeconds(seconds || 0);
  return;
}

if (
  command === 'setPlaybackRate' ||
  command === 'speed' ||
  command === 'rate'
) {
  setPlaybackRate(Number(data.rate || data.speed || 1));
  return;
}

if (command === 'fullscreen') {
  requestFullscreenToggle();
  return;
}
      } catch (e) {}
    }

    function refreshProgress() {
      if (!player || !state.isReady) return;

      try {
        state.position = Number(player.getCurrentTime() || 0);
        state.duration = Number(player.getDuration() || 0);
        state.loadedFraction = Number(player.getVideoLoadedFraction() || 0);
        state.playbackRate = Number(player.getPlaybackRate() || state.playbackRate || 1);
        state.isMuted = !!player.isMuted();

        updateUi();
        sendState();
      } catch (e) {}
    }

    function bindEvents() {
      playBtn.addEventListener('click', function(e) {
        e.stopPropagation();
        togglePlay();
      });

      centerPlay.addEventListener('click', function(e) {
        e.stopPropagation();
        togglePlay();
      });

      rewindBtn.addEventListener('click', function(e) {
        e.stopPropagation();
        seekBy(-SEEK_STEP);
      });

      forwardBtn.addEventListener('click', function(e) {
        e.stopPropagation();
        seekBy(SEEK_STEP);
      });

      muteBtn.addEventListener('click', function(e) {
        e.stopPropagation();
        toggleMute();
      });

      fullscreenBtn.addEventListener('click', function(e) {
        e.stopPropagation();
        requestFullscreenToggle();
      });

      speedBtn.addEventListener('click', function(e) {
        e.stopPropagation();
        speedMenu.classList.toggle('show');
        forceShowControls();
      });

      var speedItems = document.querySelectorAll('.speedItem');
      for (var i = 0; i < speedItems.length; i++) {
        speedItems[i].addEventListener('click', function(e) {
          e.stopPropagation();
          setPlaybackRate(parseFloat(this.getAttribute('data-speed')));
        });
      }

      progressWrap.addEventListener('pointerdown', function(e) {
        isDragging = true;
        progressWrap.classList.add('dragging');
        forceShowControls();
        handleProgressPointer(e);
      });

      window.addEventListener('pointermove', function(e) {
        if (!isDragging) return;
        handleProgressPointer(e);
      });

      window.addEventListener('pointerup', function(e) {
        if (!isDragging) return;
        isDragging = false;
        progressWrap.classList.remove('dragging');
        handleProgressPointer(e);
        showControlsTemp();
      });

      function handleTap(zone) {
        var now = Date.now();
        var isDouble = now - lastTapAt < 280;
        lastTapAt = now;

        if (ENABLE_DOUBLE_TAP && isDouble) {
          if (zone === 'left') {
            seekBy(-SEEK_STEP);
          } else if (zone === 'right') {
            seekBy(SEEK_STEP);
          } else {
            togglePlay();
          }
          return;
        }

        if (ENABLE_TAP_TOGGLE) {
          showControlsTemp();
        }
      }

      tapLeft.addEventListener('click', function() {
        handleTap('left');
      });

      tapCenter.addEventListener('click', function() {
        handleTap('center');
      });

      tapRight.addEventListener('click', function() {
        handleTap('right');
      });

      root.addEventListener('mousemove', function() {
        showControlsTemp();
      });

      document.addEventListener('click', function() {
        speedMenu.classList.remove('show');
      });

      if (ENABLE_KEYBOARD) {
        document.addEventListener('keydown', function(e) {
          if (e.code === 'Space') {
            e.preventDefault();
            togglePlay();
          } else if (e.code === 'ArrowRight') {
            seekBy(SEEK_STEP);
          } else if (e.code === 'ArrowLeft') {
            seekBy(-SEEK_STEP);
          } else if (e.code === 'KeyM') {
            toggleMute();
          } else if (e.code === 'KeyF') {
            requestFullscreenToggle();
          }
        });
      }
    }

    function handleProgressPointer(e) {
      if (!player || !state.isReady) return;

      var rect = progressTrack.getBoundingClientRect();
      var x = e.clientX - rect.left;
      var percent = x / rect.width;

      if (percent < 0) percent = 0;
      if (percent > 1) percent = 1;

      var duration = Number(player.getDuration() || 0);
      var target = duration * percent;

      seekToSeconds(target);
    }

    function loadYoutubeApi() {
      if (window.YT && window.YT.Player) {
        createPlayer();
        return;
      }

      var tag = document.createElement('script');
      tag.src = 'https://www.youtube.com/iframe_api';
      var firstScriptTag = document.getElementsByTagName('script')[0];
      firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
    }

    window.onYouTubeIframeAPIReady = function() {
      createPlayer();
    };

    function createPlayer() {
      player = new YT.Player('player', {
        width: '100%',
        height: '100%',
        videoId: VIDEO_ID,
      playerVars: {
  autoplay: AUTO_PLAY ? 1 : 0,
  controls: 0,
  disablekb: 1,
  enablejsapi: 1,
  fs: 0,
  playsinline: 1,
  modestbranding: 1,
  rel: 0,
  iv_load_policy: 3,
  cc_load_policy: 0
},
        events: {
          onReady: function() {
            state.isReady = true;
            state.duration = Number(player.getDuration() || 0);
            state.isMuted = !!player.isMuted();

            if (AUTO_PLAY) {
              player.playVideo();
            }

            hideLoading();
            updateUi();
            showControlsTemp();
            sendState();

            if (progressTimer) clearInterval(progressTimer);
            progressTimer = setInterval(refreshProgress, 700);
          },
          onStateChange: function(event) {
            if (event.data === YT.PlayerState.PLAYING) {
              state.isPlaying = true;
              hideLoading();
              showControlsTemp();
            } else if (
              event.data === YT.PlayerState.PAUSED ||
              event.data === YT.PlayerState.ENDED
            ) {
              state.isPlaying = false;
              forceShowControls();
            } else if (event.data === YT.PlayerState.BUFFERING) {
              loadingLayer.style.display = 'grid';
              loadingLayer.style.opacity = '.45';
            }

            refreshProgress();
            updateUi();
            sendState();
          },
          onPlaybackRateChange: function(event) {
            state.playbackRate = Number(event.data || 1);
            updateUi();
            sendState();
          },
          onError: function(event) {
            hideLoading();
            sendToFlutter({
              event: 'error',
              code: event.data || 0,
              message: 'YouTube player error'
            });
          }
        }
      });
    }

    window.addEventListener('resize', function() {
      updateUi();
      showControlsTemp();
    });

    window.addEventListener('orientationchange', function() {
      setTimeout(function() {
        updateUi();
        showControlsTemp();
      }, 250);
    });

    applyConfigVisibility();
    bindEvents();
    updateUi();
    loadYoutubeApi();

    ${config.customJs}
  </script>
</body>
</html>
''';
}
