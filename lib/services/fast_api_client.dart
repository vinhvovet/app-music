import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/constants.dart';
import '../data/fast_music_models.dart';

class FastYouTubeMusicClient {
  static final FastYouTubeMusicClient _instance = FastYouTubeMusicClient._internal();
  factory FastYouTubeMusicClient() => _instance;
  FastYouTubeMusicClient._internal();
  
  late Dio _dio;
  SharedPreferences? _prefs;
  String? _visitorId;
  
  // In-memory cache cho tốc độ cực nhanh
  final Map<String, FastSearchResult> _searchCache = {};
  final Map<String, CachedStream> _streamCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  /// Initialize client với cấu hình tối ưu
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _visitorId = _prefs?.getString('visitor_id') ?? _generateVisitorId();
    
    _dio = Dio(BaseOptions(
      connectTimeout: YouTubeMusicConstants.connectionTimeout,
      receiveTimeout: YouTubeMusicConstants.receiveTimeout,
      headers: {
        ...YouTubeMusicConstants.headers,
        'X-Goog-Visitor-Id': _visitorId!,
      },
    ));
    
    // Add interceptors cho logging và error handling
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (obj) => print('[FastAPI] $obj'),
    ));
    
    // Clean expired cache
    _cleanExpiredCache();
  }
  
  /// Search nhạc cực nhanh với smart caching
  Future<FastSearchResult> searchMusic(
    String query, {
    String type = 'songs',
    String? continuation,
  }) async {
    final cacheKey = '${type}_${query.toLowerCase().replaceAll(' ', '_')}';
    
    // Kiểm tra cache trước (10-50ms)
    if (_searchCache.containsKey(cacheKey)) {
      final cached = _searchCache[cacheKey]!;
      if (cached.isCacheValid) {
        print('[Cache Hit] Search: $query (${cached.tracks.length} tracks)');
        return cached;
      }
    }
    
    print('[API Call] Searching: $query');
    final stopwatch = Stopwatch()..start();
    
    try {
      // Tạo request payload giống YouTube Music client
      final payload = _buildSearchPayload(query, type, continuation);
      
      final response = await _dio.post(
        YouTubeMusicConstants.searchEndpoint,
        data: jsonEncode(payload),
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
      
      if (response.statusCode == 200) {
        final result = _parseSearchResponse(response.data, query, type);
        
        // Cache kết quả
        _searchCache[cacheKey] = result;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        stopwatch.stop();
        print('[API Success] Search completed in ${stopwatch.elapsedMilliseconds}ms');
        
        return result;
      } else {
        throw Exception('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      stopwatch.stop();
      print('[API Error] Search failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      
      // Return cached result nếu có lỗi
      if (_searchCache.containsKey(cacheKey)) {
        return _searchCache[cacheKey]!;
      }
      
      rethrow;
    }
  }
  
  /// Lấy stream URL cực nhanh
  Future<String?> getStreamUrl(String trackId, {AudioQuality quality = AudioQuality.medium}) async {
    final cacheKey = '${trackId}_${quality.name}';
    
    // Kiểm tra cache trước
    if (_streamCache.containsKey(cacheKey)) {
      final cached = _streamCache[cacheKey]!;
      if (cached.isValid) {
        print('[Cache Hit] Stream URL: $trackId');
        return cached.url;
      }
    }
    
    print('[API Call] Getting stream URL: $trackId');
    final stopwatch = Stopwatch()..start();
    
    try {
      final payload = _buildPlayerPayload(trackId);
      
      final response = await _dio.post(
        YouTubeMusicConstants.playerEndpoint,
        data: jsonEncode(payload),
      );
      
      if (response.statusCode == 200) {
        final streamUrl = _parseStreamResponse(response.data, quality);
        
        if (streamUrl != null) {
          // Cache stream URL
          _streamCache[cacheKey] = CachedStream(
            trackId: trackId,
            url: streamUrl,
            quality: quality,
            fileSize: null,
          );
          
          stopwatch.stop();
          print('[API Success] Stream URL retrieved in ${stopwatch.elapsedMilliseconds}ms');
          
          return streamUrl;
        }
      }
      
      throw Exception('Failed to get stream URL');
    } catch (e) {
      stopwatch.stop();
      print('[API Error] Stream URL failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      return null;
    }
  }
  
  /// Build search payload giống YouTube Music
  Map<String, dynamic> _buildSearchPayload(String query, String type, String? continuation) {
    final context = {
      'client': YouTubeMusicConstants.clientConfig,
      'user': {
        'lockedSafetyMode': false
      },
      'request': {
        'useSsl': true,
        'internalExperimentFlags': [],
      }
    };
    
    if (continuation != null) {
      return {
        'context': context,
        'continuation': continuation,
      };
    }
    
    return {
      'context': context,
      'query': query,
      'params': _getSearchParams(type),
    };
  }
  
  /// Build player payload
  Map<String, dynamic> _buildPlayerPayload(String videoId) {
    return {
      'context': {
        'client': YouTubeMusicConstants.clientConfig,
      },
      'videoId': videoId,
      'playlistId': null,
      'params': 'wAEB',
    };
  }
  
  /// Parse search response cực nhanh
  FastSearchResult _parseSearchResponse(Map<String, dynamic> data, String query, String type) {
    final tracks = <FastMusicTrack>[];
    String? continuation;
    
    try {
      // Navigate JSON structure efficiently
      final contents = _nav(data, ['contents', 'tabbedSearchResultsRenderer', 'tabs']);
      if (contents is List && contents.isNotEmpty) {
        final tabContent = _nav(contents[0], ['tabRenderer', 'content']);
        final sectionList = _nav(tabContent, ['sectionListRenderer', 'contents']);
        
        if (sectionList is List) {
          for (final section in sectionList) {
            final itemSection = _nav(section, ['musicShelfRenderer', 'contents']);
            if (itemSection is List) {
              for (final item in itemSection) {
                final track = _parseTrackItem(item);
                if (track != null) {
                  tracks.add(track);
                }
              }
            }
            
            // Extract continuation
            final nextContinuation = _nav(section, [
              'musicShelfRenderer',
              'continuations',
              0,
              'nextContinuationData',
              'continuation'
            ]);
            if (nextContinuation is String) {
              continuation = nextContinuation;
            }
          }
        }
      }
    } catch (e) {
      print('[Parse Error] Failed to parse search response: $e');
    }
    
    return FastSearchResult(
      tracks: tracks,
      continuation: continuation,
      query: query,
      type: type,
    );
  }
  
  /// Parse individual track item
  FastMusicTrack? _parseTrackItem(Map<String, dynamic> item) {
    try {
      final flexColumn = _nav(item, ['musicResponsiveListItemRenderer', 'flexColumns']);
      if (flexColumn is! List || flexColumn.isEmpty) return null;
      
      // Extract basic info
      final titleColumn = flexColumn[0];
      final titleRuns = _nav(titleColumn, ['text', 'runs']);
      final title = titleRuns is List && titleRuns.isNotEmpty 
        ? titleRuns[0]['text'] as String?
        : null;
      
      if (title == null) return null;
      
      // Extract video ID
      final navigationEndpoint = _nav(titleColumn, ['text', 'runs', 0, 'navigationEndpoint']);
      final videoId = _nav(navigationEndpoint, ['watchEndpoint', 'videoId']) as String?;
      
      if (videoId == null) return null;
      
      // Extract artist
      String? artist;
      if (flexColumn.length > 1) {
        final artistRuns = _nav(flexColumn[1], ['text', 'runs']);
        if (artistRuns is List && artistRuns.isNotEmpty) {
          artist = artistRuns[0]['text'] as String?;
        }
      }
      
      // Extract thumbnail
      final thumbnail = _nav(item, [
        'musicResponsiveListItemRenderer',
        'thumbnail',
        'musicThumbnailRenderer',
        'thumbnail',
        'thumbnails',
        0,
        'url'
      ]) as String?;
      
      return FastMusicTrack(
        id: videoId,
        title: title,
        artist: artist,
        thumbnailUrl: thumbnail,
      );
    } catch (e) {
      print('[Parse Error] Failed to parse track item: $e');
      return null;
    }
  }
  
  /// Parse stream response
  String? _parseStreamResponse(Map<String, dynamic> data, AudioQuality quality) {
    try {
      final formats = _nav(data, ['streamingData', 'adaptiveFormats']) as List?;
      if (formats == null) return null;
      
      // Tìm format phù hợp với quality
      for (final format in formats) {
        final mimeType = format['mimeType'] as String?;
        final url = format['url'] as String?;
        
        if (mimeType != null && url != null) {
          if (quality.codec == 'opus' && mimeType.contains('opus')) {
            return url;
          } else if (quality.codec == 'mp4a' && mimeType.contains('mp4a')) {
            return url;
          }
        }
      }
      
      // Fallback to first available
      return formats.isNotEmpty ? formats[0]['url'] as String? : null;
    } catch (e) {
      print('[Parse Error] Failed to parse stream response: $e');
      return null;
    }
  }
  
  /// Helper function để navigate JSON nhanh
  dynamic _nav(dynamic root, List<dynamic> path) {
    dynamic current = root;
    for (dynamic key in path) {
      if (key is String && current is Map && current.containsKey(key)) {
        current = current[key];
      } else if (key is int && current is List && key < current.length) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }
  
  /// Get search parameters for different types
  String _getSearchParams(String type) {
    switch (type) {
      case 'songs':
        return 'EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D';
      case 'albums':
        return 'EgWKAQIYAWoKEAkQBRAKEAMQBA%3D%3D';
      case 'artists':
        return 'EgWKAQIgAWoKEAkQBRAKEAMQBA%3D%3D';
      case 'playlists':
        return 'EgeKAQQoADgBagwQDhAKEAMQBRAJEAg%3D';
      default:
        return 'EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D';
    }
  }
  
  /// Generate visitor ID
  String _generateVisitorId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
    final random = DateTime.now().millisecondsSinceEpoch;
    String result = 'CgtM';
    
    for (int i = 0; i < 12; i++) {
      result += chars[(random + i) % chars.length];
    }
    
    _prefs?.setString('visitor_id', result);
    return result;
  }
  
  /// Clean expired cache
  void _cleanExpiredCache() {
    final now = DateTime.now();
    
    // Clean search cache
    _searchCache.removeWhere((key, value) => !value.isCacheValid);
    
    // Clean stream cache
    _streamCache.removeWhere((key, value) => !value.isValid);
    
    // Clean timestamps
    _cacheTimestamps.removeWhere((key, timestamp) => 
      now.difference(timestamp).inHours > 6);
  }
  
  /// Clear all cache
  void clearCache() {
    _searchCache.clear();
    _streamCache.clear();
    _cacheTimestamps.clear();
    print('[Cache] All caches cleared');
  }
  
  /// Get cache stats
  Map<String, int> getCacheStats() {
    return {
      'searchItems': _searchCache.length,
      'streamItems': _streamCache.length,
      'totalItems': _searchCache.length + _streamCache.length,
    };
  }
}
