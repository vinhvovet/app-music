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
