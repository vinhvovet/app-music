import 'package:flutter/foundation.dart';
import 'package:music_app/services/harmony_cache_service.dart';
import 'package:music_app/services/harmony_audio_service.dart';
import 'package:music_app/services/harmony_music_service.dart';
import 'package:music_app/data/stream_service.dart' as stream_service;

/// 🚀 Harmony Player Controller - Điều khiển phát nhạc siêu tốc
class HarmonyPlayerController extends ChangeNotifier {
  static HarmonyPlayerController? _instance;
  static HarmonyPlayerController get instance => _instance ??= HarmonyPlayerController._();
  
  HarmonyPlayerController._();
  
  late HarmonyCacheService _cacheService;
  late HarmonyAudioService _audioService;
  late HarmonyMusicService _musicService;
  
  // Current playlist info
  List<Map<String, dynamic>> _currentPlaylist = [];
  int _currentIndex = 0;
  bool _isShuffling = false;
  bool _isRepeating = false;
  
  // Loading states
  bool _isLoading = false;
  String? _loadingVideoId;
  
  // Getters
  List<Map<String, dynamic>> get currentPlaylist => _currentPlaylist;
  int get currentIndex => _currentIndex;
  bool get isShuffling => _isShuffling;
  bool get isRepeating => _isRepeating;
  bool get isLoading => _isLoading;
  String? get loadingVideoId => _loadingVideoId;
  
  Map<String, dynamic>? get currentSong => 
      _currentPlaylist.isNotEmpty && _currentIndex < _currentPlaylist.length 
          ? _currentPlaylist[_currentIndex] 
          : null;
  
  Future<void> initialize(
    HarmonyCacheService cacheService,
    HarmonyAudioService audioService,
    HarmonyMusicService musicService,
  ) async {
    _cacheService = cacheService;
    _audioService = audioService;
    _musicService = musicService;
    
    // Listen to audio service changes
    _audioService.addListener(_onAudioServiceChanged);
    
    print('🎮 Harmony Player Controller initialized');
  }
  
  void _onAudioServiceChanged() {
    notifyListeners();
  }
  
  /// 🎵 Play song instantly with cache-first approach
  Future<bool> playSongInstant(String videoId, {Map<String, dynamic>? songData}) async {
    try {
      _isLoading = true;
      _loadingVideoId = videoId;
      notifyListeners();
      
      print('🚀 Playing song instantly: $videoId');
      
      // Step 1: Get song metadata (from cache if available)
      Map<String, dynamic>? song = songData ?? _cacheService.getSong(videoId);
      
      if (song == null) {
        // Fallback: Create basic song data
        song = {
          'videoId': videoId,
          'title': 'Loading...',
          'artist': 'Loading...',
          'thumbnailUrl': null,
        };
      }
      
      // Step 2: Get stream URL (cache-first, lightning fast)
      String? streamUrl = _cacheService.getStreamUrl(videoId);
      
      if (streamUrl == null) {
        print('🔄 Stream URL not cached, fetching...');
        
        // Fetch stream URL using StreamProvider
        try {
          final streamProvider = await stream_service.StreamProvider.fetch(videoId);
          if (streamProvider.playable) {
            final audioStream = streamProvider.highestQualityAudio;
            if (audioStream != null) {
              streamUrl = audioStream.url;
              
              // Cache for next time (6 hours expiry)
              await _cacheService.cacheStreamUrl(videoId, streamUrl);
              print('✅ Stream URL fetched and cached');
            }
          }
        } catch (e) {
          print('❌ Error fetching stream URL: $e');
          _isLoading = false;
          _loadingVideoId = null;
          notifyListeners();
          return false;
        }
      } else {
        print('⚡ Stream URL loaded from cache instantly!');
      }
      
      if (streamUrl == null) {
        print('❌ No stream URL available');
        _isLoading = false;
        _loadingVideoId = null;
        notifyListeners();
        return false;
      }
      
      // Step 3: Play the song (instant if audio service is ready)
      final success = await _audioService.playSong(streamUrl, videoId, song);
      
      if (success) {
        // Cache the song metadata for next time
        await _cacheService.cacheSong(videoId, song);
        
        // Update current playlist if not already set
        if (_currentPlaylist.isEmpty || _currentPlaylist[_currentIndex]['videoId'] != videoId) {
          _currentPlaylist = [song];
          _currentIndex = 0;
        }
        
        print('🎵 Song playing successfully: ${song['title']}');
      }
      
      _isLoading = false;
      _loadingVideoId = null;
      notifyListeners();
      
      return success;
    } catch (e) {
      print('❌ Error in playSongInstant: $e');
      _isLoading = false;
      _loadingVideoId = null;
      notifyListeners();
      return false;
    }
  }
  
