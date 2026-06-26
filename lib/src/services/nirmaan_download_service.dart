// lib/src/services/nirmaan_download_service.dart
//
// Manages offline downloads for YouTube lectures.
// ─────────────────────────────────────────────────────────────────────────
//  Renamed:  YoutubeDownloadService  →  NirmaanDownloadService
//  The typedef at the bottom keeps the old name working so existing app
//  code that references YoutubeDownloadService does not need to change.
// ─────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../models/offline_lecture.dart';

class NirmaanDownloadService extends GetxService {
  static NirmaanDownloadService get I => Get.find();

  final _yt = YoutubeExplode();
  final _dio = Dio(
    BaseOptions(
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
            'AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/120.0.0.0 Safari/537.36',
        'Accept': '*/*',
        'Accept-Language': 'en-US,en;q=0.9',
        'Referer': 'https://www.youtube.com/',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 30),
    ),
  );
  final _box = GetStorage();

  static const _kList = 'offline_lectures_v1';

  final RxList<OfflineLecture> downloads = <OfflineLecture>[].obs;
  final RxMap<String, double> downloadProgress = <String, double>{}.obs;
  final RxMap<String, bool> downloading = <String, bool>{}.obs;

  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, Future<String?>> _runningDownloads = {};

  // ── Public query helpers ──────────────────────────────────────────────────

  bool isDownloading(String lectureId) => downloading[lectureId] == true;

  double progressFor(String lectureId) => downloadProgress[lectureId] ?? 0.0;

  OfflineLecture? downloadedLecture(String lectureId) {
    for (final item in downloads) {
      if (item.lectureId.toString() == lectureId) return item;
    }
    return null;
  }

  bool hasDownloadedSync(String lectureId) =>
      downloadedLecture(lectureId) != null;

  // ── Download ──────────────────────────────────────────────────────────────

  /// Starts (or joins an already-running) download for [youtubeUrl].
  /// Returns the local MP4 path on success, or null on failure / cancel.
  Future<String?> downloadYoutubeVideo({
    required String youtubeUrl,
    required String lectureId,
    required int lectureIdInt,
    required int courseId,
    required String title,
    required String courseTitle,
    required String thumbnailUrl,
    required String duration,
    void Function(double)? onProgress,
  }) {
    final running = _runningDownloads[lectureId];
    if (running != null) return running;

    final future = _downloadYoutubeVideo(
      youtubeUrl: youtubeUrl,
      lectureId: lectureId,
      lectureIdInt: lectureIdInt,
      courseId: courseId,
      title: title,
      courseTitle: courseTitle,
      thumbnailUrl: thumbnailUrl,
      duration: duration,
      onProgress: onProgress,
    );

    _runningDownloads[lectureId] = future;
    return future;
  }

  Future<String?> _downloadYoutubeVideo({
    required String youtubeUrl,
    required String lectureId,
    required int lectureIdInt,
    required int courseId,
    required String title,
    required String courseTitle,
    required String thumbnailUrl,
    required String duration,
    void Function(double)? onProgress,
  }) async {
    _setDownloading(lectureId, true);
    _setProgress(lectureId, 0, onProgress);

    try {
      // getApplicationDocumentsDirectory() needs no Android/iOS permissions.
      if (!await _requestPermission()) {
        _safeSnackbar('Permission Denied', 'Storage permission is required');
        return null;
      }

      // Already downloaded?
      final existingPath = await getLocalPath(lectureId);
      if (existingPath != null) {
        _upsert(
          OfflineLecture(
            lectureId: lectureIdInt,
            courseId: courseId,
            title: title,
            courseTitle: courseTitle,
            thumbnailUrl: thumbnailUrl,
            youtubeUrl: youtubeUrl,
            localPath: existingPath,
            duration: duration,
            downloadedAt: DateTime.now(),
          ),
        );
        _setProgress(lectureId, 1, onProgress);
        return existingPath;
      }

      final filePath = await _offlinePathFor(lectureId, courseId: courseId);
      final file = File(filePath);
      await file.parent.create(recursive: true);

      if (await file.exists()) {
        _upsert(
          OfflineLecture(
            lectureId: lectureIdInt,
            courseId: courseId,
            title: title,
            courseTitle: courseTitle,
            thumbnailUrl: thumbnailUrl,
            youtubeUrl: youtubeUrl,
            localPath: filePath,
            duration: duration,
            downloadedAt: DateTime.now(),
          ),
        );
        _setProgress(lectureId, 1, onProgress);
        return filePath;
      }

      // Resolve best available muxed stream via youtube_explode_dart.
      // Muxed streams (audio+video in one file) simplify offline playback.
      // Some videos only expose progressive streams — fall back if muxed is empty.
      final video = await _yt.videos.get(youtubeUrl);
      final manifest = await _yt.videos.streamsClient.getManifest(video.id);

      final StreamInfo streamInfo;
      if (manifest.muxed.isNotEmpty) {
        streamInfo = manifest.muxed.withHighestBitrate();
      } else if (manifest.video.isNotEmpty) {
        streamInfo = manifest.video.withHighestBitrate();
      } else {
        throw Exception('No downloadable streams found for this video');
      }

      final cancelToken = CancelToken();
      _cancelTokens[lectureId] = cancelToken;

      await _dio.download(
        streamInfo.url.toString(),
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          _setProgress(lectureId, received / total, onProgress);
        },
      );

      _upsert(
        OfflineLecture(
          lectureId: lectureIdInt,
          courseId: courseId,
          title: title,
          courseTitle: courseTitle,
          thumbnailUrl: thumbnailUrl,
          youtubeUrl: youtubeUrl,
          localPath: filePath,
          duration: duration,
          downloadedAt: DateTime.now(),
        ),
      );
      _setProgress(lectureId, 1, onProgress);
      return filePath;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        await _deletePartialFile(lectureId, courseId: courseId);
        return null;
      }
      debugPrint('NirmaanDownloadService DioException: $e');
      _safeSnackbar('Download Failed', 'Please try again');
      return null;
    } catch (e) {
      debugPrint('NirmaanDownloadService error: $e');
      _safeSnackbar('Download Failed', 'Please try again');
      return null;
    } finally {
      _cancelTokens.remove(lectureId);
      _runningDownloads.remove(lectureId);
      _setDownloading(lectureId, false);
      downloadProgress.remove(lectureId);
      downloadProgress.refresh();
    }
  }

  // ── ADD this private helper anywhere in the class ──────────────────────────
  void _safeSnackbar(String title, String message) {
    try {
      // Only show if there is a valid GetX overlay context (i.e. GetMaterialApp).
      // Falls back to a console print for apps that use plain MaterialApp.
      if (Get.overlayContext != null) {
        Get.snackbar(
          title,
          message,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        debugPrint('NirmaanDownloadService [$title]: $message');
      }
    } catch (e) {
      debugPrint('NirmaanDownloadService [$title]: $message');
    }
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  /// Cancel one (by id) or all active downloads (no id).
  void cancelDownload([String? lectureId]) {
    if (lectureId == null) {
      for (final token in _cancelTokens.values) {
        token.cancel('User cancelled');
      }
      return;
    }
    _cancelTokens[lectureId]?.cancel('User cancelled');
  }

  // ── Path resolution ───────────────────────────────────────────────────────

  /// Returns the path of a downloaded lecture, or null if not found.
  Future<String?> getLocalPath(String lectureId) async {
    final downloaded = downloadedLecture(lectureId);
    if (downloaded != null && await File(downloaded.localPath).exists()) {
      return downloaded.localPath;
    }

    final legacyPath = await _legacyOfflinePathFor(lectureId);
    if (await File(legacyPath).exists()) return legacyPath;

    return _findStoredPath(lectureId);
  }

  Future<bool> hasDownloaded(String lectureId) async =>
      await getLocalPath(lectureId) != null;

  // ── List & refresh ────────────────────────────────────────────────────────

  Future<List<OfflineLecture>> getAllDownloads() => refreshDownloads();

  Future<List<OfflineLecture>> refreshDownloads() async {
    final raw = _box.read<List>(_kList) ?? [];
    final all = <OfflineLecture>[];

    for (final item in raw) {
      try {
        if (item is Map) {
          all.add(OfflineLecture.fromJson(Map<String, dynamic>.from(item)));
        }
      } catch (e) {
        debugPrint('Skipping invalid offline lecture metadata: $e');
      }
    }

    final valid = <OfflineLecture>[];
    final staleIds = <int>[];

    for (final item in all) {
      if (await File(item.localPath).exists()) {
        valid.add(item);
      } else {
        staleIds.add(item.lectureId);
      }
    }

    _sortDownloads(valid);
    downloads.assignAll(valid);

    if (staleIds.isNotEmpty) {
      _persistDownloads(valid);
    }

    return valid;
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> deleteDownload(String lectureId) async {
    cancelDownload(lectureId);
    final paths = <String>{};
    final item = downloadedLecture(lectureId);
    if (item != null && item.localPath.isNotEmpty) paths.add(item.localPath);
    paths.add(await _legacyOfflinePathFor(lectureId));
    final foundPath = await _findStoredPath(lectureId);
    if (foundPath != null) paths.add(foundPath);

    for (final path in paths) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }

    _remove(lectureId);
  }

  Future<void> deleteAllDownloads() async {
    final items = List<OfflineLecture>.from(downloads);
    if (items.isEmpty) {
      await refreshDownloads();
      items.addAll(downloads);
    }
    for (final item in items) {
      await deleteDownload(item.lectureId.toString());
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<String> _offlinePathFor(String lectureId, {int? courseId}) async {
    final dir = await getApplicationDocumentsDirectory();
    if (courseId != null && courseId > 0) {
      return '${dir.path}/lectures/offline/course_$courseId/$lectureId.mp4';
    }
    return _legacyOfflinePathFromDir(dir.path, lectureId);
  }

  Future<String> _legacyOfflinePathFor(String lectureId) async {
    final dir = await getApplicationDocumentsDirectory();
    return _legacyOfflinePathFromDir(dir.path, lectureId);
  }

  String _legacyOfflinePathFromDir(String docsPath, String lectureId) {
    return '$docsPath/lectures/offline/$lectureId.mp4';
  }

  Future<String?> _findStoredPath(String lectureId) async {
    final dir = await getApplicationDocumentsDirectory();
    final offlineDir = Directory('${dir.path}/lectures/offline');
    if (!await offlineDir.exists()) return null;

    await for (final entity
        in offlineDir.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('/$lectureId.mp4')) {
        return entity.path;
      }
    }
    return null;
  }

  Future<void> _deletePartialFile(String lectureId, {int? courseId}) async {
    final paths = <String>{
      await _offlinePathFor(lectureId, courseId: courseId),
      await _legacyOfflinePathFor(lectureId),
    };
    for (final path in paths) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  void _setDownloading(String lectureId, bool value) {
    if (value) {
      downloading[lectureId] = true;
    } else {
      downloading.remove(lectureId);
    }
    downloading.refresh();
  }

  void _setProgress(
    String lectureId,
    double value,
    void Function(double)? onProgress,
  ) {
    final progress = value.clamp(0.0, 1.0).toDouble();
    downloadProgress[lectureId] = progress;
    downloadProgress.refresh();
    onProgress?.call(progress);
  }

  void _upsert(OfflineLecture lecture) {
    final list = downloads
        .where((item) => item.lectureId != lecture.lectureId)
        .toList()
      ..add(lecture);
    _sortDownloads(list);
    downloads.assignAll(list);
    _persistDownloads(list);
  }

  void _remove(String lectureId) {
    final list = downloads
        .where((item) => item.lectureId.toString() != lectureId)
        .toList();
    downloads.assignAll(list);
    _persistDownloads(list);
  }

  void _persistDownloads(List<OfflineLecture> list) {
    _box.write(_kList, list.map((item) => item.toJson()).toList());
  }

  void _sortDownloads(List<OfflineLecture> list) {
    list.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
  }

  /// getApplicationDocumentsDirectory() requires NO Android/iOS permissions.
  /// This method is kept for API compatibility; always returns true.
  Future<bool> _requestPermission() async => true;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    unawaited(refreshDownloads());
  }

  @override
  void onClose() {
    cancelDownload();
    _yt.close();
    _dio.close(force: true);
    super.onClose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Backward-compat alias.
//  Existing app code that uses YoutubeDownloadService.I continues to compile
//  without any changes.
// ─────────────────────────────────────────────────────────────────────────────
typedef YoutubeDownloadService = NirmaanDownloadService;
