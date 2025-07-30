import '../services/music_service.dart';
import '../services/stream_service.dart';
import 'music_models.dart';

class HarmonyMusicService {
  static final HarmonyMusicService _instance = HarmonyMusicService._internal();
  factory HarmonyMusicService() => _instance;
  HarmonyMusicService._internal();

  final MusicServices _musicService = MusicServices();
  List<MusicTrack> _cachedTracks = [];
  bool _isInitialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _musicService.init();
      _isInitialized = true;
      print('[HarmonyMusic] Service initialized successfully');
    } catch (e) {
      print('[HarmonyMusic] Failed to initialize: $e');
      // Don't throw to prevent app crash
    }
  }

  /// Search for songs on YouTube Music
  Future<List<MusicTrack>> searchSongs(String query, {int limit = 20}) async {
    if (!_isInitialized) await initialize();
    
    try {
      print('[HarmonyMusic] 🔍 Searching for: "$query"');
      
      final results = await _musicService.search(query, filter: 'songs', limit: limit);
      
      if (results.containsKey('Songs') && results['Songs'] != null) {
        final songList = results['Songs'] as List<Map<String, dynamic>>;
        
        if (songList.isNotEmpty) {
          final tracks = songList.map((songData) => _convertToMusicTrack(songData)).toList();
          
          // Filter out any invalid tracks
          final validTracks = tracks.where((track) => 
            track.videoId.isNotEmpty && 
            track.videoId != 'error' && 
            track.title.isNotEmpty &&
            track.title != 'Error loading song'
          ).toList();
          
          print('[HarmonyMusic] ✅ Successfully parsed ${validTracks.length}/${tracks.length} valid tracks for "$query"');
          
          // Update cache with new results
          if (validTracks.isNotEmpty) {
            _cachedTracks.addAll(validTracks);
            // Keep cache size reasonable (max 100 tracks)
            if (_cachedTracks.length > 100) {
              _cachedTracks = _cachedTracks.take(100).toList();
            }
          }
          
          return validTracks;
        } else {
          print('[HarmonyMusic] ⚠️ Empty song list returned for "$query"');
        }
      } else {
        print('[HarmonyMusic] ⚠️ No "Songs" key found in results for "$query"');
        print('[HarmonyMusic] Available keys: ${results.keys.toList()}');
      }
      
      return [];
    } catch (e) {
      print('[HarmonyMusic] ❌ Search error for "$query": $e');
      return [];
    }
  }

  /// Get stream URL for a song
  Future<String?> getStreamUrl(String videoId) async {
    if (videoId.isEmpty || videoId == 'mock1' || videoId == 'mock2' || videoId == 'mock3' || videoId == 'mock4' || videoId == 'mock5') {
      print('[HarmonyMusic] ⚠️ Mock or empty videoId: $videoId');
      return null;
    }
    
    try {
      print('[HarmonyMusic] 🎵 Getting stream URL for: $videoId');
      
      final streamProvider = await StreamProvider.fetch(videoId);
      
      if (streamProvider.playable) {
        final audioStream = streamProvider.highestQualityAudio;
        if (audioStream != null) {
          final streamUrl = audioStream.url.toString();
          print('[HarmonyMusic] ✅ Stream URL obtained for $videoId');
          return streamUrl;
        } else {
          print('[HarmonyMusic] ⚠️ No audio stream available for $videoId');
        }
      } else {
        print('[HarmonyMusic] ⚠️ Video not playable: $videoId');
        print('[HarmonyMusic] Status: ${streamProvider.statusMSG}');
      }
      
      return null;
    } catch (e) {
      print('[HarmonyMusic] ❌ Stream URL error for $videoId: $e');
      return null;
    }
  }

  /// Get search suggestions
  Future<List<String>> getSearchSuggestions(String query) async {
    if (!_isInitialized) await initialize();
    
    try {
      return await _musicService.getSearchSuggestion(query);
    } catch (e) {
      print('[HarmonyMusic] Suggestions error: $e');
      return [];
    }
  }

  /// Get home content
  Future<List<Map<String, dynamic>>> getHome({int limit = 4}) async {
    if (!_isInitialized) await initialize();
    
    try {
      return await _musicService.getHome(limit: limit);
    } catch (e) {
      print('[HarmonyMusic] Home content error: $e');
      return [];
    }
  }

  /// Get charts
  Future<List<Map<String, dynamic>>> getCharts({String? countryCode}) async {
    if (!_isInitialized) await initialize();
    
    try {
      return await _musicService.getCharts(countryCode: countryCode);
    } catch (e) {
      print('[HarmonyMusic] Charts error: $e');
      return [];
    }
  }

  /// Get popular songs (using home content)
  Future<List<MusicTrack>> getPopularSongs() async {
    try {
      // Use more specific Vietnamese song searches for better results
      const popularQueries = [
        'Sơn Tùng M-TP',
        'Jack J97',
        'Erik Vietnam',
        'Bích Phương',
        'Đen Vâu rapper',
        'Hoàng Thùy Linh',
        'MIN Vietnam singer',
        'Đức Phúc',
        'Vũ singer Vietnam',
        'Noo Phước Thịnh',
      ];
      
      final allTracks = <MusicTrack>[];
      int successfulRequests = 0;
      
      print('[HarmonyMusic] Starting to search for popular Vietnamese songs...');
      
      for (final query in popularQueries.take(4)) { // Reduced to 4 for better performance
        try {
          print('[HarmonyMusic] Searching for: "$query"');
          final tracks = await searchSongs(query, limit: 3); // Reduced limit per search
          
          if (tracks.isNotEmpty) {
            allTracks.addAll(tracks);
            successfulRequests++;
            print('[HarmonyMusic] ✅ Found ${tracks.length} songs for "$query"');
          } else {
            print('[HarmonyMusic] ⚠️ No songs found for "$query"');
          }
          
          // Add delay between requests to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          print('[HarmonyMusic] ❌ Error searching for "$query": $e');
          continue; // Continue with next query
        }
      }
      
      // Remove duplicates based on videoId
      final uniqueTracks = <String, MusicTrack>{};
      for (final track in allTracks) {
        if (!uniqueTracks.containsKey(track.videoId)) {
          uniqueTracks[track.videoId] = track;
        }
      }
      
      final finalTracks = uniqueTracks.values.toList();
      
      if (finalTracks.isNotEmpty) {
        // Cache the results
        _cachedTracks = finalTracks;
        print('[HarmonyMusic] ✅ Successfully loaded ${finalTracks.length} unique popular songs from $successfulRequests/${popularQueries.take(4).length} queries');
        return finalTracks;
      }
      
      // If no results from API, return empty list - the viewmodel will handle fallback
      print('[HarmonyMusic] ⚠️ No popular songs found from any query');
      return [];
      
    } catch (e) {
      print('[HarmonyMusic] ❌ Popular songs error: $e');
      return [];
    }
  }

  /// Get cached tracks (for offline display while loading)
  List<MusicTrack> getCachedTracks() {
    return List.from(_cachedTracks);
  }

  /// Clear cache
  void clearCache() {
    _cachedTracks.clear();
  }

  /// Convert API response to MusicTrack
  MusicTrack _convertToMusicTrack(Map<String, dynamic> data) {
    try {
      final videoId = data['videoId'] ?? '';
      final title = data['title'] ?? 'Unknown Title';
      final artist = data['artist'] ?? 'Unknown Artist';
      final thumbnail = data['thumbnail'];
      
      return MusicTrack(
        id: videoId,
        videoId: videoId,
        title: title,
        artist: artist,
        thumbnail: thumbnail,
        isFavorite: false,
        extras: {
          'source': 'youtube_music',
          'originalData': data,
        },
      );
    } catch (e) {
      print('[HarmonyMusic] Convert track error: $e');
      return MusicTrack(
        id: 'error',
        videoId: 'error',
        title: 'Error loading song',
        artist: 'Unknown',
        isFavorite: false,
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _musicService.dispose();
    _cachedTracks.clear();
    _isInitialized = false;
    print('[HarmonyMusic] Service disposed');
  }
}
