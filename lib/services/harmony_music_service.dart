import 'package:flutter/foundation.dart';
import 'harmony_api_client.dart';
import 'harmony_cache_manager.dart';
import 'harmony_stream_provider.dart';
import 'harmony_response_parser.dart';
import 'harmony_constants.dart';
import '../data/music_models.dart';

/// Harmony Music Service - Complete integration
class HarmonyMusicService extends ChangeNotifier {
  static final HarmonyMusicService _instance = HarmonyMusicService._internal();
  factory HarmonyMusicService() => _instance;
  HarmonyMusicService._internal();

  final HarmonyAPIClient _apiClient = HarmonyAPIClient();
  final HarmonyCacheManager _cache = HarmonyCacheManager();
  final HarmonyStreamProvider _streams = HarmonyStreamProvider();

  bool _initialized = false;
  bool _isLoading = false;
  String? _error;

  // Current state
  List<MusicTrack> _searchResults = [];
  List<MusicTrack> _trendingTracks = [];
  List<MusicTrack> _popularVietnamese = [];
  MusicTrack? _currentTrack;
  String? _currentStreamUrl;

  // Getters
  bool get isInitialized => _initialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<MusicTrack> get searchResults => _searchResults;
  List<MusicTrack> get trendingTracks => _trendingTracks;
  List<MusicTrack> get popularVietnamese => _popularVietnamese;
  MusicTrack? get currentTrack => _currentTrack;
  String? get currentStreamUrl => _currentStreamUrl;

  /// Initialize Harmony Music Service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _setLoading(true);
      _clearError();

      // Initialize all components
      await Future.wait([
        _apiClient.initialize(),
        _cache.initialize(),
        _streams.initialize(),
      ]);

      // Load initial data in background
      _loadInitialData();

