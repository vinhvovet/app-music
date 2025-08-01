import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/model/song.dart';
import '../../data/music_models.dart';
import '../../startup_performance.dart';
import '../now_playing/playing.dart';

class LyricsSearchPage extends StatefulWidget {
  final List<Song> songs;
  
  const LyricsSearchPage({super.key, required this.songs});

  @override
  State<LyricsSearchPage> createState() => _LyricsSearchPageState();
}

class _LyricsSearchPageState extends State<LyricsSearchPage> {
  final TextEditingController _lyricsController = TextEditingController();
  List<Song> _searchResults = [];
  bool _isSearching = false;

  // Converter function to convert Song to MusicTrack
  MusicTrack _convertSongToMusicTrack(Song song) {
    try {
      return MusicTrack(
        id: song.id,
        videoId: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album,
        thumbnail: song.image,
        url: song.source,
        duration: Duration(seconds: song.duration),
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
      return MusicTrack(
        id: 'error',
        videoId: 'error',
        title: 'Error loading song',
        artist: 'Unknown Artist',
        isFavorite: false,
      );
    }
  }

  void _searchInSongs(String lyrics) {
    if (lyrics.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Simulate search delay for better UX
    Future.delayed(const Duration(milliseconds: 300), () {
      final results = widget.songs.where((song) {
        // Tìm kiếm trong lyrics nếu có
        if (song.lyrics != null && song.lyrics!.isNotEmpty) {
          return song.lyrics!.toLowerCase().contains(lyrics.toLowerCase());
        }
        // Tìm kiếm trong title và artist như fallback
        return song.title.toLowerCase().contains(lyrics.toLowerCase()) ||
               song.artist.toLowerCase().contains(lyrics.toLowerCase());
      }).toList();

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search by Lyrics'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Phần nhập lời bài hát
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lyrics,
                        size: 24,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Enter song lyrics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _lyricsController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Example: "I love you like the flowing rivers..."',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF3EA513), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(15),
                    ),
                    onChanged: _searchInSongs,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Type song lyrics to search',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_lyricsController.text.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            _lyricsController.clear();
                            _searchInSongs('');
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              color: Color(0xFF3EA513),
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Kết quả tìm kiếm
            Expanded(
              child: _isSearching
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3EA513)),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Searching...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _searchResults.isEmpty && _lyricsController.text.trim().isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.music_off,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No matching songs found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try entering different lyrics',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : _searchResults.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Enter song lyrics to search',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'The app will search in the lyrics database',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.queue_music,
                                        size: 20,
                                        color: Colors.grey[700],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Found ${_searchResults.length} songs',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _searchResults.length,
                                    itemBuilder: (context, index) {
                                      final song = _searchResults[index];
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.all(12),
                                          leading: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              song.image,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  width: 60,
                                                  height: 60,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[300],
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Icon(
                                                    Icons.music_note,
                                                    color: Colors.grey,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          title: Text(
                                            song.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 4),
                                              Text(
                                                song.artist,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (song.lyrics != null && song.lyrics!.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Text(
                                                    _getMatchingLyrics(song.lyrics!, _lyricsController.text),
                                                    style: TextStyle(
                                                      color: Colors.blue[700],
                                                      fontSize: 12,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3EA513).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: const Icon(
                                              Icons.play_arrow,
                                              color: Color(0xFF3EA513),
                                              size: 24,
                                            ),
                                          ),
                                          onTap: () async {
                                            try {
                                              // Convert Song to MusicTrack for the updated playing screen
                                              final currentTrack = _convertSongToMusicTrack(song);
                                              final playlistTracks = widget.songs.map(_convertSongToMusicTrack).toList();
                                              
                                              // Get stream URL from API
                                              final api = StartupPerformance.musicAPI;
                                              final songDetails = await api.getSongDetails(currentTrack.videoId);
                                              
                                              String? streamUrl;
                                              if (songDetails['streamingUrls'] != null) {
                                                final streamingUrls = songDetails['streamingUrls'] as List<Map<String, dynamic>>;
                                                if (streamingUrls.isNotEmpty) {
                                                  streamUrl = streamingUrls.first['url'] as String;
                                                }
                                              }
                                              
                                              // Fallback to original URL if API fails
                                              streamUrl ??= currentTrack.url ?? currentTrack.extras?['source'] ?? '';
                                              
                                              if (streamUrl != null && streamUrl.isNotEmpty) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => NowPlaying(
                                                      playingSong: currentTrack,
                                                      songs: playlistTracks,
                                                      streamUrl: streamUrl!,
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              print('Error navigating to NowPlaying: $e');
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
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMatchingLyrics(String lyrics, String searchTerm) {
    if (searchTerm.trim().isEmpty) return '';
    
    final lines = lyrics.split('\n');
    for (final line in lines) {
      if (line.toLowerCase().contains(searchTerm.toLowerCase())) {
        return '..."${line.trim()}"...';
      }
    }
    return '';
  }

  @override
  void dispose() {
    _lyricsController.dispose();
    super.dispose();
  }
}
