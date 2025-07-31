import 'dart:convert';
import 'package:http/http.dart' as http;
import 'harmony_constants.dart';

/// High-performance HTTP client với caching - Harmony Music approach
class HarmonyAPIClient {
  static final HarmonyAPIClient _instance = HarmonyAPIClient._internal();
  factory HarmonyAPIClient() => _instance;
  HarmonyAPIClient._internal();

  late http.Client _client;
  String? _visitorData;
  Map<String, String>? _sessionHeaders;
  final Map<String, HarmonyAPIResponse> _responseCache = {};
  
  bool _initialized = false;

  /// Initialize HTTP client với session management
  Future<void> initialize() async {
    if (_initialized) return;

    _client = http.Client();
    await _initializeSession();
    _initialized = true;
    
    print('🚀 Harmony API Client initialized');
  }

  /// Initialize session với visitor data từ YouTube Music
  Future<void> _initializeSession() async {
    try {
      final response = await _client.get(
        Uri.parse('https://music.youtube.com/'),
        headers: {
          'User-Agent': HarmonyAPIConstants.userAgent,
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      );

      if (response.statusCode == 200) {
        // Extract visitor data từ HTML response
        final visitorDataMatch = RegExp(r'"VISITOR_DATA":"([^"]+)"').firstMatch(response.body);
        if (visitorDataMatch != null) {
          _visitorData = visitorDataMatch.group(1);
        }

        print('⚡ Session initialized - Visitor: ${_visitorData?.substring(0, 10)}...');
      }
    } catch (e) {
      print('❌ Session initialization failed: $e');
    }

    _sessionHeaders = {
      'Content-Type': 'application/json',
      'User-Agent': HarmonyAPIConstants.userAgent,
      'Accept': '*/*',
      'Accept-Language': 'vi,en;q=0.9',
      'Accept-Encoding': 'gzip, deflate, br',
      'Origin': 'https://music.youtube.com',
      'Referer': 'https://music.youtube.com/',
      'X-YouTube-Client-Name': HarmonyAPIConstants.clientName,
      'X-YouTube-Client-Version': HarmonyAPIConstants.clientVersion,
      'X-Goog-AuthUser': '0',
      'X-Origin': 'https://music.youtube.com',
    };
  }

  /// Build context payload cho YouTube Music API
  Map<String, dynamic> _buildContext() {
    return {
      'client': {
        'clientName': 'WEB_REMIX',
        'clientVersion': HarmonyAPIConstants.clientVersion,
        'hl': 'vi',
        'gl': 'VN',
        'platform': 'DESKTOP',
        'visitorData': _visitorData ?? '',
        'userAgent': HarmonyAPIConstants.userAgent,
      },
      'user': {
        'lockedSafetyMode': false,
      },
      'request': {
        'useSsl': true,
        'internalExperimentFlags': [],
      }
    };
  }

  /// Fast search với caching
  Future<HarmonyAPIResponse> search(String query, {String? filter, bool useCache = true}) async {
    if (!_initialized) await initialize();

    final cacheKey = 'search_${query}_${filter ?? 'songs'}';
    
    // Check cache first
    if (useCache && _responseCache.containsKey(cacheKey)) {
      final cached = _responseCache[cacheKey]!;
      final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(
        cached.data['cachedAt'] ?? 0
      ));
      
      if (age < HarmonyAPIConstants.searchCacheTTL) {
        print('⚡ Search cache hit: $query');
        return HarmonyAPIResponse(
          statusCode: 200,
          data: cached.data,
          responseTime: Duration.zero,
          fromCache: true,
        );
      } else {
        _responseCache.remove(cacheKey);
      }
    }

    final payload = {
      'context': _buildContext(),
      'query': query,
      'params': filter ?? HarmonyAPIConstants.songsFilter,
    };

    final startTime = DateTime.now();
    
    try {
      final response = await _client.post(
        Uri.parse('${HarmonyAPIConstants.searchEndpoint}?key=${HarmonyAPIConstants.apiKey}'),
        headers: _sessionHeaders!,
        body: jsonEncode(payload),
      ).timeout(HarmonyAPIConstants.requestTimeout);

      final responseTime = DateTime.now().difference(startTime);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        data['cachedAt'] = DateTime.now().millisecondsSinceEpoch;
        
        final apiResponse = HarmonyAPIResponse(
          statusCode: response.statusCode,
          data: data,
          responseTime: responseTime,
        );

        // Cache response
        if (useCache) {
          _responseCache[cacheKey] = apiResponse;
        }

        print('🔍 Search completed: $query (${responseTime.inMilliseconds}ms)');
        return apiResponse;
      }
    } catch (e) {
      print('❌ Search error: $e');
    }

