import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_app/state%20management/provider.dart';
import 'package:music_app/ui/now_playing/playing.dart';
import 'package:music_app/ui/components/audio_wave_animation.dart';
import 'package:music_app/ui/components/ripple_effect.dart';

class NowPlayingBar extends StatefulWidget {
  const NowPlayingBar({super.key});

  @override
  State<NowPlayingBar> createState() => _NowPlayingBarState();
}

class _NowPlayingBarState extends State<NowPlayingBar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation cho hiệu ứng pulse (nhấp nháy)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Animation cho hiệu ứng shimmer (ánh sáng chạy)
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    // Bắt đầu animations
    _pulseController.repeat(reverse: true);
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderStateManagement>(
      builder: (context, provider, child) {
        final currentTrack = provider.currentlyPlayingTrack;
        final streamUrl = provider.currentStreamUrl;
        final playlist = provider.currentPlaylist;

        // Không hiển thị gì nếu không có bài đang phát
        if (currentTrack == null || streamUrl == null) {
          return const SizedBox.shrink();
        }

        return AnimatedBuilder(
          animation: Listenable.merge([_pulseAnimation, _shimmerAnimation]),
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                // Gradient background với hiệu ứng
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.1 * _pulseAnimation.value),
                    Colors.purple.withOpacity(0.15 * _pulseAnimation.value),
                    Colors.blue.withOpacity(0.1 * _pulseAnimation.value),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                // Border với hiệu ứng pulse
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3 * _pulseAnimation.value),
                  width: 2,
                ),
                // Box shadow với hiệu ứng
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2 * _pulseAnimation.value),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Shimmer effect overlay
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Transform.translate(
                        offset: Offset(_shimmerAnimation.value * 200, 0),
                        child: Container(
                          width: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.1),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Main content
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        // Mở màn hình now playing
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => NowPlaying(
                              playingSong: currentTrack,
                              songs: playlist ?? [],
                              streamUrl: streamUrl,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            // Album art với hiệu ứng ripple và pulse
                            RippleEffect(
                              rippleColor: Colors.blue,
                              radius: 70,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: currentTrack.thumbnail != null && 
                                           currentTrack.thumbnail!.isNotEmpty
                                        ? Image.network(
                                            currentTrack.thumbnail!,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Container(
                                              color: Colors.grey.shade300,
                                              child: const Icon(
                                                CupertinoIcons.music_note_2,
                                                size: 24,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          )
                                        : Container(
                                            color: Colors.grey.shade300,
                                            child: const Icon(
                                              CupertinoIcons.music_note_2,
                                              size: 24,
                                              color: Colors.grey,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Song info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    currentTrack.title.isNotEmpty 
                                        ? currentTrack.title 
                                        : 'Untitled Song',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      // Animated music note icon
                                      Transform.scale(
                                        scale: _pulseAnimation.value,
                                        child: Icon(
                                          CupertinoIcons.music_note,
                                          size: 12,
                                          color: Colors.blue.withOpacity(0.8),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          currentTrack.artist?.isNotEmpty == true 
                                              ? currentTrack.artist! 
                                              : 'Various Artists',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Playing indicator với animation
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8, 
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Animated audio wave
                                  AudioWaveAnimation(
                                    color: Colors.blue.withOpacity(0.8),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Đang phát',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(width: 8),
                            
                            // Next button
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  // TODO: Implement next song functionality
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    CupertinoIcons.forward_fill,
                                    size: 20,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
