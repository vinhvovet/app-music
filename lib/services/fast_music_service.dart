import 'dart:async';
import '../data/fast_music_models.dart';
import 'fast_api_client.dart';
import 'fast_cache_manager.dart';

class FastMusicService {
  static final FastMusicService _instance = FastMusicService._internal();
  factory FastMusicService() => _instance;
  FastMusicService._internal();
  
  final FastYouTubeMusicClient _apiClient = FastYouTubeMusicClient();
  final FastCacheManager _cacheManager = FastCacheManager();
  
  bool _isInitialized = false;
  
  /// Initialize service - call this in main()
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final stopwatch = Stopwatch()..start();
    
    await Future.wait([
      _apiClient.initialize(),
      _cacheManager.initialize(),
    ]);
    
    _isInitialized = true;
    stopwatch.stop();
    
    print('[FastMusicService] Initialized in ${stopwatch.elapsedMilliseconds}ms');
    print('[Cache Stats] ${_cacheManager.getCacheStats()}');
  }
  
  /// Search music với tốc độ cực nhanh
  /// Expected performance: 10-50ms (cache hit), 200-500ms (API call)
  Future<FastSearchResult> searchMusic(
    String query, {
    String type = 'songs',
    String? continuation,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final stopwatch = Stopwatch()..start();
    
    try {
      // 1. Kiểm tra cache trước (10-50ms)
      final cached = _cacheManager.getCachedSearchResult(query, type);
      if (cached != null) {
        stopwatch.stop();
        print('[🚀 Cache Hit] "$query" → ${cached.tracks.length} tracks (${stopwatch.elapsedMilliseconds}ms)');
        return cached;
      }
      
      // 2. API call với smart caching (200-500ms)
      print('[🔍 API Search] "$query"...');
      final result = await _apiClient.searchMusic(query, type: type, continuation: continuation);
      
      // 3. Cache kết quả
      await _cacheManager.cacheSearchResult(result);
      
      stopwatch.stop();
      print('[✅ Search Success] "$query" → ${result.tracks.length} tracks (${stopwatch.elapsedMilliseconds}ms)');
      
      return result;
      
    } catch (e) {
      stopwatch.stop();
      print('[❌ Search Error] "$query" failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      
      // Return empty result thay vì throw error
      return FastSearchResult(
        tracks: [],
        query: query,
        type: type,
      );
    }
  }
  
  /// Get stream URL cực nhanh
  /// Expected performance: 10-30ms (cache hit), 100-300ms (API call)
  Future<String?> getStreamUrl(
    String trackId, {
    AudioQuality quality = AudioQuality.medium,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final stopwatch = Stopwatch()..start();
    
    try {
      // 1. Kiểm tra cache trước
      final cached = _cacheManager.getCachedStreamUrl(trackId, quality);
      if (cached != null) {
        stopwatch.stop();
        print('[🚀 Stream Cache Hit] $trackId (${stopwatch.elapsedMilliseconds}ms)');
        return cached;
      }
      
      // 2. API call
      print('[🎵 Getting Stream] $trackId...');
      final streamUrl = await _apiClient.getStreamUrl(trackId, quality: quality);
      
      if (streamUrl != null) {
        // 3. Cache stream URL
        final cachedStream = CachedStream(
          trackId: trackId,
          url: streamUrl,
          quality: quality,
          fileSize: null,
        );
        await _cacheManager.cacheStreamUrl(cachedStream);
        
        stopwatch.stop();
        print('[✅ Stream Success] $trackId (${stopwatch.elapsedMilliseconds}ms)');
        
        return streamUrl;
      } else {
        stopwatch.stop();
        print('[❌ Stream Failed] $trackId - No URL found (${stopwatch.elapsedMilliseconds}ms)');
        return null;
      }
      
    } catch (e) {
      stopwatch.stop();
      print('[❌ Stream Error] $trackId failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      return null;
    }
  }
  
  /// Search với debouncing cho real-time search
  Timer? _searchTimer;
  final StreamController<FastSearchResult> _searchResultController = 
    StreamController<FastSearchResult>.broadcast();
  
  Stream<FastSearchResult> get searchResultStream => _searchResultController.stream;
  
  void searchWithDebounce(String query, {Duration delay = const Duration(milliseconds: 300)}) {
    _searchTimer?.cancel();
    
    if (query.trim().isEmpty) {
      _searchResultController.add(FastSearchResult(
        tracks: [],
        query: query,
        type: 'songs',
      ));
      return;
    }
    
    _searchTimer = Timer(delay, () async {
      final result = await searchMusic(query);
      _searchResultController.add(result);
    });
  }
  
  /// Batch search multiple queries
  Future<Map<String, FastSearchResult>> batchSearch(List<String> queries) async {
    final results = <String, FastSearchResult>{};
    
    // Execute searches in parallel for better performance
    final futures = queries.map((query) async {
      final result = await searchMusic(query);
      return MapEntry(query, result);
    });
    
    final completed = await Future.wait(futures);
    
    for (final entry in completed) {
      results[entry.key] = entry.value;
    }
    
    return results;
  }
  
  /// Pre-load popular Vietnamese music for instant results
  Future<void> preloadPopularMusic() async {
    const popularQueries = [
      'nhạc trẻ', 'ballad việt', 'rap việt', 'indie việt',
      'sơn tùng mtp', 'jack', 'đen vâu', 'hiền hồ',
      'hòa minzy', 'erik', 'min', 'amee'
    ];
    
    print('[🔥 Preloading] Popular Vietnamese music...');
    final stopwatch = Stopwatch()..start();
    
    // Load in background, don't wait
    unawaited(_batchPreload(popularQueries));
    
    stopwatch.stop();
    print('[🔥 Preload Started] ${popularQueries.length} queries (${stopwatch.elapsedMilliseconds}ms)');
  }
  
  Future<void> _batchPreload(List<String> queries) async {
    for (final query in queries) {
      try {
        await searchMusic(query);
        // Small delay to not overwhelm the API
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('[Preload Warning] Failed to preload "$query": $e');
      }
    }
    print('[🔥 Preload Complete] All popular music cached');
  }
  
  /// Get service statistics
  Map<String, dynamic> getStats() {
    final cacheStats = _cacheManager.getCacheStats();
    final apiStats = _apiClient.getCacheStats();
    
    return {
      'initialized': _isInitialized,
      'cache': cacheStats,
      'api': apiStats,
      'cacheHealthy': _cacheManager.isCacheHealthy,
      'popularSearches': _cacheManager.getMostSearchedTerms(),
    };
  }
  
  /// Clear all caches
  Future<void> clearAllCaches() async {
    await _cacheManager.clearAllCache();
    _apiClient.clearCache();
    print('[🧹 Cache Cleared] All caches cleared');
  }
  
  /// Dispose resources
  void dispose() {
    _searchTimer?.cancel();
    _searchResultController.close();
  }
}

// Helper function for unawaited futures
void unawaited(Future<void> future) {
  // Intentionally ignore the future
}
