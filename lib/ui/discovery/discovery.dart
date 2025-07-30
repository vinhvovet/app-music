import 'package:flutter/material.dart';
import 'package:music_app/state management/provider.dart';
import 'package:music_app/ui/now_playing/playing.dart'; // import màn hình NowPlaying
import 'package:provider/provider.dart';
import '../../data/music_models.dart';
import '../../startup_performance.dart';

class ListFavorite extends StatelessWidget {
  const ListFavorite({super.key});

  // Converter function to convert Song to MusicTrack
  MusicTrack _convertSongToMusicTrack(dynamic song) {
    try {
      return MusicTrack(
        id: song.id ?? '',
        videoId: song.id ?? '',
        title: song.title?.isNotEmpty == true ? song.title! : 'Untitled Song',
        artist: song.artist?.isNotEmpty == true ? song.artist : null,
        album: song.album?.isNotEmpty == true ? song.album : null,
        thumbnail: song.image ?? '',
        url: song.source ?? '',
        duration: song.duration != null ? Duration(seconds: song.duration is int ? song.duration : 0) : null,
        isFavorite: song.isFavorite ?? false,
        extras: {
          'originalSong': song,
          'source': song.source ?? '',
          'lyrics': song.lyrics, // Keep original lyrics (may be null)
          'lyricsData': song.lyricsData, // Keep original lyricsData (may be null)
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
                          // Convert Song to MusicTrack for the updated playing screen
                          final currentTrack = _convertSongToMusicTrack(song);
                          final playlistTracks = favSongs.map(_convertSongToMusicTrack).toList();
                          
                          // Get stream URL for the favorite song
                          final api = StartupPerformance.musicAPI;
                          final songDetails = await api.getSongDetails(currentTrack.videoId);
                          
                          String? streamUrl;
                          if (songDetails['streamingUrls'] != null) {
                            final streamingUrls = songDetails['streamingUrls'] as List<Map<String, dynamic>>;
                            if (streamingUrls.isNotEmpty) {
                              streamUrl = streamingUrls.first['url'] as String;
                            }
                          }
                          
                          if (streamUrl != null) {
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
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => NowPlaying(
                                  playingSong: currentTrack,
                                  songs: playlistTracks,
                                  streamUrl: currentTrack.url ?? currentTrack.extras?['source'] ?? '',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          print('Error navigating to NowPlaying: $e');
                          // Show error dialog or handle gracefully
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error playing song: $e'),
                              backgroundColor: Colors.red,
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
