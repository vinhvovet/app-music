import 'package:flutter/material.dart';
import 'package:music_app/data/model/song.dart';
import 'package:music_app/data/music_models.dart';
import 'package:music_app/ui/now_playing/favorite_service.dart';

class ProviderStateManagement extends ChangeNotifier {
  final List<Song> _favoriteSongs = [];
  final _favoriteService = FavoriteService();
  bool _isLoading = false;
  
  // Currently playing music state
  MusicTrack? _currentlyPlayingTrack;
  String? _currentStreamUrl;
  List<MusicTrack>? _currentPlaylist;
  
  List<Song> get favoriteSongs => List.unmodifiable(_favoriteSongs); // Return immutable list
  bool get isLoading => _isLoading;
  
  // Getters for currently playing music
  MusicTrack? get currentlyPlayingTrack => _currentlyPlayingTrack;
  String? get currentStreamUrl => _currentStreamUrl;
  List<MusicTrack>? get currentPlaylist => _currentPlaylist;

  /// Tải danh sách yêu thích từ Firestore
  Future<void> loadFavorites() async {
    if (_isLoading) return; // Prevent multiple simultaneous calls
    
    // Kiểm tra xem user có đăng nhập không trước khi load favorites
    if (!_favoriteService.isUserAuthenticated) {
      _updateFavorites([]);
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final favorites = await _favoriteService.getFavorites();
      _updateFavorites(favorites);
    } catch (e) {
      // Log error or handle gracefully
      print('Error loading favorites: $e');
      _updateFavorites([]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Helper method to update favorites list
  void _updateFavorites(List<Song> newFavorites) {
    _favoriteSongs.clear();
    _favoriteSongs.addAll(newFavorites);
  }

  /// Kiểm tra một bài hát có đang được yêu thích không
  Future<bool> isFavorite(Song song) async {
    if (!_favoriteService.isUserAuthenticated) {
      return false;
    }
    
    // Check local cache first for better performance
    final localCheck = _favoriteSongs.any((s) => s.id == song.id);
    if (localCheck) return true;
    
    try {
      return await _favoriteService.isFavorite(song.id);
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }

  /// Thêm hoặc gỡ bài hát khỏi danh sách yêu thích
  Future<void> toggleFavorite(Song song) async {
    if (!_favoriteService.isUserAuthenticated) {
      return;
    }
    
    try {
      final isFav = _favoriteSongs.any((s) => s.id == song.id);
      
      if (isFav) {
        await _favoriteService.removeFavorite(song.id);
        _favoriteSongs.removeWhere((s) => s.id == song.id);
      } else {
        await _favoriteService.addFavorite(song);
        _favoriteSongs.add(song);
      }
      
      // Only notify listeners once after the change
      notifyListeners();
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  /// Converter method to convert MusicTrack to Song for storage
  Song _convertMusicTrackToSong(MusicTrack track) {
    return Song(
      id: track.videoId.isNotEmpty ? track.videoId : track.id,
      title: track.title,
      artist: track.artist ?? 'Unknown Artist',
      album: track.album ?? 'Unknown Album',
      source: track.url ?? track.extras?['url'] ?? '',
      image: track.thumbnail ?? '',
      duration: track.duration?.inSeconds ?? 0,
      lyrics: track.extras?['lyrics'],
      lyricsData: track.extras?['lyricsData'],
      isFavorite: track.isFavorite ?? false,
    );
  }

  /// Check if a MusicTrack is favorite
  Future<bool> isFavoriteMusicTrack(MusicTrack track) async {
    final song = _convertMusicTrackToSong(track);
    return await isFavorite(song);
  }

  /// Toggle favorite for MusicTrack
  Future<void> toggleFavoriteMusicTrack(MusicTrack track) async {
    final song = _convertMusicTrackToSong(track);
    await toggleFavorite(song);
  }

  /// Khởi tạo lại sau khi user đăng nhập
  Future<void> initializeAfterAuth() async {
    await loadFavorites();
  }

  /// Set currently playing track and related information
  void setCurrentlyPlayingTrack(MusicTrack track, String streamUrl, List<MusicTrack> playlist) {
    _currentlyPlayingTrack = track;
    _currentStreamUrl = streamUrl;
    _currentPlaylist = playlist;
    notifyListeners();
  }

  /// Check if a track is currently playing (same video ID)
  bool isTrackCurrentlyPlaying(MusicTrack track) {
    return _currentlyPlayingTrack?.videoId == track.videoId && 
           _currentlyPlayingTrack?.videoId.isNotEmpty == true;
  }

  /// Clear currently playing track (when music stops)
  void clearCurrentlyPlayingTrack() {
    _currentlyPlayingTrack = null;
    _currentStreamUrl = null;
    _currentPlaylist = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up resources
    _favoriteSongs.clear();
    _currentlyPlayingTrack = null;
    _currentStreamUrl = null;
    _currentPlaylist = null;
    super.dispose();
  }
}