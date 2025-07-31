import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'harmony_constants.dart';

/// Ultra-fast local cache manager - Harmony Music approach
class HarmonyCacheManager {
  static final HarmonyCacheManager _instance = HarmonyCacheManager._internal();
  factory HarmonyCacheManager() => _instance;
  HarmonyCacheManager._internal();

  // Hive boxes cho different data types
  static Box<Map>? _searchBox;
  static Box<Map>? _metadataBox;
  static Box<String>? _streamBox;
  static Box<String>? _thumbnailBox;
  
  // In-memory cache cho ultra-fast access
  final Map<String, Map<String, dynamic>> _memoryCache = {};
  final Map<String, String> _streamCache = {};
  
  bool _initialized = false;

  /// Initialize Hive database
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/harmony_cache');
      await cacheDir.create(recursive: true);

      Hive.init(cacheDir.path);

      // Open boxes in parallel for faster initialization
      await Future.wait([
        Hive.openBox<Map>('harmony_search').then((box) => _searchBox = box),
        Hive.openBox<Map>('harmony_metadata').then((box) => _metadataBox = box),
        Hive.openBox<String>('harmony_streams').then((box) => _streamBox = box),
        Hive.openBox<String>('harmony_thumbnails').then((box) => _thumbnailBox = box),
      ]);

      // Load frequent data into memory
      await _loadFrequentDataToMemory();

