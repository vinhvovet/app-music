import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state management/provider.dart';

class MusicVisualizer extends StatefulWidget {
  const MusicVisualizer({super.key});

  @override
  State<MusicVisualizer> createState() => _MusicVisualizerState();
}

class _MusicVisualizerState extends State<MusicVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<double> _barHeights = [];
  final int _barCount = 20;
  final Random _random = Random();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller for smooth beat-like animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Initialize bar heights
    _initializeBarHeights();
    
    // Start animation loop
    _startVisualizerAnimation();
  }

  void _initializeBarHeights() {
    _barHeights = List.generate(_barCount, (index) => _random.nextDouble() * 0.7 + 0.3);
  }

  void _startVisualizerAnimation() {
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Generate new random heights for beat effect
        if (mounted && _isPlaying) {
          setState(() {
            _barHeights = List.generate(_barCount, (index) {
              // Create more realistic music visualization
              double baseHeight = _random.nextDouble() * 0.8 + 0.2;
              // Add some correlation between adjacent bars for smoother look
              if (index > 0) {
                double previousHeight = _barHeights[index - 1];
                baseHeight = (baseHeight + previousHeight) / 2 + _random.nextDouble() * 0.3;
              }
              return baseHeight.clamp(0.1, 1.0);
            });
          });
        }
        // Repeat animation for continuous effect
        if (_isPlaying) {
          _animationController.forward(from: 0.0);
        }
      }
    });
  }

  void _updatePlayingState(bool isPlaying) {
    if (_isPlaying != isPlaying) {
      setState(() {
        _isPlaying = isPlaying;
      });
      
      if (isPlaying) {
        _animationController.forward(from: 0.0);
      } else {
        _animationController.stop();
        // Reset to static state when not playing
        setState(() {
          _barHeights = List.generate(_barCount, (index) => 0.3);
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderStateManagement>(
      builder: (context, provider, child) {
        // Check if music is currently playing
        final hasCurrentTrack = provider.currentlyPlayingTrack != null;
        
        if (!hasCurrentTrack) {
          _updatePlayingState(false);
          return const SizedBox.shrink();
        }
        
        // Assume music is playing when there's a current track
        // In a real app, you'd connect to the actual audio player
        _updatePlayingState(true);
        
        return Container(
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.withOpacity(0.1),
                Colors.blue.withOpacity(0.1),
                Colors.teal.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.purple.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Title
              Text(
                'Now Playing',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple.shade700,
                ),
              ),
              const SizedBox(height: 8),
              
              // Song info
              Text(
                provider.currentlyPlayingTrack?.title ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Visualizer bars
              Expanded(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(_barCount, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: 3,
                          height: _barHeights[index] * 40 * _animation.value + 5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.purple.shade400,
                                Colors.blue.shade400,
                                Colors.teal.shade400,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Alternative simpler visualizer for better performance
class SimpleMusicVisualizer extends StatefulWidget {
  const SimpleMusicVisualizer({super.key});

  @override
  State<SimpleMusicVisualizer> createState() => _SimpleMusicVisualizerState();
}

class _SimpleMusicVisualizerState extends State<SimpleMusicVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _barHeights = [0.3, 0.7, 0.4, 0.8, 0.5, 0.6, 0.9, 0.3, 0.7, 0.4];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderStateManagement>(
      builder: (context, provider, child) {
        final hasCurrentTrack = provider.currentlyPlayingTrack != null;
        
        if (!hasCurrentTrack) {
          return const SizedBox.shrink();
        }

        // Auto-start animation if track is playing
        if (hasCurrentTrack) {
          _controller.repeat(reverse: true);
        } else {
          _controller.stop();
        }

        return Container(
          height: 80,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Text(
                '♫ ${provider.currentlyPlayingTrack?.title ?? "Now Playing"} ♫',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: _barHeights.asMap().entries.map((entry) {
                        int index = entry.key;
                        double height = entry.value;
                        
                        double animatedHeight = height + 
                            (sin(_controller.value * 2 * pi + index * 0.5) * 0.3);
                        
                        return Container(
                          width: 3,
                          height: (animatedHeight * 30).clamp(5.0, 35.0),
                          decoration: BoxDecoration(
                            color: Colors.cyan,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyan.withOpacity(0.5),
                                blurRadius: 3,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
