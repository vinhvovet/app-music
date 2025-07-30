import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import '../../data/music_models.dart';
import '../../startup_performance.dart';

class NowPlayingModern extends StatefulWidget {
  final MusicTrack currentTrack;
  final List<MusicTrack> playlist;
  final String streamUrl;

  const NowPlayingModern({
    super.key,
    required this.currentTrack,
    required this.playlist,
    required this.streamUrl,
  });

  @override
  State<NowPlayingModern> createState() => _NowPlayingModernState();
}

class _NowPlayingModernState extends State<NowPlayingModern>
    with SingleTickerProviderStateMixin {
  
  late AudioPlayer _audioPlayer;
  late AnimationController _rotationController;
  
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.off;
  
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  
  int _currentIndex = 0;
  late MusicTrack _currentTrack;

  @override
  void initState() {
    super.initState();
    
    _audioPlayer = AudioPlayer();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    _currentTrack = widget.currentTrack;
    _currentIndex = widget.playlist.indexOf(widget.currentTrack);
    
    _initializeAudio();
    _setupAudioListeners();
  }

  void _initializeAudio() async {
    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }
      
      await _audioPlayer.setUrl(widget.streamUrl);
      await _audioPlayer.play();
      
      if (mounted) {
        setState(() {
          _isPlaying = true;
          _isLoading = false;
        });
      }
      
      _rotationController.repeat();
    } catch (e) {
      print('Error initializing audio: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupAudioListeners() {
    // Position listener
    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    });

    // Duration listener
    _audioPlayer.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() => _totalDuration = duration);
      }
    });

    // Player state listener
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        final isPlaying = state.playing;
        final processingState = state.processingState;
        
        if (isPlaying != _isPlaying) {
          setState(() => _isPlaying = isPlaying);
          
          if (isPlaying) {
            _rotationController.repeat();
          } else {
            _rotationController.stop();
          }
        }
        
        // Handle track completion
        if (processingState == ProcessingState.completed) {
          _playNext();
        }
      }
    });
  }

  void _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  void _playNext() async {
    if (_currentIndex < widget.playlist.length - 1) {
      _currentIndex++;
      await _playTrackAtIndex(_currentIndex);
    } else if (_loopMode == LoopMode.all) {
      _currentIndex = 0;
      await _playTrackAtIndex(_currentIndex);
    }
  }

  void _playPrevious() async {
    if (_currentIndex > 0) {
      _currentIndex--;
      await _playTrackAtIndex(_currentIndex);
    } else if (_loopMode == LoopMode.all) {
      _currentIndex = widget.playlist.length - 1;
      await _playTrackAtIndex(_currentIndex);
    }
  }

  Future<void> _playTrackAtIndex(int index) async {
    if (index < 0 || index >= widget.playlist.length) return;
    
    setState(() {
      _isLoading = true;
      _currentTrack = widget.playlist[index];
      _currentIndex = index;
    });

    try {
      // Get stream URL for new track
      final api = StartupPerformance.musicAPI;
      final songDetails = await api.getSongDetails(_currentTrack.videoId);
      
      if (songDetails['streamingUrls'] != null) {
        final streamingUrls = songDetails['streamingUrls'] as List<Map<String, dynamic>>;
        if (streamingUrls.isNotEmpty) {
          final streamUrl = streamingUrls.first['url'] as String;
          
          await _audioPlayer.setUrl(streamUrl);
          await _audioPlayer.play();
          
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('Error playing track: $e');
      setState(() => _isLoading = false);
    }
  }

  void _seek(Duration position) {
    _audioPlayer.seek(position);
  }

  void _toggleShuffle() {
    setState(() => _isShuffle = !_isShuffle);
    _audioPlayer.setShuffleModeEnabled(_isShuffle);
  }

  void _toggleLoopMode() {
    switch (_loopMode) {
      case LoopMode.off:
        _loopMode = LoopMode.one;
        break;
      case LoopMode.one:
        _loopMode = LoopMode.all;
        break;
      case LoopMode.all:
        _loopMode = LoopMode.off;
        break;
    }
    setState(() {});
    _audioPlayer.setLoopMode(_loopMode);
  }

  IconData get _loopIcon {
    switch (_loopMode) {
      case LoopMode.off:
        return CupertinoIcons.repeat;
      case LoopMode.one:
        return CupertinoIcons.repeat_1;
      case LoopMode.all:
        return CupertinoIcons.repeat;
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.chevron_down, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        middle: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Playing from YouTube Music',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
            Text(
              widget.playlist.length > 1 
                  ? '${_currentIndex + 1} / ${widget.playlist.length}'
                  : 'Single Track',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.ellipsis, color: Colors.white),
          onPressed: () {
            // Show more options
          },
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade900,
              Colors.purple.shade700,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(flex: 1),
                
                // Album Art
                Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationController.value * 2 * 3.14159,
                          child: _currentTrack.thumbnail != null
                              ? Image.network(
                                  _currentTrack.thumbnail!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Colors.grey.shade800,
                                    child: const Icon(
                                      CupertinoIcons.music_note_2,
                                      size: 100,
                                      color: Colors.white54,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey.shade800,
                                  child: const Icon(
                                    CupertinoIcons.music_note_2,
                                    size: 100,
                                    color: Colors.white54,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ),
                
                const Spacer(flex: 1),
                
                // Song Info
                Column(
                  children: [
                    Text(
                      _currentTrack.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentTrack.artist ?? 'Unknown Artist',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                
                const Spacer(flex: 1),
                
                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ProgressBar(
                    progress: _currentPosition,
                    total: _totalDuration,
                    onSeek: _seek,
                    barHeight: 4,
                    baseBarColor: Colors.white.withOpacity(0.3),
                    progressBarColor: Colors.white,
                    thumbColor: Colors.white,
                    timeLabelTextStyle: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Shuffle
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(
                        CupertinoIcons.shuffle,
                        color: _isShuffle ? Colors.green : Colors.white.withOpacity(0.7),
                        size: 24,
                      ),
                      onPressed: _toggleShuffle,
                    ),
                    
                    // Previous
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(
                        CupertinoIcons.backward_fill,
                        color: Colors.white.withOpacity(0.9),
                        size: 32,
                      ),
                      onPressed: _playPrevious,
                    ),
                    
                    // Play/Pause
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: _isLoading
                            ? const CupertinoActivityIndicator(color: Colors.black)
                            : Icon(
                                _isPlaying
                                    ? CupertinoIcons.pause_fill
                                    : CupertinoIcons.play_fill,
                                color: Colors.black,
                                size: 36,
                              ),
                        onPressed: _isLoading ? null : _playPause,
                      ),
                    ),
                    
                    // Next
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(
                        CupertinoIcons.forward_fill,
                        color: Colors.white.withOpacity(0.9),
                        size: 32,
                      ),
                      onPressed: _playNext,
                    ),
                    
                    // Repeat
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(
                        _loopIcon,
                        color: _loopMode != LoopMode.off 
                            ? Colors.green 
                            : Colors.white.withOpacity(0.7),
                        size: 24,
                      ),
                      onPressed: _toggleLoopMode,
                    ),
                  ],
                ),
                
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
