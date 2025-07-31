import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/harmony_music_service.dart';
import '../data/music_models.dart';
import 'package:just_audio/just_audio.dart';
import 'harmony_instant_test_page.dart';

class HarmonyMusicTestPage extends StatefulWidget {
  const HarmonyMusicTestPage({super.key});

  @override
  State<HarmonyMusicTestPage> createState() => _HarmonyMusicTestPageState();
}

class _HarmonyMusicTestPageState extends State<HarmonyMusicTestPage> {
  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  @override
  void dispose() {
    _searchController.dispose();
    _audioPlayer.dispose();
    
    // Stop playback and clear when disposing
    final harmonyService = context.read<HarmonyMusicService>();
    harmonyService.stopPlayback();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎵 Harmony Music Test'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: Consumer<HarmonyMusicService>(
          builder: (context, harmonyService, child) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Service Status
                  _buildServiceStatus(harmonyService),
                  const SizedBox(height: 20),
                  
                  // Search Section
                  _buildSearchSection(harmonyService),
                  const SizedBox(height: 20),
                  
                  // Results Section
                  Expanded(
                    child: _buildResultsSection(harmonyService),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildServiceStatus(HarmonyMusicService service) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              service.isInitialized ? Icons.check_circle : Icons.pending,
              color: service.isInitialized ? Colors.green : Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.isInitialized 
                        ? '✅ Harmony System Ready' 
                        : '⏳ Initializing...',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (service.error != null)
                    Text(
                      'Error: ${service.error}',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  if (service.currentTrack != null)
                    Text(
                      'Playing: ${service.currentTrack!.title}',
                      style: const TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                ],
              ),
            ),
            if (service.isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection(HarmonyMusicService service) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for music (Vietnamese optimized)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: (query) => _performSearch(service, query),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: service.isLoading 
                        ? null 
                        : () => _performSearch(service, _searchController.text),
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: service.isLoading 
                        ? null 
                        : () => _loadTrending(service),
                    icon: const Icon(Icons.trending_up),
                    label: const Text('Trending'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Popular Vietnamese suggestions
            Wrap(
              spacing: 8,
              children: [
                'Sơn Tùng MTP',
                'BLACKPINK',
                'Erik',
                'Hòa Minzy',
                'Jack',
              ].map((query) => ActionChip(
                label: Text(query),
                onPressed: () {
                  _searchController.text = query;
                  _performSearch(service, query);
                },
                backgroundColor: Colors.blue.shade100,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection(HarmonyMusicService service) {
    final results = service.searchResults.isNotEmpty 
        ? service.searchResults 
        : service.trendingTracks;

    if (results.isEmpty && !service.isLoading) {
      return const Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.music_note, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No results yet\nTry searching or load trending music',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  service.searchResults.isNotEmpty 
                      ? Icons.search_rounded 
                      : Icons.trending_up,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  service.searchResults.isNotEmpty 
                      ? 'Search Results (${results.length})' 
                      : 'Trending Music (${results.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final track = results[index];
                return _buildTrackTile(service, track);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackTile(HarmonyMusicService service, MusicTrack track) {
    final isCurrentTrack = service.currentTrack?.id == track.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isCurrentTrack ? 8 : 2,
      color: isCurrentTrack ? Colors.blue.shade50 : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade200,
          ),
          child: track.thumbnail?.isNotEmpty == true
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    track.thumbnail!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.music_note),
                  ),
                )
              : const Icon(Icons.music_note),
        ),
        title: Text(
          track.title,
          style: TextStyle(
            fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.normal,
            color: isCurrentTrack ? Colors.blue.shade700 : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              track.artist ?? 'Unknown Artist',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (track.duration != null)
              Text(
                _formatDuration(track.duration!),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentTrack)
              Icon(
                Icons.play_circle_filled,
                color: Colors.blue.shade600,
                size: 24,
              ),
            IconButton(
              icon: Icon(
                isCurrentTrack ? Icons.pause : Icons.play_arrow,
                color: Colors.blue.shade600,
              ),
              onPressed: () => _playTrack(service, track),
            ),
          ],
        ),
        onTap: () => _playTrack(service, track),
      ),
    );
  }

  void _performSearch(HarmonyMusicService service, String query) async {
    if (query.trim().isEmpty) return;

    print('🔍 Performing search: $query');
    await service.searchMusic(query.trim());
  }

  void _loadTrending(HarmonyMusicService service) async {
    print('📈 Loading trending music');
    await service.getTrendingMusic();
  }

  void _playTrack(HarmonyMusicService service, MusicTrack track) async {
    try {
      print('▶️ Playing track: ${track.title}');
      
      final streamUrl = await service.playTrack(track);
      
      if (streamUrl != null) {
        await _audioPlayer.setUrl(streamUrl);
        await _audioPlayer.play();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎵 Playing: ${track.title}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Failed to get stream URL');
      }
    } catch (e) {
      print('❌ Playback error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to play: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}

// Add floating action button for instant test
Widget build(BuildContext context) {
  return Scaffold(
    // ... existing scaffold content ...
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HarmonyInstantTestPage(),
          ),
        );
      },
      icon: const Icon(Icons.flash_on),
      label: const Text('⚡ Instant Test'),
      backgroundColor: Colors.orange,
    ),
  );
}
