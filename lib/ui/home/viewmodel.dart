import 'dart:async';
import 'package:music_app/data/repository/repository.dart';
import '../../data/model/song.dart';

class MusicAppViewModel {
  final StreamController<List<Song>> songStream = StreamController.broadcast();
  List<Song> _allSongs = [];

  void loadSongs() {
    final repository = DefaultRepository();
    repository.loadData().then((value) {
      if (value != null) {
        _allSongs = value;
        songStream.add(value);
      }
    });
  }
List<Song> get favoriteSongs =>
    _allSongs.where((song) => song.isFavorite).toList();

void toggleFavorite(Song song) {
  final index = _allSongs.indexWhere((s) => s.id == song.id);
  if (index != -1) {
    _allSongs[index].isFavorite = !_allSongs[index].isFavorite;
    songStream.add(_allSongs); // update stream
  }
}

  void searchByKeyword(String query) {
    if (query.isEmpty) {
      songStream.add(_allSongs);
    } else {
      final lowerQuery = query.toLowerCase();
      final filtered = _allSongs.where((song) =>
        song.title.toLowerCase().contains(lowerQuery) ||
        song.artist.toLowerCase().contains(lowerQuery) ||
        song.album.toLowerCase().contains(lowerQuery)
      ).toList();
      songStream.add(filtered);
    }
  }
}
