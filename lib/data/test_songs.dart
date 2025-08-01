// 🎵 Test Songs - Danh sách bài hát test cho development
import '../data/music_models.dart';

class TestSongs {
  /// Danh sách video IDs đã test và hoạt động
  static const List<String> workingVideoIds = [
    'jNQXAC9IVRw', // Me! - Taylor Swift (usually available)
    'uelHwf8o7_U', // Love The Way You Lie - Eminem
    'YQHsXMglC9A', // Hello - Adele
    'CevxZvSJLk8', // Katy Perry - Roar
    'lp-EO5I60KA', // Thinking Out Loud - Ed Sheeran
  ];

  /// Tạo test playlist với các bài có thể phát được
  static List<MusicTrack> getTestPlaylist() {
    return [
      MusicTrack(
        id: 'test_1',
        videoId: 'jNQXAC9IVRw',
        title: 'Me! (feat. Brendon Urie)',
        artist: 'Taylor Swift',
        duration: const Duration(minutes: 3, seconds: 13),
        thumbnail: 'https://i.ytimg.com/vi/jNQXAC9IVRw/maxresdefault.jpg',
      ),
      MusicTrack(
        id: 'test_2', 
        videoId: 'uelHwf8o7_U',
        title: 'Love The Way You Lie',
        artist: 'Eminem ft. Rihanna',
        duration: const Duration(minutes: 4, seconds: 23),
        thumbnail: 'https://i.ytimg.com/vi/uelHwf8o7_U/maxresdefault.jpg',
      ),
      MusicTrack(
        id: 'test_3',
        videoId: 'YQHsXMglC9A', 
        title: 'Hello',
        artist: 'Adele',
        duration: const Duration(minutes: 4, seconds: 55),
        thumbnail: 'https://i.ytimg.com/vi/YQHsXMglC9A/maxresdefault.jpg',
      ),
      MusicTrack(
        id: 'test_4',
        videoId: 'CevxZvSJLk8',
        title: 'Roar',
        artist: 'Katy Perry', 
        duration: const Duration(minutes: 3, seconds: 43),
        thumbnail: 'https://i.ytimg.com/vi/CevxZvSJLk8/maxresdefault.jpg',
      ),
      MusicTrack(
        id: 'test_5',
        videoId: 'lp-EO5I60KA',
        title: 'Thinking Out Loud',
        artist: 'Ed Sheeran',
        duration: const Duration(minutes: 4, seconds: 41),
        thumbnail: 'https://i.ytimg.com/vi/lp-EO5I60KA/maxresdefault.jpg',
      ),
    ];
  }

  /// Check nếu video ID có trong danh sách test
  static bool isTestVideo(String videoId) {
    return workingVideoIds.contains(videoId);
  }

  /// Thông báo khi load test songs
  static void showTestMessage() {
    print('🧪 Loading test playlist with verified working songs');
    print('🎵 These songs are known to work for testing purposes');
  }
}
