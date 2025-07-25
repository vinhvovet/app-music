import 'package:flutter/material.dart';
import 'package:music_app/data/model/song.dart';
import 'package:music_app/state management/provider.dart';
import 'package:music_app/ui/now_playing/playing.dart'; // import màn hình NowPlaying
import 'package:provider/provider.dart';

class ListFavorite extends StatelessWidget {
  const ListFavorite({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderStateManagement>();
    final favSongs = provider.favoriteSongs;

    return Scaffold(
      appBar: AppBar(title: const Center(child: Text("Những bài hát yêu thích"))),
      
      body: SafeArea(
        child: favSongs.isEmpty
            ? const Center(
                child: Text(
                  "Không có dữ liệu",
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: favSongs.length,
                itemBuilder: (context, index) {
                  final song = favSongs[index];
                  return Card(
                    
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          song.image,
                          width:  50,
                          height:  50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        song.title,
                        style:
                            const TextStyle(color: Colors.black, fontSize: 16),
                      ),
                      subtitle: Text(
                        song.artist,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14),
                      ),
                      trailing: const Icon(
                        Icons.play_arrow,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        // Khi nhấn vào, điều hướng sang NowPlaying
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => NowPlaying(
                              playingSong: song,
                              songs: favSongs,
                            ),
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
}
