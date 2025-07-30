import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:music_app/ui/discovery/discovery.dart';
import 'package:music_app/ui/home/viewmodel.dart';
import 'package:music_app/ui/settings/settings.dart';
import 'package:music_app/ui/account/user.dart';
import '../../data/music_models.dart';

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nghe nhạc ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MusicHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MusicHomePage extends StatefulWidget {
  const MusicHomePage({super.key});

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  final List<Widget> _tabs = [
    const HomeTab(),
    const ListFavorite(),
    const AccountTab(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Nghe nhạc'),
      ),
      child: CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          backgroundColor: CupertinoColors.systemBackground,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.home),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.heart),
              label: 'Yêu thích',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person),
              label: 'Tài khoản',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.settings),
              label: 'Cài đặt',
            ),
          ],
        ),
        tabBuilder: (context, index) {
          return _tabs[index];
        },
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late MusicAppViewModel _musicAppViewModel;
  List<MusicTrack> songs = [];

  @override  
  void initState() {
    super.initState();
    _musicAppViewModel = MusicAppViewModel();
    _musicAppViewModel.loadSongs();
    
    _musicAppViewModel.songStream.stream.listen((event) {
      setState(() {
        songs = event;
      });
    });
  }

  @override
  void dispose() {
    _musicAppViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Danh sách nhạc'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showSearchDialog(context),
              child: const Icon(CupertinoIcons.search),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: songs.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoActivityIndicator(),
                    SizedBox(height: 16),
                    Text('Đang tải danh sách nhạc...'),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: songs[index].thumbnail != null
                            ? Image.network(
                                songs[index].thumbnail!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.music_note, size: 56),
                              )
                            : const Icon(Icons.music_note, size: 56),
                      ),
                      title: Text(
                        songs[index].title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        songs[index].artist ?? 'Unknown Artist',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          (songs[index].isFavorite ?? false)
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          color: (songs[index].isFavorite ?? false)
                              ? CupertinoColors.systemRed
                              : null,
                        ),
                        onPressed: () {
                          _musicAppViewModel.toggleFavorite(songs[index]);
                        },
                      ),
                      onTap: () {
                        // TODO: Implement music player with new MusicTrack
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Playing: ${songs[index].title}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    String searchQuery = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tìm kiếm bài hát'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nhập tên bài hát, ca sĩ...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            searchQuery = value;
            _musicAppViewModel.searchByKeyword(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _musicAppViewModel.searchByKeyword(''); // Reset search
            },
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

class ListFavorite extends StatelessWidget {
  const ListFavorite({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Danh sách yêu thích'),
      ),
      child: Center(
        child: Text('Danh sách bài hát yêu thích sẽ hiển thị ở đây'),
      ),
    );
  }
}
