class MusicTrack {
  final String id;
  final String videoId;
  final String title;
  final String? artist;
  final String? album;
  final Duration? duration;
  final String? thumbnail;
  final String? url;
  final List<MusicArtist>? artists;
  final bool? isFavorite;
  final Map<String, dynamic>? extras;

  MusicTrack({
    required this.id,
    required this.videoId,
    required this.title,
    this.artist,
    this.album,
    this.duration,
    this.thumbnail,
    this.url,
    this.artists,
    this.isFavorite = false,
    this.extras,
  });

  MusicTrack copyWith({
    String? id,
    String? videoId,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? thumbnail,
    String? url,
    List<MusicArtist>? artists,
    bool? isFavorite,
    Map<String, dynamic>? extras,
  }) {
    return MusicTrack(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      thumbnail: thumbnail ?? this.thumbnail,
      url: url ?? this.url,
      artists: artists ?? this.artists,
      isFavorite: isFavorite ?? this.isFavorite,
      extras: extras ?? this.extras,
    );
  }

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    String? artistName;
    List<MusicArtist>? artistList;
    
    if (json['artists'] != null) {
      artistName = json['artists']?.map((e) => e['name']).toList().join(', ').toString();
      artistList = (json['artists'] as List?)?.map((e) => MusicArtist.fromJson(e)).toList();
    }

    Map? albumData;
    if (json['album'] != null) {
      if (json['album']['id'] != null) {
        albumData = json['album'];
      }
    }

    final videoId = json["videoId"] ?? json["id"] ?? "";
    
    return MusicTrack(
      id: videoId,
      videoId: videoId,
      title: json["title"] ?? "",
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'])
          : _parseDuration(json['length']),
      album: albumData != null ? albumData['name'] : null,
      artist: artistName,
      artists: artistList,
      isFavorite: json['isFavorite'] ?? false,
      thumbnail: json["thumbnails"] != null && json["thumbnails"].isNotEmpty
          ? json["thumbnails"][0]['url']
          : null,
      extras: {
        'url': json['url'],
        'length': json['length'],
        'album': albumData,
        'artists': json['artists'],
        'date': json['date'],
        'year': json['year']
      },
    );
  }

  Map<String, dynamic> toJson() => {
        "videoId": id,
        "title": title,
        'album': extras?['album'],
        'artists': extras?['artists'],
        'length': extras?['length'],
        'duration': duration?.inSeconds,
        'date': extras?['date'],
        'thumbnails': [
          if (thumbnail != null) {'url': thumbnail}
        ],
        'url': extras?['url'],
        'year': extras?['year']
      };

  static Duration? _parseDuration(String? time) {
    if (time == null) {
      return null;
    }

    int sec = 0;
    final splitted = time.split(":");
    if (splitted.length == 3) {
      sec += int.parse(splitted[0]) * 3600 +
          int.parse(splitted[1]) * 60 +
          int.parse(splitted[2]);
    } else if (splitted.length == 2) {
      sec += int.parse(splitted[0]) * 60 + int.parse(splitted[1]);
    } else if (splitted.length == 1) {
      sec += int.parse(splitted[0]);
    }
    return Duration(seconds: sec);
  }
}

class MusicAlbum {
  final String id;
  final String title;
  final String? artist;
  final String? thumbnail;
  final List<MusicTrack>? tracks;
  final int? year;
  final String? description;

  MusicAlbum({
    required this.id,
    required this.title,
    this.artist,
    this.thumbnail,
    this.tracks,
    this.year,
    this.description,
  });

  factory MusicAlbum.fromJson(Map<String, dynamic> json) {
    return MusicAlbum(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      thumbnail: json['thumbnails'] != null && json['thumbnails'].isNotEmpty
          ? json['thumbnails'][0]['url']
          : null,
      tracks: json['tracks'] != null
          ? (json['tracks'] as List)
              .map((track) => MusicTrack.fromJson(track))
              .toList()
          : null,
      year: json['year'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'thumbnails': [
          if (thumbnail != null) {'url': thumbnail}
        ],
        'tracks': tracks?.map((track) => track.toJson()).toList(),
        'year': year,
        'description': description,
      };
}

class MusicPlaylist {
  final String id;
  final String title;
  final String? description;
  final String? thumbnail;
  final List<MusicTrack>? tracks;
  final String? author;
  final int? trackCount;

  MusicPlaylist({
    required this.id,
    required this.title,
    this.description,
    this.thumbnail,
    this.tracks,
    this.author,
    this.trackCount,
  });

  factory MusicPlaylist.fromJson(Map<String, dynamic> json) {
    return MusicPlaylist(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      thumbnail: json['thumbnails'] != null && json['thumbnails'].isNotEmpty
          ? json['thumbnails'][0]['url']
          : null,
      tracks: json['tracks'] != null
          ? (json['tracks'] as List)
              .map((track) => MusicTrack.fromJson(track))
              .toList()
          : null,
      author: json['author'],
      trackCount: json['trackCount'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'thumbnails': [
          if (thumbnail != null) {'url': thumbnail}
        ],
        'tracks': tracks?.map((track) => track.toJson()).toList(),
        'author': author,
        'trackCount': trackCount,
      };
}

class MusicArtist {
  final String id;
  final String name;
  final String? description;
  final String? thumbnail;
  final String? subscribers;

  MusicArtist({
    required this.id,
    required this.name,
    this.description,
    this.thumbnail,
    this.subscribers,
  });

  factory MusicArtist.fromJson(Map<String, dynamic> json) {
    return MusicArtist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      thumbnail: json['thumbnails'] != null && json['thumbnails'].isNotEmpty
          ? json['thumbnails'][0]['url']
          : null,
      subscribers: json['subscribers'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'thumbnails': [
          if (thumbnail != null) {'url': thumbnail}
        ],
        'subscribers': subscribers,
      };
}
