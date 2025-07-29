import 'package:flutter/material.dart';
import 'package:music_app/data/model/song.dart';
import 'package:music_app/ui/now_playing/favorite_service.dart';

class ProviderStateManagement extends ChangeNotifier {
  final List<Song> _favoriteSongs = [];
  final _favoriteService = FavoriteService();

  List<Song> get favoriteSongs => _favoriteSongs;

  /// Tải danh sách yêu thích từ Firestore
  Future<void> loadFavorites() async {
    // Kiểm tra xem user có đăng nhập không trước khi load favorites
    if (!_favoriteService.isUserAuthenticated) {
      _favoriteSongs.clear();
      notifyListeners();
      return;
    }
    
    try {
      _favoriteSongs.clear();
      _favoriteSongs.addAll(await _favoriteService.getFavorites());
      notifyListeners();
    } catch (e) {
      // Log error or handle gracefully
      print('Error loading favorites: $e');
      _favoriteSongs.clear();
      notifyListeners();
    }
  }

  /// Kiểm tra một bài hát có đang được yêu thích không
  Future<bool> isFavorite(Song song) async {
    if (!_favoriteService.isUserAuthenticated) {
      return false;
    }
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
      final isFav = await _favoriteService.isFavorite(song.id);
      if (isFav) {
        await _favoriteService.removeFavorite(song.id);
        _favoriteSongs.removeWhere((s) => s.id == song.id);
      } else {
        await _favoriteService.addFavorite(song);
        _favoriteSongs.add(song);
      }
      notifyListeners();
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  /// Khởi tạo lại sau khi user đăng nhập
  Future<void> initializeAfterAuth() async {
    await loadFavorites();
  }
}