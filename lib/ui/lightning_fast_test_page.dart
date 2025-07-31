// ⚡ Lightning Fast Test Page - Demo tốc độ phát nhạc 20X nhanh hơn
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../controllers/lightning_player_controller.dart';
import '../data/music_models.dart';

class LightningFastTestPage extends StatefulWidget {
  const LightningFastTestPage({super.key});

  @override
  State<LightningFastTestPage> createState() => _LightningFastTestPageState();
}

class _LightningFastTestPageState extends State<LightningFastTestPage> 
    with TickerProviderStateMixin {
  late AnimationController _lightningController;
  late AnimationController _performanceController;
  late Animation<double> _lightningAnimation;
  late Animation<double> _performanceAnimation;
  
  bool _isTestRunning = false;
  String _status = "Ready for Lightning Fast Test";
  Map<String, dynamic> _performanceStats = {};
  
  // Test songs với real YouTube videoId 
  final List<MusicTrack> _testTracks = [
    MusicTrack(
      id: "test_1",
      videoId: "dQw4w9WgXcQ", // Rick Astley - Never Gonna Give You Up
      title: "Never Gonna Give You Up",
      artist: "Rick Astley",
      thumbnail: "https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg",
      duration: const Duration(minutes: 3, seconds: 32),
    ),
    MusicTrack(
      id: "test_2", 
      videoId: "9bZkp7q19f0", // PSY - GANGNAM STYLE
      title: "Gangnam Style",
      artist: "PSY",
      thumbnail: "https://img.youtube.com/vi/9bZkp7q19f0/maxresdefault.jpg",
      duration: const Duration(minutes: 4, seconds: 12),
    ),
    MusicTrack(
      id: "test_3",
      videoId: "kJQP7kiw5Fk", // Luis Fonsi - Despacito 
      title: "Despacito",
      artist: "Luis Fonsi ft. Daddy Yankee",
      thumbnail: "https://img.youtube.com/vi/kJQP7kiw5Fk/maxresdefault.jpg",
      duration: const Duration(minutes: 4, seconds: 41),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadPerformanceStats();
  }

  void _setupAnimations() {
    _lightningController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _performanceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _lightningAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _lightningController, curve: Curves.elasticOut)
    );
    _performanceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _performanceController, curve: Curves.easeInOut)
    );
  }

  void _loadPerformanceStats() {
    final lightningPlayer = context.read<LightningPlayerController>();
    if (mounted) {
      setState(() {
        _performanceStats = lightningPlayer.getPerformanceStats();
      });
    }
  }

  /// 🚀 Test instant playback với measurement
  Future<void> _testLightningPlayback(MusicTrack track) async {
    if (_isTestRunning) return;
    
    if (mounted) {
      setState(() {
        _isTestRunning = true;
        _status = "⚡ Testing lightning playback...";
      });
    }
    
    _lightningController.forward();
    
    try {
      final lightningPlayer = context.read<LightningPlayerController>();
      final startTime = DateTime.now();
      
      // LIGHTNING FAST PLAYBACK
      await lightningPlayer.playTrackInstant(track, newPlaylist: _testTracks);
      
      final endTime = DateTime.now();
      final latencyMs = endTime.difference(startTime).inMilliseconds;
      
      // Update performance display
      _loadPerformanceStats();
      
      if (mounted) {
        setState(() {
          _status = "🎉 LIGHTNING PLAYBACK: ${latencyMs}ms! (Target: <55ms)";
          _isTestRunning = false;
        });
      }
      
      // Flash success animation
      _performanceController.forward().then((_) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _performanceController.reverse();
        });
      });
      
      // Show performance snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.yellow),
                const SizedBox(width: 8),
                Text('Lightning Fast: ${latencyMs}ms! ${latencyMs < 55 ? "🎯 TARGET ACHIEVED!" : ""}'),
              ],
            ),
            backgroundColor: latencyMs < 55 ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = "❌ Test failed: $e";
          _isTestRunning = false;
        });
      }
    } finally {
      _lightningController.reverse();
    }
  }

  /// 🔥 Test playlist lightning switching
  Future<void> _testPlaylistLightning() async {
    if (_isTestRunning) return;
    
    if (mounted) {
      setState(() {
        _isTestRunning = true;
        _status = "🔥 Testing lightning playlist switching...";
      });
    }
    
    try {
      final lightningPlayer = context.read<LightningPlayerController>();
      final latencies = <int>[];
      
      for (int i = 0; i < _testTracks.length; i++) {
        final startTime = DateTime.now();
        
        await lightningPlayer.playTrackInstant(_testTracks[i], newPlaylist: _testTracks);
        
        final endTime = DateTime.now();
        final latency = endTime.difference(startTime).inMilliseconds;
        latencies.add(latency);
        
        if (mounted) {
          setState(() {
            _status = "🔥 Track ${i + 1}/${_testTracks.length}: ${latency}ms";
          });
        }
        
        // Short pause between tracks
        await Future.delayed(const Duration(seconds: 1));
      }
      
      final avgLatency = latencies.reduce((a, b) => a + b) / latencies.length;
      
      if (mounted) {
        setState(() {
          _status = "✅ Playlist test complete! Avg: ${avgLatency.toStringAsFixed(1)}ms";
          _isTestRunning = false;
        });
      }
      
      _loadPerformanceStats();
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = "❌ Playlist test failed: $e";
          _isTestRunning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        title: const Text('⚡ Lightning Fast Music Test'),
        backgroundColor: const Color(0xFF161b22),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Performance Header
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF21262d), Color(0xFF161b22)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF30363d)),
                ),
                child: Column(
                  children: [
                    // Lightning Icon with animation
                    AnimatedBuilder(
                      animation: _lightningAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _lightningAnimation.value,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFF6B35)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.flash_on,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Status Text
                    Text(
                      _status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Performance Improvement Display
                    AnimatedBuilder(
                      animation: _performanceAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _performanceAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.withOpacity(0.5)),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  '🎯 PERFORMANCE TARGET',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '55ms vs 1100ms = 20X FASTER!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Performance Stats Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: _buildStatCard("Last Play", "${_performanceStats['last_latency_ms'] ?? 0}ms", Icons.timer)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard("Average", "${_performanceStats['average_latency_ms'] ?? 0}ms", Icons.speed)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard("Total Tests", "${_performanceStats['total_plays'] ?? 0}", Icons.play_arrow)),
                  ],
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // System Status
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSystemStatus(),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Test Tracks List
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '⚡ Lightning Test Tracks',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = _testTracks[index];
                  return _buildTrackTile(track, index);
                },
                childCount: _testTracks.length,
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Test Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildActionButton(
                      "⚡ Test Lightning Playlist",
                      _testPlaylistLightning,
                      const Color(0xFFFF6B35),
                      enabled: !_isTestRunning,
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      "📊 View Detailed Stats", 
                      _showDetailedStats,
                      const Color(0xFF00D4FF),
                      enabled: true,
                    ),
                  ],
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363d)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFFFD700), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatus() {
    final audioStats = _performanceStats['audio_service_stats'] as Map<String, dynamic>? ?? {};
    final cacheStats = _performanceStats['cache_stats'] as Map<String, dynamic>? ?? {};
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363d)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🚀 Lightning System Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusRow('Audio Service', audioStats['is_initialized'] == true ? 'Ready' : 'Loading', audioStats['is_initialized'] == true),
          _buildStatusRow('Cache Manager', cacheStats['is_initialized'] == true ? 'Ready' : 'Loading', cacheStats['is_initialized'] == true),
          _buildStatusRow('Cache Hit Rate', '${cacheStats['hit_rate_percent'] ?? 0}%', (cacheStats['hit_rate_percent'] ?? 0) > 50),
          _buildStatusRow('Memory Cache', '${cacheStats['memory_urls'] ?? 0} URLs', true),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, bool isGood) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isGood ? Icons.check_circle : Icons.warning,
                color: isGood ? Colors.green : Colors.orange,
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackTile(MusicTrack track, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363d)),
      ),
      child: ListTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFF6B35)],
            ),
          ),
          child: const Icon(
            Icons.flash_on,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          track.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${track.artist} • ${track.duration?.toString().split('.').first ?? 'Unknown'}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: _isTestRunning ? null : () => _testLightningPlayback(track),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text(
            '⚡ TEST',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback? onPressed, Color color, {bool enabled = true}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? color : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showDetailedStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161b22),
        title: const Text(
          '📊 Lightning Performance Stats',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Audio Service: ${_performanceStats['audio_service_stats']}',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Cache Stats: ${_performanceStats['cache_stats']}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _lightningController.dispose();
    _performanceController.dispose();
    super.dispose();
  }
}
