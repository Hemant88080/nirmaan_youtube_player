// features/lecture_player/models/offline_lecture.dart
//
// Simple plain-Dart model stored as JSON list in GetStorage.
// No Hive, no code-gen. Replaces the unused DownloadedLecture Hive model.

class OfflineLecture {
  final int lectureId;
  final int courseId;
  final String title;
  final String courseTitle;
  final String thumbnailUrl;
  final String youtubeUrl;
  final String localPath;
  final String duration;
  final DateTime downloadedAt;

  const OfflineLecture({
    required this.lectureId,
    required this.courseId,
    required this.title,
    required this.courseTitle,
    required this.thumbnailUrl,
    required this.youtubeUrl,
    required this.localPath,
    required this.duration,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
        'lectureId': lectureId,
        'courseId': courseId,
        'title': title,
        'courseTitle': courseTitle,
        'thumbnailUrl': thumbnailUrl,
        'youtubeUrl': youtubeUrl,
        'localPath': localPath,
        'duration': duration,
        'downloadedAt': downloadedAt.toIso8601String(),
      };

  factory OfflineLecture.fromJson(Map<String, dynamic> j) => OfflineLecture(
        lectureId: (j['lectureId'] as num).toInt(),
        courseId: (j['courseId'] as num? ?? 0).toInt(),
        title: j['title'] as String? ?? '',
        courseTitle: j['courseTitle'] as String? ?? '',
        thumbnailUrl: j['thumbnailUrl'] as String? ?? '',
        youtubeUrl: j['youtubeUrl'] as String? ?? '',
        localPath: j['localPath'] as String? ?? '',
        duration: j['duration'] as String? ?? '--',
        downloadedAt: DateTime.tryParse(j['downloadedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
