import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:music_app/ui/discovery/discovery.dart';
import 'package:music_app/ui/home/viewmodel.dart';
import 'package:music_app/ui/now_playing/playing.dart';
import 'package:music_app/ui/settings/settings.dart';
import 'package:music_app/ui/account/user.dart';
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
        backgroundColor: Color(0xFF21293E),
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

  void observeData() {
    _viewModel.songStream.stream.listen((songList) {
      setState(() {
        songs = songList;
      });
    });
  }
}

class _SongItemSection extends StatelessWidget {
  final _HomeTabPageState parent;
  final Song song;

  const _SongItemSection({required this.parent, required this.song});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.network(song.image, width: 50, height: 50, fit: BoxFit.cover),
      title: Text(song.title),
      subtitle: Text(song.artist),
      onTap: () {
        // Implement navigation to now playing or song details if needed
      },
    );
  }
}