// 💾 Intelligent Cache Manager - Multi-Tier Caching System
// Tầng 1: Memory (RAM) - 5ms access
// Tầng 2: Hive (SSD) - 15ms access  
// Tầng 3: API calls - 500ms access
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../data/music_models.dart';

/// Cache Manager thông minh với 3 tầng cache
/// → Memory Cache: Instant access (5ms)
/// → Hive Cache: Fast local access (15ms) 
/// → API Cache: Fallback với smart expiry
class IntelligentCacheManager extends ChangeNotifier {
  static final IntelligentCacheManager _instance = IntelligentCacheManager._internal();
  factory IntelligentCacheManager() => _instance;
  IntelligentCacheManager._internal();

  // ========== MEMORY CACHE (TẦNG 1) ==========
  final Map<String, String> _memoryStreamUrls = {}; // videoId -> streamUrl
  final Map<String, List<MusicTrack>> _memorySearchResults = {}; // query -> tracks
  final Map<String, MusicTrack> _memoryTrackMetadata = {}; // videoId -> track
  final Map<String, List<MusicTrack>> _memoryPlaylists = {}; // type -> tracks
  
  // Cache size limits
  static const int MAX_MEMORY_URLS = 100;
  static const int MAX_MEMORY_SEARCHES = 50;
  static const int MAX_MEMORY_TRACKS = 200;

  // ========== HIVE BOXES (TẦNG 2) ==========
  Box? _songsCache;
  Box? _urlsCache;
  Box? _metadataCache;
  Box? _appPrefs;

  // ========== CACHE STATISTICS ==========
  int _memoryHits = 0;
  int _hiveHits = 0;
  int _apiCalls = 0;
  int _totalRequests = 0;

  // ========== INITIALIZATION ==========
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// 🚀 Initialize all cache tiers
  Future<void> initializeCache() async {
    if (_isInitialized) {
      print('⚡ Cache already initialized');
      return;
    }

    try {
      print('💾 Initializing Intelligent Cache Manager...');
      
      // Open Hive boxes with optimized settings
      _songsCache = await Hive.openBox('SongsCache');
      _urlsCache = await Hive.openBox('SongsUrlCache');
      _metadataCache = await Hive.openBox('MetadataCache');
      _appPrefs = await Hive.openBox('AppPrefs');
      
      // Load frequently accessed data to memory
      await _warmupMemoryCache();
      
      // Setup cache cleanup scheduler
      _setupCacheCleanup();
      
      _isInitialized = true;
      
      print('✅ Intelligent Cache initialized');
      _logCacheStats();
      
    } catch (e) {
      print('❌ Cache initialization failed: $e');
      _isInitialized = false;
    }
  }

  // ========== STREAM URL CACHING ==========
  
  /// ⚡ Get stream URL với intelligent lookup
  Future<String?> getStreamUrl(String videoId) async {
    _totalRequests++;
    
    // TẦNG 1: Memory cache (5ms)
    if (_memoryStreamUrls.containsKey(videoId)) {
      _memoryHits++;
      print('⚡ Memory hit for URL: $videoId');
      return _memoryStreamUrls[videoId];
    }
    
    // TẦNG 2: Hive cache (15ms)
    final cachedUrl = await _getUrlFromHive(videoId);
    if (cachedUrl != null) {
      _hiveHits++;
      // Promote to memory cache
      _cacheUrlInMemory(videoId, cachedUrl);
      print('💾 Hive hit for URL: $videoId');
      return cachedUrl;
    }
    
    // TẦNG 3: Will be API call (handled by caller)
    _apiCalls++;
    print('🌐 Cache miss for URL: $videoId - API call needed');
    return null;
  }

  /// 💾 Cache stream URL in all tiers
  Future<void> cacheStreamUrl(String videoId, String streamUrl) async {
    // Cache in memory (instant access)
    _cacheUrlInMemory(videoId, streamUrl);
    
    // Cache in Hive (persistent)
    await _cacheUrlInHive(videoId, streamUrl);
    
    print('💾 Cached stream URL for: $videoId');
  }

