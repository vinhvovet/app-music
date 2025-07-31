/// Efficient JSON navigation helper - Harmony Music approach
class HarmonyResponseParser {
  /// Navigate JSON với error handling
  static dynamic nav(Map<String, dynamic>? root, List<dynamic> path) {
    dynamic current = root;
    for (dynamic key in path) {
      if (current is Map && key is String && current.containsKey(key)) {
        current = current[key];
      } else if (current is List && key is int && key < current.length) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }

  /// Parse search results with optimized extraction
  static List<Map<String, dynamic>> parseSearchResults(Map<String, dynamic> data) {
    final results = <Map<String, dynamic>>[];
    
    try {
      // Navigate to search results
      final sections = nav(data, [
        'contents', 
        'tabbedSearchResultsRenderer', 
        'tabs', 
        0, 
        'tabRenderer', 
        'content', 
        'sectionListRenderer', 
        'contents'
      ]);
      
      if (sections is List) {
        for (var section in sections) {
          final items = nav(section, ['musicShelfRenderer', 'contents']);
          if (items is List) {
            for (var item in items) {
              final track = _parseTrackItem(item);
              if (track != null) {
                results.add(track);
              }
            }
          }
        }
      }
    } catch (e) {
      print('❌ Parse search error: $e');
    }

    return results;
  }

  /// Parse trending results
  static List<Map<String, dynamic>> parseTrendingResults(Map<String, dynamic> data) {
    final results = <Map<String, dynamic>>[];
    
    try {
      final sections = nav(data, [
        'contents', 
        'singleColumnBrowseResultsRenderer', 
        'tabs', 
        0, 
        'tabRenderer', 
        'content', 
        'sectionListRenderer', 
        'contents'
      ]);
      
      if (sections is List) {
        for (var section in sections) {
          // Try different section types
          final items = nav(section, ['musicShelfRenderer', 'contents']) ?? 
                        nav(section, ['musicCarouselShelfRenderer', 'contents']);
          
          if (items is List) {
            for (var item in items) {
              final track = _parseTrackItem(item);
              if (track != null) {
                results.add(track);
              }
            }
          }
        }
      }
    } catch (e) {
      print('❌ Parse trending error: $e');
    }

    return results;
  }

  /// Parse individual track item với optimized data extraction
  static Map<String, dynamic>? _parseTrackItem(Map<String, dynamic> item) {
    try {
      final trackData = item['musicResponsiveListItemRenderer'] ?? 
                       item['musicTwoRowItemRenderer'];
      
      if (trackData == null) return null;

      // Extract video ID (critical for playback)
      final videoId = _extractVideoId(trackData);
      if (videoId == null || videoId.isEmpty) return null;

      // Extract title
      final title = _extractTitle(trackData);
      if (title == null || title.isEmpty) return null;

      // Extract artist
      final artist = _extractArtist(trackData);

      // Extract thumbnail
      final thumbnail = _extractThumbnail(trackData);

      // Extract duration
      final duration = _extractDuration(trackData);

      return {
        'id': videoId,
        'videoId': videoId,
        'title': title,
        'artist': artist,
        'thumbnail': thumbnail,
        'duration': duration,
        'parsedAt': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      print('❌ Parse track item error: $e');
      return null;
    }
  }

  /// Extract video ID với multiple fallback strategies
  static String? _extractVideoId(Map<String, dynamic> trackData) {
    // Strategy 1: From overlay play button
    var videoId = nav(trackData, [
      'overlay', 
      'musicItemThumbnailOverlayRenderer', 
      'content', 
      'musicPlayButtonRenderer', 
      'playNavigationEndpoint', 
      'videoId'
    ]);
    
    if (videoId != null) return videoId;

    // Strategy 2: From navigation endpoint
    videoId = nav(trackData, ['navigationEndpoint', 'watchEndpoint', 'videoId']);
    if (videoId != null) return videoId;

    // Strategy 3: From fixed columns
    videoId = nav(trackData, [
      'flexColumns', 
      0, 
      'musicResponsiveListItemFlexColumnRenderer', 
      'text', 
      'runs', 
      0, 
      'navigationEndpoint', 
      'watchEndpoint', 
      'videoId'
    ]);

    return videoId;
  }

  /// Extract title với fallback strategies
  static String? _extractTitle(Map<String, dynamic> trackData) {
    // Strategy 1: From flex columns
    var title = nav(trackData, [
      'flexColumns', 
      0, 
      'musicResponsiveListItemFlexColumnRenderer', 
      'text', 
      'runs', 
      0, 
      'text'
    ]);
    
    if (title != null && title.toString().isNotEmpty) {
      return _cleanText(title.toString());
    }

    // Strategy 2: From two row renderer
    title = nav(trackData, ['header', 'musicTwoRowItemRenderer', 'title', 'runs', 0, 'text']);
    
    return title != null ? _cleanText(title.toString()) : null;
  }

  /// Extract artist với intelligent parsing
  static String? _extractArtist(Map<String, dynamic> trackData) {
    // Get artist runs from flex columns
    final runs = nav(trackData, [
      'flexColumns', 
      1, 
      'musicResponsiveListItemFlexColumnRenderer', 
      'text', 
      'runs'
    ]);
    
    if (runs is List && runs.isNotEmpty) {
      // Filter out separators and metadata
      final artistTexts = <String>[];
      
      for (var run in runs) {
        final text = run['text']?.toString().trim();
        if (text != null && text.isNotEmpty) {
          // Skip common separators and metadata
          if (!_isMetadata(text)) {
            artistTexts.add(text);
            break; // Take first non-metadata text as artist
          }
        }
      }
      
      if (artistTexts.isNotEmpty) {
        return _cleanText(artistTexts.first);
      }
    }

    // Fallback: Try subtitle
    final subtitle = nav(trackData, ['subtitle', 'runs', 0, 'text']);
    return subtitle != null ? _cleanText(subtitle.toString()) : null;
  }

  /// Extract thumbnail URL
  static String? _extractThumbnail(Map<String, dynamic> trackData) {
    final thumbnails = nav(trackData, [
      'thumbnail', 
      'musicThumbnailRenderer', 
      'thumbnail', 
      'thumbnails'
    ]);
    
    if (thumbnails is List && thumbnails.isNotEmpty) {
      // Get highest quality thumbnail
      final thumbnail = thumbnails.last;
      return thumbnail['url']?.toString();
    }
    
    return null;
  }

  /// Extract duration
  static int? _extractDuration(Map<String, dynamic> trackData) {
    final runs = nav(trackData, [
      'flexColumns', 
      1, 
      'musicResponsiveListItemFlexColumnRenderer', 
      'text', 
      'runs'
    ]);
    
    if (runs is List) {
      for (var run in runs) {
        final text = run['text']?.toString().trim();
        if (text != null && _isDuration(text)) {
          return _parseDuration(text);
        }
      }
    }
    
    return null;
  }

  /// Check if text is metadata (separator, duration, etc.)
  static bool _isMetadata(String text) {
    const separators = [' • ', ' · ', ' | ', '•', '·', '|'];
    const timePattern = r'^\d+:\d+$';
    
    return separators.contains(text) || 
           RegExp(timePattern).hasMatch(text) ||
           text.length < 2;
  }

  /// Check if text is duration format
  static bool _isDuration(String text) {
    return RegExp(r'^\d+:\d+$').hasMatch(text);
  }

  /// Parse duration string to seconds
  static int _parseDuration(String duration) {
    try {
      final parts = duration.split(':');
      if (parts.length == 2) {
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts[1]);
        return minutes * 60 + seconds;
      }
    } catch (e) {
      // Ignore parse errors
    }
    return 0;
  }

  /// Clean text from HTML entities and extra whitespace
  static String _cleanText(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  /// Extract continuation token for pagination
  static String? extractContinuation(Map<String, dynamic> data) {
    return nav(data, [
      'contents',
      'tabbedSearchResultsRenderer',
      'tabs',
      0,
      'tabRenderer',
      'content',
      'sectionListRenderer',
      'continuations',
      0,
      'nextContinuationData',
      'continuation'
    ]);
  }
}
