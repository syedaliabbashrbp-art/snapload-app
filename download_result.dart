class DownloadLink {
  final String type;     // 'video', 'audio', 'image'
  final String quality;  // '720p', 'MP3', etc
  final String url;
  final String filename;

  DownloadLink({
    required this.type,
    required this.quality,
    required this.url,
    required this.filename,
  });

  factory DownloadLink.fromJson(Map<String, dynamic> json) {
    return DownloadLink(
      type:     json['type']     ?? 'video',
      quality:  json['quality']  ?? 'Video',
      url:      json['url']      ?? '',
      filename: json['filename'] ?? 'video.mp4',
    );
  }
}

class DownloadResult {
  final bool success;
  final String platform;
  final List<DownloadLink> links;
  final String? error;

  DownloadResult({
    required this.success,
    required this.platform,
    required this.links,
    this.error,
  });

  factory DownloadResult.fromJson(Map<String, dynamic> json) {
    final rawLinks = json['links'] as List<dynamic>? ?? [];
    return DownloadResult(
      success:  json['success']  ?? false,
      platform: json['platform'] ?? 'unknown',
      links:    rawLinks.map((l) => DownloadLink.fromJson(l)).toList(),
      error:    json['error'],
    );
  }
}
