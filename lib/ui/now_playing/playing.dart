import 'dart:math';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

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
 

  @override
  void initState() {
    super.initState();
    _song = widget.playingSong;
    _imageAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    );
    _audioPlayerManager = AudioPlayerManager();
    if (_audioPlayerManager.songUrl.compareTo(_song.source) != 0) {
      _audioPlayerManager.updateSongUrl(_song.source);
      _audioPlayerManager.prepare(isNewSong: true);
    } else {
      _audioPlayerManager.prepare(isNewSong: false);
    }
    _selectedItemIndex = widget.songs.indexOf(widget.playingSong);
    _loopMode = LoopMode.off;
    _audioPlayerManager.player.playerStateStream.listen((playerState) {
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
    final bool isFavorite = _song.isFavorite;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Now Playing'),
        trailing: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_horiz),
        ),
      ),
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const SizedBox(height: 56),
              Text(_song.album),
              const Text('_ ___ _'),
              const SizedBox(height: 8),
              RotationTransition(
                turns: Tween(
                  begin: 0.0,
                  end: 1.0,
                ).animate(_imageAnimController),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: FadeInImage.assetNetwork(
                    placeholder: 'assets/itunes_256.png',
                    image: _song.image,
                    width: screenWidth - delta,
                    height: screenWidth - delta,
                    imageErrorBuilder: (context, error, stackTrace) {
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
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                child: SizedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.share_outlined),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      Column(
                        children: [
                          Text(
                            _song.title,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium!.copyWith(
                              color:
                                  Theme.of(context).textTheme.bodyMedium!.color,
                            ),
                          ),
                          // const SizedBox(height: 8),
                          Text(
                            _song.artist,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium!.copyWith(
                              color:
                                  Theme.of(context).textTheme.bodyMedium!.color,
                            ),
                          ),
                        ],
                      ),
                     IconButton(
  onPressed: () {
    setState(() {
      _song.isFavorite = !_song.isFavorite;
    });
  },
  icon: Icon(
    _song.isFavorite ? Icons.favorite : Icons.favorite_outline,
    color: _song.isFavorite ? Colors.red : Theme.of(context).colorScheme.primary,
  ),
)
,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 32, right: 32),
                child: _progressBar(),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 24,
                  top: 8,
                  right: 24,
                  bottom: 8,
                ),
                child: _mediaButtons(),
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
    super.dispose();
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

  setState(() {
    _song = nextSong;
  });

  _audioPlayerManager.updateSongUrl(nextSong.source);
  _audioPlayerManager.prepare(isNewSong: true); // 👈 bắt buộc phải có
  _audioPlayerManager.player.play(); // 👈 để bắt đầu phát

  _resetRotationAnim();
  _playRotationAnim();
}


  Widget _mediaButtons() {
    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          MediaButtonControl(
            function: _setShuffle,
            icon: Icons.shuffle,
            color: _getShuffleColor(),
            size: 24,
          ),
          MediaButtonControl(
            function: _setPrevSong,
            icon: Icons.skip_previous,
            color: Colors.deepPurple,
            size: 36,
          ),
          _playButton(),
          MediaButtonControl(
            function: _setNextSong,
            icon: Icons.skip_next,
            color: Colors.deepPurple,
            size: 36,
          ),
          MediaButtonControl(
            function: _setupRepeatOption,
            icon: _repeatingIcon(),
            color: _getRepeatingIconColor(),
            size: 24,
          ),
        ],
      ),
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
      stream: _audioPlayerManager.player.playerStateStream,
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

  void _setShuffle() {
    setState(() {
      _isShuffle = !_isShuffle;
    });
  }

  Color? _getShuffleColor() {
    return _isShuffle ? Colors.deepPurple : Colors.grey;
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

  Color? _getRepeatingIconColor() {
    return _loopMode == LoopMode.off ? Colors.grey : Colors.deepPurple;
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

  void _resetRotationAnim() {
    _currentAnimationPosition = 0.0;

    // Hoãn cập nhật controller cho đến khi build hoàn tất
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _imageAnimController.value = _currentAnimationPosition;
      }
    });
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
