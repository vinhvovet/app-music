import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:music_app/ui/discovery/discovery.dart';
import 'package:music_app/ui/home/viewmodel.dart';
import 'package:music_app/ui/now_playing/playing.dart';
import 'package:music_app/ui/settings/settings.dart';
import 'package:music_app/ui/account/user.dart';
import '../lyrics_recognition/lyrics_search_page.dart';
import '../../data/model/song.dart';

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
          backgroundColor: Theme.of(context).colorScheme.onInverseSurface,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chính'),
            BottomNavigationBarItem(icon: Icon(Icons.album), label: 'Yêu thích'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
          ],
        ),
        tabBuilder: (BuildContext context, int index) {
          return _tabs[index];
        },
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeTabPage();
  }
}

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({super.key});

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  List<Song> songs = [];
  late MusicAppViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MusicAppViewModel();
    _viewModel.loadSongs();
    observeData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header với tiêu đề "Nghe nhạc"
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3EA513).withOpacity(0.1),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nghe nhạc',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3EA513),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Khám phá và thưởng thức âm nhạc',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Thanh tìm kiếm theo tên bài hát và tác giả
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) {
                _viewModel.searchByKeyword(value);
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo nhạc sĩ, bài hát...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: songs.isEmpty
                ? const Text("Không tìm thấy bài hát nào.")
                : getListView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LyricsSearchPage(songs: songs),
            ),
          );
        },
        backgroundColor: const Color(0xFF3EA513),
        child: const Icon(
          Icons.lyrics,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  ListView getListView() {
    return ListView.separated(
      itemBuilder: (context, position) {
        return getRow(position);
      },
      separatorBuilder: (context, index) {
        return const Divider(
          color: Colors.grey,
          thickness: 1,
          indent: 24,
          endIndent: 24,
        );
      },
      itemCount: songs.length,
      shrinkWrap: true,
    );
  }

 Widget getRow(int index) {
  return ListTile(
    leading: Image.network(
      songs[index].image,
      width: 50,
      height: 50,
      fit: BoxFit.cover,
    ),
    title: Text(songs[index].title),
    subtitle: Text(songs[index].artist),
    onTap: () {
      // Điều hướng đến màn hình phát nhạc
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>  NowPlaying(playingSong: songs[index], songs: songs),
        ),
      );
    },
  );
}

  void _showLyricsSearchDialog(BuildContext context) {
    TextEditingController lyricsController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tìm kiếm theo lời bài hát'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: lyricsController,
                decoration: const InputDecoration(
                  hintText: 'Nhập lời bài hát...',
                  prefixIcon: Icon(Icons.lyrics),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              const Text(
                'Nhập một đoạn lời bài hát để tìm kiếm',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (lyricsController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  _searchByLyrics(lyricsController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3EA513),
              ),
              child: const Text('Tìm kiếm', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _searchByLyrics(String lyrics) {
    // Tìm kiếm bài hát dựa trên lời bài hát
    List<Song> foundSongs = [];
    for (Song song in songs) {
      if (song.lyrics != null && 
          song.lyrics!.toLowerCase().contains(lyrics.toLowerCase())) {
        foundSongs.add(song);
      }
    }

    if (foundSongs.isNotEmpty) {
      // Hiển thị kết quả tìm kiếm
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Tìm thấy ${foundSongs.length} bài hát'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: foundSongs.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Image.asset(
                      foundSongs[index].image,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                    title: Text(foundSongs[index].title),
                    subtitle: Text(foundSongs[index].artist),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NowPlaying(
                            playingSong: foundSongs[index], 
                            songs: songs
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      );
    } else {
      // Không tìm thấy bài hát nào
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Không tìm thấy'),
            content: const Text('Không tìm thấy bài hát nào có lời tương ứng.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void observeData() {
    _viewModel.songStream.stream.listen((songList) {
      setState(() {
        songs = songList;
      });
    });
  }
}