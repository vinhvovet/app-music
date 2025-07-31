import 'package:flutter/material.dart';
import 'package:music_app/state management/provider.dart';
import 'package:music_app/ui/now_playing/playing.dart'; // import màn hình NowPlaying
import 'package:provider/provider.dart';
import '../../data/music_models.dart';
import '../../data/model/song.dart';
import '../../startup_performance.dart';

class ListFavorite extends StatelessWidget {
  const ListFavorite({super.key});

  // Converter function to convert Song to MusicTrack
  MusicTrack _convertSongToMusicTrack(Song song) {
    try {
      return MusicTrack(
        id: song.id,
        videoId: song.id,
        title: song.title.isNotEmpty ? song.title : 'Untitled Song',
        artist: song.artist.isNotEmpty ? song.artist : null,
        album: song.album.isNotEmpty ? song.album : null,
        thumbnail: song.image,
        url: song.source,
        duration: null, // No duration needed for favorites
        isFavorite: song.isFavorite,
        extras: {
          'originalSong': song,
          'source': song.source,
          'lyrics': song.lyrics,
          'lyricsData': song.lyricsData,
        },
      );
    } catch (e) {
      print('Error converting Song to MusicTrack: $e');
      // Return a fallback MusicTrack if conversion fails
      return MusicTrack(
        id: 'error',
        videoId: 'error',
        title: 'Error loading song',
        artist: 'Unknown Artist',
        isFavorite: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderStateManagement>();
    final favSongs = provider.favoriteSongs;

    return Scaffold(
      appBar: AppBar(title: const Center(child: Text("Favorite Songs"))),
      body: SafeArea(
        child: favSongs.isEmpty
            ? const Center(
                child: Text(
                  "No favorite songs",
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: favSongs.length,
                itemBuilder: (context, index) {
                  final song = favSongs[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: song.image.isNotEmpty
                            ? Image.network(
                                song.image,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey.shade300,
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.grey,
                                      size: 24,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey.shade300,
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.grey,
                                  size: 24,
                                ),
                              ),
                      ),
                      title: Text(
                        song.title,
                        style: const TextStyle(color: Colors.black, fontSize: 16),
                      ),
                      subtitle: Text(
                        song.artist,
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                      ),
                      trailing: const Icon(
                        Icons.play_arrow,
                        color: Colors.grey,
                      ),
                      onTap: () async {
                        try {
                          print('[ListFavorite] Playing song: ${song.title} by ${song.artist}');
                          
                          // Convert Song to MusicTrack for the updated playing screen
                          final currentTrack = _convertSongToMusicTrack(song);
                          final playlistTracks = favSongs.map((s) => _convertSongToMusicTrack(s)).toList();
                          
                          print('[ListFavorite] Converted ${playlistTracks.length} tracks');
                          print('[ListFavorite] Current track ID: ${currentTrack.videoId}');
                          
                          // Get stream URL for the favorite song
                          final api = StartupPerformance.musicAPI;
                          print('[ListFavorite] Getting song details for videoId: ${currentTrack.videoId}');
                          final songDetails = await api.getSongDetails(currentTrack.videoId);
                          
                          String? streamUrl;
                          if (songDetails['streamingUrls'] != null) {
                            final streamingUrlsRaw = songDetails['streamingUrls'] as List<dynamic>;
                            final streamingUrls = streamingUrlsRaw.cast<Map<String, dynamic>>();
                            if (streamingUrls.isNotEmpty) {
                              streamUrl = streamingUrls.first['url'] as String;
                              print('[ListFavorite] Got stream URL from API');
                            }
                          }
                          
                          if (streamUrl != null) {
                            print('[ListFavorite] Navigating to NowPlaying with API stream URL');
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => NowPlaying(
                                  playingSong: currentTrack,
                                  songs: playlistTracks,
                                  streamUrl: streamUrl!,
                                ),
                              ),
                            );
                          } else {
                            // Fallback to original URL if API fails
                            final fallbackUrl = currentTrack.url ?? currentTrack.extras?['source'] ?? song.source;
                            print('[ListFavorite] Using fallback URL: $fallbackUrl');
                            
                            if (fallbackUrl.isNotEmpty) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => NowPlaying(
                                    playingSong: currentTrack,
                                    songs: playlistTracks,
                                    streamUrl: fallbackUrl,
                                  ),
                                ),
                              );
                            } else {
                              throw Exception('No valid stream URL found');
                            }
                          }
                        } catch (e) {
                          print('[ListFavorite] Error navigating to NowPlaying: $e');
                          // Show error dialog or handle gracefully
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error playing song: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
