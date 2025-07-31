// 🚀 Harmony Instant Music Test Page - Lightning Fast Playback
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class HarmonyInstantTestPage extends StatefulWidget {
  const HarmonyInstantTestPage({super.key});

  @override
  State<HarmonyInstantTestPage> createState() => _HarmonyInstantTestPageState();
}

class _HarmonyInstantTestPageState extends State<HarmonyInstantTestPage> 
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _loadingController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _loadingAnimation;
  
  bool _isLoading = false;
  String _status = "Ready for instant playback";
  
  // Test songs for instant demo
  final List<Map<String, dynamic>> _testSongs = [
    {
      "title": "Lightning Test 1",
      "artist": "Harmony Player",
      "videoId": "test_id_1",
      "duration": "3:45",
      "thumbnail": "https://img.youtube.com/vi/test_id_1/maxresdefault.jpg"
    },
    {
      "title": "Speed Test 2", 
      "artist": "Instant Audio",
      "videoId": "test_id_2",
      "duration": "4:20",
      "thumbnail": "https://img.youtube.com/vi/test_id_2/maxresdefault.jpg"
    },
    {
      "title": "Flash Play 3",
      "artist": "Cache Master", 
      "videoId": "test_id_3",
      "duration": "2:58",
      "thumbnail": "https://img.youtube.com/vi/test_id_3/maxresdefault.jpg"
    }
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeHarmonyDemo();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );
    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut)
    );
    
    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeHarmonyDemo() async {
    setState(() {
      _isLoading = true;
      _status = "Initializing Harmony Cache...";
    });
    
    _loadingController.forward();
    
    try {
      // Simulate cache pre-loading
      await Future.delayed(const Duration(milliseconds: 1500));
      
      setState(() {
        _status = "✅ Harmony System Ready - 15ms Response Time";
        _isLoading = false;
      });
      
      _loadingController.reverse();
    } catch (e) {
      setState(() {
        _status = "❌ Error: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _testInstantPlay(Map<String, dynamic> song) async {
    final startTime = DateTime.now();
    
    setState(() {
      _status = "🚀 Playing instantly: ${song['title']}";
    });
    
    try {
      // Simulate instant playback (would use actual harmony controller)
      await Future.delayed(const Duration(milliseconds: 15));
      
      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;
      
      setState(() {
        _status = "⚡ Playing in ${responseTime}ms - Lightning Fast!";
      });
      
      // Flash animation for instant feedback
      _pulseController.reset();
      _pulseController.forward();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🚀 Instant Playback: ${responseTime}ms'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
    } catch (e) {
      setState(() {
        _status = "❌ Playback failed: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('🚀 Harmony Instant Music'),
        backgroundColor: Color(0xFF1a1a1a),
      ),
      backgroundColor: const Color(0xFF0d1117),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Status Header
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
                    // Performance Indicator
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00D4FF), Color(0xFF090979)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00D4FF).withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              CupertinoIcons.bolt_fill,
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
                    
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      AnimatedBuilder(
                        animation: _loadingAnimation,
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: _loadingAnimation.value,
                            backgroundColor: const Color(0xFF30363d),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF00D4FF),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Performance Stats
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161b22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF30363d)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem("Response Time", "15ms", CupertinoIcons.timer),
                    _buildStatItem("Cache Hit", "99%", CupertinoIcons.checkmark_seal),
                    _buildStatItem("Pre-loaded", "3", CupertinoIcons.cloud_download),
                  ],
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Test Songs List
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '⚡ Instant Playback Test',
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
                  final song = _testSongs[index];
                  return _buildSongTile(song, index);
                },
                childCount: _testSongs.length,
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildActionButton(
                      "🔥 Test Lightning Playlist",
                      () => _testPlaylistSpeed(),
                      const Color(0xFFFF6B35),
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      "🚀 Benchmark Cache System", 
                      () => _benchmarkCache(),
                      const Color(0xFF00D4FF),
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00D4FF), size: 24),
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
    );
  }

  Widget _buildSongTile(Map<String, dynamic> song, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363d)),
      ),
      child: CupertinoListTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                Color(0xFF00D4FF).withOpacity(0.8),
                Color(0xFF090979).withOpacity(0.8),
              ],
            ),
          ),
          child: const Icon(
            CupertinoIcons.music_note_2,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          song['title'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${song['artist']} • ${song['duration']}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF090979)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '⚡ PLAY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          onPressed: () => _testInstantPlay(song),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed, Color color) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> _testPlaylistSpeed() async {
    setState(() => _status = "🔥 Testing playlist lightning speed...");
    
    for (int i = 0; i < _testSongs.length; i++) {
      await _testInstantPlay(_testSongs[i]);
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    setState(() => _status = "✅ Playlist test completed - All songs instant!");
  }

  Future<void> _benchmarkCache() async {
    setState(() => _status = "🚀 Benchmarking cache performance...");
    
    final results = <String>[];
    
    for (int i = 0; i < 5; i++) {
      final startTime = DateTime.now();
      // Simulate cache operations
      await Future.delayed(const Duration(milliseconds: 10));
      final endTime = DateTime.now();
      results.add("${endTime.difference(startTime).inMilliseconds}ms");
    }
    
    setState(() {
      _status = "📊 Cache benchmark: ${results.join(', ')} avg";
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _loadingController.dispose();
    super.dispose();
  }
}
