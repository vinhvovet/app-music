import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/harmony_music_service.dart';
import '../state management/provider.dart';
import 'package:provider/provider.dart';
import 'auth_form/login_screen.dart';

/// Test page để kiểm tra tính năng đăng xuất dừng nhạc
class TestLogoutMusicPage extends StatefulWidget {
  const TestLogoutMusicPage({Key? key}) : super(key: key);

  @override
  State<TestLogoutMusicPage> createState() => _TestLogoutMusicPageState();
}

class _TestLogoutMusicPageState extends State<TestLogoutMusicPage> {
  final HarmonyMusicService _harmonyService = HarmonyMusicService();
  bool _isPlaying = false;
  String _currentSong = "Không có bài hát";

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  void _initializeService() async {
    await _harmonyService.initialize();
    _harmonyService.addListener(_updatePlayingState);
  }

  void _updatePlayingState() {
    if (mounted) {
      setState(() {
        _isPlaying = _harmonyService.currentTrack != null;
        _currentSong = _harmonyService.currentTrack?.title ?? "Không có bài hát";
      });
    }
  }

  // Test phát nhạc
  void _playTestMusic() async {
    try {
      print('🎵 Testing music search...');
      final results = await _harmonyService.searchMusic('vietnamese music');
      
      if (results.isNotEmpty) {
        // Simulate playing the first track
        setState(() {
          _isPlaying = true;
          _currentSong = results.first.title;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎵 Tìm thấy ${results.length} bài hát: ${results.first.title}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Không tìm thấy bài hát nào'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ Error searching music: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi tìm nhạc: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Test đăng xuất và dừng nhạc
  void _testLogoutWithMusicStop() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Test Đăng xuất', style: TextStyle(color: Colors.black)),
        content: const Text('Kiểm tra: Đăng xuất sẽ dừng phát nhạc?',
            style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Test Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        print('🛑 Testing logout music stop...');
        
        // 🛑 Stop music playback when logging out
        await _harmonyService.clearAll(); // Stop playback and clear all data
        print('🛑 Music stopped on logout');

        // Clear currently playing track
        final provider = context.read<ProviderStateManagement>();
        provider.clearCurrentlyPlayingTrack();

        // Sign out from Firebase
        await FirebaseAuth.instance.signOut();
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🛑 Test thành công: Đã đăng xuất và dừng phát nhạc'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('❌ Logout test error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi test đăng xuất: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _harmonyService.removeListener(_updatePlayingState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Test Logout Music Stop', 
            style: TextStyle(color: Colors.black)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Music Status Card
            Card(
              color: _isPlaying ? Colors.green[50] : Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      _isPlaying ? Icons.music_note : Icons.music_off,
                      size: 48,
                      color: _isPlaying ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Trạng thái: ${_isPlaying ? "Đang phát" : "Đã dừng"}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isPlaying ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bài hát: $_currentSong',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Test Buttons
            ElevatedButton.icon(
              onPressed: _playTestMusic,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Phát nhạc test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: _isPlaying ? _testLogoutWithMusicStop : null,
              icon: const Icon(Icons.logout),
              label: const Text('Test Đăng xuất + Dừng nhạc'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPlaying ? Colors.red : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Hướng dẫn test:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Nhấn "Phát nhạc test" để bắt đầu phát nhạc\n'
                    '2. Kiểm tra trạng thái "Đang phát"\n'
                    '3. Nhấn "Test Đăng xuất + Dừng nhạc"\n'
                    '4. Xác nhận nhạc đã dừng và về màn hình login',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
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
}
