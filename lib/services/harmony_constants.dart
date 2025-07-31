/// API constants and configurations - Harmony Music approach
class HarmonyAPIConstants {
  // YouTube Music Internal API endpoints
  static const String baseUrl = 'https://music.youtube.com/youtubei/v1';
  static const String apiKey = 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30';
  
  // Client headers for reverse engineering
  static const String clientName = '67'; // YouTube Music Web client
  static const String clientVersion = '1.20231213.01.00';
  static const String userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  
  // API endpoints
  static const String searchEndpoint = '$baseUrl/search';
  static const String browseEndpoint = '$baseUrl/browse';
  static const String playerEndpoint = '$baseUrl/player';
  static const String nextEndpoint = '$baseUrl/next';
  
  // Browse IDs for different content types
  static const String homeBrowseId = 'FEmusic_home';
  static const String trendingBrowseId = 'FEmusic_trending';
  static const String chartsTopSongsBrowseId = 'FEmusic_charts_top_songs_country';
  
  // Search filters
  static const String songsFilter = 'EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D';
  static const String videosFilter = 'EgWKAQIQAWoKEAkQChAFEAMQBA%3D%3D';
  static const String albumsFilter = 'EgWKAQIYAWoKEAkQChAFEAMQBA%3D%3D';
  static const String artistsFilter = 'EgWKAQIgAWoKEAkQChAFEAMQBA%3D%3D';
  static const String playlistsFilter = 'EgWKAQIoAWoKEAkQChAFEAMQBA%3D%3D';
  
  // Cache TTL configurations
  static const Duration searchCacheTTL = Duration(minutes: 30);
  static const Duration streamCacheTTL = Duration(hours: 6);
  static const Duration metadataCacheTTL = Duration(hours: 24);
  static const Duration thumbnailCacheTTL = Duration(days: 7);
  
  // Performance settings
  static const int maxConcurrentRequests = 5;
  static const Duration requestTimeout = Duration(seconds: 15);
  static const int retryAttempts = 3;
  static const Duration retryDelay = Duration(milliseconds: 500);
  
  // Popular Vietnamese search terms for pre-caching
  static const List<String> popularVietnameseQueries = [
    'nhạc trẻ 2024',
    'vpop',
    'sơn tùng mtp',
    'đen vâu',
    'justatee',
    'hieuthuhai',
    'karik',
    'rap việt',
    'nhạc chill',
    'acoustic',
    'ballad việt',
    'nhạc remix',
    'k-icm',
    'jack',
    'amee',
    'min',
    'erik',
    'duc phuc',
    'hoang thuy linh',
    'my tam'
  ];
  
  // Quality options for streams
  static const Map<String, String> audioQualities = {
    'low': 'opus/96kbps',
    'medium': 'opus/128kbps',
    'high': 'opus/160kbps',
    'highest': 'mp4a/256kbps'
  };
}

/// Request/Response models for API communication
class HarmonyAPIRequest {
  final String endpoint;
  final Map<String, dynamic> data;
  final Map<String, String> headers;
  final Duration timeout;
  
  const HarmonyAPIRequest({
    required this.endpoint,
    required this.data,
    required this.headers,
    this.timeout = HarmonyAPIConstants.requestTimeout,
  });
}

class HarmonyAPIResponse {
  final int statusCode;
  final Map<String, dynamic> data;
  final Duration responseTime;
  final bool fromCache;
  
  const HarmonyAPIResponse({
    required this.statusCode,
    required this.data,
    required this.responseTime,
    this.fromCache = false,
  });
  
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}
