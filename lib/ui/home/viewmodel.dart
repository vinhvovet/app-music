import 'dart:async';
import '../../data/music_models.dart';
import '../../startup_performance.dart';

class MusicAppViewModel {
  StreamController<List<MusicTrack>>? _songStream;
  StreamController<bool>? _loadingStream;
  
  List<MusicTrack> _allSongs = [];
  bool _isLoading = false;
  Timer? _searchTimer;

  // Lazy initialization of streams
  StreamController<List<MusicTrack>> get songStream {
    if (_songStream == null || _songStream!.isClosed) {
      _songStream = StreamController.broadcast();
    }
    return _songStream!;
  }
  
  StreamController<bool> get loadingStream {
    if (_loadingStream == null || _loadingStream!.isClosed) {
      _loadingStream = StreamController.broadcast();
    }
    return _loadingStream!;
  }

  // Add loading state getter
  bool get isLoading => _isLoading;

  void loadSongs() async {
    if (_isLoading) return; // Prevent multiple calls
    
    _setLoading(true);
    
    try {
      print('[ViewModel] Loading songs using YouTube Music Complete API...');
      final api = StartupPerformance.musicAPI;
      
      // Load 50 bài mới nhất using the new API  
      final popularSongs = await api.getPopularSongs(limit: 50);
      
      if (popularSongs.isNotEmpty) {
        print('[ViewModel] Loaded ${popularSongs.length} popular songs from API');
        
        // Debug: Print first song data
        if (popularSongs.isNotEmpty) {
          final firstSong = popularSongs.first;
          print('[ViewModel] DEBUG First song raw data:');
          print('[ViewModel] - videoId: ${firstSong['videoId']}');  
          print('[ViewModel] - title: "${firstSong['title']}"');
          print('[ViewModel] - artist: "${firstSong['artist']}"');
          print('[ViewModel] - thumbnail: ${firstSong['thumbnail']}');
        }
        
        final tracks = popularSongs.map((songData) => _convertToMusicTrack(songData)).toList();
        _allSongs = tracks;
        
        // Stream will be recreated if closed, so we can safely add
        songStream.add(tracks);
      } else {
        print('[ViewModel] No popular songs found, using fallback');
        // Fallback: Create some mock data
        final mockSongs = _createMockSongs();
        _allSongs = mockSongs;
        
        // Stream will be recreated if closed, so we can safely add
        songStream.add(mockSongs);
      }
      
    } catch (e) {
      print('[ViewModel] Error loading songs: $e');
      // Add mock songs as fallback
      final mockSongs = _createMockSongs();
      _allSongs = mockSongs;
      
      // Stream will be recreated if closed, so we can safely add
      songStream.add(mockSongs);
    } finally {
      _setLoading(false);
    }
  }

  /// Reset and reload songs (useful after login/logout)
  void resetAndLoadSongs() {
    print('[ViewModel] Resetting and reloading songs...');
    _allSongs.clear();
    loadSongs();
  }

  MusicTrack _convertToMusicTrack(Map<String, dynamic> data) {
    try {
      // Debug: Print raw data first
      print('[ViewModel] DEBUG Converting track data:');
      print('[ViewModel] - Raw title: "${data['title']}"');
      print('[ViewModel] - Raw artist: "${data['artist']}"');
      
      // Improved title extraction
      String title = data['title']?.toString().trim() ?? '';
      if (title.isEmpty || title == 'Unknown Title') {
        // Try to extract from videoId or other fields
        title = data['videoId']?.toString() ?? 'Untitled Song';
      }

      // Improved artist extraction
      String? artist = data['artist']?.toString().trim();
      if (artist == null || artist.isEmpty || artist == 'Unknown Artist') {
        // Try to extract from other fields or leave as null
        artist = null;
      }

      print('[ViewModel] DEBUG After processing:');
      print('[ViewModel] - Final title: "$title"');
      print('[ViewModel] - Final artist: "$artist"');

      return MusicTrack(
        id: data['videoId'] ?? '',
        videoId: data['videoId'] ?? '',
        title: title,  
        artist: artist,
        thumbnail: data['thumbnail'],
        duration: data['duration'] != null 
            ? Duration(seconds: data['duration']) 
            : null,
        extras: {
          'source': 'youtube_music_complete_api',
          'originalData': data,
        },
      );
    } catch (e) {
      print('[ViewModel] Error converting track: $e');
      return MusicTrack(
        id: 'error',
        videoId: 'error',
        title: 'Error loading song',
        artist: null,
        isFavorite: false,
      );
    }
  }

