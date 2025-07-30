class Constants {
  // YouTube Music base URLs
  static const String baseUrl = 'https://music.youtube.com';
  static const String apiUrl = 'https://music.youtube.com/youtubei/v1';
  
  // API endpoints
  static const String searchEndpoint = '/search';
  static const String browseEndpoint = '/browse';
  static const String playerEndpoint = '/player';
  static const String nextEndpoint = '/next';
  
  // Client info
  static const String clientName = 'WEB_REMIX';
  static const String clientVersion = '1.20241028.01.00';
  static const String userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  
  // Headers
  static Map<String, String> get headers => {
    'User-Agent': userAgent,
    'Accept': '*/*',
    'Accept-Language': 'en-US,en;q=0.9',
    'Content-Type': 'application/json',
    'X-Goog-Api-Key': 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30',
    'X-Goog-Visitor-Id': 'CgtHSzhybFFfTTc1MCiJw6bEBjIKCgJWThIEGgAgMA%3D%3D',
  };
  
  // Search filters
  static const Map<String, String> searchFilters = {
    'songs': 'EgWKAQIIAWoKEAoQAxAEEAkQBQ%3D%3D',
    'videos': 'EgWKAQIQAWoKEAoQAxAEEAkQBQ%3D%3D',
    'albums': 'EgWKAQIYAWoKEAoQAxAEEAkQBQ%3D%3D',
    'artists': 'EgWKAQIgAWoKEAoQAxAEEAkQBQ%3D%3D',
    'playlists': 'EgWKAQIoAWoKEAoQAxAEEAkQBQ%3D%3D',
  };
}

// Helper functions for debugging
void printINFO(String message) {
  print('[INFO] $message');
}

void printERROR(String message) {
  print('[ERROR] $message');
}

void printDEBUG(String message) {
  print('[DEBUG] $message');
}
