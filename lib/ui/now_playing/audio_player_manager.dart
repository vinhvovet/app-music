import 'dart:async';
import 'dart:developer' as developer;

import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerManager {
  // StreamController để quản lý lời bài hát
  final StreamController<String> _lyricsStreamController = StreamController<String>.broadcast();

  // Getter để trả về Stream
  Stream<String> get lyricsStream => _lyricsStreamController.stream;

  // Hàm để cập nhật lời bài hát
  void updateLyrics(String lyrics) {
    if (!_lyricsStreamController.isClosed) {
      _lyricsStreamController.add(lyrics);
    } else {
      developer.log("⚠️ Attempted to add lyrics to a closed StreamController.", name: 'AudioPlayerManager');
    }
  }

  // Singleton pattern
  AudioPlayerManager._internal();

  static final AudioPlayerManager _instance = AudioPlayerManager._internal();

  factory AudioPlayerManager() => _instance;

  // Các thuộc tính khác
  String get currentUrl => _songUrl;
  AudioPlayer? _player;
  Stream<DurationState>? durationState;
  String _songUrl = "";

  AudioPlayer get player {
    _player ??= AudioPlayer();
    return _player!;
  }

  // Get player state stream as broadcast stream
  Stream<PlayerState> get playerStateStream => player.playerStateStream.asBroadcastStream();

  // Chuẩn bị bài hát
  Future<void> prepare({bool isNewSong = false}) async {
    if (_songUrl.isEmpty) return;

    durationState = Rx.combineLatest2<Duration, PlaybackEvent, DurationState>(
      player.positionStream,
      player.playbackEventStream,
      (position, playbackEvent) => DurationState(
        progress: position,
        buffered: playbackEvent.bufferedPosition,
        total: playbackEvent.duration,
      ),
    ).asBroadcastStream();

    if (isNewSong) {
      try {
        await player.setUrl(_songUrl);
      } catch (e) {
        developer.log("🔴 Error setting song URL: $e", name: 'AudioPlayerManager');
      }
    }
  }

  // Cập nhật URL bài hát
  Future<void> updateSongUrl(String url) async {
    _songUrl = url;
    await prepare(isNewSong: true);
  }

  // Dừng phát nhạc
  Future<void> stop() async {
    await player.stop();
  }

  // Giải phóng tài nguyên
  Future<void> dispose() async {
    await player.dispose();
    _player = null; // Để player được tạo lại nếu cần
    if (!_lyricsStreamController.isClosed) {
      _lyricsStreamController.close();
    }
  }
}

// Lớp DurationState để quản lý trạng thái thời lượng bài hát
class DurationState {
  const DurationState({
    required this.progress,
    required this.buffered,
    this.total,
  });

  final Duration progress;
  final Duration buffered;
  final Duration? total;
}