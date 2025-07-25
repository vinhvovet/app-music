import 'package:flutter/material.dart';
import 'package:music_app/data/model/song.dart';
import 'package:music_app/state%20management/provider.dart';
import 'package:provider/provider.dart';
import '../home/viewmodel.dart';

class DiscoveryTab extends StatefulWidget {
  const DiscoveryTab({super.key});

  @override
  State<DiscoveryTab> createState() => _DiscoveryTabState();
}

class _DiscoveryTabState extends State<DiscoveryTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderStateManagement>(
      builder:
          (context, provider, child) => Scaffold(
            body: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => ListFavorite()),
                      );
                    },
                    child: Container(
                      height: 200,
                      width: 100,
                      child: Center(child: Icon(Icons.favorite)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

class ListFavorite extends StatefulWidget {
  const ListFavorite({super.key});

  @override
  State<ListFavorite> createState() => _ListFavoriteState();
}

class _ListFavoriteState extends State<ListFavorite> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderStateManagement>(
      builder:
          (context, provider, child) => Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children:
                      provider.favoriteSongs
                          .map(
                            (song) => ListTile(
                              leading: Image.network(
                                song.image,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                              title: Text(song.title),
                              subtitle: Text(song.artist),
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
          ),
    );
  }
}
