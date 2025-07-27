import 'package:flutter/material.dart';
import 'package:music_app/data/model/song.dart';
import 'package:music_app/ui/now_playing/favorite_service.dart';

class ProviderStateManagement extends ChangeNotifier {
  final List<Song> _favoriteSongs = [];
  final _favoriteService = FavoriteService();

  List<Song> get favoriteSongs => _favoriteSongs;

  /// Tải danh sách yêu thích từ Firestore
  Future<void> loadFavorites() async {
    _favoriteSongs.clear();
    _favoriteSongs.addAll(await _favoriteService.getFavorites());
    notifyListeners();
  }

  /// Kiểm tra một bài hát có đang được yêu thích không
  Future<bool> isFavorite(Song song) async {
    return await _favoriteService.isFavorite(song.id);
  }

  /// Thêm hoặc gỡ bài hát khỏi danh sách yêu thích
  Future<void> toggleFavorite(Song song) async {
    final isFav = await _favoriteService.isFavorite(song.id);
    if (isFav) {
      await _favoriteService.removeFavorite(song.id);
      _favoriteSongs.removeWhere((s) => s.id == song.id);
    } else {
      await _favoriteService.addFavorite(song);
      _favoriteSongs.add(song);
    }
    notifyListeners();
  }
}