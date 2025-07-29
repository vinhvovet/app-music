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
  
  // Animation variables for CD rotation
  late Stream<Duration> _positionStream;
  bool _isAnimationRunning = false; // Track animation state

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _song = widget.playingSong;
    _imageAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    );
    // Không khởi động animation ngay lập tức, chỉ khi user ấn play

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

    // Listen to position changes for karaoke
    _positionStream = _audioPlayerManager.player.positionStream;
    _positionStream.listen((position) {
      // Position stream for progress bar updates if needed
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    
    // Responsive sizing based on orientation
    const delta = 64;
    final imageSize = isLandscape 
        ? (screenHeight * 0.6) // Use height as reference in landscape
        : (screenWidth - delta); // Use width as reference in portrait
    final radius = imageSize / 2;

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
          body: isLandscape 
              ? _buildLandscapeLayout(context, provider, imageSize, radius)
              : _buildPortraitLayout(context, provider, imageSize, radius),
        ),
      ),
    );
  }

  // Portrait layout - vertical orientation
  Widget _buildPortraitLayout(BuildContext context, ProviderStateManagement provider, double imageSize, double radius) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        const SizedBox(height: 100),
        Text(_song.album),
        // Indicator 2 hình chữ nhật
        SizedBox(
          height: 60,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    _buildCDImage(imageSize, radius),
                    _buildSongInfo(context, provider),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: _progressBar(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: _mediaButtons(),
                    ),
                  ],
                ),
              ),
              // Trang 2: Development page
              _page2(context),
            ],
          ),
        ),
      ],
    );
  }

  // Landscape layout - horizontal orientation
  Widget _buildLandscapeLayout(BuildContext context, ProviderStateManagement provider, double imageSize, double radius) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Left side - CD Image
            Expanded(
              flex: 3,
              child: Center(
                child: _buildCDImage(imageSize, radius),
              ),
            ),
            // Right side - Controls
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(2, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 20,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.deepPurple
                              : Colors.deepPurple.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  // Song info
                  _buildSongInfo(context, provider),
                  const SizedBox(height: 20),
                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _progressBar(),
                  ),
                  const SizedBox(height: 20),
                  // Media buttons
                  _mediaButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build CD image
  Widget _buildCDImage(double imageSize, double radius) {
    return RotationTransition(
      turns: Tween(begin: 0.0, end: 1.0).animate(_imageAnimController),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: FadeInImage.assetNetwork(
          placeholder: 'assets/itunes_256.png',
          image: _song.image,
          width: imageSize,
          height: imageSize,
          fit: BoxFit.cover,
          imageErrorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/itunes_256.png',
              width: imageSize,
              height: imageSize,
              fit: BoxFit.cover,
            );
          },
        ),
      ),
    );
  }

  // Helper method to build song info
  Widget _buildSongInfo(BuildContext context, ProviderStateManagement provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: _shareSong,
            icon: const Icon(Icons.share_outlined),
            color: Theme.of(context).colorScheme.primary,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _song.title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _song.artist,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
                  isFav ? Icons.favorite : Icons.favorite_border_outlined,
                  color: isFav ? Colors.red : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  SingleChildScrollView _page2(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              Icon(
                Icons.music_note_outlined,
                size: 120,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 20),
              Text(
                'Trang này đang được phát triển',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Các tính năng mới sẽ sớm được thêm vào',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
    _isAnimationRunning = false;
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
          if (_isAnimationRunning) {
            _pauseRotationAnim();
          }
          return Container(
            margin: const EdgeInsets.all(8),
            width: 48,
            height: 48,
            child: const CircularProgressIndicator(),
          );
        } else if (playing != true) {
          if (_isAnimationRunning) {
            _pauseRotationAnim();
          }
          return MediaButtonControl(
            function: () {
              _audioPlayerManager.player.play();
            },
            icon: Icons.play_arrow,
            color: null,
            size: 48,
          );
        } else if (processingState != ProcessingState.completed) {
          if (!_isAnimationRunning) {
            _playRotationAnim();
          }
          return MediaButtonControl(
            function: () {
              _audioPlayerManager.player.pause();
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
    if (!_isAnimationRunning) {
      _isAnimationRunning = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _imageAnimController.forward(from: _currentAnimationPosition);
          _imageAnimController.repeat();
        }
      });
    }
  }

  void _pauseRotationAnim() {
    if (_isAnimationRunning) {
      _stopRotationAnim();
      _currentAnimationPosition = _imageAnimController.value;
      _isAnimationRunning = false;
    }
  }

  void _stopRotationAnim() {
    _imageAnimController.stop();
    _isAnimationRunning = false;
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
