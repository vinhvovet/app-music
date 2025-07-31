class YouTubeMusicConstants {
  // YouTube Music Internal API Endpoints
  static const String baseUrl = 'https://music.youtube.com';
  static const String apiBaseUrl = 'https://music.youtube.com/youtubei/v1';
  
  // Critical endpoints for fast data access
  static const String searchEndpoint = '$apiBaseUrl/search';
  static const String browseEndpoint = '$apiBaseUrl/browse';
  static const String playerEndpoint = '$apiBaseUrl/player';
  static const String nextEndpoint = '$apiBaseUrl/next';
  
  // Client information for API authentication
  static const Map<String, dynamic> clientConfig = {
    'clientName': 'WEB_REMIX',
    'clientVersion': '1.20240701.01.00',
    'hl': 'vi', // Vietnamese
    'gl': 'VN', // Vietnam
    'experimentIds': [],
    'utcOffsetMinutes': 420, // GMT+7
  };
  
  // Headers để giả mạo YouTube Music client
  static const Map<String, String> headers = {
    'Accept': '*/*',
    'Accept-Encoding': 'gzip, deflate',
    'Accept-Language': 'vi-VN,vi;q=0.9,en;q=0.8',
    'Content-Type': 'application/json',
    'Origin': 'https://music.youtube.com',
    'Referer': 'https://music.youtube.com/',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
    'X-Goog-AuthUser': '0',
    'X-YouTube-Client-Name': '67', // YouTube Music Web
    'X-YouTube-Client-Version': '1.20240701.01.00',
    'X-Goog-Visitor-Id': '', // Will be set dynamically
  };
  
  // Search contexts for different types
  static const Map<String, Map<String, dynamic>> searchContexts = {
    'songs': {
      'category': 1,
      'filter': 'songs',
    },
    'albums': {
      'category': 2,
      'filter': 'albums',
    },
    'artists': {
      'category': 3,
      'filter': 'artists',
    },
    'playlists': {
      'category': 4,
      'filter': 'playlists',
    },
  };
  
  // Caching configuration
  static const Duration cacheExpiry = Duration(hours: 6);
  static const Duration streamUrlExpiry = Duration(hours: 1);
  static const int maxCacheSize = 500; // Max cached items
  
  // Quality presets
  static const List<String> audioQualities = [
    'high',    // opus ~160kbps
    'medium',  // opus ~128kbps  
    'low',     // opus ~96kbps
  ];
  
  // Batch processing limits
  static const int maxBatchSize = 50;
  static const int defaultPageSize = 20;
  
  // Timeout configurations
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  
  // Popular Vietnamese search terms for better results
  static const List<String> vietnameseGenres = [
    'nhạc trẻ', 'bolero', 'nhạc vàng', 'rap việt',
    'indie việt', 'pop việt', 'rock việt', 'folk việt'
  ];
}
