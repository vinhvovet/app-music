import 'package:flutter/material.dart';
import 'album.dart';

class SongDetailScreen extends StatelessWidget {
  static const routeName = '/detail'; // Đặt routeName ở đây

  final Album album;

  const SongDetailScreen({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(album.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.network(album.image),
            const SizedBox(height: 16),
            Text(album.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Artist: ${album.artist}'),
            Text('Album: ${album.album}'),
            Text('Duration: ${album.duration} sec'),
          ],
        ),
      ),
    );
  }
}
