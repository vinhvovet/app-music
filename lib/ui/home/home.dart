import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:music_app/ui/home/viewmodel.dart';
import 'package:music_app/ui/settings/settings.dart';
import 'package:music_app/ui/account/user.dart';
import 'package:music_app/ui/now_playing/playing.dart';
import '../../data/music_models.dart';
import '../../data/model/song.dart';
import '../../state management/provider.dart';

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MusicHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MusicHomePage extends StatefulWidget {
  const MusicHomePage({super.key});

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  final List<Widget> _tabs = [
    const HomeTab(),
    const ListFavorite(),
    const AccountTab(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        heroTag: "main_nav",
        transitionBetweenRoutes: false,
        middle: const Text('Music Player'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.lab_flask),
          onPressed: () {
            Navigator.pushNamed(context, '/test-api');
          },
        ),
      ),
      child: CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          backgroundColor: CupertinoColors.systemBackground,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.heart),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person),
              label: 'Account',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.settings),
              label: 'Settings',
            ),
          ],
        ),
        tabBuilder: (context, index) {
          return _tabs[index];
        },
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  MusicAppViewModel? _musicAppViewModel;
  List<MusicTrack> songs = [];
  bool isLoading = false;
  bool _isPlayingMusic = false;
  final TextEditingController _searchController = TextEditingController();

  @override  
  void initState() {
    super.initState();
    
    // Get viewModel from Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _musicAppViewModel = Provider.of<MusicAppViewModel>(context, listen: false);
      
      // Listen to songs stream
      _musicAppViewModel!.songStream.stream.listen((event) {
        print('HomeTab: Received ${event.length} songs'); // Debug
        if (mounted) {
          setState(() {
            songs = event;
          });
        }
      });
      
      // Listen to loading stream
      _musicAppViewModel!.loadingStream.stream.listen((loading) {
        print('HomeTab: Loading state: $loading'); // Debug
        if (mounted) {
          setState(() {
            isLoading = loading;
          });
        }
      });
      
      // Load songs after setting up listeners
      print('HomeTab: About to load songs...');
      _musicAppViewModel!.loadSongs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _musicAppViewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        heroTag: "home_tab",
        transitionBetweenRoutes: false,
        middle: const Text('Music Library'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Search TextField
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CupertinoTextField(
                controller: _searchController,
                placeholder: 'Search songs, artists...',
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(CupertinoIcons.search, color: CupertinoColors.systemGrey),
                ),
                suffix: _searchController.text.isNotEmpty
                    ? CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 0,
                        child: const Icon(CupertinoIcons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          _musicAppViewModel?.searchByKeyword('');
                          setState(() {});
                        },
                      )
                    : null,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                onChanged: (value) {
                  _musicAppViewModel?.searchByKeyword(value);
                  if (mounted) {
                    setState(() {}); // Update suffix visibility
                  }
                },
              ),
            ),
            // Songs List
            Expanded(
              child: songs.isEmpty && isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoActivityIndicator(),
                    SizedBox(height: 16),
                    Text('Loading music from YouTube Music...'),
                  ],
                ),
              )
            : songs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.music_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No songs found'),
                        SizedBox(height: 8),
                        Text('Try searching for different songs', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final track = songs[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        elevation: 2,
                        child: ListTile(
                          leading: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade200,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: track.thumbnail != null && track.thumbnail!.isNotEmpty
                                  ? Image.network(
                                      track.thumbnail!,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(
                                        CupertinoIcons.music_note_2,
                                        size: 32,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : const Icon(
                                      CupertinoIcons.music_note_2,
                                      size: 32,
                                      color: Colors.grey,
                                    ),
                            ),
                          ),
                          title: Text(
                            track.title.isNotEmpty ? track.title : 'Untitled Song',
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
                              Text(
                                track.artist?.isNotEmpty == true 
                                    ? track.artist! 
                                    : 'Various Artists',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (track.duration != null)
                                Text(
                                  _formatDuration(track.duration!),
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Consumer<ProviderStateManagement>(
                                  builder: (context, provider, child) {
                                    return FutureBuilder<bool>(
                                      future: provider.isFavoriteMusicTrack(track),
                                      builder: (context, snapshot) {
                                        final isFavorite = snapshot.data ?? (track.isFavorite ?? false);
                                        return Icon(
                                          isFavorite
                                              ? CupertinoIcons.heart_fill
                                              : CupertinoIcons.heart,
                                          color: isFavorite
                                              ? CupertinoColors.systemRed
                                              : Colors.grey,
                                          size: 20,
                                        );
                                      },
                                    );
                                  },
                                ),
                                onPressed: () async {
                                  final provider = Provider.of<ProviderStateManagement>(context, listen: false);
                                  await provider.toggleFavoriteMusicTrack(track);
                                },
                              ),
                              Icon(
                                CupertinoIcons.play_circle_fill,
                                color: Theme.of(context).primaryColor,
                                size: 28,
                              ),
                            ],
                          ),
                          onTap: () => _playMusic(track),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _playMusic(MusicTrack track) async {
    if (!mounted) return;

    // Prevent multiple calls
    if (_isPlayingMusic) return;
    _isPlayingMusic = true;

    try {
      // Get stream URL (removed loading dialog for better performance)
      final streamUrl = await _musicAppViewModel?.getStreamUrl(track.videoId);
      
      
      if (streamUrl != null) {
        // Navigate to now playing screen
        if (mounted) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => NowPlaying(
                playingSong: track,
                songs: songs,
                streamUrl: streamUrl,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text('❌ Cannot play: ${track.title}'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Error: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } finally {
      _isPlayingMusic = false;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class ListFavorite extends StatelessWidget {
  const ListFavorite({super.key});

  // Converter function to convert Song to MusicTrack
  MusicTrack _convertSongToMusicTrack(Song song) {
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
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        heroTag: "favorites_tab",
        transitionBetweenRoutes: false,
        middle: Text('Favorite Songs'),
      ),
      child: SafeArea(
        child: Consumer<ProviderStateManagement>(
          builder: (context, provider, child) {
            final favSongs = provider.favoriteSongs;
            
            // Debug log để kiểm tra
            print('[ListFavorite] DEBUG: Number of favorite songs: ${favSongs.length}');
            if (favSongs.isNotEmpty) {
              print('[ListFavorite] DEBUG: First favorite song: ${favSongs.first.title}');
            }
            
            if (provider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoActivityIndicator(),
                    SizedBox(height: 16),
                    Text('Loading favorites...'),
                  ],
                ),
              );
            }
            
            if (favSongs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.heart, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No favorite songs yet', style: TextStyle(fontSize: 18)),
                    SizedBox(height: 8),
                    Text('Add songs to favorites from the Home tab', 
                         style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: favSongs.length,
              itemBuilder: (context, index) {
                final song = favSongs[index];
                final track = _convertSongToMusicTrack(song);
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  elevation: 2,
                  child: ListTile(
                    leading: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade200,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: track.thumbnail != null && track.thumbnail!.isNotEmpty
                            ? Image.network(
                                track.thumbnail!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  CupertinoIcons.music_note_2,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                              )
                            : const Icon(
                                CupertinoIcons.music_note_2,
                                size: 32,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                    title: Text(
                      track.title.isNotEmpty ? track.title : 'Untitled Song',
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
                        Text(
                          track.artist?.isNotEmpty == true 
                              ? track.artist! 
                              : 'Various Artists',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (track.duration != null)
                          Text(
                            _formatDuration(track.duration!),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            CupertinoIcons.heart_fill,
                            color: CupertinoColors.systemRed,
                            size: 20,
                          ),
                          onPressed: () async {
                            await provider.toggleFavorite(song);
                          },
                        ),
                        Icon(
                          CupertinoIcons.play_circle_fill,
                          color: Theme.of(context).primaryColor,
                          size: 28,
                        ),
                      ],
                    ),
                    onTap: () => _playMusic(context, track, favSongs.map((s) => _convertSongToMusicTrack(s)).toList()),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _playMusic(BuildContext context, MusicTrack track, List<MusicTrack> allTracks) async {
    try {
      // Get the MusicAppViewModel to get stream URL
      final viewModel = Provider.of<MusicAppViewModel>(context, listen: false);
      final streamUrl = await viewModel.getStreamUrl(track.videoId);
      
      if (streamUrl != null) {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => NowPlaying(
              playingSong: track,
              songs: allTracks,
              streamUrl: streamUrl,
            ),
          ),
        );
      } else {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('❌ Cannot play: ${track.title}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('Error: $e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';  
  }
}