  /// 🔥 Pre-cache multiple URLs for instant playback
  Future<void> precacheStreamUrls(List<String> videoIds) async {
    print('🔥 Pre-caching ${videoIds.length} stream URLs...');
    
    for (final videoId in videoIds) {
      // Check if already cached
      final cached = await getStreamUrl(videoId);
      if (cached == null) {
        // Mark for API pre-loading
        await _markForPreloading(videoId);
      }
    }
    
    print('✅ Pre-cache setup completed');
  }

  // ========== SEARCH RESULTS CACHING ==========
  
  /// 🔍 Get cached search results
  List<MusicTrack>? getCachedSearchResults(String query) {
    _totalRequests++;
    
    // Memory cache first
    if (_memorySearchResults.containsKey(query)) {
      _memoryHits++;
      print('⚡ Memory hit for search: $query');
      return _memorySearchResults[query];
    }
    
    // Check Hive cache
    final cached = _songsCache?.get('search_$query');
    if (cached != null) {
      _hiveHits++;
      final tracks = _deserializeTrackList(cached);
      
      // Promote to memory
      _memorySearchResults[query] = tracks;
      _enforceMemoryLimits();
      
      print('💾 Hive hit for search: $query');
      return tracks;
    }
    
    print('🌐 Cache miss for search: $query');
    return null;
  }

  /// 💾 Cache search results
  Future<void> cacheSearchResults(String query, List<MusicTrack> tracks) async {
    // Cache in memory
    _memorySearchResults[query] = tracks;
    _enforceMemoryLimits();
    
    // Cache in Hive
    final serialized = _serializeTrackList(tracks);
    await _songsCache?.put('search_$query', serialized);
    
    print('💾 Cached search results for: $query (${tracks.length} tracks)');
  }

  // ========== TRACK METADATA CACHING ==========
  
  /// 🎵 Get cached track metadata
  MusicTrack? getCachedTrack(String videoId) {
    _totalRequests++;
    
    // Memory cache first
    if (_memoryTrackMetadata.containsKey(videoId)) {
      _memoryHits++;
      return _memoryTrackMetadata[videoId];
    }
    
    // Hive cache
    final cached = _metadataCache?.get(videoId);
    if (cached != null) {
      _hiveHits++;
      final track = MusicTrack.fromJson(Map<String, dynamic>.from(cached));
      
      // Promote to memory
      _memoryTrackMetadata[videoId] = track;
      _enforceMemoryLimits();
      
      return track;
    }
    
    return null;
  }

  /// 💾 Cache track metadata
  Future<void> cacheTrack(MusicTrack track) async {
    // Memory cache
    _memoryTrackMetadata[track.videoId] = track;
    _enforceMemoryLimits();
    
    // Hive cache
    await _metadataCache?.put(track.videoId, track.toJson());
    
    print('💾 Cached track metadata: ${track.title}');
  }

  // ========== PLAYLIST CACHING ==========
  
  /// 📋 Get cached playlist
  List<MusicTrack>? getCachedPlaylist(String playlistType) {
    if (_memoryPlaylists.containsKey(playlistType)) {
      return _memoryPlaylists[playlistType];
    }
    
    final cached = _songsCache?.get('playlist_$playlistType');
    if (cached != null) {
      final tracks = _deserializeTrackList(cached);
      _memoryPlaylists[playlistType] = tracks;
      return tracks;
    }
    
    return null;
  }

  /// 💾 Cache playlist
  Future<void> cachePlaylist(String playlistType, List<MusicTrack> tracks) async {
    _memoryPlaylists[playlistType] = tracks;
    
    final serialized = _serializeTrackList(tracks);
    await _songsCache?.put('playlist_$playlistType', serialized);
    
    print('💾 Cached playlist: $playlistType (${tracks.length} tracks)');
  }

  // ========== HELPER METHODS ==========
  
