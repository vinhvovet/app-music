/// Optimized music track model - chỉ lưu data cần thiết
class FastMusicTrack {
  final String id;
  final String title;
  final String? artist;
  final String? album;
  final String? thumbnailUrl;
  final int? duration; // in seconds
  final DateTime cachedAt;
  
  // Stream URLs - cached separately với expiry ngắn hơn
  String? _streamUrl;
  DateTime? _streamCachedAt;
  
  FastMusicTrack({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    this.thumbnailUrl,
    this.duration,
    DateTime? cachedAt,
  }) : cachedAt = cachedAt ?? DateTime.now();
  
  // Getters
  String get displayTitle => title.trim();
  String get displayArtist => artist?.trim() ?? 'Unknown Artist';
  String get displayAlbum => album?.trim() ?? '';
  String get displayDuration => _formatDuration(duration);
  bool get isCacheValid => DateTime.now().difference(cachedAt).inHours < 6;
  
  // Stream URL management
  String? get streamUrl => _isStreamValid ? _streamUrl : null;
  bool get _isStreamValid => 
    _streamUrl != null && 
    _streamCachedAt != null && 
    DateTime.now().difference(_streamCachedAt!).inHours < 1;
  
  void setStreamUrl(String url) {
    _streamUrl = url;
    _streamCachedAt = DateTime.now();
  }
  
  void clearStream() {
    _streamUrl = null;
    _streamCachedAt = null;
  }
  
  // Helper methods
  String _formatDuration(int? seconds) {
    if (seconds == null) return '';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  // JSON serialization - optimized
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'album': album,
    'thumbnailUrl': thumbnailUrl,
    'duration': duration,
    'cachedAt': cachedAt.millisecondsSinceEpoch,
  };
  
  factory FastMusicTrack.fromJson(Map<String, dynamic> json) {
    return FastMusicTrack(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      artist: json['artist'],
      album: json['album'],
      thumbnailUrl: json['thumbnailUrl'],
      duration: json['duration'],
      cachedAt: json['cachedAt'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(json['cachedAt'])
        : DateTime.now(),
    );
  }
  
  // Equality và hashCode cho efficient caching
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is FastMusicTrack && runtimeType == other.runtimeType && id == other.id;
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() => 'FastMusicTrack(id: $id, title: $title, artist: $artist)';
}

/// Search result model - optimized for batch processing
class FastSearchResult {
  final List<FastMusicTrack> tracks;
  final String? continuation; // For pagination
  final DateTime cachedAt;
  final String query;
  final String type; // 'songs', 'albums', etc.
  
  FastSearchResult({
    required this.tracks,
    this.continuation,
    required this.query,
    required this.type,
    DateTime? cachedAt,
  }) : cachedAt = cachedAt ?? DateTime.now();
  
  bool get isCacheValid => DateTime.now().difference(cachedAt).inHours < 3;
  bool get hasMore => continuation != null && continuation!.isNotEmpty;
  
  // Cache key for efficient lookup
  String get cacheKey => '${type}_${query.toLowerCase().replaceAll(' ', '_')}';
  
  // JSON serialization
  Map<String, dynamic> toJson() => {
    'tracks': tracks.map((track) => track.toJson()).toList(),
    'continuation': continuation,
    'cachedAt': cachedAt.millisecondsSinceEpoch,
    'query': query,
    'type': type,
  };
  
  factory FastSearchResult.fromJson(Map<String, dynamic> json) {
    return FastSearchResult(
      tracks: (json['tracks'] as List<dynamic>?)
        ?.map((trackJson) => FastMusicTrack.fromJson(trackJson))
        .toList() ?? [],
      continuation: json['continuation'],
      query: json['query'] ?? '',
      type: json['type'] ?? 'songs',
      cachedAt: json['cachedAt'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(json['cachedAt'])
        : DateTime.now(),
    );
  }
}

/// Stream quality options
enum AudioQuality {
  low(96, 'opus'),
  medium(128, 'opus'), 
  high(160, 'opus'),
  highest(256, 'mp4a');
  
  const AudioQuality(this.bitrate, this.codec);
  final int bitrate;
  final String codec;
  
  String get description => '${codec.toUpperCase()} ${bitrate}kbps';
}

/// Cached stream info
class CachedStream {
  final String trackId;
  final String url;
  final AudioQuality quality;
  final DateTime cachedAt;
  final int? fileSize;
  
  CachedStream({
    required this.trackId,
    required this.url,
    required this.quality,
    required this.fileSize,
    DateTime? cachedAt,
  }) : cachedAt = cachedAt ?? DateTime.now();
  
  bool get isValid => DateTime.now().difference(cachedAt).inMinutes < 30;
  
  String get cacheKey => '${trackId}_${quality.name}';
  
  // JSON serialization
  Map<String, dynamic> toJson() => {
    'trackId': trackId,
    'url': url,
    'quality': quality.name,
    'cachedAt': cachedAt.millisecondsSinceEpoch,
    'fileSize': fileSize,
  };
  
  factory CachedStream.fromJson(Map<String, dynamic> json) {
    return CachedStream(
      trackId: json['trackId'] ?? '',
      url: json['url'] ?? '',
      quality: AudioQuality.values.firstWhere(
        (q) => q.name == json['quality'],
        orElse: () => AudioQuality.medium,
      ),
      fileSize: json['fileSize'],
      cachedAt: json['cachedAt'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(json['cachedAt'])
        : DateTime.now(),
    );
  }
}
