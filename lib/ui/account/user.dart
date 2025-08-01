import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:music_app/ui/auth_form/login_screen.dart';
import 'package:music_app/controllers/lightning_player_controller.dart';
import 'package:music_app/services/permanent_audio_service.dart';
import 'package:music_app/services/harmony_music_service.dart';
import 'package:music_app/ui/now_playing/audio_player_manager.dart';
import 'package:music_app/state%20management/provider.dart';
import 'package:provider/provider.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Không có người dùng đăng nhập")),
      );
    }

   return Scaffold(
  appBar: AppBar(
    title: const Text('Tài khoản'),
  ),
  body: SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin tài khoản',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email'),
            subtitle: Text(user.email ?? 'Chưa có email'),
          ),
          const SizedBox(height: 32), // <- Thay Spacer bằng SizedBox (Spacer sẽ bị xung đột với SinglechildScrollView)
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  // ⚡ Inform Lightning Music System about logout
                  await lightningPlayer.onUserLogout();
                  await permanentAudio.onUserLogout();
                  print('⚡ Lightning Music System: User session cleared');

                  // 🛑 Stop music playback when logging out
                  final harmonyService = context.read<HarmonyMusicService>();
                  await harmonyService.clearAll(); // Stop playback and clear all data
                  print('🛑 Harmony Music Service cleared');

                  // 🎵 Dispose AudioPlayerManager to free resources
                  await AudioPlayerManager().dispose();
                  print('🎵 AudioPlayerManager disposed');

                  // Clear provider data
                  final provider = context.read<ProviderStateManagement>();
                  provider.clearCurrentlyPlayingTrack(); // Clear currently playing track
                  print('✅ Provider state cleared');
                  
                  await FirebaseAuth.instance.signOut();
                  print('✅ Firebase logout successful');
                  
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  print('❌ Logout error: $e');
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);

  }
}
