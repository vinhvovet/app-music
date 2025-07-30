import 'package:dio/dio.dart';
import 'constant.dart';
import 'nav_parser.dart';

class MusicServices {
  late Dio _dio;
  bool _initialized = false;
  
  /// Initialize the service
  Future<void> init() async {
    if (_initialized) return;
    
    try {
      _dio = Dio(BaseOptions(
        baseUrl: Constants.apiUrl,
        headers: Constants.headers,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      
      // Add logging interceptor for debugging
      _dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (obj) => printDEBUG(obj.toString()),
      ));
      
      _initialized = true;
      printINFO('MusicServices initialized successfully');
    } catch (e) {
      printERROR('Failed to initialize MusicServices: $e');
      rethrow;
    }
  }
  
  /// Search for music
  Future<Map<String, dynamic>> search(
    String query, {
    String? filter,
    int limit = 20,
  }) async {
    if (!_initialized) await init();
    
    try {
      printINFO('Searching for: "$query" with filter: ${filter ?? "none"}');
      
      final context = {
        'client': {
          'clientName': Constants.clientName,
          'clientVersion': Constants.clientVersion,
        }
      };
      
      final params = filter != null ? Constants.searchFilters[filter] : null;
      
      final requestBody = {
        'context': context,
        'query': query,
        'params': params,
      };
      
      final response = await _dio.post(
        Constants.searchEndpoint,
        data: requestBody,
        queryParameters: {'key': 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30'},
      );
      
      printDEBUG('Search response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        if (response.data == null) {
          printERROR('Search response data is null');
          return {};
        }
        
        printDEBUG('Search response received, parsing...');
        final result = _parseSearchResponse(response.data, filter ?? 'songs', limit);
        printINFO('Search completed: ${result['Songs']?.length ?? 0} songs found');
        return result;
      } else {
        printERROR('Search failed with status: ${response.statusCode}');
        printERROR('Response: ${response.data}');
        return {};
      }
    } catch (e) {
      printERROR('Search error for query "$query": $e');
      if (e.toString().contains('DioException')) {
        printERROR('Network error - check internet connection');
      }
      return {};
    }
  }
  
  /// Get search suggestions
  Future<List<String>> getSearchSuggestion(String query) async {
    if (!_initialized) await init();
    
    try {
      final response = await _dio.get(
        'https://music.youtube.com/youtubei/v1/music/get_search_suggestions',
        queryParameters: {
          'input': query,
          'key': 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30',
        },
      );
      
      if (response.statusCode == 200) {
        final suggestions = <String>[];
        final contents = response.data['contents'];
        
        if (contents != null) {
          for (var item in contents) {
            final text = item['searchSuggestionsSectionRenderer']
                ?['contents']?[0]?['searchSuggestionRenderer']
                ?['suggestion']?['runs']?[0]?['text'];
            if (text != null) {
              suggestions.add(text);
            }
          }
        }
        
        return suggestions;
      }
      
      return [];
    } catch (e) {
      printERROR('Get suggestions error: $e');
      return [];
    }
  }
  
