import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaan_youtube_player/nirmaan_youtube_player.dart';

void main() {
  group('extractYoutubeVideoId', () {
    test('extracts an ID from supported YouTube URL formats', () {
      expect(
        extractYoutubeVideoId(
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        'dQw4w9WgXcQ',
      );

      expect(
        extractYoutubeVideoId('https://youtu.be/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );

      expect(
        extractYoutubeVideoId(
          'https://www.youtube.com/embed/dQw4w9WgXcQ',
        ),
        'dQw4w9WgXcQ',
      );

      expect(
        extractYoutubeVideoId(
          'https://www.youtube.com/shorts/dQw4w9WgXcQ',
        ),
        'dQw4w9WgXcQ',
      );
    });
  });
}