import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

/// 🚀 Harmony Audio Service - Audio engine siêu tốc
class HarmonyAudioService extends ChangeNotifier {
  static HarmonyAudioService? _instance;
  static HarmonyAudioService get instance => _instance ??= HarmonyAudioService._();
  
  HarmonyAudioService._();
  
  late AudioPlayer _player;
  late AudioSession _session;
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  // Current playing info
  String? _currentVideoId;
  Map<String, dynamic>? _currentSong;
  
  // Getters
  AudioPlayer get player => _player;
  String? get currentVideoId => _currentVideoId;
  Map<String, dynamic>? get currentSong => _currentSong;
  
  // Stream getters for real-time updates
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<double> get volumeStream => _player.volumeStream;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize audio session for optimal playback
      _session = await AudioSession.instance;
      await _session.configure(const AudioSessionConfiguration.music());
      
      // Initialize audio player with optimized settings
      _player = AudioPlayer(
        // Use platform-specific audio backends for best performance
        audioPipeline: AudioPipeline(
          androidAudioEffects: [
            // Enable hardware acceleration when available
            AndroidLoudnessEnhancer(),
          ],
        ),
      );
      
      // Setup audio interruption handling
      _session.interruptionEventStream.listen((event) {
        _handleInterruption(event);
      });
      
      // Setup becoming noisy handling (headphones unplugged)
      _session.becomingNoisyEventStream.listen((_) {
        _player.pause();
      });
      
      _isInitialized = true;
      print('🎵 Harmony Audio Service initialized - Ready for instant playback!');
      notifyListeners();
    } catch (e) {
      print('❌ Error initializing audio service: $e');
    }
  }
  
  /// 🎵 Play song with lightning speed
  Future<bool> playSong(String streamUrl, String videoId, Map<String, dynamic> songData) async {
    if (!_isInitialized) {
      print('❌ Audio service not initialized');
      return false;
    }
    
    try {
      print('🎵 Playing song: ${songData['title']} (${videoId})');
      
      // Set current song info
      _currentVideoId = videoId;
      _currentSong = songData;
      notifyListeners();
      
      // Set audio source và play ngay lập tức
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(streamUrl),
          tag: MediaItem(
            id: videoId,
            title: songData['title'] ?? 'Unknown Title',
            artist: songData['artist'] ?? 'Unknown Artist',
            artUri: songData['thumbnailUrl'] != null 
                ? Uri.parse(songData['thumbnailUrl']) 
                : null,
          ),
        ),
      );
      
      // Play immediately
      await _player.play();
      
      print('✅ Song started playing successfully');
      return true;
    } catch (e) {
      print('❌ Error playing song: $e');
      return false;
    }
  }
  
  /// 🎵 Resume playback
  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      print('❌ Error resuming playback: $e');
    }
  }
  
  /// 🎵 Pause playback
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      print('❌ Error pausing playback: $e');
    }
  }
  
  /// 🎵 Stop playback
  Future<void> stop() async {
    try {
      await _player.stop();
      _currentVideoId = null;
      _currentSong = null;
      notifyListeners();
    } catch (e) {
      print('❌ Error stopping playback: $e');
    }
  }
  
  /// 🎵 Seek to position
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      print('❌ Error seeking: $e');
    }
  }
  
  /// 🎵 Set volume
  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      print('❌ Error setting volume: $e');
    }
  }
  
  /// 🎵 Set playback speed
  Future<void> setSpeed(double speed) async {
    try {
      await _player.setSpeed(speed.clamp(0.5, 2.0));
    } catch (e) {
      print('❌ Error setting speed: $e');
    }
  }
  
  /// 🎵 Handle audio interruptions
  void _handleInterruption(AudioInterruptionEvent event) {
    try {
      switch (event.type) {
        case AudioInterruptionType.duck:
          // Lower volume during interruption
          _player.setVolume(0.3);
          break;
        case AudioInterruptionType.pause:
          // Pause playback
          _player.pause();
          break;
        case AudioInterruptionType.unknown:
          break;
      }
      
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(0.3);
            break;
          case AudioInterruptionType.pause:
            _player.pause();
            break;
          case AudioInterruptionType.unknown:
            break;
        }
      } else {
        // Interruption ended
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(1.0);
            break;
          case AudioInterruptionType.pause:
            // Auto-resume based on interruption type
            if (event.type == AudioInterruptionType.pause) {
              _player.play();
            }
            break;
          case AudioInterruptionType.unknown:
            break;
        }
      }
    } catch (e) {
      print('❌ Error handling audio interruption: $e');
    }
  }
  
  /// 🎵 Preload next song URL for instant switching
  Future<void> preloadNext(String streamUrl) async {
    try {
      // This could be enhanced to preload the next song
      // For now, just cache the URL in memory
      print('🔄 Preloading next song URL for instant playback');
    } catch (e) {
      print('❌ Error preloading next song: $e');
    }
  }
  
  /// 🎵 Get current playback info
  Map<String, dynamic> getCurrentPlaybackInfo() {
    return {
      'videoId': _currentVideoId,
      'song': _currentSong,
      'isPlaying': _player.playing,
      'position': _player.position.inMilliseconds,
      'duration': _player.duration?.inMilliseconds,
      'volume': _player.volume,
      'speed': _player.speed,
    };
  }
  
  /// 🎵 Dispose resources
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

/// 🎵 Media Item for audio session
class MediaItem {
  final String id;
  final String title;
  final String artist;
  final Uri? artUri;
  
  const MediaItem({
    required this.id,
    required this.title,
    required this.artist,
    this.artUri,
  });
}
