import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:music_app/ui/auth_form/login_screen.dart';
 // giả sử đã tạo

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _isDarkMode = false;
  String _selectedLanguage = 'Tiếng Việt';

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
      // TODO: Áp dụng thay đổi theme toàn app nếu cần
    });
  }

  void _changeLanguage(String? value) {
    setState(() {
      if (value != null) {
        _selectedLanguage = value;
        // TODO: Lưu ngôn ngữ bằng SharedPreferences hoặc Provider
      }
    });
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2B3147),
        title: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?',
            style: TextStyle(color: Colors.white70)),
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
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đăng xuất')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF21293E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Cài đặt', style: TextStyle(color: Colors.white)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: const Text('Tài khoản', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Xem và chỉnh sửa thông tin cá nhân',
                style: TextStyle(color: Colors.white70)),
            onTap: () {
            },
          ),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.white),
            title: const Text('Thông tin ứng dụng', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Phiên bản 1.0.0',
                style: TextStyle(color: Colors.white70)),
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