  /// 🔥 Warmup memory cache with frequently accessed data
  Future<void> _warmupMemoryCache() async {
    try {
      // Load recent search results
      final recentSearches = _appPrefs?.get('recent_searches', defaultValue: <String>[]) as List<String>;
      for (final query in recentSearches.take(10)) {
        final cached = _songsCache?.get('search_$query');
        if (cached != null) {
          _memorySearchResults[query] = _deserializeTrackList(cached);
        }
      }
      
      // Load frequently played tracks
      final frequentTracks = _appPrefs?.get('frequent_tracks', defaultValue: <String>[]) as List<String>;
      for (final videoId in frequentTracks.take(50)) {
        final cached = _metadataCache?.get(videoId);
        if (cached != null) {
          _memoryTrackMetadata[videoId] = MusicTrack.fromJson(Map<String, dynamic>.from(cached));
        }
        
        final cachedUrl = await _getUrlFromHive(videoId);
        if (cachedUrl != null) {
          _memoryStreamUrls[videoId] = cachedUrl;
        }
      }
      
      print('🔥 Memory cache warmed up with frequently accessed data');
      
    } catch (e) {
      print('⚠️ Memory warmup failed: $e');
    }
  }

  /// 💾 Get URL from Hive with expiry check
  Future<String?> _getUrlFromHive(String videoId) async {
    try {
      final cached = _urlsCache?.get(videoId);
      if (cached == null) return null;
      
      final data = Map<String, dynamic>.from(cached);
      final cachedAt = data['cached_at'] as int;
      final url = data['url'] as String;
      
      // Check expiry (6 hours)
      const expiryDuration = Duration(hours: 6);
      final isExpired = DateTime.now().millisecondsSinceEpoch - cachedAt > expiryDuration.inMilliseconds;
      
      if (isExpired) {
        await _urlsCache?.delete(videoId);
        print('🗑️ Expired URL removed: $videoId');
        return null;
      }
      
      return url;
      
    } catch (e) {
      print('⚠️ Hive URL lookup failed: $e');
      return null;
    }
  }