      _initialized = true;
      print('🎵 Harmony Music Service initialized');
      
    } catch (e) {
      _setError('Initialization failed: $e');
      print('❌ Service initialization error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load initial data (trending + popular Vietnamese)
  void _loadInitialData() async {
    try {
      // Load trending music
      final trending = await getTrendingMusic();
      _trendingTracks = trending;

      // Pre-load popular Vietnamese songs
      await _preloadPopularVietnamese();

      notifyListeners();
    } catch (e) {
      print('❌ Initial data load error: $e');
    }
  }

  /// Search music với instant caching
  Future<List<MusicTrack>> searchMusic(String query, {int maxResults = 20}) async {
    if (!_initialized) await initialize();

    try {
      _setLoading(true);
      _clearError();

      // Ultra-fast cache check (~10ms)
      final cached = _cache.getCachedSearchResults(query, 'songs');
      if (cached != null && cached.isNotEmpty) {
        final musicTracks = cached.map((trackData) => _convertToMusicTrack(trackData)).toList();
        
        _searchResults = musicTracks;
        notifyListeners();
        print('⚡ Search cache hit: ${musicTracks.length} results (${query.substring(0, 8)}...)');
        return musicTracks;
      }

      print('🔍 Searching: "$query"');

      // Search using Harmony API
      final response = await _apiClient.search(query);
      final tracks = HarmonyResponseParser.parseSearchResults(response.data);

      // Convert to MusicTrack objects
      final musicTracks = tracks.map((trackData) => _convertToMusicTrack(trackData)).toList();

      // Cache results
      await _cache.cacheSearchResults(query, 'songs', tracks);

      // Pre-resolve streams for top results (background)
      final topIds = musicTracks.take(5).map((t) => t.videoId).toList();
      _streams.preResolveStreams(topIds);

      _searchResults = musicTracks;
      notifyListeners();

      print('✅ Search complete: ${musicTracks.length} results');
      return musicTracks;

    } catch (e) {
      _setError('Search failed: $e');
      print('❌ Search error: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Get trending music
  Future<List<MusicTrack>> getTrendingMusic({int maxResults = 50}) async {
    if (!_initialized) await initialize();

    try {
      // Check cache first
      final cached = _cache.getCachedSearchResults('__TRENDING__', 'trending');
      if (cached != null && cached.isNotEmpty) {
        final musicTracks = cached.map((trackData) => _convertToMusicTrack(trackData)).toList();
        print('⚡ Trending cache hit: ${musicTracks.length} results');
        return musicTracks;
      }

      print('📈 Loading trending music...');

      // Get trending from Harmony API
      final response = await _apiClient.getTrending();
      final tracks = HarmonyResponseParser.parseTrendingResults(response.data);

      // Convert to MusicTrack objects
      final musicTracks = tracks.map((trackData) => _convertToMusicTrack(trackData)).toList();

      // Cache trending results
      await _cache.cacheSearchResults('__TRENDING__', 'trending', tracks);

      // Pre-resolve streams for trending tracks (background)
      final trendingIds = musicTracks.take(10).map((t) => t.videoId).toList();
      _streams.preResolveStreams(trendingIds);

      print('✅ Trending loaded: ${musicTracks.length} tracks');
      return musicTracks;

    } catch (e) {
      _setError('Failed to load trending: $e');
      print('❌ Trending error: $e');
      return [];
    }
  }

  /// Play track - INSTANT loading với stream caching
  Future<String?> playTrack(MusicTrack track) async {
    if (!_initialized) await initialize();

    try {
      _currentTrack = track;
      notifyListeners();

      if (track.videoId.isEmpty) {
        throw Exception('No video ID for track');
      }

      print('▶️ Playing: ${track.title} - ${track.artist}');

      // Get direct stream URL (cache-first: ~10-50ms)
      final streamUrl = await _streams.getDirectStreamUrl(
        track.videoId,
        quality: 'high'
      );

      if (streamUrl == null) {
        throw Exception('Failed to resolve stream');
      }

      _currentStreamUrl = streamUrl;
      notifyListeners();

      // Pre-load next tracks in playlist/search results
      _preloadAdjacentTracks(track);

      print('✅ Stream ready: ${track.title}');
      return streamUrl;

    } catch (e) {
      _setError('Playback failed: $e');
      print('❌ Playback error: $e');
      return null;
    }
  }

  /// Pre-load adjacent tracks for seamless playback
  void _preloadAdjacentTracks(MusicTrack currentTrack) async {
    try {
      final currentList = _searchResults.isNotEmpty ? _searchResults : _trendingTracks;
      final currentIndex = currentList.indexWhere((t) => t.id == currentTrack.id);
      
      if (currentIndex != -1) {
        final preloadIds = <String>[];
        
        // Next 3 tracks
        for (int i = 1; i <= 3; i++) {
          final nextIndex = currentIndex + i;
          if (nextIndex < currentList.length) {
            final nextTrack = currentList[nextIndex];
            if (nextTrack.videoId.isNotEmpty) {
              preloadIds.add(nextTrack.videoId);
            }
          }
        }
        
        // Previous 1 track
        if (currentIndex > 0) {
          final prevTrack = currentList[currentIndex - 1];
          if (prevTrack.videoId.isNotEmpty) {
            preloadIds.add(prevTrack.videoId);
          }
        }

        if (preloadIds.isNotEmpty) {
          _streams.preResolveStreams(preloadIds);
          print('🔄 Pre-loading ${preloadIds.length} adjacent tracks');
        }
      }
    } catch (e) {
      print('❌ Pre-load error: $e');
    }
  }

  /// Pre-load popular Vietnamese songs
  Future<void> _preloadPopularVietnamese() async {
    try {
      final popularQueries = HarmonyAPIConstants.popularVietnameseQueries.take(5);
      
      for (final query in popularQueries) {
        final tracks = await searchMusic(query, maxResults: 10);
        if (tracks.isNotEmpty) {
          _popularVietnamese.addAll(tracks.take(3));
        }
        
        // Rate limiting
        await Future.delayed(const Duration(milliseconds: 300));
      }

      print('✅ Popular Vietnamese pre-loaded: ${_popularVietnamese.length} tracks');
    } catch (e) {
      print('❌ Vietnamese pre-load error: $e');
    }
  }

  /// Get similar tracks
  Future<List<MusicTrack>> getSimilarTracks(MusicTrack track, {int maxResults = 20}) async {
    if (!_initialized) await initialize();

    try {
      // Use artist name and genre keywords for similarity
      final query = '${track.artist} ${track.title.split(' ').take(2).join(' ')}';
      final similar = await searchMusic(query, maxResults: maxResults);
      
      // Filter out the current track
      return similar.where((t) => t.id != track.id).toList();
    } catch (e) {
      print('❌ Similar tracks error: $e');
      return [];
    }
  }

  /// Get track metadata (detailed info)
  Future<Map<String, dynamic>?> getTrackMetadata(String videoId) async {
    if (!_initialized) await initialize();

    try {
      return await _streams.getTrackMetadata(videoId);
    } catch (e) {
      print('❌ Metadata error: $e');
      return null;
    }
  }

  /// Convert track data to MusicTrack object
  MusicTrack _convertToMusicTrack(Map<String, dynamic> trackData) {
    return MusicTrack(
      id: trackData['videoId'] ?? '',
      videoId: trackData['videoId'] ?? '',
      title: trackData['title'] ?? 'Unknown',
      artist: trackData['artist'] ?? 'Unknown Artist',
      duration: _parseDurationFromString(trackData['duration']),
      thumbnail: trackData['thumbnail'] ?? '',
      album: trackData['album'],
      extras: {
        'harmonySource': true,
        'originalData': trackData,
      },
    );
  }

  /// Parse duration string to Duration object
  Duration? _parseDurationFromString(dynamic duration) {
    if (duration == null) return null;
    
    try {
      if (duration is int) {
        return Duration(seconds: duration);
      }
      
      if (duration is String) {
        final parts = duration.split(':');
        if (parts.length == 2) {
          return Duration(
            minutes: int.parse(parts[0]),
            seconds: int.parse(parts[1])
          );
        } else if (parts.length == 3) {
          return Duration(
            hours: int.parse(parts[0]),
            minutes: int.parse(parts[1]),
            seconds: int.parse(parts[2])
          );
        }
      }
    } catch (e) {
      print('❌ Duration parse error: $e');
    }
    
    return null;
  }

  /// Stop current playback and clear
  Future<void> stopPlayback() async {
    try {
      _currentTrack = null;
      _currentStreamUrl = null;
      notifyListeners();
      print('🛑 Playback stopped');
    } catch (e) {
      print('❌ Stop playback error: $e');
    }
  }

  /// Clear all data and stop playback
  Future<void> clearAll() async {
    try {
      await stopPlayback();
      _searchResults = [];
      _trendingTracks = [];
      _popularVietnamese = [];
      notifyListeners();
      print('🧹 All data cleared');
    } catch (e) {
      print('❌ Clear all error: $e');
    }
  }

  /// Clear search results
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Set error state
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error state
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _streams.dispose();
    super.dispose();
  }
}
