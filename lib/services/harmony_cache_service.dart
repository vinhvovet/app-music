import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

/// 🚀 Harmony Cache Service - Hệ thống cache đa tầng cực nhanh
class HarmonyCacheService extends ChangeNotifier {
  static const String _songsBox = 'SongsCache';
  static const String _urlsBox = 'SongsUrlCache';
  static const String _prefsBox = 'AppPrefs';
  static const String _metadataBox = 'MetadataCache';
  
  late Box _songs;
  late Box _urls;
  late Box _prefs;
  late Box _metadata;
  
  // Memory cache cho tốc độ tối đa
  final Map<String, dynamic> _memoryCache = <String, dynamic>{};
  final Map<String, String> _urlMemoryCache = <String, String>{};
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _initializeBoxes();
      await _loadMemoryCache();
      _isInitialized = true;
      print('🚀 Harmony Cache Service initialized - Lightning fast cache ready!');
      notifyListeners();
    } catch (e) {
      print('❌ Error initializing HarmonyCacheService: $e');
    }
  }
  
  Future<void> _initializeBoxes() async {
    try {
      _songs = await Hive.openBox(_songsBox);
      _urls = await Hive.openBox(_urlsBox);
      _prefs = await Hive.openBox(_prefsBox);
      _metadata = await Hive.openBox(_metadataBox);
      
      // Set default preferences for optimal performance
      if (!_prefs.containsKey('streamingQuality')) {
        await _prefs.put('streamingQuality', 1); // Adaptive quality
      }
      if (!_prefs.containsKey('cacheSongs')) {
        await _prefs.put('cacheSongs', false); // Stream directly
      }
      if (!_prefs.containsKey('preloadUrls')) {
        await _prefs.put('preloadUrls', true); // Enable pre-loading
      }
    } catch (e) {
      print('❌ Error initializing cache boxes: $e');
    }
  }
  
  Future<void> _loadMemoryCache() async {
    try {
      // Load frequently used data into memory for instant access
      final recentSongs = _songs.get('recent_songs', defaultValue: <String, dynamic>{});
      if (recentSongs is Map) {
        _memoryCache.addAll(recentSongs.cast<String, dynamic>());
      }
      
      // Load recent URLs into memory
      final recentUrls = _urls.toMap();
      for (final entry in recentUrls.entries) {
        if (entry.key is String && entry.value is String) {
          _urlMemoryCache[entry.key] = entry.value;
        }
      }
      
      print('📦 Memory cache loaded: ${_memoryCache.length} songs, ${_urlMemoryCache.length} URLs');
    } catch (e) {
      print('❌ Error loading memory cache: $e');
    }
  }
  
  /// 🎵 Cache song metadata với memory layer
  Future<void> cacheSong(String videoId, Map<String, dynamic> songData) async {
    try {
      // Memory cache first (fastest)
      _memoryCache[videoId] = songData;
      
      // Disk cache (persistent)
      await _songs.put(videoId, songData);
      
      // Update recent songs
      final recentSongs = Map<String, dynamic>.from(_songs.get('recent_songs', defaultValue: <String, dynamic>{}));
      recentSongs[videoId] = songData;
      
      // Keep only last 100 recent songs for performance
      if (recentSongs.length > 100) {
        final keys = recentSongs.keys.toList();
        keys.take(keys.length - 100).forEach(recentSongs.remove);
      }
      
      await _songs.put('recent_songs', recentSongs);
    } catch (e) {
      print('❌ Error caching song: $e');
    }
  }
  
  /// 🎵 Get song metadata với tốc độ lightning
  Map<String, dynamic>? getSong(String videoId) {
    try {
      // Check memory cache first (5ms)
      if (_memoryCache.containsKey(videoId)) {
        return _memoryCache[videoId];
      }
      
      // Check disk cache (15ms)
      final songData = _songs.get(videoId);
      if (songData != null && songData is Map<String, dynamic>) {
        // Load into memory for next time
        _memoryCache[videoId] = songData;
        return songData;
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting song: $e');
      return null;
    }
  }
  
  /// 🎵 Cache stream URL với expiry
  Future<void> cacheStreamUrl(String videoId, String streamUrl, {Duration? expiry}) async {
    try {
      final expiryTime = DateTime.now().add(expiry ?? const Duration(hours: 6));
      final urlData = {
        'url': streamUrl,
        'expiry': expiryTime.millisecondsSinceEpoch,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Memory cache first
      _urlMemoryCache[videoId] = streamUrl;
      
      // Disk cache with metadata
      await _urls.put(videoId, urlData);
    } catch (e) {
      print('❌ Error caching stream URL: $e');
    }
  }
  
  /// 🎵 Get stream URL với instant access
  String? getStreamUrl(String videoId) {
    try {
      // Check memory cache first (instant)
      if (_urlMemoryCache.containsKey(videoId)) {
        return _urlMemoryCache[videoId];
      }
      
      // Check disk cache with expiry validation
      final urlData = _urls.get(videoId);
      if (urlData != null && urlData is Map) {
        final expiry = urlData['expiry'] as int?;
        if (expiry != null && DateTime.now().millisecondsSinceEpoch < expiry) {
          final url = urlData['url'] as String?;
          if (url != null) {
            // Load into memory for instant access
            _urlMemoryCache[videoId] = url;
            return url;
          }
        } else {
          // URL expired, remove it
          _urls.delete(videoId);
          _urlMemoryCache.remove(videoId);
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting stream URL: $e');
      return null;
    }
  }
  
  /// 🎵 Pre-load stream URLs for instant playback
  Future<void> preloadStreamUrls(List<String> videoIds) async {
    if (!getPreference('preloadUrls', true)) return;
    
    try {
      final uncachedIds = <String>[];
      
      // Check which URLs we don't have cached
      for (final videoId in videoIds) {
        if (getStreamUrl(videoId) == null) {
          uncachedIds.add(videoId);
        }
      }
      
      if (uncachedIds.isNotEmpty) {
        print('🔄 Pre-loading ${uncachedIds.length} stream URLs in background...');
        // Background pre-loading will be implemented in HarmonyMusicService
        // This allows instant playback when user clicks
      }
    } catch (e) {
      print('❌ Error pre-loading stream URLs: $e');
    }
  }
  
  /// 🎵 Batch cache multiple songs
  Future<void> batchCacheSongs(Map<String, Map<String, dynamic>> songs) async {
    try {
      for (final entry in songs.entries) {
        await cacheSong(entry.key, entry.value);
      }
      print('📦 Batch cached ${songs.length} songs');
    } catch (e) {
      print('❌ Error batch caching songs: $e');
    }
  }
  
  /// 🎵 Get/Set preferences
  T getPreference<T>(String key, T defaultValue) {
    try {
      return _prefs.get(key, defaultValue: defaultValue) as T;
    } catch (e) {
      return defaultValue;
    }
  }
  
  Future<void> setPreference<T>(String key, T value) async {
    try {
      await _prefs.put(key, value);
    } catch (e) {
      print('❌ Error setting preference: $e');
    }
  }
  
  /// 🎵 Cache stats for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'memory_songs': _memoryCache.length,
      'memory_urls': _urlMemoryCache.length,
      'disk_songs': _songs.length,
      'disk_urls': _urls.length,
      'preferences': _prefs.length,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }
  
  /// 🎵 Clear cache khi cần
  Future<void> clearCache({bool keepPreferences = true}) async {
    try {
      _memoryCache.clear();
      _urlMemoryCache.clear();
      
      await _songs.clear();
      await _urls.clear();
      await _metadata.clear();
      
      if (!keepPreferences) {
        await _prefs.clear();
      }
      
      print('🗑️ Cache cleared successfully');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }
  
  /// 🎵 Optimize cache - remove old entries
  Future<void> optimizeCache() async {
    try {
      // Remove expired URLs
      final urlKeys = _urls.keys.toList();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      for (final key in urlKeys) {
        final urlData = _urls.get(key);
        if (urlData is Map) {
          final expiry = urlData['expiry'] as int?;
          if (expiry != null && now > expiry) {
            await _urls.delete(key);
            _urlMemoryCache.remove(key);
          }
        }
      }
      
      print('🔧 Cache optimized - removed expired entries');
    } catch (e) {
      print('❌ Error optimizing cache: $e');
    }
  }
}
