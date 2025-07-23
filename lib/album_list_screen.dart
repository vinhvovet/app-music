import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'album_provider.dart';
import 'song_detail_screen.dart';

class AlbumListScreen extends StatefulWidget {
  const AlbumListScreen({super.key});

  @override
  State<AlbumListScreen> createState() => _AlbumListScreenState();
}

class _AlbumListScreenState extends State<AlbumListScreen> {
  @override
  void initState() {
    super.initState();
    // Gọi fetch khi widget được tạo
    Provider.of<AlbumProvider>(context, listen: false).fetchAlbum();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Center(child : Text('Album List'))),
      body: Consumer<AlbumProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          final albums = provider.albums;

          return ListView.builder(
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return ListTile(
                leading: Image.network(album.image, width: 50, height: 50, fit: BoxFit.cover),
                title: Text(album.title),
                subtitle: Text(album.artist),
                trailing: IconButton(onPressed: (){
                  // Thêm hành động khi nhấn vào biểu tượng
                  showDialog(context: context, builder: (context) {
                    return AlertDialog(
                      title: Text('Album Details'),
                      content: Text('Title: ${album.title}\nArtist: ${album.artist}'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    );
                  });
                }, icon: Icon(Icons.more_horiz)),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    SongDetailScreen.routeName,
                    arguments: album,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
