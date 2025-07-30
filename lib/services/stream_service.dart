import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class StreamProvider {
  final String videoId;
  final bool playable;
  final String? statusMSG;
  final List<AudioStreamInfo> audioStreams;
  
  StreamProvider._({
    required this.videoId,
    required this.playable,
    this.statusMSG,
    required this.audioStreams,
  });
  
  /// Fetch stream data for a video ID
  static Future<StreamProvider> fetch(String videoId) async {
    try {
      final yt = YoutubeExplode();
      
      // Get stream manifest
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly.toList();
      
      yt.close();
      
      return StreamProvider._(
        videoId: videoId,
        playable: audioStreams.isNotEmpty,
        audioStreams: audioStreams,
      );
    } catch (e) {
      printERROR('Error fetching stream: $e');
      return StreamProvider._(
        videoId: videoId,
        playable: false,
        statusMSG: 'Error: $e',
        audioStreams: [],
      );
    }
  }
  
  /// Get highest quality audio stream
  AudioStreamInfo? get highestQualityAudio {
    if (audioStreams.isEmpty) return null;
    
    // Sort by bitrate descending
    final sortedStreams = List<AudioStreamInfo>.from(audioStreams);
    sortedStreams.sort((a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond));
    
    return sortedStreams.first;
  }
  
  /// Get lowest quality audio stream
  AudioStreamInfo? get lowQualityAudio {
    if (audioStreams.isEmpty) return null;
    
    // Sort by bitrate ascending
    final sortedStreams = List<AudioStreamInfo>.from(audioStreams);
    sortedStreams.sort((a, b) => a.bitrate.bitsPerSecond.compareTo(b.bitrate.bitsPerSecond));
    
    return sortedStreams.first;
  }
  
  /// Get medium quality audio stream
  AudioStreamInfo? get mediumQualityAudio {
    if (audioStreams.isEmpty) return null;
    if (audioStreams.length == 1) return audioStreams.first;
    
    // Sort by bitrate and get middle one
    final sortedStreams = List<AudioStreamInfo>.from(audioStreams);
    sortedStreams.sort((a, b) => a.bitrate.bitsPerSecond.compareTo(b.bitrate.bitsPerSecond));
    
    final middleIndex = sortedStreams.length ~/ 2;
    return sortedStreams[middleIndex];
  }
}

void printERROR(String message) {
  print('[ERROR] $message');
}