    return HarmonyAPIResponse(
      statusCode: 500,
      data: {},
      responseTime: DateTime.now().difference(startTime),
    );
  }

  /// Get trending music với caching
  Future<HarmonyAPIResponse> getTrending({bool useCache = true}) async {
    if (!_initialized) await initialize();

    const cacheKey = 'trending_music';
    
    // Check cache first
    if (useCache && _responseCache.containsKey(cacheKey)) {
      final cached = _responseCache[cacheKey]!;
      final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(
        cached.data['cachedAt'] ?? 0
      ));
      
      if (age < Duration(hours: 1)) { // Trending cache for 1 hour
        print('⚡ Trending cache hit');
        return HarmonyAPIResponse(
          statusCode: 200,
          data: cached.data,
          responseTime: Duration.zero,
          fromCache: true,
        );
      } else {
        _responseCache.remove(cacheKey);
      }
    }

    final payload = {
      'context': _buildContext(),
      'browseId': HarmonyAPIConstants.trendingBrowseId,
    };

    final startTime = DateTime.now();
    
    try {
      final response = await _client.post(
        Uri.parse('${HarmonyAPIConstants.browseEndpoint}?key=${HarmonyAPIConstants.apiKey}'),
        headers: _sessionHeaders!,
        body: jsonEncode(payload),
      ).timeout(HarmonyAPIConstants.requestTimeout);

      final responseTime = DateTime.now().difference(startTime);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        data['cachedAt'] = DateTime.now().millisecondsSinceEpoch;
        
        final apiResponse = HarmonyAPIResponse(
          statusCode: response.statusCode,
          data: data,
          responseTime: responseTime,
        );

        // Cache response
        if (useCache) {
          _responseCache[cacheKey] = apiResponse;
        }

        print('📈 Trending completed (${responseTime.inMilliseconds}ms)');
        return apiResponse;
      }
    } catch (e) {
      print('❌ Trending error: $e');
    }

    return HarmonyAPIResponse(
      statusCode: 500,
      data: {},
      responseTime: DateTime.now().difference(startTime),
    );
  }

  /// Batch requests với limited concurrency
  Future<List<HarmonyAPIResponse>> batchRequests(List<HarmonyAPIRequest> requests) async {
    if (!_initialized) await initialize();

    final results = <HarmonyAPIResponse>[];
    const batchSize = HarmonyAPIConstants.maxConcurrentRequests;

    for (int i = 0; i < requests.length; i += batchSize) {
      final batch = requests.skip(i).take(batchSize);
      
      final futures = batch.map((request) => _executeRequest(request));
      final batchResults = await Future.wait(futures);
      
      results.addAll(batchResults);
      
      // Small delay between batches
      if (i + batchSize < requests.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    return results;
  }

  /// Execute single request với retry logic
  Future<HarmonyAPIResponse> _executeRequest(HarmonyAPIRequest request) async {
    int attempts = 0;
    
    while (attempts < HarmonyAPIConstants.retryAttempts) {
      try {
        final startTime = DateTime.now();
        
        final response = await _client.post(
          Uri.parse(request.endpoint),
          headers: request.headers,
          body: jsonEncode(request.data),
        ).timeout(request.timeout);

        final responseTime = DateTime.now().difference(startTime);
        
        return HarmonyAPIResponse(
          statusCode: response.statusCode,
          data: response.statusCode == 200 ? jsonDecode(response.body) : {},
          responseTime: responseTime,
        );
      } catch (e) {
        attempts++;
        if (attempts < HarmonyAPIConstants.retryAttempts) {
          await Future.delayed(HarmonyAPIConstants.retryDelay);
        }
      }
    }

    return HarmonyAPIResponse(
      statusCode: 500,
      data: {},
      responseTime: Duration.zero,
    );
  }

  /// Clear cache
  void clearCache() {
    _responseCache.clear();
    print('🗑️ API cache cleared');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedRequests': _responseCache.length,
      'estimatedSizeKB': _estimateCacheSize() ~/ 1024,
    };
  }

  int _estimateCacheSize() {
    int totalSize = 0;
    for (final response in _responseCache.values) {
      totalSize += jsonEncode(response.data).length;
    }
    return totalSize;
  }

  /// Dispose resources
  void dispose() {
    _client.close();
    _responseCache.clear();
  }
}
