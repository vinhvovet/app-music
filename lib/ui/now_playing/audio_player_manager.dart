import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerManager {
  AudioPlayerManager._internal();

  static final AudioPlayerManager _instance = AudioPlayerManager._internal();

  factory AudioPlayerManager() => _instance;
  String get currentUrl => _songUrl;


  AudioPlayer? _player;
  Stream<DurationState>? durationState;
  String _songUrl = "";

  AudioPlayer get player {
    _player ??= AudioPlayer();
    return _player!;
  }

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
    );

    if (isNewSong) {
      try {
        await player.setUrl(_songUrl);
      } catch (e) {
        print("🔴 Error setting song URL: $e");
      }
    }
  }

  Future<void> updateSongUrl(String url) async {
    _songUrl = url;
    await prepare(isNewSong: true);
  }

  Future<void> stop() async {
    await player.stop();
  }

  Future<void> dispose() async {
    await player.dispose();
    _player = null; // Để player được tạo lại nếu cần
  }
}

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