  /// 🎵 Set playlist and play song
  Future<bool> setPlaylistAndPlay(List<Map<String, dynamic>> playlist, int index) async {
    try {
      _currentPlaylist = List.from(playlist);
      _currentIndex = index.clamp(0, playlist.length - 1);
      notifyListeners();
      
      if (playlist.isNotEmpty && index < playlist.length) {
        final song = playlist[index];
        final videoId = song['videoId'] as String;
        
        // Pre-load stream URLs for next/previous songs in background
        _preloadAdjacentSongs();
        
        return await playSongInstant(videoId, songData: song);
      }
      
      return false;
    } catch (e) {
      print('❌ Error setting playlist: $e');
      return false;
    }
  }
  
  /// 🎵 Play next song
  Future<bool> playNext() async {
    if (_currentPlaylist.isEmpty) return false;
    
    try {
      int nextIndex;
      
      if (_isShuffling) {
        // Random next song
        nextIndex = (DateTime.now().millisecondsSinceEpoch % _currentPlaylist.length);
      } else {
        // Sequential next
        nextIndex = _currentIndex + 1;
        
        if (nextIndex >= _currentPlaylist.length) {
          if (_isRepeating) {
            nextIndex = 0; // Repeat playlist
          } else {
            return false; // End of playlist
          }
        }
      }
      
      _currentIndex = nextIndex;
      final song = _currentPlaylist[_currentIndex];
      final videoId = song['videoId'] as String;
      
      // Pre-load adjacent songs
      _preloadAdjacentSongs();
      
      return await playSongInstant(videoId, songData: song);
    } catch (e) {
      print('❌ Error playing next song: $e');
      return false;
    }
  }
  
  /// 🎵 Play previous song
  Future<bool> playPrevious() async {
    if (_currentPlaylist.isEmpty) return false;
    
    try {
      int prevIndex = _currentIndex - 1;
      
      if (prevIndex < 0) {
        if (_isRepeating) {
          prevIndex = _currentPlaylist.length - 1; // Go to last song
        } else {
          return false; // Beginning of playlist
        }
      }
      
      _currentIndex = prevIndex;
      final song = _currentPlaylist[_currentIndex];
      final videoId = song['videoId'] as String;
      
      // Pre-load adjacent songs
      _preloadAdjacentSongs();
      
      return await playSongInstant(videoId, songData: song);
    } catch (e) {
      print('❌ Error playing previous song: $e');
      return false;
    }
  }
  
  /// 🎵 Pre-load stream URLs for adjacent songs
  void _preloadAdjacentSongs() {
    if (!_cacheService.getPreference('preloadUrls', true)) return;
    
    try {
      final preloadIds = <String>[];
      
      // Pre-load next song
      if (_currentIndex + 1 < _currentPlaylist.length) {
        preloadIds.add(_currentPlaylist[_currentIndex + 1]['videoId']);
      } else if (_isRepeating && _currentPlaylist.isNotEmpty) {
        preloadIds.add(_currentPlaylist[0]['videoId']);
      }
      
      // Pre-load previous song
      if (_currentIndex - 1 >= 0) {
        preloadIds.add(_currentPlaylist[_currentIndex - 1]['videoId']);
      } else if (_isRepeating && _currentPlaylist.isNotEmpty) {
        preloadIds.add(_currentPlaylist.last['videoId']);
      }
      
      if (preloadIds.isNotEmpty) {
        _cacheService.preloadStreamUrls(preloadIds);
      }
    } catch (e) {
      print('❌ Error pre-loading adjacent songs: $e');
    }
  }
  
  /// 🎵 Toggle shuffle
  void toggleShuffle() {
    _isShuffling = !_isShuffling;
    notifyListeners();
    print('🔀 Shuffle: $_isShuffling');
  }
  
  /// 🎵 Toggle repeat
  void toggleRepeat() {
    _isRepeating = !_isRepeating;
    notifyListeners();
    print('🔁 Repeat: $_isRepeating');
  }
  
  /// 🎵 Seek to position
  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }
  
  /// 🎵 Play/pause toggle
  Future<void> togglePlayPause() async {
    if (_audioService.player.playing) {
      await _audioService.pause();
    } else {
      await _audioService.play();
    }
  }
  
  /// 🎵 Set volume
  Future<void> setVolume(double volume) async {
    await _audioService.setVolume(volume);
  }
  
  /// 🎵 Get current playback info
  Map<String, dynamic> getPlaybackInfo() {
    final audioInfo = _audioService.getCurrentPlaybackInfo();
    return {
      ...audioInfo,
      'playlist': _currentPlaylist,
      'currentIndex': _currentIndex,
      'isShuffling': _isShuffling,
      'isRepeating': _isRepeating,
      'isLoading': _isLoading,
      'loadingVideoId': _loadingVideoId,
    };
  }
  
  @override
  void dispose() {
    _audioService.removeListener(_onAudioServiceChanged);
    super.dispose();
  }
}
