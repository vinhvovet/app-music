import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/fast_music_models.dart';

class FastCacheManager {
  static final FastCacheManager _instance = FastCacheManager._internal();
  factory FastCacheManager() => _instance;
  FastCacheManager._internal();
  
  SharedPreferences? _prefs;
  
  // Cache keys
  static const String _searchCacheKey = 'search_cache';
  static const String _streamCacheKey = 'stream_cache';
  static const String _lastCleanupKey = 'last_cleanup';
  
  // In-memory cache for ultra-fast access
  final Map<String, FastSearchResult> _searchCache = {};
  final Map<String, CachedStream> _streamCache = {};
  
  /// Initialize cache manager
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFromDisk();
    await _cleanupIfNeeded();
  }
  
  /// Cache search result
  Future<void> cacheSearchResult(FastSearchResult result) async {
    _searchCache[result.cacheKey] = result;
    await _saveToDisk();
  }
  
  /// Get cached search result
  FastSearchResult? getCachedSearchResult(String query, String type) {
    final cacheKey = '${type}_${query.toLowerCase().replaceAll(' ', '_')}';
    final cached = _searchCache[cacheKey];
    
    if (cached != null && cached.isCacheValid) {
      return cached;
    }
    
    // Remove expired cache
    if (cached != null && !cached.isCacheValid) {
      _searchCache.remove(cacheKey);
    }
    
    return null;
  }
  
  /// Cache stream URL
  Future<void> cacheStreamUrl(CachedStream stream) async {
    _streamCache[stream.cacheKey] = stream;
    await _saveToDisk();
  }
  
  /// Get cached stream URL
  String? getCachedStreamUrl(String trackId, AudioQuality quality) {
    final cacheKey = '${trackId}_${quality.name}';
    final cached = _streamCache[cacheKey];
    
    if (cached != null && cached.isValid) {
      return cached.url;
    }
    
    // Remove expired cache
    if (cached != null && !cached.isValid) {
      _streamCache.remove(cacheKey);
    }
    
    return null;
  }
  
  /// Save cache to disk for persistence
  Future<void> _saveToDisk() async {
    if (_prefs == null) return;
    
    try {
      // Save search cache
      final searchCacheJson = _searchCache.map((key, value) => 
        MapEntry(key, value.toJson()));
      await _prefs!.setString(_searchCacheKey, jsonEncode(searchCacheJson));
      
      // Save stream cache
      final streamCacheJson = _streamCache.map((key, value) => 
        MapEntry(key, value.toJson()));
      await _prefs!.setString(_streamCacheKey, jsonEncode(streamCacheJson));
      
    } catch (e) {
      print('[Cache Error] Failed to save cache: $e');
    }
  }
  
  /// Load cache from disk
  Future<void> _loadFromDisk() async {
    if (_prefs == null) return;
    
    try {
      // Load search cache
      final searchCacheString = _prefs!.getString(_searchCacheKey);
      if (searchCacheString != null) {
        final searchCacheJson = jsonDecode(searchCacheString) as Map<String, dynamic>;
        _searchCache.clear();
        
        for (final entry in searchCacheJson.entries) {
          try {
            final result = FastSearchResult.fromJson(entry.value);
            if (result.isCacheValid) {
              _searchCache[entry.key] = result;
            }
          } catch (e) {
            print('[Cache Warning] Invalid search cache entry: ${entry.key}');
          }
        }
      }
      
      // Load stream cache
      final streamCacheString = _prefs!.getString(_streamCacheKey);
      if (streamCacheString != null) {
        final streamCacheJson = jsonDecode(streamCacheString) as Map<String, dynamic>;
        _streamCache.clear();
        
        for (final entry in streamCacheJson.entries) {
          try {
            final stream = CachedStream.fromJson(entry.value);
            if (stream.isValid) {
              _streamCache[entry.key] = stream;
            }
          } catch (e) {
            print('[Cache Warning] Invalid stream cache entry: ${entry.key}');
          }
        }
      }
      
      print('[Cache] Loaded ${_searchCache.length} search results, ${_streamCache.length} streams');
      
    } catch (e) {
      print('[Cache Error] Failed to load cache: $e');
    }
  }
  
  /// Cleanup expired cache if needed
  Future<void> _cleanupIfNeeded() async {
    if (_prefs == null) return;
    
    final lastCleanup = _prefs!.getInt(_lastCleanupKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Cleanup every 6 hours
    if (now - lastCleanup > 6 * 60 * 60 * 1000) {
      await cleanupExpiredCache();
      await _prefs!.setInt(_lastCleanupKey, now);
    }
  }
  
  /// Cleanup expired cache entries
  Future<void> cleanupExpiredCache() async {
    final initialSearchCount = _searchCache.length;
    final initialStreamCount = _streamCache.length;
    
    // Remove expired search results
    _searchCache.removeWhere((key, value) => !value.isCacheValid);
    
    // Remove expired streams
    _streamCache.removeWhere((key, value) => !value.isValid);
    
    await _saveToDisk();
    
    final removedSearch = initialSearchCount - _searchCache.length;
    final removedStream = initialStreamCount - _streamCache.length;
    
    print('[Cache Cleanup] Removed $removedSearch search results, $removedStream streams');
  }
  
  /// Clear all cache
  Future<void> clearAllCache() async {
    _searchCache.clear();
    _streamCache.clear();
    
    if (_prefs != null) {
      await _prefs!.remove(_searchCacheKey);
      await _prefs!.remove(_streamCacheKey);
      await _prefs!.remove(_lastCleanupKey);
    }
    
    print('[Cache] All cache cleared');
  }
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final totalSearchTracks = _searchCache.values
      .fold<int>(0, (sum, result) => sum + result.tracks.length);
    
    final totalCacheSize = _estimateCacheSize();
    
    return {
      'searchResults': _searchCache.length,
      'totalTracks': totalSearchTracks,
      'streamUrls': _streamCache.length,
      'estimatedSizeMB': (totalCacheSize / (1024 * 1024)).toStringAsFixed(2),
      'validSearchResults': _searchCache.values.where((r) => r.isCacheValid).length,
      'validStreamUrls': _streamCache.values.where((s) => s.isValid).length,
    };
  }
  
  /// Estimate cache size in bytes
  int _estimateCacheSize() {
    int totalSize = 0;
    
    // Estimate search cache size
    for (final result in _searchCache.values) {
      totalSize += jsonEncode(result.toJson()).length;
    }
    
    // Estimate stream cache size
    for (final stream in _streamCache.values) {
      totalSize += jsonEncode(stream.toJson()).length;
    }
    
    return totalSize;
  }
  
  /// Pre-cache popular searches for instant results
  Future<void> preCachePopularSearches() async {
    // Implement this if you have a list of popular searches
    // For now, just cleanup
    await cleanupExpiredCache();
  }
  
  /// Get most searched terms for analytics
  List<String> getMostSearchedTerms() {
    final searchCounts = <String, int>{};
    
    for (final result in _searchCache.values) {
      final query = result.query.toLowerCase();
      searchCounts[query] = (searchCounts[query] ?? 0) + 1;
    }
    
    final sorted = searchCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(10).map((e) => e.key).toList();
  }
  
  /// Check if cache is healthy
  bool get isCacheHealthy {
    final stats = getCacheStats();
    final sizeMB = double.tryParse(stats['estimatedSizeMB']) ?? 0;
    
    // Cache is healthy if under 50MB and has reasonable hit rate
    return sizeMB < 50 && _searchCache.isNotEmpty;
  }
}
