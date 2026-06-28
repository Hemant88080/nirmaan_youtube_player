// import 'dart:convert';
// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:fullscreen_window/fullscreen_window.dart';
//
// import '../controller/nirmaan_youtube_controller.dart';
// import '../parser/youtube_url_parser.dart';
// import '../html/nirmaan_youtube_html.dart';
//
// Widget buildPlatformYoutubePlayer({
//   required String url,
//   required NirmaanYoutubeController controller,
//   required bool autoPlay,
//   ValueChanged<bool>? onFullscreenChanged,
//   String? localVideoPath, // NEW
// }) {
//   if (!Platform.isWindows) {
//     return const ColoredBox(
//       color: Colors.black,
//       child: Center(
//         child: Text(
//           'Windows player only',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//     );
//   }
//
//   return _NirmaanYoutubePlayerWindows(
//     url: url,
//     controller: controller,
//     autoPlay: autoPlay,
//     onFullscreenChanged: onFullscreenChanged,
//     localVideoPath: localVideoPath, // NEW
//   );
// }
//
// class _NirmaanYoutubePlayerWindows extends StatefulWidget {
//   final String url;
//   final NirmaanYoutubeController controller;
//   final bool autoPlay;
//   final ValueChanged<bool>? onFullscreenChanged;
//   final String? localVideoPath; // NEW
//
//   const _NirmaanYoutubePlayerWindows({
//     required this.url,
//     required this.controller,
//     required this.autoPlay,
//     this.onFullscreenChanged,
//     this.localVideoPath, // NEW
//   });
//
//   @override
//   State<_NirmaanYoutubePlayerWindows> createState() =>
//       _NirmaanYoutubePlayerWindowsState();
// }
//
// class _NirmaanYoutubePlayerWindowsState
//     extends State<_NirmaanYoutubePlayerWindows> {
//   InAppWebViewController? _webController;
//
//   HttpServer? _server;
//   String? _playerUrl;
//   String? _errorMessage;
//
//   bool _isNativeFullscreen = false;
//
//   bool get _isOffline => widget.localVideoPath != null;
//
//   @override
//   void initState() {
//     super.initState();
//
//     widget.controller.bind(
//       play: _play,
//       pause: _pause,
//       mute: _mute,
//       unMute: _unMute,
//       seekTo: _seekTo,
//       setPlaybackRate: _setPlaybackRate,
//     );
//
//     _startLocalServer();
//   }
//
//   Future<void> _startLocalServer() async {
//     try {
//       _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
//       final port = _server!.port;
//
//       _server!.listen((HttpRequest request) async {
//         final response = request.response;
//         final path = request.uri.path;
//
//         // ── Serve MP4 when offline ────────────────────────────────────────
//         if (_isOffline && path == '/video.mp4') {
//           final file = File(widget.localVideoPath!);
//           if (!await file.exists()) {
//             response.statusCode = HttpStatus.notFound;
//             await response.close();
//             return;
//           }
//
//           final fileLength = await file.length();
//           final rangeHeader = request.headers.value('range');
//
//           response.headers.contentType = ContentType('video', 'mp4');
//           response.headers.set('Accept-Ranges', 'bytes');
//           response.headers.set('Access-Control-Allow-Origin', '*');
//           response.headers.set('Cache-Control', 'no-store');
//           response.headers.set('Content-Disposition', 'inline');
//
//           if (rangeHeader != null) {
//             final match =
//             RegExp(r'bytes=(\d+)-(\d*)').firstMatch(rangeHeader);
//             if (match != null) {
//               final start = int.parse(match.group(1)!);
//               final end = match.group(2)!.isEmpty
//                   ? fileLength - 1
//                   : int.parse(match.group(2)!);
//               final length = end - start + 1;
//
//               response.statusCode = HttpStatus.partialContent;
//               response.headers.set(
//                   'Content-Range', 'bytes $start-$end/$fileLength');
//               response.contentLength = length;
//
//               final raf = await file.open();
//               await raf.setPosition(start);
//               var remaining = length;
//               const chunkSize = 65536;
//               while (remaining > 0) {
//                 final toRead =
//                 remaining < chunkSize ? remaining : chunkSize;
//                 final chunk = await raf.read(toRead);
//                 response.add(chunk);
//                 remaining -= chunk.length;
//               }
//               await raf.close();
//             } else {
//               response.contentLength = fileLength;
//               await response.addStream(file.openRead());
//             }
//           } else {
//             response.contentLength = fileLength;
//             await response.addStream(file.openRead());
//           }
//
//           await response.close();
//           return;
//         }
//
//         // ── Serve the HTML player ─────────────────────────────────────────
//         response.headers.contentType = ContentType.html;
//         response.headers.set(
//             'Referrer-Policy', 'strict-origin-when-cross-origin');
//         response.headers.set('Access-Control-Allow-Origin', '*');
//
//         response.write(
//             _isOffline ? _buildOfflineHtml(port) : _buildHtml());
//         await response.close();
//       });
//
//       _playerUrl = 'http://127.0.0.1:$port/player.html';
//       if (mounted) setState(() {});
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _errorMessage = 'Local player server failed:\n\n$e';
//       });
//     }
//   }
//
//   // ── YouTube online HTML (unchanged) ───────────────────────────────────────
//   String _buildHtml() {
//     final videoId = extractYoutubeVideoId(widget.url);
//
//     return buildNirmaanYoutubeHtml(
//       NirmaanYoutubeHtmlConfig(
//         videoId: videoId,
//         autoPlay: widget.autoPlay,
//         sourceName: 'nirmaan-youtube-windows',
//         bridgeType: NirmaanYoutubeBridgeType.inAppWebView,
//         fullscreenType: NirmaanYoutubeFullscreenType.nativeFlutter,
//         topLeftSlotHtml: 'Nirmaan Academy',
//         topRightSlotHtml: '',
//         bottomLeftSlotHtml: '',
//         bottomRightSlotHtml: '',
//         customCss: '''
//           #root { border-radius: 0; }
//         ''',
//       ),
//     );
//   }
//
//   String _buildOfflineHtml(int port) {
//     final videoSrc = 'http://127.0.0.1:$port/video.mp4';
//     final autoPlayJs = widget.autoPlay ? 'true' : 'false';
//
//     return '''<!DOCTYPE html>
// <html lang="en">
// <head>
// <meta charset="UTF-8">
// <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
// <style>
// /* ── Reset ── */
// *,*::before,*::after{margin:0;padding:0;box-sizing:border-box;-webkit-tap-highlight-color:transparent;}
// html,body{width:100%;height:100%;background:#000;overflow:hidden;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;}
// /* ── Root ── */
// #root{position:relative;width:100%;height:100%;display:flex;align-items:center;justify-content:center;background:#000;}
// /* ── Video ── */
// video{width:100%;height:100%;object-fit:contain;background:#000;outline:none;pointer-events:none;}
// /* ── Gradient scrim ── */
// #scrim-top{position:absolute;top:0;left:0;right:0;height:80px;background:linear-gradient(to bottom,rgba(0,0,0,.70),transparent);pointer-events:none;transition:opacity .25s;}
// #scrim-bot{position:absolute;bottom:0;left:0;right:0;height:120px;background:linear-gradient(to top,rgba(0,0,0,.80),transparent);pointer-events:none;transition:opacity .25s;}
// .scrim-hidden{opacity:0!important;}
// /* ── Top bar ── */
// #top-bar{position:absolute;top:0;left:0;right:0;display:flex;align-items:center;padding:10px 14px 6px;gap:8px;transition:opacity .25s;}
// #top-bar.hidden{opacity:0;pointer-events:none;}
// #brand{color:#fff;font-size:13px;font-weight:700;letter-spacing:.3px;opacity:.9;}
// #offline-pill{margin-left:auto;background:rgba(108,99,255,.85);color:#fff;font-size:10px;font-weight:700;padding:2px 8px;border-radius:20px;}
// /* ── Center tap zones ── */
// #zones{position:absolute;inset:0;display:grid;grid-template-columns:1fr 1fr 1fr;}
// .zone{cursor:pointer;}
// /* ── Seek flash ── */
// #seek-flash{position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);background:rgba(0,0,0,.72);color:#fff;font-size:14px;font-weight:700;padding:8px 20px;border-radius:30px;pointer-events:none;opacity:0;transition:opacity .15s;white-space:nowrap;}
// #seek-flash.show{opacity:1;}
// /* ── Center play icon (shows when paused) ── */
// #center-icon{position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);font-size:56px;color:rgba(255,255,255,.90);pointer-events:none;transition:opacity .2s;}
// #center-icon.hidden{opacity:0;}
// /* ── Bottom controls ── */
// #controls{position:absolute;bottom:0;left:0;right:0;padding:0 12px 10px;transition:opacity .25s;}
// #controls.hidden{opacity:0;pointer-events:none;}
// /* Progress */
// #prog-wrap{width:100%;height:18px;display:flex;align-items:center;cursor:pointer;margin-bottom:4px;}
// #prog-track{position:relative;width:100%;height:4px;background:rgba(255,255,255,.25);border-radius:2px;overflow:hidden;}
// #prog-buf{position:absolute;left:0;top:0;height:100%;background:rgba(255,255,255,.35);width:0%;}
// #prog-fill{position:absolute;left:0;top:0;height:100%;background:#6C63FF;width:0%;border-radius:2px;}
// #prog-thumb{position:absolute;top:50%;transform:translate(-50%,-50%);width:13px;height:13px;background:#fff;border-radius:50%;left:0%;box-shadow:0 1px 4px rgba(0,0,0,.5);}
// /* Row */
// #row{display:flex;align-items:center;gap:4px;}
// /* Buttons */
// .btn{background:none;border:none;cursor:pointer;color:#fff;padding:6px;display:flex;align-items:center;justify-content:center;border-radius:6px;transition:background .15s;-webkit-tap-highlight-color:transparent;}
// .btn:active{background:rgba(255,255,255,.12);}
// .btn svg{display:block;}
// /* Time */
// #time-lbl{color:rgba(255,255,255,.88);font-size:12px;white-space:nowrap;padding:0 4px;}
// #spacer{flex:1;}
// /* Speed menu */
// #speed-wrap{position:relative;}
// #speed-btn-lbl{color:#fff;font-size:12px;font-weight:700;padding:5px 9px;background:rgba(0,0,0,.55);border:1px solid rgba(255,255,255,.20);border-radius:20px;cursor:pointer;user-select:none;}
// #speed-menu{display:none;position:absolute;bottom:calc(100% + 6px);right:0;background:#111;border-radius:10px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,.6);min-width:90px;}
// #speed-menu.open{display:block;}
// .sp-item{padding:9px 14px;color:#fff;font-size:13px;cursor:pointer;display:flex;align-items:center;gap:8px;}
// .sp-item:hover{background:rgba(255,255,255,.08);}
// .sp-item.active{color:#9D97FF;}
// .sp-dot{width:6px;height:6px;border-radius:50%;background:#6C63FF;opacity:0;}
// .sp-item.active .sp-dot{opacity:1;}
// </style>
// </head>
// <body>
// <div id="root">
//   <video id="vid" playsinline webkit-playsinline
//     controlsList="nodownload nofullscreen noremoteplayback"
//     disablePictureInPicture
//     oncontextmenu="return false">
//   </video>
//
//   <!-- Gradient scrims -->
//   <div id="scrim-top"></div>
//   <div id="scrim-bot"></div>
//
//   <!-- Top bar -->
//   <div id="top-bar">
//     <span id="brand">Nirmaan Academy</span>
//     <span id="offline-pill">✓ OFFLINE</span>
//   </div>
//
//   <!-- Triple-zone tap layer -->
//   <div id="zones">
//     <div class="zone" id="zone-left"></div>
//     <div class="zone" id="zone-mid"></div>
//     <div class="zone" id="zone-right"></div>
//   </div>
//
//   <!-- Seek flash -->
//   <div id="seek-flash"></div>
//
//   <!-- Center play icon -->
//   <div id="center-icon">▶</div>
//
//   <!-- Bottom controls -->
//   <div id="controls">
//     <!-- Progress bar -->
//     <div id="prog-wrap">
//       <div id="prog-track">
//         <div id="prog-buf"></div>
//         <div id="prog-fill"></div>
//         <div id="prog-thumb"></div>
//       </div>
//     </div>
//
//     <!-- Button row -->
//     <div id="row">
//       <!-- Replay 10 -->
//       <button class="btn" id="btn-back" title="-10s">
//         <svg width="22" height="22" viewBox="0 0 24 24" fill="white">
//           <path d="M12 5V1L7 6l5 5V7c3.31 0 6 2.69 6 6s-2.69 6-6 6-6-2.69-6-6H4c0 4.42 3.58 8 8 8s8-3.58 8-8-3.58-8-8-8z"/>
//           <text x="12" y="14" text-anchor="middle" font-size="6" font-weight="700" fill="white">10</text>
//         </svg>
//       </button>
//
//       <!-- Play/Pause -->
//       <button class="btn" id="btn-play" title="Play/Pause">
//         <svg id="icon-play" width="32" height="32" viewBox="0 0 24 24" fill="white"><path d="M8 5v14l11-7z"/></svg>
//         <svg id="icon-pause" width="32" height="32" viewBox="0 0 24 24" fill="white" style="display:none"><path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/></svg>
//       </button>
//
//       <!-- Forward 10 -->
//       <button class="btn" id="btn-fwd" title="+10s">
//         <svg width="22" height="22" viewBox="0 0 24 24" fill="white">
//           <path d="M12 5V1l5 5-5 5V7c-3.31 0-6 2.69-6 6s2.69 6 6 6 6-2.69 6-6h2c0 4.42-3.58 8-8 8s-8-3.58-8-8 3.58-8 8-8z"/>
//           <text x="12" y="14" text-anchor="middle" font-size="6" font-weight="700" fill="white">10</text>
//         </svg>
//       </button>
//
//       <!-- Mute -->
//       <button class="btn" id="btn-mute" title="Mute">
//         <svg id="icon-unmuted" width="20" height="20" viewBox="0 0 24 24" fill="white"><path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"/></svg>
//         <svg id="icon-muted" width="20" height="20" viewBox="0 0 24 24" fill="white" style="display:none"><path d="M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4L9.91 6.09 12 8.18V4z"/></svg>
//       </button>
//
//       <!-- Time -->
//       <span id="time-lbl">0:00 / 0:00</span>
//       <div id="spacer"></div>
//
//       <!-- Speed -->
//       <div id="speed-wrap">
//         <div id="speed-btn-lbl">1x</div>
//         <div id="speed-menu">
//           <div class="sp-item" data-speed="0.5"><span class="sp-dot"></span>0.5x</div>
//           <div class="sp-item active" data-speed="1"><span class="sp-dot"></span>1x</div>
//           <div class="sp-item" data-speed="1.25"><span class="sp-dot"></span>1.25x</div>
//           <div class="sp-item" data-speed="1.5"><span class="sp-dot"></span>1.5x</div>
//           <div class="sp-item" data-speed="2"><span class="sp-dot"></span>2x</div>
//         </div>
//       </div>
//
//       <!-- Fullscreen -->
//       <button class="btn" id="btn-fs" title="Fullscreen">
//         <svg id="icon-fs-enter" width="20" height="20" viewBox="0 0 24 24" fill="white"><path d="M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zM14 5v2h3v3h2V5h-5z"/></svg>
//         <svg id="icon-fs-exit" width="20" height="20" viewBox="0 0 24 24" fill="white" style="display:none"><path d="M5 16h3v3h2v-5H5v2zm3-8H5v2h5V5H8v3zm6 11h2v-3h3v-2h-5v5zm2-11V5h-2v5h5V8h-3z"/></svg>
//       </button>
//     </div>
//   </div>
// </div>
//
// <script>
// (function(){
// 'use strict';
//
// /* ── Constants ─────────────────────────────────────────────────────────────── */
// const SOURCE      = 'nirmaan-youtube-windows';
// const SEEK_STEP   = 10;
// const AUTO_HIDE   = 3000;
//
// /* ── Elements ──────────────────────────────────────────────────────────────── */
// const vid         = document.getElementById('vid');
// const root        = document.getElementById('root');
// const topBar      = document.getElementById('top-bar');
// const scrimTop    = document.getElementById('scrim-top');
// const scrimBot    = document.getElementById('scrim-bot');
// const controls    = document.getElementById('controls');
// const progWrap    = document.getElementById('prog-wrap');
// const progBuf     = document.getElementById('prog-buf');
// const progFill    = document.getElementById('prog-fill');
// const progThumb   = document.getElementById('prog-thumb');
// const timeLbl     = document.getElementById('time-lbl');
// const btnPlay     = document.getElementById('btn-play');
// const iconPlay    = document.getElementById('icon-play');
// const iconPause   = document.getElementById('icon-pause');
// const btnBack     = document.getElementById('btn-back');
// const btnFwd      = document.getElementById('btn-fwd');
// const btnMute     = document.getElementById('btn-mute');
// const iconUnmuted = document.getElementById('icon-unmuted');
// const iconMuted   = document.getElementById('icon-muted');
// const btnFs       = document.getElementById('btn-fs');
// const iconFsEnter = document.getElementById('icon-fs-enter');
// const iconFsExit  = document.getElementById('icon-fs-exit');
// const centerIcon  = document.getElementById('center-icon');
// const seekFlash   = document.getElementById('seek-flash');
// const speedWrap   = document.getElementById('speed-wrap');
// const speedBtnLbl = document.getElementById('speed-btn-lbl');
// const speedMenu   = document.getElementById('speed-menu');
// const speedItems  = document.querySelectorAll('.sp-item');
// const zoneLeft    = document.getElementById('zone-left');
// const zoneMid     = document.getElementById('zone-mid');
// const zoneRight   = document.getElementById('zone-right');
//
// /* ── State ─────────────────────────────────────────────────────────────────── */
// let ctrlVisible    = true;
// let hideTimer      = null;
// let seekFlashTimer = null;
// let isScrubbing    = false;
// let isFullscreen   = false;
// let lastSpeed      = 1;
//
// /* ── Disable download / save ────────────────────────────────────────────────
//    1. controlsList already set in HTML attribute
//    2. Block right-click / long-press context menu                             */
// document.addEventListener('contextmenu', e => e.preventDefault());
// document.addEventListener('selectstart', e => e.preventDefault());
//
// /* ── Load video ─────────────────────────────────────────────────────────────── */
// vid.src = '${videoSrc}';
// if (${autoPlayJs}) {
//   vid.autoplay = true;
//   vid.play().catch(() => {});
// }
//
// /* ── Bridge to Flutter ──────────────────────────────────────────────────────── */
// function reportState() {
//   const state = {
//     source:       SOURCE,
//     isReady:      vid.readyState >= 2,
//     isPlaying:    !vid.paused && !vid.ended,
//     isMuted:      vid.muted,
//     showControls: ctrlVisible,
//     position:     Math.round(vid.currentTime  * 1000),
//     duration:     Math.round((vid.duration||0)* 1000),
//     playbackRate: vid.playbackRate,
//   };
//   if (window.flutter_inappwebview) {
//     window.flutter_inappwebview.callHandler('nirmaanState', state);
//   }
// }
// setInterval(() => { if (!vid.paused) reportState(); }, 500);
//
// /* ── Video events ───────────────────────────────────────────────────────────── */
// vid.addEventListener('play',     () => { syncPlayBtn(); reportState(); });
// vid.addEventListener('pause',    () => { syncPlayBtn(); revealControls(false); reportState(); });
// vid.addEventListener('ended',    () => { syncPlayBtn(); revealControls(false); reportState(); });
// vid.addEventListener('seeked',   () => reportState());
// vid.addEventListener('canplay',  () => reportState());
// vid.addEventListener('timeupdate', updateProgress);
//
// vid.addEventListener('progress', () => {
//   if (!vid.duration) return;
//   try {
//     const b = vid.buffered;
//     if (b.length) {
//       progBuf.style.width = (b.end(b.length-1)/vid.duration*100)+'%';
//     }
//   } catch(e){}
// });
//
// /* ── Progress bar ───────────────────────────────────────────────────────────── */
// function updateProgress() {
//   if (!vid.duration || isScrubbing) return;
//   const pct = vid.currentTime / vid.duration;
//   progFill.style.width  = (pct*100)+'%';
//   progThumb.style.left  = (pct*100)+'%';
//   timeLbl.textContent   = fmt(vid.currentTime)+' / '+fmt(vid.duration);
// }
//
// function scrubFromEvent(e) {
//   const rect = progWrap.getBoundingClientRect();
//   const x    = ('touches' in e ? e.touches[0].clientX : e.clientX);
//   const pct  = Math.max(0, Math.min(1, (x - rect.left) / rect.width));
//   vid.currentTime = pct * vid.duration;
//   progFill.style.width  = (pct*100)+'%';
//   progThumb.style.left  = (pct*100)+'%';
//   timeLbl.textContent   = fmt(vid.currentTime)+' / '+fmt(vid.duration);
// }
//
// progWrap.addEventListener('mousedown', e => {
//   isScrubbing = true;
//   scrubFromEvent(e);
//   revealControls(false);
// });
// progWrap.addEventListener('touchstart', e => {
//   isScrubbing = true;
//   scrubFromEvent(e);
//   revealControls(false);
// }, {passive:true});
// document.addEventListener('mousemove',  e => { if (isScrubbing) scrubFromEvent(e); });
// document.addEventListener('touchmove',  e => { if (isScrubbing) scrubFromEvent(e); }, {passive:true});
// document.addEventListener('mouseup',    () => { if (isScrubbing) { isScrubbing=false; revealControls(true); }});
// document.addEventListener('touchend',   () => { if (isScrubbing) { isScrubbing=false; revealControls(true); }});
//
// /* ── Controls visibility ────────────────────────────────────────────────────── */
// function revealControls(autoHide) {
//   ctrlVisible = true;
//   [controls, topBar].forEach(el => el.classList.remove('hidden'));
//   [scrimTop, scrimBot].forEach(el => el.classList.remove('scrim-hidden'));
//   clearTimeout(hideTimer);
//   if (autoHide && !vid.paused) {
//     hideTimer = setTimeout(hideControls, AUTO_HIDE);
//   }
// }
//
// function hideControls() {
//   ctrlVisible = false;
//   [controls, topBar].forEach(el => el.classList.add('hidden'));
//   [scrimTop, scrimBot].forEach(el => el.classList.add('scrim-hidden'));
// }
//
// /* ── Tap zones ──────────────────────────────────────────────────────────────── */
// // Double-tap tracking
// const tapState = {left:0, mid:0, right:0};
//
// function handleZoneTap(zone) {
//   if (zone === 'mid') {
//     if (!ctrlVisible) { revealControls(true); }
//     else { hideControls(); }
//     return;
//   }
//   const now = Date.now();
//   const last = tapState[zone];
//   tapState[zone] = now;
//   if (now - last < 300) {
//     // Double-tap
//     tapState[zone] = 0;
//     const delta = zone === 'left' ? -SEEK_STEP : SEEK_STEP;
//     seek(delta);
//     revealControls(true);
//   } else {
//     // Single-tap — reveal or hide
//     if (!ctrlVisible) { revealControls(true); }
//   }
// }
//
// zoneLeft.addEventListener('click',  () => handleZoneTap('left'));
// zoneMid.addEventListener('click',   () => handleZoneTap('mid'));
// zoneRight.addEventListener('click', () => handleZoneTap('right'));
//
// /* ── Play / Pause ───────────────────────────────────────────────────────────── */
// function togglePlay() {
//   if (vid.paused || vid.ended) { vid.play().catch(()=>{}); }
//   else                          { vid.pause(); }
//   revealControls(true);
// }
//
// function syncPlayBtn() {
//   const playing = !vid.paused && !vid.ended;
//   iconPlay.style.display  = playing ? 'none' : 'block';
//   iconPause.style.display = playing ? 'block' : 'none';
//   centerIcon.textContent  = playing ? '' : '▶';
//   centerIcon.classList.toggle('hidden', playing);
// }
//
// btnPlay.addEventListener('click', togglePlay);
//
// /* ── Seek ±10 ───────────────────────────────────────────────────────────────── */
// function seek(delta) {
//   vid.currentTime = Math.max(0, Math.min(vid.duration||0, vid.currentTime + delta));
//   showFlash((delta > 0 ? '+' : '') + delta + ' sec');
//   reportState();
// }
//
// function showFlash(txt) {
//   seekFlash.textContent = txt;
//   seekFlash.classList.add('show');
//   clearTimeout(seekFlashTimer);
//   seekFlashTimer = setTimeout(() => seekFlash.classList.remove('show'), 700);
// }
//
// btnBack.addEventListener('click', () => { seek(-SEEK_STEP); revealControls(true); });
// btnFwd.addEventListener('click',  () => { seek( SEEK_STEP); revealControls(true); });
//
// /* ── Mute ───────────────────────────────────────────────────────────────────── */
// function syncMute() {
//   iconUnmuted.style.display = vid.muted ? 'none'  : 'block';
//   iconMuted.style.display   = vid.muted ? 'block' : 'none';
// }
// btnMute.addEventListener('click', () => { vid.muted = !vid.muted; syncMute(); reportState(); revealControls(true); });
//
// /* ── Speed ──────────────────────────────────────────────────────────────────── */
// speedBtnLbl.addEventListener('click', e => {
//   e.stopPropagation();
//   speedMenu.classList.toggle('open');
//   revealControls(false);
// });
//
// speedItems.forEach(item => {
//   item.addEventListener('click', e => {
//     e.stopPropagation();
//     const sp = parseFloat(item.dataset.speed);
//     vid.playbackRate = sp;
//     lastSpeed = sp;
//     speedBtnLbl.textContent = (sp === Math.floor(sp) ? sp.toFixed(0) : sp) + 'x';
//     speedItems.forEach(i => i.classList.remove('active'));
//     item.classList.add('active');
//     speedMenu.classList.remove('open');
//     revealControls(true);
//     reportState();
//   });
// });
//
// document.addEventListener('click', () => speedMenu.classList.remove('open'));
//
// /* ── Fullscreen ─────────────────────────────────────────────────────────────── */
// function toggleFs() {
//   if (window.flutter_inappwebview) {
//     window.flutter_inappwebview.callHandler('nirmaanFullscreen');
//   }
// }
//
// function syncFsIcon(full) {
//   iconFsEnter.style.display = full ? 'none'  : 'block';
//   iconFsExit.style.display  = full ? 'block' : 'none';
// }
//
// btnFs.addEventListener('click', () => { toggleFs(); revealControls(true); });
//
// /* ── Commands from Flutter (NirmaanYoutubeController) ───────────────────────── */
// window.nirmaanCommand = function(cmd) {
//   switch (cmd.type) {
//     case 'play':   vid.play().catch(()=>{}); break;
//     case 'pause':  vid.pause();              break;
//     case 'seek':   vid.currentTime = cmd.seconds; break;
//     case 'speed':  vid.playbackRate = cmd.rate;
//                    speedBtnLbl.textContent = (cmd.rate===Math.floor(cmd.rate)?cmd.rate.toFixed(0):cmd.rate)+'x';
//                    speedItems.forEach(i=>{
//                      i.classList.toggle('active', parseFloat(i.dataset.speed)===cmd.rate);
//                    });
//                    break;
//     case 'mute':   vid.muted = true;  syncMute(); break;
//     case 'unmute': vid.muted = false; syncMute(); break;
//   }
//   reportState();
// };
//
// /* Called from Flutter after fullscreen transition */
// window.nirmaanSetFullscreen = function(val) {
//   isFullscreen = val;
//   syncFsIcon(val);
// };
// window.nirmaanResizeFix  = function() {};
// window.showControlsTemp  = function() { revealControls(true); };
//
// /* ── Keyboard shortcuts (desktop/macOS) ─────────────────────────────────────── */
// document.addEventListener('keydown', e => {
//   switch(e.code) {
//     case 'Space':       e.preventDefault(); togglePlay();          break;
//     case 'ArrowRight':  e.preventDefault(); seek( SEEK_STEP);       break;
//     case 'ArrowLeft':   e.preventDefault(); seek(-SEEK_STEP);       break;
//     case 'KeyM':        vid.muted=!vid.muted; syncMute(); break;
//     case 'KeyF':        toggleFs();            break;
//   }
//   revealControls(true);
// });
//
// /* ── Helpers ────────────────────────────────────────────────────────────────── */
// function fmt(s) {
//   if (!s || isNaN(s)) return '0:00';
//   const h = Math.floor(s/3600);
//   const m = Math.floor((s%3600)/60);
//   const sec = Math.floor(s%60);
//   return (h>0?h+':':'')+(h>0?String(m).padStart(2,'0'):m)+':'+String(sec).padStart(2,'0');
// }
//
// /* ── Init ───────────────────────────────────────────────────────────────────── */
// syncPlayBtn();
// syncMute();
// revealControls(true);
// })();
// </script>
// </body>
// </html>''';
//   }
//
//   // ── All below: UNCHANGED from original ───────────────────────────────────
//
//   Future<void> _toggleNativeFullscreen() async {
//     try {
//       _isNativeFullscreen = !_isNativeFullscreen;
//       await FullScreenWindow.setFullScreen(_isNativeFullscreen);
//       widget.onFullscreenChanged?.call(_isNativeFullscreen);
//       await _webController?.evaluateJavascript(
//         source: '''
//           if (window.nirmaanSetFullscreen) {
//             window.nirmaanSetFullscreen(${_isNativeFullscreen ? 'true' : 'false'});
//           }
//           if (window.nirmaanResizeFix) { window.nirmaanResizeFix(); }
//           if (window.showControlsTemp) { window.showControlsTemp(); }
//         ''',
//       );
//     } catch (e) {
//       debugPrint('WINDOWS FULLSCREEN ERROR => $e');
//     }
//   }
//
//   void _handleState(dynamic raw) {
//     try {
//       final value = raw is String ? jsonDecode(raw) : raw;
//       if (value is! Map) return;
//       if (value['source'] != 'nirmaan-youtube-windows') return;
//       widget.controller.updateValue(
//         widget.controller.value.copyWith(
//           isReady: value['isReady'] == true,
//           isPlaying: value['isPlaying'] == true,
//           isMuted: value['isMuted'] == true,
//           position: Duration(milliseconds: value['position'] ?? 0),
//           duration: Duration(milliseconds: value['duration'] ?? 0),
//           playbackRate: (value['playbackRate'] ?? 1).toDouble(),
//         ),
//       );
//     } catch (e) {
//       debugPrint('WINDOWS YOUTUBE STATE ERROR => $e');
//     }
//   }
//
//   Future<void> _sendToPlayer(Map<String, dynamic> data) async {
//     final json = jsonEncode(data);
//     await _webController?.evaluateJavascript(
//       source:
//       'if (window.nirmaanCommand) { window.nirmaanCommand($json); }',
//     );
//   }
//
//   Future<void> _play()               async => _sendToPlayer({'type': 'play'});
//   Future<void> _pause()              async => _sendToPlayer({'type': 'pause'});
//   Future<void> _mute()               async => _sendToPlayer({'type': 'mute'});
//   Future<void> _unMute()             async => _sendToPlayer({'type': 'unmute'});
//   Future<void> _seekTo(Duration pos) async =>
//       _sendToPlayer({'type': 'seek', 'seconds': pos.inMilliseconds / 1000});
//   Future<void> _setPlaybackRate(double rate) async =>
//       _sendToPlayer({'type': 'speed', 'rate': rate});
//
//   @override
//   void dispose() {
//     if (_isNativeFullscreen) FullScreenWindow.setFullScreen(false);
//     _server?.close(force: true);
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_errorMessage != null) {
//       return ColoredBox(
//         color: Colors.black,
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(18),
//             child: Text(
//               _errorMessage!,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                   color: Colors.white, fontSize: 14, height: 1.4),
//             ),
//           ),
//         ),
//       );
//     }
//
//     if (_playerUrl == null) {
//       return const ColoredBox(
//         color: Colors.black,
//         child: Center(
//           child: CircularProgressIndicator(color: Colors.white),
//         ),
//       );
//     }
//
//     return InAppWebView(
//       initialUrlRequest: URLRequest(
//         url: WebUri(_playerUrl!),
//         headers: {'Referer': _playerUrl!},
//       ),
//       initialSettings: InAppWebViewSettings(
//         javaScriptEnabled: true,
//         mediaPlaybackRequiresUserGesture: false,
//         transparentBackground: false,
//         allowsInlineMediaPlayback: true,
//         iframeAllow: 'autoplay; encrypted-media; fullscreen',
//         iframeAllowFullscreen: true,
//         supportZoom: false,
//         builtInZoomControls: false,
//         displayZoomControls: false,
//       ),
//       onWebViewCreated: (controller) {
//         _webController = controller;
//         controller.addJavaScriptHandler(
//           handlerName: 'nirmaanState',
//           callback: (args) {
//             if (args.isNotEmpty) _handleState(args.first);
//             return null;
//           },
//         );
//         controller.addJavaScriptHandler(
//           handlerName: 'nirmaanFullscreen',
//           callback: (args) async {
//             await _toggleNativeFullscreen();
//             return null;
//           },
//         );
//       },
//     );
//   }
// }

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fullscreen_window/fullscreen_window.dart';

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
  if (!Platform.isWindows) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Text(
          'Windows player only',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  return _NirmaanYoutubePlayerWindows(
    url: url,
    controller: controller,
    autoPlay: autoPlay,
    onFullscreenChanged: onFullscreenChanged,
    localVideoPath: localVideoPath,
    offlineIcons: offlineIcons,
  );
}

class _NirmaanYoutubePlayerWindows extends StatefulWidget {
  final String url;
  final NirmaanYoutubeController controller;
  final bool autoPlay;
  final ValueChanged<bool>? onFullscreenChanged;
  final String? localVideoPath;
  final NirmaanPlayerIcons offlineIcons;

  const _NirmaanYoutubePlayerWindows({
    required this.url,
    required this.controller,
    required this.autoPlay,
    this.onFullscreenChanged,
    this.localVideoPath,
    this.offlineIcons = const NirmaanPlayerIcons(),
  });

  @override
  State<_NirmaanYoutubePlayerWindows> createState() =>
      _NirmaanYoutubePlayerWindowsState();
}

class _NirmaanYoutubePlayerWindowsState
    extends State<_NirmaanYoutubePlayerWindows> {
  InAppWebViewController? _webController;

  HttpServer? _server;
  String? _playerUrl;
  String? _errorMessage;

  bool _isNativeFullscreen = false;

  bool get _isOffline => widget.localVideoPath != null;

  @override
  void didUpdateWidget(covariant _NirmaanYoutubePlayerWindows oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localVideoPath != widget.localVideoPath &&
        _playerUrl != null) {
      _webController?.loadUrl(
        urlRequest: URLRequest(url: WebUri(_playerUrl!)),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    widget.controller.bind(
      play: _play,
      pause: _pause,
      mute: _mute,
      unMute: _unMute,
      seekTo: _seekTo,
      setPlaybackRate: _setPlaybackRate,
    );

    _startLocalServer();
  }

  Future<void> _startLocalServer() async {
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = _server!.port;

      _server!.listen((HttpRequest request) async {
        final response = request.response;
        final path = request.uri.path;

        // ── Serve MP4 when offline ────────────────────────────────────────
        if (_isOffline && path == '/video.mp4') {
          final file = File(widget.localVideoPath!);
          if (!await file.exists()) {
            response.statusCode = HttpStatus.notFound;
            await response.close();
            return;
          }

          final fileLength = await file.length();
          final rangeHeader = request.headers.value('range');

          response.headers.contentType = ContentType('video', 'mp4');
          response.headers.set('Accept-Ranges', 'bytes');
          response.headers.set('Access-Control-Allow-Origin', '*');
          response.headers.set('Cache-Control', 'no-store');
          response.headers.set('Content-Disposition', 'inline');

          if (rangeHeader != null) {
            final match = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(rangeHeader);
            if (match != null) {
              final start = int.parse(match.group(1)!);
              final end = match.group(2)!.isEmpty
                  ? fileLength - 1
                  : int.parse(match.group(2)!);
              final length = end - start + 1;

              response.statusCode = HttpStatus.partialContent;
              response.headers.set(
                'Content-Range',
                'bytes $start-$end/$fileLength',
              );
              response.contentLength = length;

              final raf = await file.open();
              await raf.setPosition(start);
              var remaining = length;
              const chunkSize = 65536;
              while (remaining > 0) {
                final toRead = remaining < chunkSize ? remaining : chunkSize;
                final chunk = await raf.read(toRead);
                response.add(chunk);
                remaining -= chunk.length;
              }
              await raf.close();
            } else {
              response.contentLength = fileLength;
              await response.addStream(file.openRead());
            }
          } else {
            response.contentLength = fileLength;
            await response.addStream(file.openRead());
          }

          await response.close();
          return;
        }

        // ── Serve the HTML player ─────────────────────────────────────────
        response.headers.contentType = ContentType.html;
        response.headers.set(
          'Referrer-Policy',
          'strict-origin-when-cross-origin',
        );
        response.headers.set('Access-Control-Allow-Origin', '*');

        response.write(_isOffline ? _buildOfflineHtml(port) : _buildHtml());
        await response.close();
      });

      _playerUrl = 'http://127.0.0.1:$port/player.html';
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Local player server failed:\n\n$e';
      });
    }
  }

  // ── YouTube online HTML (unchanged) ───────────────────────────────────────
  String _buildHtml() {
    final videoId = extractYoutubeVideoId(widget.url);

    return buildNirmaanYoutubeHtml(
      NirmaanYoutubeHtmlConfig(
        videoId: videoId,
        autoPlay: widget.autoPlay,
        sourceName: 'nirmaan-youtube-windows',
        bridgeType: NirmaanYoutubeBridgeType.inAppWebView,
        fullscreenType: NirmaanYoutubeFullscreenType.nativeFlutter,
        topLeftSlotHtml: 'Nirmaan Academy',
        topRightSlotHtml: '',
        bottomLeftSlotHtml: '',
        bottomRightSlotHtml: '',
        customCss: '''
          #root { border-radius: 0; }
        ''',
      ),
    );
  }

  String _wrapId(String id, String inner, {bool hidden = false}) {
    final style = hidden ? ' style="display:none"' : '';
    return '<span id="$id"$style class="ic-wrap">$inner</span>';
  }

  String _buildOfflineHtml(int port) {
    final videoSrc = 'http://127.0.0.1:$port/video.mp4';
    final autoPlayJs = widget.autoPlay ? 'true' : 'false';

    final ic = widget.offlineIcons;
    const dRewind =
        '<svg width="22" height="22" viewBox="0 0 24 24" fill="white"><path d="M12 5V1L7 6l5 5V7c3.31 0 6 2.69 6 6s-2.69 6-6 6-6-2.69-6-6H4c0 4.42 3.58 8 8 8s8-3.58 8-8-3.58-8-8-8z"/><text x="12" y="14" text-anchor="middle" font-size="6" font-weight="700" fill="white">10</text></svg>';
    const dForward =
        '<svg width="22" height="22" viewBox="0 0 24 24" fill="white"><path d="M12 5V1l5 5-5 5V7c-3.31 0-6 2.69-6 6s2.69 6 6 6 6-2.69 6-6h2c0 4.42-3.58 8-8 8s-8-3.58-8-8 3.58-8 8-8z"/><text x="12" y="14" text-anchor="middle" font-size="6" font-weight="700" fill="white">10</text></svg>';
    const dPlay =
        '<svg id="icon-play" width="32" height="32" viewBox="0 0 24 24" fill="white"><path d="M8 5v14l11-7z"/></svg>';
    const dPause =
        '<svg id="icon-pause" width="32" height="32" viewBox="0 0 24 24" fill="white" style="display:none"><path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/></svg>';
    const dUnmuted =
        '<svg id="icon-unmuted" width="20" height="20" viewBox="0 0 24 24" fill="white"><path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"/></svg>';
    const dMuted =
        '<svg id="icon-muted" width="20" height="20" viewBox="0 0 24 24" fill="white" style="display:none"><path d="M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4L9.91 6.09 12 8.18V4z"/></svg>';
    const dFsEnter =
        '<svg id="icon-fs-enter" width="20" height="20" viewBox="0 0 24 24" fill="white"><path d="M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zM14 5v2h3v3h2V5h-5z"/></svg>';
    const dFsExit =
        '<svg id="icon-fs-exit" width="20" height="20" viewBox="0 0 24 24" fill="white" style="display:none"><path d="M5 16h3v3h2v-5H5v2zm3-8H5v2h5V5H8v3zm6 11h2v-3h3v-2h-5v5zm2-11V5h-2v5h5V8h-3z"/></svg>';

    final icRewind = ic.rewind != null ? ic.rewind!.toHtml(dRewind) : dRewind;
    final icForward =
        ic.forward != null ? ic.forward!.toHtml(dForward) : dForward;
    final icPlay =
        ic.play != null ? _wrapId('icon-play', ic.play!.toHtml(dPlay)) : dPlay;
    final icPause = ic.pause != null
        ? _wrapId('icon-pause', ic.pause!.toHtml(dPause), hidden: true)
        : dPause;
    final icUnmuted = ic.volume != null
        ? _wrapId('icon-unmuted', ic.volume!.toHtml(dUnmuted))
        : dUnmuted;
    final icMuted = ic.mute != null
        ? _wrapId('icon-muted', ic.mute!.toHtml(dMuted), hidden: true)
        : dMuted;
    final icFsEnter = ic.fullscreen != null
        ? _wrapId('icon-fs-enter', ic.fullscreen!.toHtml(dFsEnter))
        : dFsEnter;
    final icFsExit = ic.exitFullscreen != null
        ? _wrapId(
            'icon-fs-exit',
            ic.exitFullscreen!.toHtml(dFsExit),
            hidden: true,
          )
        : dFsExit;

    return '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>
/* ── Reset ── */
*,*::before,*::after{margin:0;padding:0;box-sizing:border-box;-webkit-tap-highlight-color:transparent;}
html,body{width:100%;height:100%;background:#000;overflow:hidden;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;}
/* ── Root ── */
#root{position:relative;width:100%;height:100%;display:flex;align-items:center;justify-content:center;background:#000;}
/* ── Video ── */
video{width:100%;height:100%;object-fit:contain;background:#000;outline:none;pointer-events:none;}
/* ── Gradient scrim ── */
#scrim-top{position:absolute;top:0;left:0;right:0;height:80px;background:linear-gradient(to bottom,rgba(0,0,0,.70),transparent);pointer-events:none;transition:opacity .25s;}
#scrim-bot{position:absolute;bottom:0;left:0;right:0;height:120px;background:linear-gradient(to top,rgba(0,0,0,.80),transparent);pointer-events:none;transition:opacity .25s;}
.scrim-hidden{opacity:0!important;}
/* ── Top bar ── */
#top-bar{position:absolute;top:0;left:0;right:0;display:flex;align-items:center;padding:10px 14px 6px;gap:8px;transition:opacity .25s;}
#top-bar.hidden{opacity:0;pointer-events:none;}
#brand{color:#fff;font-size:13px;font-weight:700;letter-spacing:.3px;opacity:.9;}
#offline-pill{margin-left:auto;background:rgba(108,99,255,.85);color:#fff;font-size:10px;font-weight:700;padding:2px 8px;border-radius:20px;}
/* ── Center tap zones ── */
#zones{position:absolute;inset:0;display:grid;grid-template-columns:1fr 1fr 1fr;}
.zone{cursor:pointer;}
/* ── Seek flash ── */
#seek-flash{position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);background:rgba(0,0,0,.72);color:#fff;font-size:14px;font-weight:700;padding:8px 20px;border-radius:30px;pointer-events:none;opacity:0;transition:opacity .15s;white-space:nowrap;}
#seek-flash.show{opacity:1;}
/* ── Center play icon (shows when paused) ── */
#center-icon{position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);font-size:56px;color:rgba(255,255,255,.90);pointer-events:none;transition:opacity .2s;}
#center-icon.hidden{opacity:0;}
/* ── Bottom controls ── */
#controls{position:absolute;bottom:0;left:0;right:0;padding:0 12px 10px;transition:opacity .25s;}
#controls.hidden{opacity:0;pointer-events:none;}
/* Progress */
#prog-wrap{width:100%;height:18px;display:flex;align-items:center;cursor:pointer;margin-bottom:4px;}
#prog-track{position:relative;width:100%;height:4px;background:rgba(255,255,255,.25);border-radius:2px;overflow:hidden;}
#prog-buf{position:absolute;left:0;top:0;height:100%;background:rgba(255,255,255,.35);width:0%;}
#prog-fill{position:absolute;left:0;top:0;height:100%;background:#6C63FF;width:0%;border-radius:2px;}
#prog-thumb{position:absolute;top:50%;transform:translate(-50%,-50%);width:13px;height:13px;background:#fff;border-radius:50%;left:0%;box-shadow:0 1px 4px rgba(0,0,0,.5);}
/* Row */
#row{display:flex;align-items:center;gap:4px;}
/* Buttons */
.btn{background:none;border:none;cursor:pointer;color:#fff;padding:6px;display:flex;align-items:center;justify-content:center;border-radius:6px;transition:background .15s;-webkit-tap-highlight-color:transparent;}
.btn:active{background:rgba(255,255,255,.12);}
.btn svg{display:block;}
.ic-wrap{display:inline-flex;align-items:center;justify-content:center;}
.ic-wrap svg,.ic-wrap img{display:block;width:100%;height:100%;}
/* Time */
#time-lbl{color:rgba(255,255,255,.88);font-size:12px;white-space:nowrap;padding:0 4px;}
#spacer{flex:1;}
/* Speed menu */
#speed-wrap{position:relative;}
#speed-btn-lbl{color:#fff;font-size:12px;font-weight:700;padding:5px 9px;background:rgba(0,0,0,.55);border:1px solid rgba(255,255,255,.20);border-radius:20px;cursor:pointer;user-select:none;}
#speed-menu{display:none;position:absolute;bottom:calc(100% + 6px);right:0;background:#111;border-radius:10px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,.6);min-width:90px;}
#speed-menu.open{display:block;}
.sp-item{padding:9px 14px;color:#fff;font-size:13px;cursor:pointer;display:flex;align-items:center;gap:8px;}
.sp-item:hover{background:rgba(255,255,255,.08);}
.sp-item.active{color:#9D97FF;}
.sp-dot{width:6px;height:6px;border-radius:50%;background:#6C63FF;opacity:0;}
.sp-item.active .sp-dot{opacity:1;}
</style>
</head>
<body>
<div id="root">
  <video id="vid" playsinline webkit-playsinline
    controlsList="nodownload nofullscreen noremoteplayback"
    disablePictureInPicture
    oncontextmenu="return false">
  </video>

  <!-- Gradient scrims -->
  <div id="scrim-top"></div>
  <div id="scrim-bot"></div>

  <!-- Top bar -->
  <div id="top-bar">
    <span id="brand">Nirmaan Academy</span>
    <span id="offline-pill">✓ OFFLINE</span>
  </div>

  <!-- Triple-zone tap layer -->
  <div id="zones">
    <div class="zone" id="zone-left"></div>
    <div class="zone" id="zone-mid"></div>
    <div class="zone" id="zone-right"></div>
  </div>

  <!-- Seek flash -->
  <div id="seek-flash"></div>

  <!-- Center play icon -->
  <div id="center-icon">▶</div>

  <!-- Bottom controls -->
  <div id="controls">
    <!-- Progress bar -->
    <div id="prog-wrap">
      <div id="prog-track">
        <div id="prog-buf"></div>
        <div id="prog-fill"></div>
        <div id="prog-thumb"></div>
      </div>
    </div>

    <!-- Button row -->
    <div id="row">
      <!-- Replay 10 -->
      <button class="btn" id="btn-back" title="-10s">$icRewind</button>

      <!-- Play/Pause -->
      <button class="btn" id="btn-play" title="Play/Pause">
        $icPlay
        $icPause
      </button>

      <!-- Forward 10 -->
      <button class="btn" id="btn-fwd" title="+10s">$icForward</button>

      <!-- Mute -->
      <button class="btn" id="btn-mute" title="Mute">
        $icUnmuted
        $icMuted
      </button>

      <!-- Time -->
      <span id="time-lbl">0:00 / 0:00</span>
      <div id="spacer"></div>

      <!-- Speed -->
      <div id="speed-wrap">
        <div id="speed-btn-lbl">1x</div>
        <div id="speed-menu">
          <div class="sp-item" data-speed="0.5"><span class="sp-dot"></span>0.5x</div>
          <div class="sp-item active" data-speed="1"><span class="sp-dot"></span>1x</div>
          <div class="sp-item" data-speed="1.25"><span class="sp-dot"></span>1.25x</div>
          <div class="sp-item" data-speed="1.5"><span class="sp-dot"></span>1.5x</div>
          <div class="sp-item" data-speed="2"><span class="sp-dot"></span>2x</div>
        </div>
      </div>

      <!-- Fullscreen -->
      <button class="btn" id="btn-fs" title="Fullscreen">
        $icFsEnter
        $icFsExit
      </button>
    </div>
  </div>
</div>

<script>
(function(){
'use strict';

/* ── Constants ─────────────────────────────────────────────────────────────── */
const SOURCE      = 'nirmaan-youtube-windows';
const SEEK_STEP   = 10;
const AUTO_HIDE   = 3000;

/* ── Elements ──────────────────────────────────────────────────────────────── */
const vid         = document.getElementById('vid');
const root        = document.getElementById('root');
const topBar      = document.getElementById('top-bar');
const scrimTop    = document.getElementById('scrim-top');
const scrimBot    = document.getElementById('scrim-bot');
const controls    = document.getElementById('controls');
const progWrap    = document.getElementById('prog-wrap');
const progBuf     = document.getElementById('prog-buf');
const progFill    = document.getElementById('prog-fill');
const progThumb   = document.getElementById('prog-thumb');
const timeLbl     = document.getElementById('time-lbl');
const btnPlay     = document.getElementById('btn-play');
const iconPlay    = document.getElementById('icon-play');
const iconPause   = document.getElementById('icon-pause');
const btnBack     = document.getElementById('btn-back');
const btnFwd      = document.getElementById('btn-fwd');
const btnMute     = document.getElementById('btn-mute');
const iconUnmuted = document.getElementById('icon-unmuted');
const iconMuted   = document.getElementById('icon-muted');
const btnFs       = document.getElementById('btn-fs');
const iconFsEnter = document.getElementById('icon-fs-enter');
const iconFsExit  = document.getElementById('icon-fs-exit');
const centerIcon  = document.getElementById('center-icon');
const seekFlash   = document.getElementById('seek-flash');
const speedWrap   = document.getElementById('speed-wrap');
const speedBtnLbl = document.getElementById('speed-btn-lbl');
const speedMenu   = document.getElementById('speed-menu');
const speedItems  = document.querySelectorAll('.sp-item');
const zoneLeft    = document.getElementById('zone-left');
const zoneMid     = document.getElementById('zone-mid');
const zoneRight   = document.getElementById('zone-right');

/* ── State ─────────────────────────────────────────────────────────────────── */
let ctrlVisible    = true;
let hideTimer      = null;
let seekFlashTimer = null;
let isScrubbing    = false;
let isFullscreen   = false;
let lastSpeed      = 1;

/* ── Disable download / save ────────────────────────────────────────────────
   1. controlsList already set in HTML attribute
   2. Block right-click / long-press context menu                             */
document.addEventListener('contextmenu', e => e.preventDefault());
document.addEventListener('selectstart', e => e.preventDefault());

/* ── Load video ─────────────────────────────────────────────────────────────── */
vid.src = '$videoSrc';
if ($autoPlayJs) {
  vid.autoplay = true;
  vid.play().catch(() => {});
}

/* ── Bridge to Flutter ──────────────────────────────────────────────────────── */
function reportState() {
  const state = {
    source:       SOURCE,
    isReady:      vid.readyState >= 2,
    isPlaying:    !vid.paused && !vid.ended,
    isMuted:      vid.muted,
    showControls: ctrlVisible,
    position:     Math.round(vid.currentTime  * 1000),
    duration:     Math.round((vid.duration||0)* 1000),
    playbackRate: vid.playbackRate,
  };
  if (window.flutter_inappwebview) {
    window.flutter_inappwebview.callHandler('nirmaanState', state);
  }
}
setInterval(() => { if (!vid.paused) reportState(); }, 500);

/* ── Video events ───────────────────────────────────────────────────────────── */
vid.addEventListener('play',     () => { syncPlayBtn(); reportState(); });
vid.addEventListener('pause',    () => { syncPlayBtn(); revealControls(false); reportState(); });
vid.addEventListener('ended',    () => { syncPlayBtn(); revealControls(false); reportState(); });
vid.addEventListener('seeked',   () => reportState());
vid.addEventListener('canplay',  () => reportState());
vid.addEventListener('timeupdate', updateProgress);

vid.addEventListener('progress', () => {
  if (!vid.duration) return;
  try {
    const b = vid.buffered;
    if (b.length) {
      progBuf.style.width = (b.end(b.length-1)/vid.duration*100)+'%';
    }
  } catch(e){}
});

/* ── Progress bar ───────────────────────────────────────────────────────────── */
function updateProgress() {
  if (!vid.duration || isScrubbing) return;
  const pct = vid.currentTime / vid.duration;
  progFill.style.width  = (pct*100)+'%';
  progThumb.style.left  = (pct*100)+'%';
  timeLbl.textContent   = fmt(vid.currentTime)+' / '+fmt(vid.duration);
}

function scrubFromEvent(e) {
  const rect = progWrap.getBoundingClientRect();
  const x    = ('touches' in e ? e.touches[0].clientX : e.clientX);
  const pct  = Math.max(0, Math.min(1, (x - rect.left) / rect.width));
  vid.currentTime = pct * vid.duration;
  progFill.style.width  = (pct*100)+'%';
  progThumb.style.left  = (pct*100)+'%';
  timeLbl.textContent   = fmt(vid.currentTime)+' / '+fmt(vid.duration);
}

progWrap.addEventListener('mousedown', e => {
  isScrubbing = true;
  scrubFromEvent(e);
  revealControls(false);
});
progWrap.addEventListener('touchstart', e => {
  isScrubbing = true;
  scrubFromEvent(e);
  revealControls(false);
}, {passive:true});
document.addEventListener('mousemove',  e => { if (isScrubbing) scrubFromEvent(e); });
document.addEventListener('touchmove',  e => { if (isScrubbing) scrubFromEvent(e); }, {passive:true});
document.addEventListener('mouseup',    () => { if (isScrubbing) { isScrubbing=false; revealControls(true); }});
document.addEventListener('touchend',   () => { if (isScrubbing) { isScrubbing=false; revealControls(true); }});

/* ── Controls visibility ────────────────────────────────────────────────────── */
function revealControls(autoHide) {
  ctrlVisible = true;
  [controls, topBar].forEach(el => el.classList.remove('hidden'));
  [scrimTop, scrimBot].forEach(el => el.classList.remove('scrim-hidden'));
  clearTimeout(hideTimer);
  if (autoHide && !vid.paused) {
    hideTimer = setTimeout(hideControls, AUTO_HIDE);
  }
}

function hideControls() {
  ctrlVisible = false;
  [controls, topBar].forEach(el => el.classList.add('hidden'));
  [scrimTop, scrimBot].forEach(el => el.classList.add('scrim-hidden'));
}

/* ── Tap zones ──────────────────────────────────────────────────────────────── */
// Double-tap tracking
const tapState = {left:0, mid:0, right:0};

function handleZoneTap(zone) {
  if (zone === 'mid') {
    if (!ctrlVisible) { revealControls(true); }
    else { hideControls(); }
    return;
  }
  const now = Date.now();
  const last = tapState[zone];
  tapState[zone] = now;
  if (now - last < 300) {
    // Double-tap
    tapState[zone] = 0;
    const delta = zone === 'left' ? -SEEK_STEP : SEEK_STEP;
    seek(delta);
    revealControls(true);
  } else {
    // Single-tap — reveal or hide
    if (!ctrlVisible) { revealControls(true); }
  }
}

zoneLeft.addEventListener('click',  () => handleZoneTap('left'));
zoneMid.addEventListener('click',   () => handleZoneTap('mid'));
zoneRight.addEventListener('click', () => handleZoneTap('right'));

/* ── Play / Pause ───────────────────────────────────────────────────────────── */
function togglePlay() {
  if (vid.paused || vid.ended) { vid.play().catch(()=>{}); }
  else                          { vid.pause(); }
  revealControls(true);
}

function syncPlayBtn() {
  const playing = !vid.paused && !vid.ended;
  iconPlay.style.display  = playing ? 'none' : 'block';
  iconPause.style.display = playing ? 'block' : 'none';
  centerIcon.textContent  = playing ? '' : '▶';
  centerIcon.classList.toggle('hidden', playing);
}

btnPlay.addEventListener('click', togglePlay);

/* ── Seek ±10 ───────────────────────────────────────────────────────────────── */
function seek(delta) {
  vid.currentTime = Math.max(0, Math.min(vid.duration||0, vid.currentTime + delta));
  showFlash((delta > 0 ? '+' : '') + delta + ' sec');
  reportState();
}

function showFlash(txt) {
  seekFlash.textContent = txt;
  seekFlash.classList.add('show');
  clearTimeout(seekFlashTimer);
  seekFlashTimer = setTimeout(() => seekFlash.classList.remove('show'), 700);
}

btnBack.addEventListener('click', () => { seek(-SEEK_STEP); revealControls(true); });
btnFwd.addEventListener('click',  () => { seek( SEEK_STEP); revealControls(true); });

/* ── Mute ───────────────────────────────────────────────────────────────────── */
function syncMute() {
  iconUnmuted.style.display = vid.muted ? 'none'  : 'block';
  iconMuted.style.display   = vid.muted ? 'block' : 'none';
}
btnMute.addEventListener('click', () => { vid.muted = !vid.muted; syncMute(); reportState(); revealControls(true); });

/* ── Speed ──────────────────────────────────────────────────────────────────── */
speedBtnLbl.addEventListener('click', e => {
  e.stopPropagation();
  speedMenu.classList.toggle('open');
  revealControls(false);
});

speedItems.forEach(item => {
  item.addEventListener('click', e => {
    e.stopPropagation();
    const sp = parseFloat(item.dataset.speed);
    vid.playbackRate = sp;
    lastSpeed = sp;
    speedBtnLbl.textContent = (sp === Math.floor(sp) ? sp.toFixed(0) : sp) + 'x';
    speedItems.forEach(i => i.classList.remove('active'));
    item.classList.add('active');
    speedMenu.classList.remove('open');
    revealControls(true);
    reportState();
  });
});

document.addEventListener('click', () => speedMenu.classList.remove('open'));

/* ── Fullscreen ─────────────────────────────────────────────────────────────── */
function toggleFs() {
  if (window.flutter_inappwebview) {
    window.flutter_inappwebview.callHandler('nirmaanFullscreen');
  }
}

function syncFsIcon(full) {
  iconFsEnter.style.display = full ? 'none'  : 'block';
  iconFsExit.style.display  = full ? 'block' : 'none';
}

btnFs.addEventListener('click', () => { toggleFs(); revealControls(true); });

/* ── Commands from Flutter (NirmaanYoutubeController) ───────────────────────── */
window.nirmaanCommand = function(cmd) {
  switch (cmd.type) {
    case 'play':   vid.play().catch(()=>{}); break;
    case 'pause':  vid.pause();              break;
    case 'seek':   vid.currentTime = cmd.seconds; break;
    case 'speed':  vid.playbackRate = cmd.rate;
                   speedBtnLbl.textContent = (cmd.rate===Math.floor(cmd.rate)?cmd.rate.toFixed(0):cmd.rate)+'x';
                   speedItems.forEach(i=>{
                     i.classList.toggle('active', parseFloat(i.dataset.speed)===cmd.rate);
                   });
                   break;
    case 'mute':   vid.muted = true;  syncMute(); break;
    case 'unmute': vid.muted = false; syncMute(); break;
  }
  reportState();
};

/* Called from Flutter after fullscreen transition */
window.nirmaanSetFullscreen = function(val) {
  isFullscreen = val;
  syncFsIcon(val);
};
window.nirmaanResizeFix  = function() {};
window.showControlsTemp  = function() { revealControls(true); };

/* ── Keyboard shortcuts (desktop/macOS) ─────────────────────────────────────── */
document.addEventListener('keydown', e => {
  switch(e.code) {
    case 'Space':       e.preventDefault(); togglePlay();          break;
    case 'ArrowRight':  e.preventDefault(); seek( SEEK_STEP);       break;
    case 'ArrowLeft':   e.preventDefault(); seek(-SEEK_STEP);       break;
    case 'KeyM':        vid.muted=!vid.muted; syncMute(); break;
    case 'KeyF':        toggleFs();            break;
  }
  revealControls(true);
});

/* ── Helpers ────────────────────────────────────────────────────────────────── */
function fmt(s) {
  if (!s || isNaN(s)) return '0:00';
  const h = Math.floor(s/3600);
  const m = Math.floor((s%3600)/60);
  const sec = Math.floor(s%60);
  return (h>0?h+':':'')+(h>0?String(m).padStart(2,'0'):m)+':'+String(sec).padStart(2,'0');
}

/* ── Init ───────────────────────────────────────────────────────────────────── */
syncPlayBtn();
syncMute();
revealControls(true);
})();
</script>
</body>
</html>''';
  }

  // ── All below: UNCHANGED from original ───────────────────────────────────

  Future<void> _toggleNativeFullscreen() async {
    try {
      _isNativeFullscreen = !_isNativeFullscreen;
      await FullScreenWindow.setFullScreen(_isNativeFullscreen);
      widget.onFullscreenChanged?.call(_isNativeFullscreen);
      await _webController?.evaluateJavascript(
        source: '''
          if (window.nirmaanSetFullscreen) {
            window.nirmaanSetFullscreen(${_isNativeFullscreen ? 'true' : 'false'});
          }
          if (window.nirmaanResizeFix) { window.nirmaanResizeFix(); }
          if (window.showControlsTemp) { window.showControlsTemp(); }
        ''',
      );
    } catch (e) {
      debugPrint('WINDOWS FULLSCREEN ERROR => $e');
    }
  }

  void _handleState(dynamic raw) {
    try {
      final value = raw is String ? jsonDecode(raw) : raw;
      if (value is! Map) return;
      if (value['source'] != 'nirmaan-youtube-windows') return;

      final posMs = (value['position'] as num?)?.round() ??
          (((value['positionSeconds'] as num?)?.toDouble() ?? 0.0) * 1000)
              .round();
      final durMs = (value['duration'] as num?)?.round() ??
          (((value['durationSeconds'] as num?)?.toDouble() ?? 0.0) * 1000)
              .round();

      widget.controller.updateValue(
        widget.controller.value.copyWith(
          isReady: value['isReady'] == true,
          isPlaying: value['isPlaying'] == true,
          isMuted: value['isMuted'] == true,
          position: Duration(milliseconds: posMs),
          duration: Duration(milliseconds: durMs),
          playbackRate: (value['playbackRate'] as num? ?? 1).toDouble(),
        ),
      );
    } catch (e) {
      debugPrint('WINDOWS YOUTUBE STATE ERROR => $e');
    }
  }

  Future<void> _sendToPlayer(Map<String, dynamic> data) async {
    final json = jsonEncode(data);
    await _webController?.evaluateJavascript(
      source: 'if (window.nirmaanCommand) { window.nirmaanCommand($json); }',
    );
  }

  Future<void> _play() async => _sendToPlayer({'type': 'play'});
  Future<void> _pause() async => _sendToPlayer({'type': 'pause'});
  Future<void> _mute() async => _sendToPlayer({'type': 'mute'});
  Future<void> _unMute() async => _sendToPlayer({'type': 'unmute'});
  Future<void> _seekTo(Duration pos) async =>
      _sendToPlayer({'type': 'seek', 'seconds': pos.inMilliseconds / 1000});
  Future<void> _setPlaybackRate(double rate) async =>
      _sendToPlayer({'type': 'speed', 'rate': rate});

  @override
  void dispose() {
    if (_isNativeFullscreen) FullScreenWindow.setFullScreen(false);
    _server?.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ),
      );
    }

    if (_playerUrl == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(_playerUrl!),
        headers: {'Referer': _playerUrl!},
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        transparentBackground: false,
        allowsInlineMediaPlayback: true,
        iframeAllow: 'autoplay; encrypted-media; fullscreen',
        iframeAllowFullscreen: true,
        supportZoom: false,
        builtInZoomControls: false,
        displayZoomControls: false,
      ),
      onWebViewCreated: (controller) {
        _webController = controller;
        controller.addJavaScriptHandler(
          handlerName: 'nirmaanState',
          callback: (args) {
            if (args.isNotEmpty) _handleState(args.first);
            return null;
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'nirmaanFullscreen',
          callback: (args) async {
            await _toggleNativeFullscreen();
            return null;
          },
        );
      },
    );
  }
}
