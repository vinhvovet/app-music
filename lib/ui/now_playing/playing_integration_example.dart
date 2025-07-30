// Example of how to integrate the updated playing.dart with your new MusicTrack data
// This shows how to navigate from your home screen to the now playing screen

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../data/music_models.dart';
import '../../startup_performance.dart';
import 'playing.dart';

class PlayingIntegrationExample {
  
  // Example method to show how to navigate to the now playing screen
  // Call this from your home screen when user taps on a song
  static void navigateToNowPlaying(
    BuildContext context,
    MusicTrack currentTrack,
    List<MusicTrack> playlist,
    String streamUrl,
  ) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => NowPlaying(
          playingSong: currentTrack,
          songs: playlist,
          streamUrl: streamUrl,
        ),
      ),
    );
  }
  
  // Example of how to convert from your viewmodel data to the playing screen
  // You can call this from your home.dart when user taps on a song
  static Future<void> playTrackFromViewmodel(
    BuildContext context,
    MusicTrack track,
    List<MusicTrack> allTracks,
  ) async {
    try {
      // Get stream URL from API
      final api = StartupPerformance.musicAPI;
      final songDetails = await api.getSongDetails(track.videoId);
      
      String? streamUrl;
      if (songDetails['streamingUrls'] != null) {
        final streamingUrls = songDetails['streamingUrls'] as List<Map<String, dynamic>>;
        if (streamingUrls.isNotEmpty) {
          streamUrl = streamingUrls.first['url'] as String;
        }
      }
      
      // Fallback to track URL if API fails
      streamUrl ??= track.url ?? track.extras?['source'] ?? '';
      
      // Ensure the track is in the playlist
      List<MusicTrack> playlist = allTracks;
      if (!playlist.contains(track)) {
        playlist = [track, ...allTracks];
      }
      
      if (streamUrl != null && streamUrl.isNotEmpty) {
        navigateToNowPlaying(context, track, playlist, streamUrl);
      }
    } catch (e) {
      print('Error getting stream URL: $e');
      // Use fallback URL
      final fallbackUrl = track.url ?? track.extras?['source'] ?? '';
      List<MusicTrack> playlist = allTracks;
      if (!playlist.contains(track)) {
        playlist = [track, ...allTracks];
      }
      navigateToNowPlaying(context, track, playlist, fallbackUrl);
    }
  }
}

/*
USAGE EXAMPLE IN YOUR HOME.dart:

In your _playMusic method in home.dart, instead of navigating to NowPlayingModern,
you can navigate to the updated playing screen like this:

void _playMusic(MusicTrack track) async {
  if (!mounted) return;

  if (_isPlayingMusic) return;
  _isPlayingMusic = true;

  try {
    // Use the playing.dart screen with your existing functionality
    PlayingIntegrationExample.playTrackFromViewmodel(
      context,
      track,
      songs, // Your list of songs from viewmodel
    );
  } catch (e) {
    // Handle error
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('Error: $e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  } finally {
    _isPlayingMusic = false;
  }
}

This way you keep all your existing functionality from playing.dart but with the new MusicTrack data model!
*/