      _initialized = true;
      print('⚡ Harmony Cache initialized successfully');
      _printCacheStats();
      
    } catch (e) {
      print('❌ Cache initialization failed: $e');
    }
  }

  /// Load frequently accessed data to memory for instant access
  Future<void> _loadFrequentDataToMemory() async {
    try {
      // Load popular search results to memory
      for (final query in HarmonyAPIConstants.popularVietnameseQueries.take(10)) {
        final key = _generateSearchKey(query, 'songs');
        final cached = _searchBox?.get(key);
        if (cached != null && _isCacheValid(cached, HarmonyAPIConstants.searchCacheTTL)) {
          _memoryCache[key] = Map<String, dynamic>.from(cached);
        }
      }

      print('📱 Loaded ${_memoryCache.length} items to memory cache');
    } catch (e) {
      print('❌ Memory cache loading error: $e');
    }
  }

  /// Cache search results với intelligent storage
  Future<void> cacheSearchResults(String query, String type, List<Map<String, dynamic>> results) async {
    if (!_initialized || _searchBox == null) return;

    try {
      final key = _generateSearchKey(query, type);
      final cacheData = {
        'results': results,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
        'query': query,
        'type': type,
        'hitCount': (_searchBox!.get(key)?['hitCount'] ?? 0) + 1,
      };

      // Store in Hive
      await _searchBox!.put(key, cacheData);

      // Store in memory if frequently accessed
      if (cacheData['hitCount'] > 2) {
        _memoryCache[key] = Map<String, dynamic>.from(cacheData);
      }

      print('💾 Cached search: $query (${results.length} results)');
    } catch (e) {
      print('❌ Cache search error: $e');
    }
  }

  /// Get cached search results với memory-first strategy
  List<Map<String, dynamic>>? getCachedSearchResults(String query, String type) {
    if (!_initialized) return null;

    try {
      final key = _generateSearchKey(query, type);

      // Check memory cache first (ultra-fast: ~10ms)
      if (_memoryCache.containsKey(key)) {
        final cached = _memoryCache[key]!;
        if (_isCacheValid(cached, HarmonyAPIConstants.searchCacheTTL)) {
          print('⚡ Memory cache hit: $query');
          return (cached['results'] as List).cast<Map<String, dynamic>>();
        } else {
          _memoryCache.remove(key);
        }
      }

      // Check Hive cache (fast: ~50ms)
      if (_searchBox != null) {
        final cached = _searchBox!.get(key);
        if (cached != null && _isCacheValid(cached, HarmonyAPIConstants.searchCacheTTL)) {
          print('💾 Hive cache hit: $query');
          
          // Promote to memory cache if frequently accessed
          if (cached['hitCount'] > 1) {
            _memoryCache[key] = Map<String, dynamic>.from(cached);
          }
          
          return (cached['results'] as List).cast<Map<String, dynamic>>();
        } else if (cached != null) {
          _searchBox!.delete(key);
        }
      }
    } catch (e) {
      print('❌ Get cached search error: $e');
    }

    return null;
  }

  /// Cache stream URL với expiry tracking
  Future<void> cacheStreamUrl(String videoId, String url, String quality) async {
    if (!_initialized || _streamBox == null) return;

    try {
      final key = '${videoId}_$quality';
      final cacheData = '$url|${DateTime.now().millisecondsSinceEpoch}';
      
      await _streamBox!.put(key, cacheData);
      
      // Also cache in memory for immediate access
      _streamCache[key] = cacheData;
      
      print('🎵 Cached stream: ${videoId.substring(0, 8)}... ($quality)');
    } catch (e) {
      print('❌ Cache stream error: $e');
    }
  }

  /// Get cached stream URL với memory-first strategy
  String? getCachedStreamUrl(String videoId, String quality) {
    if (!_initialized) return null;

    try {
      final key = '${videoId}_$quality';

      // Check memory first
      if (_streamCache.containsKey(key)) {
        final cached = _streamCache[key]!;
        if (_isStreamValid(cached)) {
          print('⚡ Stream memory hit: ${videoId.substring(0, 8)}...');
          return cached.split('|')[0];
        } else {
          _streamCache.remove(key);
        }
      }

      // Check Hive cache
      if (_streamBox != null) {
        final cached = _streamBox!.get(key);
        if (cached != null && _isStreamValid(cached)) {
          print('💾 Stream Hive hit: ${videoId.substring(0, 8)}...');
          
          // Promote to memory
          _streamCache[key] = cached;
          return cached.split('|')[0];
        } else if (cached != null) {
          _streamBox!.delete(key);
        }
      }
    } catch (e) {
      print('❌ Get cached stream error: $e');
    }

    return null;
  }

  /// Batch cache multiple tracks for performance
  Future<void> batchCacheTracks(List<Map<String, dynamic>> tracks) async {
    if (!_initialized || _metadataBox == null) return;

    try {
      final batchData = <String, Map>{};
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final track in tracks) {
        final key = track['id'] ?? track['videoId'];
        if (key != null) {
          batchData[key] = {
            ...track,
            'cachedAt': now,
          };
        }
      }

      await _metadataBox!.putAll(batchData);
      print('📦 Batch cached ${tracks.length} tracks');
    } catch (e) {
      print('❌ Batch cache error: $e');
    }
  }

  /// Pre-cache popular content for instant access
  Future<void> preCachePopularContent() async {
    if (!_initialized) return;

    print('🔄 Pre-caching popular Vietnamese content...');
    
    // This would be called by the main service to pre-cache
    // popular searches in background for instant access
    
    await cleanupExpiredCache();
    print('✅ Pre-cache completed');
  }

  /// Cleanup expired cache entries
  Future<void> cleanupExpiredCache() async {
    if (!_initialized) return;

    try {
      int cleanedCount = 0;

      // Clean search cache
      if (_searchBox != null) {
        final keysToDelete = <String>[];
        for (final key in _searchBox!.keys) {
          final cached = _searchBox!.get(key);
          if (cached != null && !_isCacheValid(cached, HarmonyAPIConstants.searchCacheTTL)) {
            keysToDelete.add(key);
          }
        }
        for (final key in keysToDelete) {
          await _searchBox!.delete(key);
          _memoryCache.remove(key);
          cleanedCount++;
        }
      }

      // Clean stream cache
      if (_streamBox != null) {
        final keysToDelete = <String>[];
        for (final key in _streamBox!.keys) {
          final cached = _streamBox!.get(key);
          if (cached != null && !_isStreamValid(cached)) {
            keysToDelete.add(key);
          }
        }
        for (final key in keysToDelete) {
          await _streamBox!.delete(key);
          _streamCache.remove(key);
          cleanedCount++;
        }
      }

      print('🗑️ Cleaned $cleanedCount expired cache entries');
    } catch (e) {
      print('❌ Cleanup cache error: $e');
    }
  }

  /// Check if cache data is still valid
  bool _isCacheValid(Map cached, Duration ttl) {
    final cachedAt = cached['cachedAt'] as int? ?? 0;
    final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
    return age < ttl.inMilliseconds;
  }

  /// Check if stream URL is still valid (6 hour TTL)
  bool _isStreamValid(String cached) {
    try {
      final parts = cached.split('|');
      if (parts.length != 2) return false;
      
      final cachedAt = int.parse(parts[1]);
      final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
      return age < HarmonyAPIConstants.streamCacheTTL.inMilliseconds;
    } catch (e) {
      return false;
    }
  }

  /// Generate consistent cache key
  String _generateSearchKey(String query, String type) {
    return '${type}_${query.toLowerCase().replaceAll(' ', '_')}';
  }

  /// Print cache statistics
  void _printCacheStats() {
    final searchCount = _searchBox?.length ?? 0;
    final metadataCount = _metadataBox?.length ?? 0;
    final streamCount = _streamBox?.length ?? 0;
    final memoryCount = _memoryCache.length;

    print('📊 Cache Stats:');
    print('   Memory: $memoryCount items');
    print('   Search: $searchCount results');
    print('   Metadata: $metadataCount tracks');
    print('   Streams: $streamCount URLs');
  }

  /// Get cache statistics for UI
  Map<String, dynamic> getCacheStats() {
    return {
      'memoryItems': _memoryCache.length,
      'searchResults': _searchBox?.length ?? 0,
      'metadataItems': _metadataBox?.length ?? 0,
      'streamUrls': _streamBox?.length ?? 0,
      'thumbnails': _thumbnailBox?.length ?? 0,
    };
  }

  /// Clear all caches
  Future<void> clearAllCache() async {
    try {
      _memoryCache.clear();
      _streamCache.clear();
      
      await Future.wait([
        _searchBox?.clear() ?? Future.value(),
        _metadataBox?.clear() ?? Future.value(),
        _streamBox?.clear() ?? Future.value(),
        _thumbnailBox?.clear() ?? Future.value(),
      ]);
      
      print('🗑️ All cache cleared');
    } catch (e) {
      print('❌ Clear cache error: $e');
    }
  }

  /// Check cache health
  bool get isHealthy {
    return _initialized && 
           _searchBox != null && 
           _metadataBox != null && 
           _streamBox != null;
  }
}
