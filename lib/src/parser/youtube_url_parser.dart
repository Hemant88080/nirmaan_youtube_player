String extractYoutubeVideoId(String url) {
  final uri = Uri.tryParse(url.trim());

  if (uri == null) return url.trim();

  if (uri.host.contains('youtu.be')) {
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
  }

  if (uri.queryParameters['v'] != null) {
    return uri.queryParameters['v']!;
  }

  if (uri.pathSegments.contains('embed')) {
    final index = uri.pathSegments.indexOf('embed');
    if (uri.pathSegments.length > index + 1) {
      return uri.pathSegments[index + 1];
    }
  }

  if (uri.pathSegments.contains('shorts')) {
    final index = uri.pathSegments.indexOf('shorts');
    if (uri.pathSegments.length > index + 1) {
      return uri.pathSegments[index + 1];
    }
  }

  return url.trim();
}
