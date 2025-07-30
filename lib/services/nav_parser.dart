class NavParser {
  /// Parse navigation data from YouTube Music response
  static List<dynamic> parseSearchResults(Map<String, dynamic> data, String resultType) {
    try {
      // First check the direct path for search results
      final contents = data['contents']?['tabbedSearchResultsRenderer']?['tabs'];
      if (contents != null) {
        for (var tab in contents) {
          final tabRenderer = tab['tabRenderer'];
          if (tabRenderer != null) {
            final sectionList = tabRenderer['content']?['sectionListRenderer']?['contents'];
            if (sectionList != null && sectionList.isNotEmpty) {
              final musicResponsiveList = sectionList[0]?['musicResponsiveListRenderer']?['contents'];
              if (musicResponsiveList != null) {
                return musicResponsiveList;
              }
            }
          }
        }
      }
      
      // Alternative path for different response structures
      final singleColumn = data['contents']?['singleColumnSearchResultsRenderer']?['tabs'];
      if (singleColumn != null) {
        for (var tab in singleColumn) {
          final sectionList = tab['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
          if (sectionList != null) {
            for (var section in sectionList) {
              final musicShelf = section['musicShelfRenderer']?['contents'];
              if (musicShelf != null) {
                return musicShelf;
              }
            }
          }
        }
      }
      
      return [];
    } catch (e) {
      printERROR('Error parsing search results: $e');
      return [];
    }
  }
  
  /// Extract song data from search result item
  static Map<String, dynamic>? parseSongItem(Map<String, dynamic> item) {
    try {
      // Handle both musicResponsiveListItemRenderer and musicTwoRowItemRenderer
      final itemRenderer = item['musicResponsiveListItemRenderer'] ?? item['musicTwoRowItemRenderer'];
      if (itemRenderer == null) return null;
      
      // Get video ID from various endpoints
      String? videoId;
      
      // Try overlay endpoint first
      final playNavigationEndpoint = itemRenderer['overlay']?['musicItemThumbnailOverlayRenderer']
          ?['content']?['musicPlayButtonRenderer']?['playNavigationEndpoint'];
      videoId = playNavigationEndpoint?['watchEndpoint']?['videoId'];
      
      // Try navigation endpoint
      if (videoId == null) {
        videoId = itemRenderer['navigationEndpoint']?['watchEndpoint']?['videoId'];
      }
      
      // Try flex columns for videoId
      if (videoId == null) {
        final flexColumns = itemRenderer['flexColumns'];
        if (flexColumns != null) {
          for (var column in flexColumns) {
            final navEndpoint = column['musicResponsiveListItemColumnRenderer']
                ?['text']?['runs']?[0]?['navigationEndpoint'];
            if (navEndpoint != null) {
              videoId = navEndpoint['watchEndpoint']?['videoId'];
              if (videoId != null) break;
            }
          }
        }
      }
      
      if (videoId == null) return null;
      
      // Parse title and artist
      String? title, artist, album;
      String? thumbnailUrl;
      
      final flexColumns = itemRenderer['flexColumns'];
      if (flexColumns != null) {
        // Get title (usually first column)
        if (flexColumns.length > 0) {
          final titleRuns = flexColumns[0]?['musicResponsiveListItemColumnRenderer']
              ?['text']?['runs'];
          if (titleRuns != null && titleRuns.isNotEmpty) {
            title = titleRuns[0]['text'];
          }
        }
        
        // Get artist and other info (usually second column)
        if (flexColumns.length > 1) {
          final secondColumnRuns = flexColumns[1]?['musicResponsiveListItemColumnRenderer']
              ?['text']?['runs'];
          if (secondColumnRuns != null) {
            // Parse artist from runs, skipping separators
            for (var run in secondColumnRuns) {
              final text = run['text'];
              if (text != ' • ' && text != 'Song' && text != 'Video' && !text.startsWith('Album')) {
                if (run['navigationEndpoint']?['browseEndpoint'] != null) {
                  artist ??= text; // This is likely the artist
                  break;
                }
              }
            }
            
            // If no artist found, use first non-separator text
            if (artist == null) {
              for (var run in secondColumnRuns) {
                final text = run['text'];
                if (text != ' • ' && text != 'Song' && text != 'Video' && text.trim().isNotEmpty) {
                  artist = text;
                  break;
                }
              }
            }
          }
        }
      }
      
      // Get thumbnail
      final thumbnails = itemRenderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'];
      if (thumbnails != null && thumbnails.isNotEmpty) {
        // Use highest quality thumbnail
        thumbnailUrl = thumbnails.last['url'];
      }
      
      return {
        'videoId': videoId,
        'title': title?.trim().isNotEmpty == true ? title!.trim() : null,
        'artist': artist ?? 'Unknown Artist',
        'album': album,
        'thumbnail': thumbnailUrl,
        'duration': null, // Will be filled by stream service
      };
    } catch (e) {
      printERROR('Error parsing song item: $e');
      printERROR('Item data: $item'); // Debug info
      return null;
    }
  }
  
  /// Parse home content sections
  static List<Map<String, dynamic>> parseHomeContent(Map<String, dynamic> data) {
    try {
      final sections = <Map<String, dynamic>>[];
      final contents = data['contents']?['singleColumnBrowseResultsRenderer']
          ?['tabs']?[0]?['tabRenderer']?['content']
          ?['sectionListRenderer']?['contents'];
          
      if (contents == null) return sections;
      
      for (var section in contents) {
        final sectionData = _parseSection(section);
        if (sectionData != null) {
          sections.add(sectionData);
        }
      }
      
      return sections;
    } catch (e) {
      printERROR('Error parsing home content: $e');
      return [];
    }
  }
  
  static Map<String, dynamic>? _parseSection(Map<String, dynamic> section) {
    try {
      final musicCarouselShelf = section['musicCarouselShelfRenderer'];
      if (musicCarouselShelf == null) return null;
      
      final header = musicCarouselShelf['header']?['musicCarouselShelfBasicHeaderRenderer']?['title']?['runs']?[0]?['text'];
      final contents = musicCarouselShelf['contents'];
      
      if (header == null || contents == null) return null;
      
      final items = <Map<String, dynamic>>[];
      for (var item in contents) {
        final parsedItem = _parseCarouselItem(item);
        if (parsedItem != null) {
          items.add(parsedItem);
        }
      }
      
      return {
        'title': header,
        'items': items,
      };
    } catch (e) {
      printERROR('Error parsing section: $e');
      return null;
    }
  }
  
  static Map<String, dynamic>? _parseCarouselItem(Map<String, dynamic> item) {
    // This would parse individual items in carousels (songs, albums, playlists)
    // Implementation depends on the specific item type
    return null;
  }
}

void printERROR(String message) {
  print('[ERROR] $message');
}
