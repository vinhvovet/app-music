# Hướng dẫn sử dụng Integrated Music System

## Tổng quan
Tôi đã tích hợp thành công hệ thống nhạc từ Harmony-Music vào project của bạn. Hệ thống này cung cấp:

1. **Local Music Support**: Hỗ trợ đọc nhạc từ file JSON local
2. **Online Music Search**: Tìm kiếm nhạc online từ YouTube Music (tính năng nâng cao)
3. **Combined Search**: Tìm kiếm kết hợp local + online
4. **Music Models**: Models chuẩn cho Track, Album, Playlist, Artist
5. **Performance Optimization**: Khởi tạo tối ưu trong StartupPerformance

## Các file đã được tạo/cập nhật:

### 1. Models và Services
- `lib/data/music_models.dart`: Định nghĩa các model cho MusicTrack, MusicAlbum, MusicPlaylist, MusicArtist
- `lib/data/music_service_simple.dart`: Service đơn giản để demo, có thể mở rộng thành full service sau
- `lib/data/integrated_music_service.dart`: Service tích hợp chính, kết hợp local và online
- `lib/data/helper.dart`: Các hàm tiện ích
- `lib/data/constant.dart`, `nav_parser.dart`, `utils.dart`: Các file hỗ trợ từ Harmony-Music

### 2. UI Demo
- `lib/ui/music_search_demo.dart`: Widget demo để test các tính năng mới

### 3. Cập nhật chính
- `lib/startup_performance.dart`: Đã tích hợp khởi tạo Music Service
- `lib/main.dart`: Thêm route cho demo page
- `lib/ui/auth_form/login_screen.dart`: Thêm button "Demo Music Search"
- `assets/songs.json`: Đã cập nhật format tương thích với MusicTrack model

## Cách sử dụng:

### 1. Khởi tạo (đã tự động)
```dart
// Đã được tự động gọi trong main.dart
await StartupPerformance.initializeServices();
```

### 2. Truy cập Music Service
```dart
// Lấy service instance
final musicService = StartupPerformance.musicService;

// Lấy danh sách nhạc local
List<MusicTrack> localTracks = musicService.getLocalTracks();

// Tìm kiếm kết hợp
Map<String, dynamic> results = await musicService.searchCombined('tên bài hát');

// Tìm kiếm chỉ online
Map<String, dynamic> onlineResults = await musicService.searchOnline('query');

// Lấy gợi ý tìm kiếm
List<String> suggestions = await musicService.getSearchSuggestions('vietnam');

// Lấy lời bài hát từ local
String? lyrics = musicService.getLocalLyrics('track_id');
```

### 3. Test Demo
1. Chạy app: `flutter run`
2. Trên màn hình login, nhấn button "Demo Music Search" (màu cam)
3. Tab "Local": Xem danh sách nhạc local từ JSON
4. Tab "Search Results": Nhập từ khóa để tìm kiếm
5. Nhấn biểu tượng 3 chấm để xem options (Play, Lyrics, Info)
6. Nhấn FAB (floating button) để test các tính năng khác

## Format JSON mới:

File `assets/songs.json` đã được cập nhật với format tương thích:

```json
{
  "songs": [
    {
      "videoId": "track_id",
      "title": "Tên bài hát",
      "artists": [{"name": "Nghệ sĩ", "id": "artist_id"}],
      "album": {"name": "Album", "id": "album_id"},
      "thumbnails": [{"url": "image_url"}],
      "url": "audio_url",
      "duration": 224,
      "length": "3:44",
      "lyrics": "Lời bài hát...",
      "lyricsData": {
        "lines": [
          {
            "text": "Dòng lời",
            "startTime": 12000,
            "endTime": 16000
          }
        ]
      }
    }
  ]
}
```

## Tính năng có sẵn:
✅ Đọc và hiển thị nhạc local
✅ Tìm kiếm trong nhạc local  
✅ Hiển thị thông tin chi tiết bài hát
✅ Hiển thị lời bài hát
✅ UI demo đầy đủ
✅ Performance optimization
✅ **YouTube streaming support** - Lấy stream URL từ YouTube
✅ **Stream quality selection** - Chọn chất lượng cao/thấp
✅ **Error handling** - Xử lý lỗi streaming

## Tính năng streaming mới:

### 1. Lấy Stream URL
```dart
// Lấy stream provider với đầy đủ thông tin
StreamProvider streamProvider = await musicService.getStreamUrl('video_id');

// Lấy URL chất lượng cao
String? highQualityUrl = await musicService.getHighQualityAudioUrl('video_id');

// Lấy URL chất lượng thấp  
String? lowQualityUrl = await musicService.getLowQualityAudioUrl('video_id');
```

### 2. Test Streaming trong Demo
1. Chạy app và vào "Demo Music Search"
2. Nhấn menu 3 chấm của bất kỳ bài hát nào
3. Chọn **"Test Stream"** để test lấy stream URL
4. Hoặc nhấn FAB → **"Test Stream URL"** để test với video mẫu

### 3. Stream Info Available
- **Playable status**: Có thể stream hay không
- **Multiple formats**: Danh sách các format audio có sẵn
- **Quality selection**: Chọn chất lượng dựa trên itag
- **Bitrate & Size info**: Thông tin chi tiết về chất lượng
- **Direct URL**: URL trực tiếp để stream

## Dependencies đã thêm:
- `dio: ^5.7.0` - Cho HTTP requests
- `youtube_explode_dart: ^2.2.1` - **Cho YouTube streaming**

## Cách mở rộng hệ thống:

1. **Để kích hoạt full online search**: Cập nhật `music_service_simple.dart` thành `music_service.dart` và cung cấp các parser functions cần thiết.

2. **Để thêm streaming**: Tích hợp với just_audio player đã có sẵn trong project.

3. **Để sync với Firebase**: Sử dụng Firestore để lưu playlists, favorites.

Hệ thống đã sẵn sàng sử dụng và có thể mở rộng theo nhu cầu!
