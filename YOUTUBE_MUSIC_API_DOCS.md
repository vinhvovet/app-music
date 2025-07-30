# YouTube Music Complete API Documentation

## Overview

The `YouTubeMusicCompleteAPI` is a comprehensive Flutter service that provides access to YouTube Music data including search, song details, streaming URLs, charts, and artist information.

## Installation

Add the following dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  dio: ^5.3.2
  youtube_explode_dart: ^2.0.0
  provider: ^6.1.1
```

## Setup

1. Initialize the API in your app startup:

```dart
// In startup_performance.dart
await StartupPerformance.initializeServices();

// Access the API instance
final api = StartupPerformance.musicAPI;
```

## API Methods

### 1. Search Music

Search for songs, artists, albums, or playlists.

```dart
Future<Map<String, dynamic>> searchMusic(
  String query, {
  String filter = 'all', // 'songs', 'artists', 'albums', 'playlists', 'all'
  int limit = 20,
})
```

**Example:**
```dart
final results = await api.searchMusic('billie eilish', filter: 'songs');

if (results['songs'] != null) {
  final songs = results['songs'] as List<Map<String, dynamic>>;
  for (var song in songs) {
    print('${song['title']} - ${song['artist']}');
  }
}
```

**Response Structure:**
```json
{
  "songs": [
    {
      "videoId": "DyDfgMOUjCI",
      "title": "bad guy",
      "artist": "Billie Eilish",
      "album": "WHEN WE ALL FALL ASLEEP, WHERE DO WE GO?",
      "duration": "194",
      "thumbnail": "https://...",
      "views": "1.2B views"
    }
  ],
  "artists": [...],
  "albums": [...],
  "playlists": [...]
}
```

### 2. Get Song Details

Get detailed information about a song including streaming URLs.

```dart
Future<Map<String, dynamic>> getSongDetails(String videoId)
```

**Example:**
```dart
final details = await api.getSongDetails('DyDfgMOUjCI');

print('Title: ${details['title']}');
print('Artist: ${details['artist']}');
print('Duration: ${details['duration']} seconds');

if (details['streamingUrls'] != null) {
  final urls = details['streamingUrls'] as List<Map<String, dynamic>>;
  final bestQuality = urls.first;
  print('Stream URL: ${bestQuality['url']}');
}
```

**Response Structure:**
```json
{
  "videoId": "DyDfgMOUjCI",
  "title": "bad guy",
  "artist": "Billie Eilish",
  "album": "WHEN WE ALL FALL ASLEEP, WHERE DO WE GO?",
  "duration": 194,
  "thumbnail": "https://...",
  "streamingUrls": [
    {
      "quality": "high",
      "container": "mp4",
      "url": "https://...",
      "bitrate": 128
    }
  ]
}
```

### 3. Get Charts

Get trending music charts.

```dart
Future<Map<String, dynamic>> getCharts({String region = 'US'})
```

**Example:**
```dart
final charts = await api.getCharts();
print('Charts: ${charts.toString()}');
```

### 4. Get Popular Songs

Get a list of popular songs with customizable limit.

```dart
Future<List<Map<String, dynamic>>> getPopularSongs({int limit = 50})
```

**Example:**
```dart
final popularSongs = await api.getPopularSongs(limit: 10);

for (int i = 0; i < popularSongs.length; i++) {
  final song = popularSongs[i];
  print('${i + 1}. ${song['title']} - ${song['artist']}');
}
```

### 5. Get Artist Information

Get detailed information about an artist.

```dart
Future<Map<String, dynamic>> getArtist(String artistId)
```

**Example:**
```dart
final artistInfo = await api.getArtist('UC0C-w0YjGpqDWGG5mJBdSgQ');

print('Artist: ${artistInfo['name']}');
print('Subscribers: ${artistInfo['subscribers']}');

if (artistInfo['topSongs'] != null) {
  final topSongs = artistInfo['topSongs'] as List<Map<String, dynamic>>;
  for (var song in topSongs) {
    print('- ${song['title']}');
  }
}
```

## Error Handling

All API methods return error information in the response:

```dart
final result = await api.searchMusic('some query');

if (result['error'] != null) {
  print('Error: ${result['error']}');
  // Handle error appropriately
} else {
  // Process successful result
}
```

## Usage in ViewModels

Integrate with your Flutter app using Provider pattern:

```dart
class MusicAppViewModel extends ChangeNotifier {
  final YouTubeMusicCompleteAPI _api = StartupPerformance.musicAPI;
  List<MusicTrack> _songs = [];
  bool _isLoading = false;

  List<MusicTrack> get songs => _songs;
  bool get isLoading => _isLoading;

  Future<void> loadSongs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final popularSongs = await _api.getPopularSongs(limit: 20);
      _songs = popularSongs.map((song) => MusicTrack.fromMap(song)).toList();
    } catch (e) {
      print('Error loading songs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> getStreamUrl(String videoId) async {
    try {
      final details = await _api.getSongDetails(videoId);
      
      if (details['streamingUrls'] != null) {
        final urls = details['streamingUrls'] as List<Map<String, dynamic>>;
        return urls.first['url'] as String;
      }
    } catch (e) {
      print('Error getting stream URL: $e');
    }
    return null;
  }

  Future<void> searchByKeyword(String keyword) async {
    if (keyword.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final results = await _api.searchMusic(keyword, filter: 'songs');
      
      if (results['songs'] != null) {
        final songs = results['songs'] as List<Map<String, dynamic>>;
        _songs = songs.map((song) => MusicTrack.fromMap(song)).toList();
      }
    } catch (e) {
      print('Error searching: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

## Performance Considerations

1. **Caching**: The API includes built-in caching for popular songs to reduce API calls.

2. **Error Recovery**: Implements retry logic and fallback mechanisms.

3. **Quality Selection**: Automatically selects the best available streaming quality.

4. **Lazy Loading**: Only loads data when requested to optimize startup time.

## Testing

Use the provided test page to verify API functionality:

```dart
// Navigate to test page
Navigator.pushNamed(context, '/test-api');
```

The test page includes:
- Search functionality testing
- Song details and streaming URL retrieval
- Charts and popular songs testing
- Error handling validation

## Troubleshooting

### Common Issues

1. **No streaming URLs found**: 
   - The video might be region-locked or unavailable
   - Try with a different video ID

2. **Search returns empty results**:
   - Check your internet connection
   - Verify the search query is valid

3. **API timeout errors**:
   - The service might be temporarily unavailable
   - Implement retry logic in your app

### Debug Mode

Enable debug logging in the API constructor:

```dart
final api = YouTubeMusicCompleteAPI(enableDebug: true);
```

This will print detailed request/response information to help diagnose issues.
