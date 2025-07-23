import 'package:flutter/material.dart';
import 'album.dart';
import 'http_request.dart';

class AlbumProvider with ChangeNotifier {
  List<Album> _albums = [];
  bool _isLoading = false;
  String? _error;

  List<Album> get albums => _albums;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAlbum() async {
    _isLoading = true;
    _error = null;
    try {
      _albums = await fetchAlbums();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    notifyListeners();
  }
}
