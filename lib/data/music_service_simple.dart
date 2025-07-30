// ignore_for_file: constant_identifier_names
import 'dart:convert';
import 'package:dio/dio.dart';
import 'helper.dart';
import 'constant.dart';

enum AudioQuality {
  Low,
  High,
}

class MusicServices {
  final Map<String, String> _headers = {
    'user-agent': userAgent,
    'accept': '*/*',
    'accept-encoding': 'gzip, deflate',
    'content-type': 'application/json',
    'content-encoding': 'gzip',
    'origin': domain,
    'cookie': 'CONSENT=YES+1',
  };

  final Map<String, dynamic> _context = {
    'context': {
      'client': {
        "clientName": "WEB_REMIX",
        "clientVersion": "1.20230213.01.00",
      },
      'user': {}
    }
  };

  final dio = Dio();

  Future<void> init() async {
    // Check visitor id in data base, if not generate one, set lang code
    final date = DateTime.now();
    _context['context']['client']['clientVersion'] =
        "1.${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}.01.00";   
    final signatureTimestamp = getDatestamp() - 1;
    _context['playbackContext'] = {
      'contentPlaybackContext': {'signatureTimestamp': signatureTimestamp},
    };
    // Set default language
    hlCode = "en";
    final visitorId = await _genrateVisitorId();
    if (visitorId != null) {
      _headers['X-Goog-Visitor-Id'] = visitorId;
      printINFO("New Visitor id generated ($visitorId)");
    } else {
      // Fallback visitor ID
      _headers['X-Goog-Visitor-Id'] = generateVisitorId();
    }
  }

  set hlCode(String code) {
    _context['context']['client']['hl'] = code;
  }

  Future<String?> _genrateVisitorId() async {
    try {
      final response =
          await dio.get(domain, options: Options(headers: _headers));
      final reg = RegExp(r'ytcfg\.set\s*\(\s*({.+?})\s*\)\s*;');
      final matches = reg.firstMatch(response.data.toString());
      String? visitorId;
      if (matches != null) {
        final ytcfg = json.decode(matches.group(1).toString());
        visitorId = ytcfg['VISITOR_DATA']?.toString();
      }
      return visitorId;
    } catch (e) {
      return null;
    }
  }

  Future<Response> _sendRequest(String action, Map<dynamic, dynamic> data,
      {additionalParams = ""}) async {
    try {
      final response =
          await dio.post("$baseUrl$action$fixedParms$additionalParams",
              options: Options(
                headers: _headers,
              ),
              data: data);
      if (response.statusCode == 200) {
        return response;
      } else {
        return _sendRequest(action, data, additionalParams: additionalParams);
      }
    } on DioException catch (e) {
      printINFO("Error $e");
      throw NetworkError();
    }
  }

  /// Get home page content
  Future<dynamic> getHome({int limit = 4}) async {
    try {
      final data = Map.from(_context);
      data["browseId"] = "FEmusic_home";
      final response = await _sendRequest("browse", data);
      // Simplified response for demo
      return [];
    } catch (e) {
      printERROR("Error getting home: $e");
      return [];
    }
  }

  /// Get music charts
  Future<List<Map<String, dynamic>>> getCharts({String? countryCode}) async {
    try {
      final data = Map.from(_context);
      data['browseId'] = 'FEmusic_charts';
      if (countryCode != null) {
        data['formData'] = {
          'selectedValues': [countryCode]
        };
      }
      final response = await _sendRequest('browse', data);
      // Simplified response for demo
      return [];
    } catch (e) {
      printERROR("Error getting charts: $e");
      return [];
    }
  }

  /// Get watch playlist/queue for a song
  Future<Map<String, dynamic>> getWatchPlaylist(
      {String videoId = "",
      String? playlistId,
      int limit = 25,
      bool radio = false,
      bool shuffle = false,
      String? additionalParamsNext,
      bool onlyRelated = false}) async {
    try {
      if (videoId.isNotEmpty && videoId.substring(0, 4) == "MPED") {
        videoId = videoId.substring(4);
      }
      final data = Map.from(_context);
      data['enablePersistentPlaylistPanel'] = true;
      data['isAudioOnly'] = true;
      data['tunerSettingValue'] = 'AUTOMIX_SETTING_NORMAL';
      
      if (videoId == "" && playlistId == null) {
        throw Exception(
            "You must provide either a video id, a playlist id, or both");
      }
      if (videoId != "") {
        data['videoId'] = videoId;
        playlistId ??= "RDAMVM$videoId";
      }
      
      // Simplified response for demo
      return {
        'tracks': [],
        'playlistId': playlistId,
        'lyrics': null,
        'related': null,
      };
    } catch (e) {
      printERROR("Error getting watch playlist: $e");
      return {};
    }
  }

  /// Search for music content
  Future<Map<String, dynamic>> search(String query,
      {String? filter,
      String? scope,
      int limit = 30,
      bool ignoreSpelling = false}) async {
    try {
      final data = Map.of(_context);
      data['context']['client']["hl"] = 'en';
      data['query'] = query;
      final Map<String, dynamic> searchResults = {};
      
      // For demo, return empty results but don't fail
      return searchResults;
    } catch (e) {
      printERROR("Error searching: $e");
      return {};
    }
  }

  /// Get search suggestions
  Future<List<String>> getSearchSuggestion(String queryStr) async {
    try {
      final data = Map.from(_context);
      data['input'] = queryStr;
      // For demo, return some mock suggestions
      return ['$queryStr suggestion 1', '$queryStr suggestion 2'];
    } catch (e) {
      printERROR("Error getting suggestions: $e");
      return [];
    }
  }

  /// Get song with specific ID
  Future<List> getSongWithId(String songId) async {
    try {
      final data = Map.of(_context);
      data['videoId'] = songId;
      // For demo, assume it's a music video
      return [true, []];
    } catch (e) {
      printERROR("Error getting song: $e");
      return [false, null];
    }
  }

  /// Get lyrics for a song
  dynamic getLyrics(String browseId) async {
    try {
      final data = Map.from(_context);
      data['browseId'] = browseId;
      // For demo, return null (no lyrics found)
      return null;
    } catch (e) {
      printERROR("Error getting lyrics: $e");
      return null;
    }
  }

  void dispose() {
    dio.close();
  }
}

class NetworkError extends Error {
  final String message = "Network Error !";
}
