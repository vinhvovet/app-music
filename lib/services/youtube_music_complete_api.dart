import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeMusicCompleteAPI {
  late Dio _dio;
  bool _initialized = false;
  final YoutubeExplode _youtube = YoutubeExplode();
  
  // YouTube Music API constants
  static const String _baseUrl = 'https://music.youtube.com/youtubei/v1';
  static const String _apiKey = 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30';
  static const String _clientName = 'WEB_REMIX';
  static const String _clientVersion = '1.20241028.01.00';
  
  /// Initialize the API
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _dio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));
      
      // Add default headers
      _dio.options.headers.addAll({
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': '*/*',
        'Accept-Language': 'en-US,en;q=0.9',
        'X-Goog-Api-Key': _apiKey,
        'Origin': 'https://music.youtube.com',
        'Referer': 'https://music.youtube.com/',
      });
      
      // Add logging interceptor
      _dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (obj) => print('[YT Music API] $obj'),
      ));
      
      _initialized = true;
      print('[YouTubeMusicCompleteAPI] ✅ Initialized successfully');
    } catch (e) {
      print('[YouTubeMusicCompleteAPI] ❌ Initialization failed: $e');
      rethrow;
    }
  }

  /// Build context for requests
  Map<String, dynamic> _buildContext() {
    return {
      'context': {
        'client': {
          'clientName': _clientName,
          'clientVersion': _clientVersion,
          'hl': 'en',
          'gl': 'US',
        },
        'user': {
          'lockedSafetyMode': false,
        },
      },
    };
  }

  /// Search for music
  Future<Map<String, dynamic>> searchMusic(String query, {String filter = 'songs'}) async {
    if (!_initialized) await initialize();
    
    try {
      print('[YouTubeMusicCompleteAPI] Searching for: "$query" with filter: $filter');
      
      final requestBody = _buildContext();
      requestBody['query'] = query;
      
      // Add search filter params
      final filterParams = {
        'songs': 'EgWKAQIIAWoKEAoQAxAEEAkQBQ%3D%3D',
        'videos': 'EgWKAQIQAWoKEAoQAxAEEAkQBQ%3D%3D',
        'albums': 'EgWKAQIYAWoKEAoQAxAEEAkQBQ%3D%3D',
        'artists': 'EgWKAQIgAWoKEAoQAxAEEAkQBQ%3D%3D',
        'playlists': 'EgWKAQIoAWoKEAoQAxAEEAkQBQ%3D%3D',
      };
      
      if (filterParams.containsKey(filter)) {
        requestBody['params'] = filterParams[filter];
      }
      
      final response = await _dio.post(
        '/search',
        queryParameters: {'key': _apiKey},
        data: requestBody,
      );
      
      if (response.statusCode == 200) {
        final results = _parseSearchResults(response.data, filter);
        print('[YouTubeMusicCompleteAPI] Found ${results['songs']?.length ?? 0} songs');
        return results;
      } else {
        throw Exception('Search failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('[YouTubeMusicCompleteAPI] Search error: $e');
      return {'songs': [], 'error': e.toString()};
    }
  }

  /// Parse search results
  Map<String, dynamic> _parseSearchResults(Map<String, dynamic> data, String filter) {
    try {
      final songs = <Map<String, dynamic>>[];
      
      // Navigate through the complex YouTube Music response structure
      final contents = data['contents']?['tabbedSearchResultsRenderer']?['tabs'];
      print('[YouTubeMusicCompleteAPI] 🔍 Contents available: ${contents != null}');
      print('[YouTubeMusicCompleteAPI] 🔍 Contents length: ${contents?.length}');
      
      if (contents != null) {
        for (int tabIndex = 0; tabIndex < contents.length; tabIndex++) {
          final tab = contents[tabIndex];
          print('[YouTubeMusicCompleteAPI] 🔍 Tab $tabIndex keys: ${tab.keys.toList()}');
          
          final tabRenderer = tab['tabRenderer'];
          if (tabRenderer != null) {
            print('[YouTubeMusicCompleteAPI] 🔍 TabRenderer keys: ${tabRenderer.keys.toList()}');
            
            final sectionList = tabRenderer['content']?['sectionListRenderer']?['contents'];
            print('[YouTubeMusicCompleteAPI] 🔍 SectionList available: ${sectionList != null}');
            print('[YouTubeMusicCompleteAPI] 🔍 SectionList length: ${sectionList?.length}');
            
            if (sectionList != null) {
              for (int sectionIndex = 0; sectionIndex < sectionList.length; sectionIndex++) {
                final section = sectionList[sectionIndex];
                print('[YouTubeMusicCompleteAPI] 🔍 Section $sectionIndex keys: ${section.keys.toList()}');
                
                final musicShelf = section['musicShelfRenderer'];
                if (musicShelf != null) {
                  print('[YouTubeMusicCompleteAPI] 🔍 Found musicShelfRenderer');
                  final items = musicShelf['contents'];
                  print('[YouTubeMusicCompleteAPI] 🔍 MusicShelf items: ${items?.length}');
                  if (items != null) {
                    for (int itemIndex = 0; itemIndex < items.length; itemIndex++) {
                      final item = items[itemIndex];
                      print('[YouTubeMusicCompleteAPI] 🔍 Item $itemIndex keys: ${item.keys.toList()}');
                      final songData = _parseSongItem(item);
                      if (songData != null) {
                        songs.add(songData);
                      }
                    }
                  }
                }
                
                // Also check musicResponsiveListRenderer
                final musicList = section['musicResponsiveListRenderer'];
                if (musicList != null) {
                  print('[YouTubeMusicCompleteAPI] 🔍 Found musicResponsiveListRenderer');
                  final items = musicList['contents'];
                  print('[YouTubeMusicCompleteAPI] 🔍 MusicList items: ${items?.length}');
                  if (items != null) {
                    for (int itemIndex = 0; itemIndex < items.length; itemIndex++) {
                      final item = items[itemIndex];
                      print('[YouTubeMusicCompleteAPI] 🔍 List Item $itemIndex keys: ${item.keys.toList()}');
                      final songData = _parseSongItem(item);
                      if (songData != null) {
                        songs.add(songData);
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      
      return {'songs': songs};
    } catch (e) {
      print('[YouTubeMusicCompleteAPI] Parse error: $e');
      return {'songs': []};
    }
  }

  /// Parse individual song item
  Map<String, dynamic>? _parseSongItem(Map<String, dynamic> item) {
    try {
      final itemRenderer = item['musicResponsiveListItemRenderer'] ?? 
                          item['musicTwoRowItemRenderer'];
      
      if (itemRenderer == null) return null;
      
      // Extract video ID
      String? videoId;
      final overlay = itemRenderer['overlay']?['musicItemThumbnailOverlayRenderer']
          ?['content']?['musicPlayButtonRenderer']?['playNavigationEndpoint'];
      videoId = overlay?['watchEndpoint']?['videoId'];
      
      if (videoId == null) {
        final navigationEndpoint = itemRenderer['navigationEndpoint'];
        videoId = navigationEndpoint?['watchEndpoint']?['videoId'];
      }
      
      if (videoId == null) return null;
      
      print('[YouTubeMusicCompleteAPI] 🎵 Parsing song with videoId: $videoId');
      
      // Extract title and artist
      String? title, artist;
      final flexColumns = itemRenderer['flexColumns'];
      
      print('[YouTubeMusicCompleteAPI] 📊 FlexColumns available: ${flexColumns != null}');
      if (flexColumns != null) {
        print('[YouTubeMusicCompleteAPI] 📊 FlexColumns length: ${flexColumns.length}');
      }
      
      if (flexColumns != null && flexColumns.isNotEmpty) {
        // Title is usually in the first column
        final firstColumn = flexColumns[0];
        print('[YouTubeMusicCompleteAPI] 📊 First column keys: ${firstColumn.keys.toList()}');
        
        final titleRenderer = firstColumn['musicResponsiveListItemFlexColumnRenderer'];
        if (titleRenderer != null) {
          print('[YouTubeMusicCompleteAPI] 📊 Title renderer keys: ${titleRenderer.keys.toList()}');
          final titleRuns = titleRenderer['text']?['runs'];
          if (titleRuns != null && titleRuns.isNotEmpty) {
            title = titleRuns[0]['text'];
            print('[YouTubeMusicCompleteAPI] 📝 Raw title: "$title"');
            // Decode HTML entities if present
            if (title != null) {
              title = _decodeHtmlEntities(title);
              print('[YouTubeMusicCompleteAPI] 📝 Decoded title: "$title"');
            }
          }
        }
        
        // Artist is usually in the second column
        if (flexColumns.length > 1) {
          final secondColumn = flexColumns[1];
          print('[YouTubeMusicCompleteAPI] 📊 Second column keys: ${secondColumn.keys.toList()}');
          
          final artistRenderer = secondColumn['musicResponsiveListItemFlexColumnRenderer'];
          if (artistRenderer != null) {
            print('[YouTubeMusicCompleteAPI] 📊 Artist renderer keys: ${artistRenderer.keys.toList()}');
            final artistRuns = artistRenderer['text']?['runs'];
            if (artistRuns != null) {
              print('[YouTubeMusicCompleteAPI] 📊 Artist runs count: ${artistRuns.length}');
              // Try to find the artist name
              final artistTexts = <String>[];
              for (int i = 0; i < artistRuns.length; i++) {
                final run = artistRuns[i];
                final text = run['text'];
                print('[YouTubeMusicCompleteAPI] 📊 Run $i text: "$text"');
                if (text != null && text.trim().isNotEmpty) {
                  final cleanText = text.trim();
                  if (cleanText != '•' && cleanText != 'Song' && cleanText != 'Video' && 
                      cleanText != 'Album' && cleanText != 'Playlist' && 
                      cleanText != ' • ' && cleanText != ' · ' && cleanText != ', ') {
                    artistTexts.add(_decodeHtmlEntities(cleanText));
                  }
                }
              }
              
              print('[YouTubeMusicCompleteAPI] 👤 Found artist texts: $artistTexts');
              // Take the first meaningful text as artist name
              if (artistTexts.isNotEmpty) {
                artist = artistTexts.first;
                print('[YouTubeMusicCompleteAPI] 👤 Final artist: "$artist"');
              }
            }
          }
        }
      }
      
      // Extract thumbnail
      String? thumbnail;
      final thumbnails = itemRenderer['thumbnail']?['musicThumbnailRenderer']
          ?['thumbnail']?['thumbnails'];
      if (thumbnails != null && thumbnails.isNotEmpty) {
        thumbnail = thumbnails.last['url'];
      }
      
      return {
        'videoId': videoId,
        'title': title?.trim().isNotEmpty == true ? title!.trim() : null,
        'artist': artist?.trim().isNotEmpty == true ? artist!.trim() : null,
        'thumbnail': thumbnail,
        'duration': null,
      };
    } catch (e) {
      print('[YouTubeMusicCompleteAPI] Parse song item error: $e');
      return null;
    }
  }

  /// Get detailed song information including streaming URLs
  Future<Map<String, dynamic>> getSongDetails(String videoId) async {
    try {
      print('[YouTubeMusicCompleteAPI] Getting details for video: $videoId');
      
      // Use youtube_explode_dart to get streaming URLs
      final video = await _youtube.videos.get(videoId);
      final manifest = await _youtube.videos.streamsClient.getManifest(videoId);
      
      // Get audio streams
      final audioStreams = manifest.audioOnly.toList();
      final streamingUrls = <Map<String, dynamic>>[];
      
      for (final stream in audioStreams) {
        streamingUrls.add({
          'url': stream.url.toString(),
          'bitrate': stream.bitrate.bitsPerSecond,
          'container': stream.container.name,
          'quality': _getQualityLabel(stream.bitrate.bitsPerSecond),
        });
      }
      
      // Sort by quality (highest first)
      streamingUrls.sort((a, b) => b['bitrate'].compareTo(a['bitrate']));
      
      return {
        'videoId': videoId,
        'title': video.title,
        'artist': video.author,
        'duration': video.duration?.inSeconds,
        'thumbnail': video.thumbnails.highResUrl,
        'description': video.description,
        'streamingUrls': streamingUrls,
        'highestQualityUrl': streamingUrls.isNotEmpty ? streamingUrls.first['url'] : null,
        'lowestQualityUrl': streamingUrls.isNotEmpty ? streamingUrls.last['url'] : null,
      };
    } catch (e) {
      print('[YouTubeMusicCompleteAPI] Get song details error: $e');
      
      // 🔄 Fallback: Try to get basic video info without streams
      try {
        final video = await _youtube.videos.get(videoId);
        print('[YouTubeMusicCompleteAPI] Fallback: Got basic video info');
        
        return {
          'videoId': videoId,
          'title': video.title,
          'artist': video.author,
          'duration': video.duration?.inSeconds,
          'thumbnail': video.thumbnails.highResUrl,
          'description': video.description,
          'streamingUrls': [],
          'error': 'Streams not available: ${e.toString()}',
          'fallback': true,
        };
      } catch (fallbackError) {
        print('[YouTubeMusicCompleteAPI] Fallback also failed: $fallbackError');
        
        return {
          'videoId': videoId,
          'error': e.toString(),
          'streamingUrls': [],
          'title': 'Unknown Title',
          'artist': 'Unknown Artist',
        };
      }
    }
  }

  /// Get quality label from bitrate
  String _getQualityLabel(int bitrate) {
    if (bitrate >= 320000) return 'High (320kbps+)';
    if (bitrate >= 256000) return 'Medium (256kbps)';
    if (bitrate >= 128000) return 'Standard (128kbps)';
    return 'Low (<128kbps)';
  }

  /// Get music charts
  Future<Map<String, dynamic>> getCharts({String countryCode = 'US'}) async {
    if (!_initialized) await initialize();
    
    try {
      print('[YouTubeMusicCompleteAPI] Getting charts for: $countryCode');
      
      final requestBody = _buildContext();
      requestBody['browseId'] = 'FEmusic_charts';
      
      final response = await _dio.post(
        '/browse',
        queryParameters: {'key': _apiKey},
        data: requestBody,
      );
      
      if (response.statusCode == 200) {
        // Parse charts response (simplified for now)
        return {
          'countryCode': countryCode,
          'charts': [],
          'message': 'Charts data available but parsing not implemented yet',
        };
      } else {
        throw Exception('Charts request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('[YouTubeMusicCompleteAPI] Get charts error: $e');
      return {'charts': [], 'error': e.toString()};
    }
  }

  /// Get artist information
  Future<Map<String, dynamic>> getArtist(String browseId) async {
    if (!_initialized) await initialize();
    
    try {
      print('[YouTubeMusicCompleteAPI] Getting artist: $browseId');
      
      final requestBody = _buildContext();
      requestBody['browseId'] = browseId;
      
      final response = await _dio.post(
        '/browse',
        queryParameters: {'key': _apiKey},
        data: requestBody,
      );
      
      if (response.statusCode == 200) {
        // Parse artist response (simplified for now)
        return {
          'browseId': browseId,
          'artist': {},
          'message': 'Artist data available but parsing not implemented yet',
        };
      } else {
        throw Exception('Artist request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('[YouTubeMusicCompleteAPI] Get artist error: $e');
      return {'artist': {}, 'error': e.toString()};
    }
  }

  /// Get popular songs from different regions/genres
  Future<List<Map<String, dynamic>>> getPopularSongs({int limit = 20}) async {
    try {
      final popularQueries = [
        'trending music 2024',
        'top hits',
        'viral songs', 
        'popular music',
        'chart toppers',
        'new songs 2024',
        'latest hits',
        'top 50 songs',
        'billboard hits',
        'spotify top',
      ];
      
      final allSongs = <Map<String, dynamic>>[];
      
      // Lấy từ nhiều queries hơn để có đủ 50 bài
      final numQueries = (limit / 10).ceil().clamp(2, popularQueries.length);
      final songsPerQuery = (limit / numQueries).ceil();
      
      for (final query in popularQueries.take(numQueries)) {
        try {
          final results = await searchMusic(query, filter: 'songs');
          if (results['songs'] != null) {
            final songs = results['songs'] as List<Map<String, dynamic>>;
            allSongs.addAll(songs.take(songsPerQuery));
            print('[YouTubeMusicCompleteAPI] Added ${songs.take(songsPerQuery).length} songs from "$query"');
          }
          
          // Add delay to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          print('[YouTubeMusicCompleteAPI] Error with query "$query": $e');
          continue;
        }
      }
      
      // Remove duplicates by videoId
      final uniqueSongs = <String, Map<String, dynamic>>{};
      for (final song in allSongs) {
        final videoId = song['videoId'];
        if (videoId != null && !uniqueSongs.containsKey(videoId)) {
          uniqueSongs[videoId] = song;
        }
      }
      
      final finalSongs = uniqueSongs.values.take(limit).toList();
      print('[YouTubeMusicCompleteAPI] Returning ${finalSongs.length} unique popular songs');
      return finalSongs;
    } catch (e) {
      print('[YouTubeMusicCompleteAPI] Get popular songs error: $e');
      return [];
    }
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
    _youtube.close();
    _initialized = false;
    print('[YouTubeMusicCompleteAPI] Disposed');
  }

  /// Decode HTML entities in text
  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('%20', ' ')
        .replaceAll('%27', "'")
        .replaceAll('%22', '"')
        .replaceAll('%26', '&');
  }
}
