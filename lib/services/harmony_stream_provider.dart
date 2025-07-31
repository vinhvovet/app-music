import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:io';
import 'harmony_cache_manager.dart';
import 'harmony_constants.dart';

/// Direct stream access provider - Harmony Music approach
class HarmonyStreamProvider {
  static final HarmonyStreamProvider _instance = HarmonyStreamProvider._internal();
  factory HarmonyStreamProvider() => _instance;
  HarmonyStreamProvider._internal();

  late YoutubeExplode _ytExplode;
  final HarmonyCacheManager _cache = HarmonyCacheManager();
  
  bool _initialized = false;

  /// Initialize stream provider
  Future<void> initialize() async {
    if (_initialized) return;

    _ytExplode = YoutubeExplode();
    _initialized = true;
    
    print('🎵 Harmony Stream Provider ready');
  }

  /// Get direct stream URL với quality options
  Future<String?> getDirectStreamUrl(String videoId, {String quality = 'high'}) async {
    if (!_initialized) await initialize();

    try {
      // Check cache first (ultra-fast: ~10-50ms)
      final cachedUrl = _cache.getCachedStreamUrl(videoId, quality);
      if (cachedUrl != null) {
        return cachedUrl;
      }

      print('🔄 Resolving stream: ${videoId.substring(0, 8)}... ($quality)');
      
      // Get stream manifest
      final manifest = await _ytExplode.videos.streamsClient.getManifest(videoId);
      
      String? selectedUrl;
      
      switch (quality) {
        case 'highest':
          // Best quality available (mp4a 256kbps)
          var audioStream = manifest.audioOnly
              .where((s) => s.codec.mimeType.contains('mp4a'))
              .fold<AudioOnlyStreamInfo?>(null, (best, current) => 
                best == null || current.bitrate.bitsPerSecond > best.bitrate.bitsPerSecond 
                  ? current : best);
          
          selectedUrl = audioStream?.url.toString();
          break;
          
        case 'high':
          // High quality opus (160kbps)
          var audioStream = manifest.audioOnly
              .where((s) => s.codec.mimeType.contains('opus'))
              .where((s) => s.bitrate.bitsPerSecond >= 128000 && s.bitrate.bitsPerSecond <= 192000)
              .fold<AudioOnlyStreamInfo?>(null, (best, current) => 
                best == null || current.bitrate.bitsPerSecond > best.bitrate.bitsPerSecond 
                  ? current : best);
          
          // Fallback to best opus if specific bitrate not found
          audioStream ??= manifest.audioOnly
              .where((s) => s.codec.mimeType.contains('opus'))
              .fold<AudioOnlyStreamInfo?>(null, (best, current) => 
                best == null || current.bitrate.bitsPerSecond > best.bitrate.bitsPerSecond 
                  ? current : best);
          
          selectedUrl = audioStream?.url.toString();
          break;
          
        case 'medium':
          // Medium quality (128kbps)
          var audioStream = manifest.audioOnly
              .where((s) => s.bitrate.bitsPerSecond >= 96000 && s.bitrate.bitsPerSecond <= 160000)
              .fold<AudioOnlyStreamInfo?>(null, (best, current) => 
                best == null || current.bitrate.bitsPerSecond > best.bitrate.bitsPerSecond 
                  ? current : best);
          
          selectedUrl = audioStream?.url.toString();
          break;
          
        case 'low':
          // Low quality for data saving
          var audioStream = manifest.audioOnly
              .fold<AudioOnlyStreamInfo?>(null, (best, current) => 
                best == null || current.bitrate.bitsPerSecond < best.bitrate.bitsPerSecond 
                  ? current : best);
          
          selectedUrl = audioStream?.url.toString();
          break;
      }

      if (selectedUrl != null) {
        // Cache for future use
        await _cache.cacheStreamUrl(videoId, selectedUrl, quality);
        print('✅ Stream resolved: ${videoId.substring(0, 8)}... ($quality)');
        return selectedUrl;
      }

    } catch (e) {
      print('❌ Stream resolution error for $videoId: $e');
    }

    return null;
  }