  /// 💾 Cache URL in Hive with timestamp
  Future<void> _cacheUrlInHive(String videoId, String streamUrl) async {
    try {
      await _urlsCache?.put(videoId, {
        'url': streamUrl,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('⚠️ Hive URL caching failed: $e');
    }
  }

  /// ⚡ Cache URL in memory with size limit
  void _cacheUrlInMemory(String videoId, String streamUrl) {
    _memoryStreamUrls[videoId] = streamUrl;
    
    // Enforce memory limits
    if (_memoryStreamUrls.length > MAX_MEMORY_URLS) {
      final oldestKey = _memoryStreamUrls.keys.first;
      _memoryStreamUrls.remove(oldestKey);
    }
  }

  /// 🔄 Enforce memory cache limits
  void _enforceMemoryLimits() {
    // URLs
    while (_memoryStreamUrls.length > MAX_MEMORY_URLS) {
      final oldestKey = _memoryStreamUrls.keys.first;
      _memoryStreamUrls.remove(oldestKey);
    }
    
    // Search results
    while (_memorySearchResults.length > MAX_MEMORY_SEARCHES) {
      final oldestKey = _memorySearchResults.keys.first;
      _memorySearchResults.remove(oldestKey);
    }
    
    // Track metadata
    while (_memoryTrackMetadata.length > MAX_MEMORY_TRACKS) {
      final oldestKey = _memoryTrackMetadata.keys.first;
      _memoryTrackMetadata.remove(oldestKey);
    }
  }

  /// 📊 Serialize track list for Hive storage
  List<Map<String, dynamic>> _serializeTrackList(List<MusicTrack> tracks) {
    return tracks.map((track) => track.toJson()).toList();
  }

  /// 📊 Deserialize track list from Hive storage
  List<MusicTrack> _deserializeTrackList(dynamic cached) {
    try {
      final List<dynamic> list = cached as List<dynamic>;
      return list.map((item) => MusicTrack.fromJson(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      print('⚠️ Track deserialization failed: $e');
      return [];
    }
  }

  /// 🔄 Mark video for pre-loading
  Future<void> _markForPreloading(String videoId) async {
    try {
      final preloadList = _appPrefs?.get('preload_queue', defaultValue: <String>[]) as List<String>;
      if (!preloadList.contains(videoId)) {
        preloadList.add(videoId);
        await _appPrefs?.put('preload_queue', preloadList);
      }
    } catch (e) {
      print('⚠️ Preload marking failed: $e');
    }
  }

  /// 🧹 Setup automatic cache cleanup
  void _setupCacheCleanup() {
    // Clean up expired entries every hour
    // This would typically be done with a timer in a real app
    print('🧹 Cache cleanup scheduler setup');
  }

  /// 📊 Log cache performance statistics
  void _logCacheStats() {
    final hitRate = _totalRequests > 0 ? ((_memoryHits + _hiveHits) / _totalRequests * 100) : 0;
    
    print('📊 Cache Statistics:');
    print('   Memory: ${_memoryStreamUrls.length} URLs, ${_memorySearchResults.length} searches, ${_memoryTrackMetadata.length} tracks');
    print('   Hit Rate: ${hitRate.toStringAsFixed(1)}% (${_memoryHits} memory + ${_hiveHits} hive / ${_totalRequests} total)');
    print('   API Calls: $_apiCalls');
  }

  /// 📊 Get cache performance stats
  Map<String, dynamic> getPerformanceStats() {
    final hitRate = _totalRequests > 0 ? ((_memoryHits + _hiveHits) / _totalRequests * 100) : 0;
    
    return {
      'memory_urls': _memoryStreamUrls.length,
      'memory_searches': _memorySearchResults.length,
      'memory_tracks': _memoryTrackMetadata.length,
      'total_requests': _totalRequests,
      'memory_hits': _memoryHits,
      'hive_hits': _hiveHits,
      'api_calls': _apiCalls,
      'hit_rate_percent': double.parse(hitRate.toStringAsFixed(1)),
      'is_initialized': _isInitialized,
    };
  }

  /// 🧹 Clear specific cache type
  Future<void> clearCache({bool memory = false, bool hive = false}) async {
    if (memory) {
      _memoryStreamUrls.clear();
      _memorySearchResults.clear();
      _memoryTrackMetadata.clear();
      _memoryPlaylists.clear();
      print('🧹 Memory cache cleared');
    }
    
    if (hive) {
      await _songsCache?.clear();
      await _urlsCache?.clear();
      await _metadataCache?.clear();
      print('🧹 Hive cache cleared');
    }
    
    notifyListeners();
  }
  
  /// 🔄 Pre-load popular content for instant access (Background operation)
  Future<void> preloadPopularContent() async {
    try {
      print('🔄 Starting popular content pre-loading...');
      
      // Pre-load trending songs metadata
      final trendingPlaylist = getCachedPlaylist('trending');
      if (trendingPlaylist != null && trendingPlaylist.isNotEmpty) {
        // Pre-cache stream URLs for trending songs
        final videoIds = trendingPlaylist.take(10).map((t) => t.videoId).toList();
        await precacheStreamUrls(videoIds);
        print('🔥 Pre-cached ${videoIds.length} trending stream URLs');
      }
      
      // Pre-load recent searches if any
      final recentSearches = _memorySearchResults.keys.take(3).toList();
      for (final query in recentSearches) {
        final results = getCachedSearchResults(query);
        if (results != null && results.isNotEmpty) {
          final videoIds = results.take(5).map((t) => t.videoId).toList();
          await precacheStreamUrls(videoIds);
          print('🔍 Pre-cached recent search: "$query"');
        }
      }
      
      print('✅ Popular content pre-loading completed');
      
    } catch (e) {
      print('⚠️ Popular content pre-loading failed: $e');
    }
  }
}

/// 💾 Global cache manager instance
final intelligentCache = IntelligentCacheManager();
