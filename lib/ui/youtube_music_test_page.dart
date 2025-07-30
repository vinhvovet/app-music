import 'package:flutter/material.dart';
import '../startup_performance.dart';

class YouTubeMusicTestPage extends StatefulWidget {
  const YouTubeMusicTestPage({super.key});

  @override
  State<YouTubeMusicTestPage> createState() => _YouTubeMusicTestPageState();
}

class _YouTubeMusicTestPageState extends State<YouTubeMusicTestPage> {
  String _output = '';
  bool _isLoading = false;

  void _addOutput(String text) {
    setState(() {
      _output += '\n${DateTime.now().toString().substring(11, 19)}: $text';
    });
  }

  void _clearOutput() {
    setState(() {
      _output = '';
    });
  }

  Future<void> _testSearch() async {
    setState(() => _isLoading = true);
    _addOutput('🔍 Testing search for "billie eilish"...');
    
    try {
      final api = StartupPerformance.musicAPI;
      final results = await api.searchMusic('billie eilish', filter: 'songs');
      
      _addOutput('✅ Search completed!');
      _addOutput('Found ${results['songs']?.length ?? 0} songs');
      
      if (results['songs'] != null) {
        final songs = results['songs'] as List<Map<String, dynamic>>;
        for (int i = 0; i < (songs.length > 3 ? 3 : songs.length); i++) {
          final song = songs[i];
          _addOutput('   ${i + 1}. ${song['title']} - ${song['artist']}');
        }
      }
      
      if (results['error'] != null) {
        _addOutput('❌ Error: ${results['error']}');
      }
    } catch (e) {
      _addOutput('❌ Exception: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testSongDetails() async {
    setState(() => _isLoading = true);
    
    // Test with a popular song - Billie Eilish "Bad Guy"
    const videoId = 'DyDfgMOUjCI';
    _addOutput('🎵 Testing song details for videoId: $videoId');
    
    try {
      final api = StartupPerformance.musicAPI;
      final songDetails = await api.getSongDetails(videoId);
      
      _addOutput('✅ Song details retrieved!');
      _addOutput('Title: ${songDetails['title']}');
      _addOutput('Artist: ${songDetails['artist']}');
      _addOutput('Duration: ${songDetails['duration']} seconds');
      
      if (songDetails['streamingUrls'] != null) {
        final streamingUrls = songDetails['streamingUrls'] as List<Map<String, dynamic>>;
        _addOutput('📺 Found ${streamingUrls.length} streaming URLs:');
        
        for (int i = 0; i < (streamingUrls.length > 2 ? 2 : streamingUrls.length); i++) {
          final stream = streamingUrls[i];
          _addOutput('   ${i + 1}. ${stream['quality']} - ${stream['container']}');
        }
      }
      
      if (songDetails['error'] != null) {
        _addOutput('❌ Error: ${songDetails['error']}');
      }
    } catch (e) {
      _addOutput('❌ Exception: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testCharts() async {
    setState(() => _isLoading = true);
    _addOutput('📊 Testing charts...');
    
    try {
      final api = StartupPerformance.musicAPI;
      final charts = await api.getCharts();
      
      _addOutput('✅ Charts request completed!');
      _addOutput('Response: ${charts.toString()}');
      
      if (charts['error'] != null) {
        _addOutput('❌ Error: ${charts['error']}');
      }
    } catch (e) {
      _addOutput('❌ Exception: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testPopularSongs() async {
    setState(() => _isLoading = true);
    _addOutput('🔥 Testing popular songs...');
    
    try {
      final api = StartupPerformance.musicAPI;
      final popularSongs = await api.getPopularSongs(limit: 5);
      
      _addOutput('✅ Popular songs retrieved!');
      _addOutput('Found ${popularSongs.length} popular songs:');
      
      for (int i = 0; i < popularSongs.length; i++) {
        final song = popularSongs[i];
        _addOutput('   ${i + 1}. ${song['title']} - ${song['artist']}');
      }
    } catch (e) {
      _addOutput('❌ Exception: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Music Complete API Test'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Control buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('Test Search'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testSongDetails,
                  icon: const Icon(Icons.music_note),
                  label: const Text('Test Song Details'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testCharts,
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('Test Charts'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testPopularSongs,
                  icon: const Icon(Icons.whatshot),
                  label: const Text('Test Popular'),
                ),
                ElevatedButton.icon(
                  onPressed: _clearOutput,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Loading indicator
          if (_isLoading)
            const LinearProgressIndicator(),
          
          // Output area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _output.isEmpty 
                    ? 'Tap any button above to test the YouTube Music Complete API...\n\nAPI Features:\n• Search Music\n• Get Song Details + Streaming URLs\n• Get Charts\n• Get Popular Songs'
                    : _output,
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
