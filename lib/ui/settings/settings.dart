import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:music_app/state%20management/provider.dart';
import 'package:music_app/ui/auth_form/login_screen.dart';
import 'package:music_app/ui/settings/profile_screen.dart';
import 'package:music_app/services/harmony_music_service.dart';
import 'package:provider/provider.dart';
 // giả sử đã tạo

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {




void _logout() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
      title: const Text('Đăng xuất', style: TextStyle(color: Colors.black)),
      content: const Text('Bạn có chắc chắn muốn đăng xuất?',
          style: TextStyle(color: Colors.black)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirm == true) {
    try {
      // 🛑 Stop music playback when logging out
      final harmonyService = context.read<HarmonyMusicService>();
      await harmonyService.clearAll(); // Stop playback and clear all data
      print('🛑 Music stopped on logout');

      // Clear provider data
      final provider = context.read<ProviderStateManagement>();
      provider.clearCurrentlyPlayingTrack(); // Clear currently playing track

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🛑 Đã đăng xuất và dừng phát nhạc'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Logout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng xuất: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Cài đặt', style: TextStyle(color: Colors.black)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: Colors.black),
            title: const Text('Tài khoản', style: TextStyle(color: Colors.black)),
            subtitle: const Text('Xem và chỉnh sửa thông tin cá nhân',
                style: TextStyle(color: Colors.black54)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.black),
            title: const Text('Thông tin ứng dụng', style: TextStyle(color: Colors.black)),
            subtitle: const Text('Phiên bản 1.0.0',
                style: TextStyle(color: Colors.black54)),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