  List<MusicTrack> _createMockSongs() {
    return [
      MusicTrack(
        id: 'mock1',
        videoId: 'dQw4w9WgXcQ',
        title: 'Never Gonna Give You Up',
        artist: 'Rick Astley',
        thumbnail: null,
      ),
      MusicTrack(
        id: 'mock2', 
        videoId: 'kJQP7kiw5Fk',
        title: 'Despacito',
        artist: 'Luis Fonsi ft. Daddy Yankee',
        thumbnail: null,
      ),
      MusicTrack(
        id: 'mock3',
        videoId: '9bZkp7q19f0', 
        title: 'Gangnam Style',
        artist: 'PSY',
        thumbnail: null,
      ),
      MusicTrack(
        id: 'mock4',
        videoId: 'RgKAFK5djSk',
        title: 'Waka Waka',
        artist: 'Shakira',
        thumbnail: null,
      ),
      MusicTrack(
        id: 'mock5',
        videoId: 'hT_nvWreIhg',
        title: 'Counting Stars',
        artist: 'OneRepublic',
        thumbnail: null,
      ),
    ];
  }

  void searchByKeyword(String query) async {
    // Cancel previous search timer to debounce search
    _searchTimer?.cancel();
    
    if (query.isEmpty) {
      songStream.add(List.from(_allSongs));
      return;
    }
    
    _searchTimer = Timer(const Duration(milliseconds: 500), () async {
      _setLoading(true);
      
      try {
        print('[ViewModel] Searching for: "$query"');
        final api = StartupPerformance.musicAPI;
        
        // Search using the new YouTube Music Complete API
        final searchResults = await api.searchMusic(query, filter: 'songs');
        
          if (searchResults['songs'] != null) {
          final songs = searchResults['songs'] as List<Map<String, dynamic>>;
          final tracks = songs.map((songData) => _convertToMusicTrack(songData)).toList();
          
          songStream.add(tracks);
          print('[ViewModel] Search completed: ${tracks.length} results for "$query"');
        } else {
          // No results found
          songStream.add([]);
          print('[ViewModel] No search results for "$query"');
        }      } catch (e) {
        print('[ViewModel] Search error: $e');
        // Fallback to local search in all songs
        final lowerQuery = query.toLowerCase();
        final filtered = _allSongs.where((song) =>
          song.title.toLowerCase().contains(lowerQuery) ||
          (song.artist?.toLowerCase().contains(lowerQuery) ?? false)
        ).toList();
        
        songStream.add(filtered);
      } finally {
        _setLoading(false);
      }
    });
  }

  List<MusicTrack> get favoriteSongs =>
      _allSongs.where((song) => song.isFavorite ?? false).toList();

  void toggleFavorite(MusicTrack song) {
    final index = _allSongs.indexWhere((s) => s.videoId == song.videoId);
    if (index != -1) {
      _allSongs[index] = _allSongs[index].copyWith(
        isFavorite: !(_allSongs[index].isFavorite ?? false)
      );
      
      // Update stream to trigger UI rebuild
      if (songStream.hasListener) {
        songStream.add(List.from(_allSongs)); // Create new list for proper stream update
      }
    }
  }

  /// Get stream URL for playback using YouTube Music Complete API
  Future<String?> getStreamUrl(String videoId) async {
    try {
      print('[ViewModel] Getting stream URL for: $videoId');
      final api = StartupPerformance.musicAPI;
      
      final songDetails = await api.getSongDetails(videoId);
      print('[ViewModel] Song details: ${songDetails.keys}');
      
      if (songDetails['streamingUrls'] != null) {
        final streamingUrlsRaw = songDetails['streamingUrls'] as List<dynamic>;
        final streamingUrls = streamingUrlsRaw.cast<Map<String, dynamic>>();
        if (streamingUrls.isNotEmpty) {
          final highestQualityUrl = streamingUrls.first['url'] as String;
          print('[ViewModel] ✅ Stream URL obtained: ${highestQualityUrl.substring(0, 50)}...');
          return highestQualityUrl;
        }
      }
      
      // Fallback to highestQualityUrl if available
      if (songDetails['highestQualityUrl'] != null) {
        final url = songDetails['highestQualityUrl'] as String;
        print('[ViewModel] ✅ Using fallback stream URL');
        return url;
      }
      
      print('[ViewModel] ❌ No stream URL available for $videoId');
      return null;
      
    } catch (e) {
      print('[ViewModel] ❌ Error getting stream URL: $e');
      return null;
    }
  }

  /// Get search suggestions (placeholder for now)
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      // For now, return some basic suggestions
      // This could be enhanced with actual YouTube Music suggestions API
      return [
        '$query songs',
        '$query hits',
        '$query music',
        '$query playlist',
        '$query artist',
      ];
    } catch (e) {
      print('[ViewModel] Error getting suggestions: $e');
      return [];
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loadingStream.hasListener) {
      loadingStream.add(loading);
    }
  }

  /// Clear all data (useful for logout)
  void clearAllData() {
    print('[ViewModel] Clearing all data...');
    _allSongs.clear();
    _searchTimer?.cancel();
    if (songStream.hasListener) {
      songStream.add([]);
    }
  }

  void dispose() {
    print('[ViewModel] Disposing ViewModel...');
    _searchTimer?.cancel();
    if (_songStream != null && !_songStream!.isClosed) {
      _songStream!.close();
    }
    if (_loadingStream != null && !_loadingStream!.isClosed) {
      _loadingStream!.close();
    }
  }
}
