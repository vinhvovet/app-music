import 'dart:math';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/state management/provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/model/song.dart';
import 'audio_player_manager.dart';

class NowPlaying extends StatelessWidget {
  const NowPlaying({super.key, required this.playingSong, required this.songs});

  final Song playingSong;
  final List<Song> songs;

  @override
  Widget build(BuildContext context) {
    return NowPlayingPage(songs: songs, playingSong: playingSong);
  }
}

class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({
    super.key,
    required this.songs,
    required this.playingSong,
  });

  final Song playingSong;
  final List<Song> songs;

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _imageAnimController;
  late AudioPlayerManager _audioPlayerManager;
  late int _selectedItemIndex;
  late Song _song;
  double _currentAnimationPosition = 0.0;
  bool _isShuffle = false;
  late LoopMode _loopMode;

  late PageController _pageController;
  int _currentPage = 0;
  double _lyricsFontSize = 16.0; // Default lyrics font size
  String _searchQuery = ''; // For lyrics search

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _song = widget.playingSong;
    _imageAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    );
    _playRotationAnim(); // Khởi động animation xoay ảnh

    _audioPlayerManager = AudioPlayerManager();
    if (_audioPlayerManager.currentUrl != _song.source) {
      _audioPlayerManager.updateSongUrl(_song.source);
      _audioPlayerManager.prepare(isNewSong: true);
    } else {
      _audioPlayerManager.prepare(isNewSong: false);
    }
    _selectedItemIndex = widget.songs.indexOf(widget.playingSong);
    _loopMode = LoopMode.off;
    _audioPlayerManager.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _onSongCompleted();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const delta = 64;
    final radius = (screenWidth - delta) / 2;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Now Playing'),
        // trailing: IconButton(
        //   onPressed: () {},
        //   icon: const Icon(Icons.more_horiz),
        // ),
      ),
      child: Consumer<ProviderStateManagement>(
        builder: (context, provider, child) => Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const SizedBox(height: 100),
              Text(_song.album),
              // Indicator 2 hình chữ nhật
              SizedBox(
                height: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(2, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 24,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.deepPurple
                            : Colors.deepPurple.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }),
                ),
              ),
              // PageView giữa 2 trang
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    // Trang 1: UI phát nhạc
                    SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const SizedBox(height: 8),
                          RotationTransition(
                            turns: Tween(begin: 0.0, end: 1.0)
                                .animate(_imageAnimController),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(radius),
                              child: FadeInImage.assetNetwork(
                                placeholder: 'assets/itunes_256.png',
                                image: _song.image,
                                width: screenWidth - delta,
                                height: screenWidth - delta,
                                imageErrorBuilder:
                                    (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/itunes_256.png',
                                    width: screenWidth - delta,
                                    height: screenWidth - delta,
                                  );
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                IconButton(
                                  onPressed: _shareSong,
                                  icon: const Icon(Icons.share_outlined),
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                ),
                                Column(
                                  children: [
                                    Text(_song.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                    Text(_song.artist,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                  ],
                                ),
                                FutureBuilder<bool>(
                                  future: provider.isFavorite(_song),
                                  builder: (context, snapshot) {
                                    final isFav = snapshot.data ?? false;
                                    return IconButton(
                                      onPressed: () {
                                        provider.toggleFavorite(_song);
                                      },
                                      icon: Icon(
                                        isFav
                                            ? Icons.favorite
                                            : Icons
                                                .favorite_border_outlined,
                                        color: isFav ? Colors.red : null,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 32),
                            child: _progressBar(),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 8),
                            child: _mediaButtons(),
                          ),
                        ],
                      ),
                    ),
                    // Trang 2: Lời bài hát
                    _page2(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SingleChildScrollView _page2(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với tên bài hát và nghệ sĩ
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.withOpacity(0.1), Colors.transparent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lời bài hát',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _song.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _song.artist,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Lyrics content với styling được cải thiện
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_song.lyrics != null && _song.lyrics!.isNotEmpty) ...[
                    // Hiển thị lời bài hát thực tế
                    _buildLyricsContent(_song.lyrics!),
                  ] else ...[
                    // Hiển thị thông báo khi không có lời bài hát
                    _buildNoLyricsContent(context),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Footer với thông tin thêm
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.album, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Album: ${_song.album}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Icon(Icons.access_time, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${(_song.duration ~/ 60)}:${(_song.duration % 60).toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
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

  Widget _buildLyricsContent(String lyrics) {
    final lines = lyrics.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lyrics với line numbering và better formatting
        ...lines.asMap().entries.map((entry) {
          final index = entry.key;
          final line = entry.value.trim();
          
          if (line.isEmpty) {
            return const SizedBox(height: 12); // Space between verses
          }
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line number
                Container(
                  width: 30,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                // Lyrics line with search highlighting
                Expanded(
                  child: _buildHighlightedText(line, _searchQuery),
                ),
              ],
            ),
          );
        }).toList(),
        
        const SizedBox(height: 20),
        
        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.search,
              label: 'Tìm kiếm',
              onTap: () => _showSearchDialog(context, lyrics),
            ),
            _buildActionButton(
              icon: Icons.text_fields,
              label: 'Cỡ chữ',
              onTap: () => _showTextSizeDialog(context),
            ),
            _buildActionButton(
              icon: Icons.copy,
              label: 'Sao chép',
              onTap: () => _copyLyrics(lyrics),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoLyricsContent(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.music_note_outlined,
          size: 80,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          'Lời bài hát chưa có sẵn',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Chúng tôi đang cập nhật lời bài hát cho "${_song.title}"',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Implement lyrics request feature
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tính năng này sẽ sớm được cập nhật!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Yêu cầu thêm lời'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.deepPurple),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.deepPurple,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context, String lyrics) {
    final TextEditingController searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tìm kiếm trong lời bài hát'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Nhập từ khóa...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
              Navigator.pop(context);
            },
            child: const Text('Xóa'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          fontSize: _lyricsFontSize,
          height: 1.6,
          color: Colors.black87,
        ),
      );
    }

    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    
    int start = 0;
    int index = lowerText.indexOf(lowerQuery);
    
    while (index != -1) {
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: TextStyle(
            fontSize: _lyricsFontSize,
            height: 1.6,
            color: Colors.black87,
          ),
        ));
      }
      
      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          fontSize: _lyricsFontSize,
          height: 1.6,
          color: Colors.white,
          backgroundColor: Colors.deepPurple,
          fontWeight: FontWeight.bold,
        ),
      ));
      
      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }
    
    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: TextStyle(
          fontSize: _lyricsFontSize,
          height: 1.6,
          color: Colors.black87,
        ),
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }

  void _showTextSizeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cỡ chữ lời bài hát'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Nhỏ'),
              trailing: _lyricsFontSize == 14.0 
                ? const Icon(Icons.check, color: Colors.deepPurple) 
                : null,
              onTap: () {
                setState(() => _lyricsFontSize = 14.0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Vừa'),
              trailing: _lyricsFontSize == 16.0 
                ? const Icon(Icons.check, color: Colors.deepPurple) 
                : null,
              onTap: () {
                setState(() => _lyricsFontSize = 16.0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Lớn'),
              trailing: _lyricsFontSize == 18.0 
                ? const Icon(Icons.check, color: Colors.deepPurple) 
                : null,
              onTap: () {
                setState(() => _lyricsFontSize = 18.0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Rất lớn'),
              trailing: _lyricsFontSize == 20.0 
                ? const Icon(Icons.check, color: Colors.deepPurple) 
                : null,
              onTap: () {
                setState(() => _lyricsFontSize = 20.0);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _copyLyrics(String lyrics) {
    Clipboard.setData(ClipboardData(text: lyrics));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép lời bài hát!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _imageAnimController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _shareSong() {
    final songTitle = _song.title;
    final songArtist = _song.artist;
    final songUrl = _song.source;

    final shareContent =
        '🎵 bài hát "$songTitle" của $songArtist. Nghe ngay tại đây: $songUrl';
    Share.share(shareContent);
  }

  void _onSongCompleted() {
    if (_loopMode == LoopMode.one) {
      _audioPlayerManager.player.seek(Duration.zero);
      _audioPlayerManager.player.play();
      return;
    }
    if (_isShuffle) {
      _selectedItemIndex = Random().nextInt(widget.songs.length);
    } else if (_selectedItemIndex < widget.songs.length - 1) {
      ++_selectedItemIndex;
    } else if (_loopMode == LoopMode.all) {
      _selectedItemIndex = 0;
    } else {
      return;
    }
    final nextSong = widget.songs[_selectedItemIndex];
    setState(() => _song = nextSong);
    _audioPlayerManager.updateSongUrl(nextSong.source);
    _audioPlayerManager.prepare(isNewSong: true);
    _audioPlayerManager.player.play();
    _resetRotationAnim();
    _playRotationAnim();
  }

  void _resetRotationAnim() {
    _currentAnimationPosition = 0.0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _imageAnimController.value = _currentAnimationPosition;
      }
    });
  }

  Widget _mediaButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        MediaButtonControl(
            function: () => setState(() => _isShuffle = !_isShuffle),
            icon: Icons.shuffle,
            color: _isShuffle ? Colors.deepPurple : Colors.grey,
            size: 24),
        MediaButtonControl(
            function: _setPrevSong,
            icon: Icons.skip_previous,
            color: Colors.deepPurple,
            size: 36),
        _playButton(),
        MediaButtonControl(
            function: _setNextSong,
            icon: Icons.skip_next,
            color: Colors.deepPurple,
            size: 36),
        MediaButtonControl(
            function: _setupRepeatOption,
            icon: _repeatingIcon(),
            color: _loopMode == LoopMode.off ? Colors.grey : Colors.deepPurple,
            size: 24),
      ],
    );
  }

  StreamBuilder<DurationState> _progressBar() {
    return StreamBuilder<DurationState>(
      stream: _audioPlayerManager.durationState,
      builder: (context, snapshot) {
        final durationState = snapshot.data;
        final progress = durationState?.progress ?? Duration.zero;
        final buffered = durationState?.buffered ?? Duration.zero;
        final total = durationState?.total ?? Duration.zero;
        return ProgressBar(
          progress: progress,
          total: total,
          buffered: buffered,
          onSeek: _audioPlayerManager.player.seek,
          barHeight: 5.0,
          barCapShape: BarCapShape.round,
          baseBarColor: Colors.grey.withValues(alpha: 0.3),
          progressBarColor: Colors.deepPurple,
          bufferedBarColor: Colors.grey.withValues(alpha: 0.3),
          thumbColor: Colors.deepPurple, // không đổi nếu bạn không cần alpha
          thumbGlowColor: Colors.green.withValues(alpha: 0.3),
        );
      },
    );
  }

  StreamBuilder<PlayerState> _playButton() {
    return StreamBuilder(
      stream: _audioPlayerManager.playerStateStream,
      builder: (context, snapshot) {
        final playState = snapshot.data;
        final processingState = playState?.processingState;
        final playing = playState?.playing;
        if (processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering) {
          _pauseRotationAnim();
          return Container(
            margin: const EdgeInsets.all(8),
            width: 48,
            height: 48,
            child: const CircularProgressIndicator(),
          );
        } else if (playing != true) {
          return MediaButtonControl(
            function: () {
              _audioPlayerManager.player.play();
            },
            icon: Icons.play_arrow,
            color: null,
            size: 48,
          );
        } else if (processingState != ProcessingState.completed) {
          _playRotationAnim();
          return MediaButtonControl(
            function: () {
              _audioPlayerManager.player.pause();
              _pauseRotationAnim();
            },
            icon: Icons.pause,
            color: null,
            size: 48,
          );
        } else {
          if (processingState == ProcessingState.completed) {
            _stopRotationAnim();
            _resetRotationAnim();
          }
          return MediaButtonControl(
            function: () {
              _audioPlayerManager.player.seek(Duration.zero);
              _resetRotationAnim();
              _playRotationAnim();
            },
            icon: Icons.replay,
            color: null,
            size: 48,
          );
        }
      },
    );
  }

  void _setNextSong() {
    if (_isShuffle) {
      var random = Random();
      _selectedItemIndex = random.nextInt(widget.songs.length);
    } else if (_selectedItemIndex < widget.songs.length - 1) {
      ++_selectedItemIndex;
    } else if (_loopMode == LoopMode.all &&
        _selectedItemIndex == widget.songs.length - 1) {
      _selectedItemIndex = 0;
    }
    if (_selectedItemIndex >= widget.songs.length) {
      _selectedItemIndex = _selectedItemIndex % widget.songs.length;
    }
    final nextSong = widget.songs[_selectedItemIndex];
    _audioPlayerManager.updateSongUrl(nextSong.source);
    _audioPlayerManager.prepare(isNewSong: true); // 👈 thêm dòng này
    _audioPlayerManager.player.play(); // 👈 thêm dòng này
    _resetRotationAnim();
    setState(() {
      _song = nextSong;
    });
  }

  void _setPrevSong() {
    if (_isShuffle) {
      var random = Random();
      _selectedItemIndex = random.nextInt(widget.songs.length);
    } else if (_selectedItemIndex > 0) {
      --_selectedItemIndex;
    } else if (_loopMode == LoopMode.all && _selectedItemIndex == 0) {
      _selectedItemIndex = widget.songs.length - 1;
    }
    if (_selectedItemIndex < 0) {
      _selectedItemIndex = (-1 * _selectedItemIndex) % widget.songs.length;
    }
    final nextSong = widget.songs[_selectedItemIndex];
    _audioPlayerManager.updateSongUrl(nextSong.source);
    _audioPlayerManager.prepare(isNewSong: true); // 👈 thêm dòng này
    _audioPlayerManager.player.play(); // 👈 thêm dòng này
    _resetRotationAnim();
    setState(() {
      _song = nextSong;
    });
  }

  void _setupRepeatOption() {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.one;
    } else if (_loopMode == LoopMode.one) {
      _loopMode = LoopMode.all;
    } else {
      _loopMode = LoopMode.off;
    }
    setState(() {
      _audioPlayerManager.player.setLoopMode(_loopMode);
    });
  }

  IconData _repeatingIcon() {
    return switch (_loopMode) {
      LoopMode.one => Icons.repeat_one,
      LoopMode.all => Icons.repeat_on,
      _ => Icons.repeat,
    };
  }

  // void _playRotationAnim() {
  //   _imageAnimController.forward(from: _currentAnimationPosition);
  //   _imageAnimController.repeat();
  // }

  void _playRotationAnim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _imageAnimController.forward(from: _currentAnimationPosition);
      _imageAnimController.repeat();
    });
  }

  void _pauseRotationAnim() {
    _stopRotationAnim();
    _currentAnimationPosition = _imageAnimController.value;
  }

  void _stopRotationAnim() {
    _imageAnimController.stop();
  }

}

class MediaButtonControl extends StatefulWidget {
  const MediaButtonControl({
    super.key,
    required this.function,
    required this.icon,
    required this.color,
    required this.size,
  });

  final void Function()? function;
  final IconData icon;
  final double? size;
  final Color? color;

  @override
  State<StatefulWidget> createState() => _MediaButtonControlState();
}

class _MediaButtonControlState extends State<MediaButtonControl> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.function,
      icon: Icon(widget.icon),
      iconSize: widget.size,
      color: widget.color ?? Theme.of(context).colorScheme.primary,
    );
  }
}