  /// Batch resolve stream URLs với limited concurrency
  Future<Map<String, String>> batchResolveStreams(List<String> videoIds, {String quality = 'high'}) async {
    if (!_initialized) await initialize();

    final results = <String, String>{};
    final uncachedIds = <String>[];

    // Check cache first for all IDs
    for (final id in videoIds) {
      final cached = _cache.getCachedStreamUrl(id, quality);
      if (cached != null) {
        results[id] = cached;
      } else {
        uncachedIds.add(id);
      }
    }

    print('⚡ Cached streams: ${results.length}, Need resolve: ${uncachedIds.length}');

    if (uncachedIds.isEmpty) return results;

    // Resolve uncached URLs với controlled concurrency
    const batchSize = HarmonyAPIConstants.maxConcurrentRequests;
    
    for (int i = 0; i < uncachedIds.length; i += batchSize) {
      final batch = uncachedIds.skip(i).take(batchSize).toList();
      
      final futures = batch.map((id) => _resolveWithFallback(id, quality));
      final batchResults = await Future.wait(futures);
      
      for (int j = 0; j < batch.length; j++) {
        final url = batchResults[j];
        if (url != null) {
          results[batch[j]] = url;
        }
      }
      
      // Rate limiting between batches
      if (i + batchSize < uncachedIds.length) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    return results;
  }

  /// Resolve stream URL với retry và fallback
  Future<String?> _resolveWithFallback(String videoId, String quality) async {
    // Try multiple qualities as fallback
    final qualities = [quality];
    if (quality != 'medium') qualities.add('medium');
    if (quality != 'low') qualities.add('low');

    for (final q in qualities) {
      try {
        final url = await getDirectStreamUrl(videoId, quality: q);
        if (url != null) return url;
      } catch (e) {
        print('❌ Fallback error for $videoId ($q): $e');
      }
    }

    return null;
  }

  /// Pre-resolve streams for upcoming tracks (background)
  Future<void> preResolveStreams(List<String> videoIds, {String quality = 'high'}) async {
    if (!_initialized) await initialize();

    print('🔄 Pre-resolving ${videoIds.length} streams...');
    
    final uncachedIds = videoIds.where((id) => 
      _cache.getCachedStreamUrl(id, quality) == null
    ).toList();

    if (uncachedIds.isEmpty) {
      print('✅ All streams already cached');
      return;
    }

    // Background resolution với lower priority
    _preResolveInBackground(uncachedIds, quality);
  }

  /// Background pre-resolution
  void _preResolveInBackground(List<String> videoIds, String quality) async {
    const batchSize = 2; // Lower concurrency for background
    
    for (int i = 0; i < videoIds.length; i += batchSize) {
      final batch = videoIds.skip(i).take(batchSize).toList();
      
      final futures = batch.map((id) => getDirectStreamUrl(id, quality: quality));
      await Future.wait(futures);
      
      // Longer delay for background processing
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    print('✅ Background pre-resolve completed');
  }

  /// Get track metadata using YouTube Explode
  Future<Map<String, dynamic>?> getTrackMetadata(String videoId) async {
    if (!_initialized) await initialize();

    try {
      final video = await _ytExplode.videos.get(videoId);
      
      return {
        'id': videoId,
        'title': video.title,
        'artist': video.author,
        'duration': video.duration?.inSeconds,
        'thumbnail': video.thumbnails.highResUrl,
        'description': video.description,
        'viewCount': video.engagement.viewCount,
        'publishDate': video.publishDate?.toIso8601String(),
      };
    } catch (e) {
      print('❌ Metadata error for $videoId: $e');
      return null;
    }
  }

  /// Validate stream URL (quick check)
  Future<bool> validateStreamUrl(String url) async {
    try {
      final request = await HttpClient().headUrl(Uri.parse(url));
      request.headers.set('User-Agent', HarmonyAPIConstants.userAgent);
      final response = await request.close();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get available quality options for a video
  Future<List<String>> getAvailableQualities(String videoId) async {
    if (!_initialized) await initialize();

    try {
      final manifest = await _ytExplode.videos.streamsClient.getManifest(videoId);
      final qualities = <String>[];
      
      // Check for different quality levels
      final streams = manifest.audioOnly;
      
      if (streams.any((s) => s.codec.mimeType.contains('mp4a'))) {
        qualities.add('highest');
      }
      if (streams.any((s) => s.bitrate.bitsPerSecond >= 128000)) {
        qualities.add('high');
      }
      if (streams.any((s) => s.bitrate.bitsPerSecond >= 96000)) {
        qualities.add('medium');
      }
      if (streams.isNotEmpty) {
        qualities.add('low');
      }
      
      return qualities;
    } catch (e) {
      print('❌ Quality check error for $videoId: $e');
      return ['medium']; // Default fallback
    }
  }

  /// Dispose resources
  void dispose() {
    _ytExplode.close();
  }
}
