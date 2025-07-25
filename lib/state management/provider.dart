import 'package:flutter/material.dart';
import 'package:music_app/data/model/song.dart';

class ProviderStateManagement extends ChangeNotifier {
  final List<Song> _favoriteSongs = [];

  List<Song> get favoriteSongs => _favoriteSongs;

  /// Kiểm tra một bài hát có đang được yêu thích không
  bool isFavorite(Song song) {
    return _favoriteSongs.any((s) => s.id == song.id);
  }

  /// Thêm hoặc gỡ bài hát khỏi danh sách yêu thích
  void toggleFavorite(Song song) {
    final existingIndex = _favoriteSongs.indexWhere((s) => s.id == song.id);
    if (existingIndex >= 0) {
      _favoriteSongs.removeAt(existingIndex); // Gỡ bỏ nếu đã có
    } else {
      _favoriteSongs.add(song); // Thêm nếu chưa có
    }
    notifyListeners();
  }
}
