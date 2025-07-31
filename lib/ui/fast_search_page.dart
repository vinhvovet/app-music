import 'package:flutter/material.dart';
import '../services/fast_music_service.dart';
import '../data/fast_music_models.dart';

class FastSearchWidget extends StatefulWidget {
  const FastSearchWidget({super.key});

  @override
  State<FastSearchWidget> createState() => _FastSearchWidgetState();
}

class _FastSearchWidgetState extends State<FastSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FastMusicService _musicService = FastMusicService();
  
  List<FastMusicTrack> _searchResults = [];
  bool _isLoading = false;
  String _lastQuery = '';
  int _lastSearchTime = 0;
  
  @override
  void initState() {
    super.initState();
    _setupSearchStream();
  }
  
  void _setupSearchStream() {
    _musicService.searchResultStream.listen((result) {
      if (mounted) {
        setState(() {
          _searchResults = result.tracks;
          _isLoading = false;
          _lastQuery = result.query;
        });
      }
    });
  }
  
  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    final searchStart = DateTime.now().millisecondsSinceEpoch;
    _musicService.searchWithDebounce(query);
    
    // Track search performance
    _musicService.searchResultStream.take(1).listen((_) {
      _lastSearchTime = DateTime.now().millisecondsSinceEpoch - searchStart;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚡ Fast Music Search'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showStats,
            icon: const Icon(Icons.analytics),
            tooltip: 'Performance Stats',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBox(),
          _buildPerformanceIndicator(),
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }
  
  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade100, Colors.blue.shade100],
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search music... (Try: "nhạc trẻ", "sơn tùng")',
          prefixIcon: const Icon(Icons.search, color: Colors.purple),
          suffixIcon: _isLoading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : _searchController.text.isNotEmpty 
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  icon: const Icon(Icons.clear, color: Colors.grey),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
  
  Widget _buildPerformanceIndicator() {
    if (_lastQuery.isEmpty) return const SizedBox.shrink();
    
    final Color performanceColor = _lastSearchTime < 100 
      ? Colors.green 
      : _lastSearchTime < 500 
        ? Colors.orange 
        : Colors.red;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: performanceColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            _lastSearchTime < 100 ? Icons.flash_on : Icons.timer,
            color: performanceColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Search: "${_lastQuery}" → ${_searchResults.length} results (${_lastSearchTime}ms)',
            style: TextStyle(
              color: performanceColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      itemCount: _searchResults.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final track = _searchResults[index];
        return _buildTrackItem(track, index);
      },
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Search for your favorite music',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try: "nhạc trẻ", "sơn tùng", "đen vâu"',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrackItem(FastMusicTrack track, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade100,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: Colors.purple.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          track.displayTitle,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          track.displayArtist,
          style: TextStyle(color: Colors.grey.shade600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (track.displayDuration.isNotEmpty)
              Text(
                track.displayDuration,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _playTrack(track),
              icon: const Icon(Icons.play_arrow, color: Colors.purple),
              tooltip: 'Play',
            ),
          ],
        ),
        onTap: () => _showTrackDetails(track),
      ),
    );
  }
  
  void _playTrack(FastMusicTrack track) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Getting stream URL...'),
          ],
        ),
      ),
    );
    
    final stopwatch = Stopwatch()..start();
    final streamUrl = await _musicService.getStreamUrl(track.id);
    stopwatch.stop();
    
    Navigator.of(context).pop(); // Close loading dialog
    
    if (streamUrl != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stream URL ready in ${stopwatch.elapsedMilliseconds}ms!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Copy URL',
            textColor: Colors.white,
            onPressed: () {
              // Copy URL to clipboard
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to get stream URL'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showTrackDetails(FastMusicTrack track) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(track.displayTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Artist: ${track.displayArtist}'),
            if (track.displayAlbum.isNotEmpty) 
              Text('Album: ${track.displayAlbum}'),
            if (track.displayDuration.isNotEmpty)
              Text('Duration: ${track.displayDuration}'),
            Text('ID: ${track.id}'),
            const SizedBox(height: 8),
            Text(
              'Cached: ${track.isCacheValid ? "✅ Valid" : "❌ Expired"}',
              style: TextStyle(
                color: track.isCacheValid ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showStats() {
    final stats = _musicService.getStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚡ Performance Stats'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🚀 Service Status: ${stats['initialized'] ? "Ready" : "Loading"}'),
              const Divider(),
              Text('💾 Cache Stats:'),
              Text('  • Search Results: ${stats['cache']['searchResults']}'),
              Text('  • Total Tracks: ${stats['cache']['totalTracks']}'),
              Text('  • Stream URLs: ${stats['cache']['streamUrls']}'),
              Text('  • Cache Size: ${stats['cache']['estimatedSizeMB']} MB'),
              const Divider(),
              Text('📊 API Stats:'),
              Text('  • Memory Cache: ${stats['api']['totalItems']} items'),
              const Divider(),
              Text('🔥 Popular Searches:'),
              for (final query in (stats['popularSearches'] as List).take(5))
                Text('  • $query'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _musicService.clearAllCaches();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All caches cleared!')),
              );
            },
            child: const Text('Clear Cache'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