  /// Get home content
  Future<List<Map<String, dynamic>>> getHome({int limit = 4}) async {
    if (!_initialized) await init();
    
    try {
      final context = {
        'client': {
          'clientName': Constants.clientName,
          'clientVersion': Constants.clientVersion,
        }
      };
      
      final requestBody = {
        'context': context,
        'browseId': 'FEmusic_home',
      };
      
      final response = await _dio.post(
        Constants.browseEndpoint,
        data: requestBody,
        queryParameters: {'key': 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30'},
      );
      
      if (response.statusCode == 200) {
        final sections = NavParser.parseHomeContent(response.data);
        return sections.take(limit).toList();
      }
      
      return [];
    } catch (e) {
      printERROR('Get home error: $e');
      return [];
    }
  }
  
  /// Get charts
  Future<List<Map<String, dynamic>>> getCharts({String? countryCode}) async {
    if (!_initialized) await init();
    
    try {
      final context = {
        'client': {
          'clientName': Constants.clientName,
          'clientVersion': Constants.clientVersion,
        }
      };
      
      final requestBody = {
        'context': context,
        'browseId': 'FEmusic_charts',
      };
      
      final response = await _dio.post(
        Constants.browseEndpoint,
        data: requestBody,
        queryParameters: {'key': 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30'},
      );
      
      if (response.statusCode == 200) {
        // Parse charts response
        return [];
      }
      
      return [];
    } catch (e) {
      printERROR('Get charts error: $e');
      return [];
    }
  }
  
  /// Get watch playlist (queue)
  Future<Map<String, dynamic>> getWatchPlaylist({
    required String videoId,
    String? playlistId,
    int limit = 25,
    bool radio = false,
    bool shuffle = false,
  }) async {
    if (!_initialized) await init();
    
    try {
      final context = {
        'client': {
          'clientName': Constants.clientName,
          'clientVersion': Constants.clientVersion,
        }
      };
      
      final requestBody = {
        'context': context,
        'videoId': videoId,
        'playlistId': playlistId,
        'isAudioOnly': true,
      };
      
      final response = await _dio.post(
        Constants.nextEndpoint,
        data: requestBody,
        queryParameters: {'key': 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30'},
      );
      
      if (response.statusCode == 200) {
        // Parse playlist response
        return {};
      }
      
      return {};
    } catch (e) {
      printERROR('Get watch playlist error: $e');
      return {};
    }
  }
  
  /// Get song with ID
  Future<Map<String, dynamic>?> getSongWithId(String songId) async {
    return await search(songId).then((results) {
      if (results.containsKey('Songs') && results['Songs'].isNotEmpty) {
        return results['Songs'][0];
      }
      return null;
    });
  }
  
  /// Get lyrics
  Future<String?> getLyrics(String browseId) async {
    if (!_initialized) await init();
    
    try {
      final context = {
        'client': {
          'clientName': Constants.clientName,
          'clientVersion': Constants.clientVersion,
        }
      };
      
      final requestBody = {
        'context': context,
        'browseId': browseId,
      };
      
      final response = await _dio.post(
        Constants.browseEndpoint,
        data: requestBody,
        queryParameters: {'key': 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30'},
      );
      
      if (response.statusCode == 200) {
        // Parse lyrics from response
        final contents = response.data['contents']?['sectionListRenderer']
            ?['contents']?[0]?['musicDescriptionShelfRenderer']
            ?['description']?['runs'];
            
        if (contents != null) {
          final lyrics = StringBuffer();
          for (var run in contents) {
            lyrics.write(run['text'] ?? '');
          }
          return lyrics.toString();
        }
      }
      
      return null;
    } catch (e) {
      printERROR('Get lyrics error: $e');
      return null;
    }
  }
  
  /// Parse search response
  Map<String, dynamic> _parseSearchResponse(
    Map<String, dynamic> data,
    String filter,
    int limit,
  ) {
    try {
      final results = <String, List<Map<String, dynamic>>>{};
      
      if (filter == 'songs') {
        final songItems = NavParser.parseSearchResults(data, 'songs');
        final songs = <Map<String, dynamic>>[];
        
        printDEBUG('Found ${songItems.length} raw search items');
        
        for (var item in songItems.take(limit)) {
          final song = NavParser.parseSongItem(item);
          if (song != null) {
            songs.add(song);
            printDEBUG('Parsed song: ${song['title']} by ${song['artist']}');
          } else {
            printDEBUG('Failed to parse item: ${item.toString().substring(0, 100)}...');
          }
        }
        
        printINFO('Successfully parsed ${songs.length} songs from ${songItems.length} items');
        results['Songs'] = songs;
      }
      
      return results;
    } catch (e) {
      printERROR('Parse search response error: $e');
      printERROR('Response structure: ${data.keys.toList()}');
      return {};
    }
  }
  
  /// Dispose resources
  void dispose() {
    _dio.close();
    _initialized = false;
    printINFO('MusicServices disposed');
  }
}

void printINFO(String message) {
  print('[INFO] $message');
}

void printERROR(String message) {
  print('[ERROR] $message');
}

void printDEBUG(String message) {
  print('[DEBUG] $message');
}
