/// YouTube Music Complete API Usage Examples
/// 
/// This file demonstrates how to use the YouTubeMusicCompleteAPI
/// with various real-world scenarios and best practices

import '../startup_performance.dart';

class YouTubeMusicAPIUsageExamples {
  
  /// Example 1: Search for songs by artist
  static Future<void> exampleSearchByArtist() async {
    final api = StartupPerformance.musicAPI;
    
    print('🔍 Searching for songs by Billie Eilish...');
    final results = await api.searchMusic('billie eilish', filter: 'songs');
    
    if (results['songs'] != null) {
      final songs = results['songs'] as List<Map<String, dynamic>>;
      print('Found ${songs.length} songs:');
      
      for (var song in songs.take(5)) {
        print('  - ${song['title']} by ${song['artist']}');
      }
    }
  }
  
  /// Example 2: Get streaming URL for a specific song
  static Future<void> exampleGetStreamingUrl() async {
    const videoId = 'DyDfgMOUjCI'; // Billie Eilish - Bad Guy
    final api = StartupPerformance.musicAPI;
    
    print('🎵 Getting streaming URL for video: $videoId');
    final songDetails = await api.getSongDetails(videoId);
    
    if (songDetails['streamingUrls'] != null) {
      final streamingUrls = songDetails['streamingUrls'] as List<Map<String, dynamic>>;
      
      print('Available streaming qualities:');
      for (var stream in streamingUrls) {
        print('  - Quality: ${stream['quality']}, Container: ${stream['container']}');
        print('    URL: ${stream['url'].substring(0, 50)}...');
      }
      
      // Get best quality URL
      if (streamingUrls.isNotEmpty) {
        final bestQuality = streamingUrls.first;
        print('🎧 Best quality URL: ${bestQuality['url']}');
      }
    }
  }
  
  /// Example 3: Search with different filters
  static Future<void> exampleSearchWithFilters() async {
    final api = StartupPerformance.musicAPI;
    final query = 'the weeknd';
    
    // Search for songs
    print('🎵 Searching for songs: $query');
    final songsResult = await api.searchMusic(query, filter: 'songs');
    print('Found ${songsResult['songs']?.length ?? 0} songs');
    
    // Search for artists
    print('👤 Searching for artists: $query');
    final artistsResult = await api.searchMusic(query, filter: 'artists');
    print('Found ${artistsResult['artists']?.length ?? 0} artists');
    
    // Search for albums
    print('💿 Searching for albums: $query');
    final albumsResult = await api.searchMusic(query, filter: 'albums');
    print('Found ${albumsResult['albums']?.length ?? 0} albums');
  }
  
  /// Example 4: Get popular songs with custom limit
  static Future<void> exampleGetPopularSongs() async {
    final api = StartupPerformance.musicAPI;
    
    print('🔥 Getting top 10 popular songs...');
    final popularSongs = await api.getPopularSongs(limit: 10);
    
    print('Top ${popularSongs.length} popular songs:');
    for (int i = 0; i < popularSongs.length; i++) {
      final song = popularSongs[i];
      print('  ${i + 1}. ${song['title']} - ${song['artist']}');
    }
  }
  
  /// Example 5: Get artist information and their top songs
  static Future<void> exampleGetArtistInfo() async {
    final api = StartupPerformance.musicAPI;
    const artistId = 'UC0C-w0YjGpqDWGG5mJBdSgQ'; // Example artist ID
    
    print('👤 Getting artist information...');
    final artistInfo = await api.getArtist(artistId);
    
    if (artistInfo['name'] != null) {
      print('Artist: ${artistInfo['name']}');
      print('Subscribers: ${artistInfo['subscribers'] ?? 'Unknown'}');
      
      if (artistInfo['topSongs'] != null) {
        final topSongs = artistInfo['topSongs'] as List<Map<String, dynamic>>;
        print('Top songs:');
        for (var song in topSongs.take(5)) {
          print('  - ${song['title']}');
        }
      }
    }
  }
  
  /// Example 6: Error handling and fallbacks
  static Future<void> exampleErrorHandling() async {
    final api = StartupPerformance.musicAPI;
    
    try {
      // Test with invalid video ID
      print('🧪 Testing error handling with invalid video ID...');
      final result = await api.getSongDetails('invalid_video_id');
      
      if (result['error'] != null) {
        print('✅ Error handled correctly: ${result['error']}');
      } else {
        print('❌ Expected error but got result');
      }
    } catch (e) {
      print('🚨 Exception caught: $e');
    }
  }
  
  /// Example 7: Complete workflow - Search, get details, and prepare for playback
  static Future<void> exampleCompleteWorkflow() async {
    final api = StartupPerformance.musicAPI;
    
    print('🎯 Complete workflow example:');
    print('1️⃣ Searching for "imagine dragons thunder"...');
    
    final searchResults = await api.searchMusic('imagine dragons thunder', filter: 'songs');
    
    if (searchResults['songs'] != null && searchResults['songs'].isNotEmpty) {
      final firstSong = searchResults['songs'][0] as Map<String, dynamic>;
      final videoId = firstSong['videoId'];
      
      print('2️⃣ Found song: ${firstSong['title']} by ${firstSong['artist']}');
      print('3️⃣ Getting streaming details for video: $videoId');
      
      final songDetails = await api.getSongDetails(videoId);
      
      if (songDetails['streamingUrls'] != null) {
        final streamingUrls = songDetails['streamingUrls'] as List<Map<String, dynamic>>;
        
        print('4️⃣ Ready for playback!');
        print('   Title: ${songDetails['title']}');
        print('   Artist: ${songDetails['artist']}');
        print('   Duration: ${songDetails['duration']} seconds');
        print('   Available qualities: ${streamingUrls.length}');
        print('   Best URL: ${streamingUrls.first['url'].substring(0, 50)}...');
      }
    } else {
      print('❌ No songs found');
    }
  }
  
  /// Run all examples
  static Future<void> runAllExamples() async {
    print('🚀 Running YouTube Music Complete API Examples...\n');
    
    await exampleSearchByArtist();
    print('\n' + '='*50 + '\n');
    
    await exampleGetStreamingUrl();
    print('\n' + '='*50 + '\n');
    
    await exampleSearchWithFilters();
    print('\n' + '='*50 + '\n');
    
    await exampleGetPopularSongs();
    print('\n' + '='*50 + '\n');
    
    await exampleGetArtistInfo();
    print('\n' + '='*50 + '\n');
    
    await exampleErrorHandling();
    print('\n' + '='*50 + '\n');
    
    await exampleCompleteWorkflow();
    print('\n🎉 All examples completed!');
  }
}
