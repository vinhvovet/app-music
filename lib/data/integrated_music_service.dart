import 'dart:convert';
import 'package:flutter/services.dart';
import 'music_models.dart';
import 'music_service_simple.dart';
import 'stream_service.dart';

class IntegratedMusicService {
  static final IntegratedMusicService _instance = IntegratedMusicService._internal();
  factory IntegratedMusicService() => _instance;
  IntegratedMusicService._internal();

  final MusicServices _musicService = MusicServices();
  List<MusicTrack> _localTracks = [];
  
  bool _isInitialized = false;

  /// Khởi tạo service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Khởi tạo music service
      await _musicService.init();
      
      // Load local tracks từ JSON
      await _loadLocalTracks();
      
      _isInitialized = true;
    } catch (e) {
      print('Lỗi khởi tạo IntegratedMusicService: $e');
    }
  }

  /// Load tracks từ file JSON local
  Future<void> _loadLocalTracks() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/songs.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> songsJson = jsonData['songs'];
      
      _localTracks = songsJson.map((json) => _convertJsonToMusicTrack(json)).toList();
    } catch (e) {
      print('Lỗi load local tracks: $e');
      _localTracks = [];
    }
  }

  /// Convert JSON format cũ sang MusicTrack model mới
  MusicTrack _convertJsonToMusicTrack(Map<String, dynamic> json) {
    try {
      // Handle artist field - có thể là String hoặc Map
      String? artist;
      if (json['artist'] is String) {
        artist = json['artist'];
      } else if (json['artist'] is Map && json['artist']['name'] != null) {
        artist = json['artist']['name'];
      }
      
      // Handle album field - có thể là String hoặc Map  
      String? album;
      if (json['album'] is String) {
        album = json['album'];
      } else if (json['album'] is Map && json['album']['name'] != null) {
        album = json['album']['name'];
      }
      
      // Safely parse duration
      Duration? duration;
      try {
        if (json['duration'] != null) {
          duration = Duration(seconds: int.parse(json['duration'].toString()));
        }
      } catch (e) {
        duration = null;
      }
      
      return MusicTrack(
        id: json['id']?.toString() ?? '',
        videoId: json['videoId']?.toString() ?? json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        artist: artist,
        album: album,
        duration: duration,
        thumbnail: json['image']?.toString(),
        url: json['source']?.toString(),
        extras: {
          'lyrics': json['lyrics']?.toString(),
          'lyricsData': json['lyricsData'],
          'isLocal': true,
        },
      );
    } catch (e) {
      print('Lỗi convert JSON track: $e');
      return MusicTrack(
        id: json['id']?.toString() ?? 'unknown',
        videoId: json['videoId']?.toString() ?? json['id']?.toString() ?? 'unknown',
        title: json['title']?.toString().trim().isNotEmpty == true ? json['title'].toString().trim() : 'Untitled Song',
        artist: 'Unknown Artist',
        album: '',
        extras: {'isLocal': true},
      );
    }
  }

  /// Lấy tất cả bài hát local
  List<MusicTrack> getLocalTracks() {
    return List.from(_localTracks);
  }

  /// Tìm kiếm online
  Future<Map<String, dynamic>> searchOnline(String query, {
    String? filter,
    int limit = 30,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      return await _musicService.search(query, filter: filter, limit: limit);
    } catch (e) {
      print('Lỗi tìm kiếm online: $e');
      return {};
    }
  }

  /// Tìm kiếm kết hợp (local + online)
  Future<Map<String, dynamic>> searchCombined(String query, {
    String? filter,
    int limit = 30,
  }) async {
    final results = <String, dynamic>{};
    
    // Tìm kiếm local
    final localResults = _searchLocal(query);
    if (localResults.isNotEmpty) {
      results['Local Songs'] = localResults;
    }
    
    // Tìm kiếm online
    try {
      final onlineResults = await searchOnline(query, filter: filter, limit: limit);
      results.addAll(onlineResults);
    } catch (e) {
      print('Lỗi tìm kiếm online: $e');
    }
    
    return results;
  }

  /// Tìm kiếm local
  List<MusicTrack> _searchLocal(String query) {
    if (query.isEmpty) return _localTracks;
    
    final lowercaseQuery = query.toLowerCase();
    return _localTracks.where((track) {
      return track.title.toLowerCase().contains(lowercaseQuery) ||
             (track.artist?.toLowerCase().contains(lowercaseQuery) ?? false) ||
             (track.album?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  /// Lấy gợi ý tìm kiếm
  Future<List<String>> getSearchSuggestions(String query) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      return await _musicService.getSearchSuggestion(query);
    } catch (e) {
      print('Lỗi lấy gợi ý: $e');
      return [];
    }
  }

  /// Lấy watch playlist cho một bài hát
  Future<Map<String, dynamic>> getWatchPlaylist({
    required String videoId,
    String? playlistId,
    int limit = 25,
    bool radio = false,
    bool shuffle = false,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      return await _musicService.getWatchPlaylist(
        videoId: videoId,
        playlistId: playlistId,
        limit: limit,
        radio: radio,
        shuffle: shuffle,
      );
    } catch (e) {
      print('Lỗi lấy watch playlist: $e');
      return {};
    }
  }

  /// Lấy lời bài hát
  Future<String?> getLyrics(String browseId) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      return await _musicService.getLyrics(browseId);
    } catch (e) {
      print('Lỗi lấy lời bài hát: $e');
      return null;
    }
  }

  /// Lấy lời bài hát local
  String? getLocalLyrics(String trackId) {
    final track = _localTracks.firstWhere(
      (t) => t.id == trackId,
      orElse: () => MusicTrack(id: '', videoId: '', title: ''),
    );
    
    if (track.id.isNotEmpty) {
      return track.extras?['lyrics'];
    }
    return null;
  }

  /// Lấy charts
  Future<List<Map<String, dynamic>>> getCharts({String? countryCode}) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      return await _musicService.getCharts(countryCode: countryCode);
    } catch (e) {
      print('Lỗi lấy charts: $e');
      return [];
    }
  }

  /// Lấy home content
  Future<dynamic> getHome({int limit = 4}) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      return await _musicService.getHome(limit: limit);
    } catch (e) {
      print('Lỗi lấy home content: $e');
      return [];
    }
  }

  /// Lấy stream URL từ video ID
  Future<StreamProvider> getStreamUrl(String videoId) async {
    try {
      return await StreamProvider.fetch(videoId);
    } catch (e) {
      print('Lỗi lấy stream URL: $e');
      return StreamProvider(
        playable: false,
        statusMSG: 'Không thể lấy stream URL: $e',
      );
    }
  }

  /// Lấy audio URL chất lượng cao từ video ID
  Future<String?> getHighQualityAudioUrl(String videoId) async {
    try {
      final streamProvider = await getStreamUrl(videoId);
      if (streamProvider.playable) {
        return streamProvider.highestQualityAudio?.url;
      }
      return null;
    } catch (e) {
      print('Lỗi lấy audio URL: $e');
      return null;
    }
  }

  /// Lấy audio URL chất lượng thấp để tiết kiệm bandwidth
  Future<String?> getLowQualityAudioUrl(String videoId) async {
    try {
      final streamProvider = await getStreamUrl(videoId);
      if (streamProvider.playable) {
        return streamProvider.lowQualityAudio?.url;
      }
      return null;
    } catch (e) {
      print('Lỗi lấy audio URL chất lượng thấp: $e');
      return null;
    }
  }

  /// Dispose service
  void dispose() {
    _musicService.dispose();
  }
}
