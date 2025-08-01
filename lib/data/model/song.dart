import 'lyric_line.dart';

class Song {
  Song({
    required this.id,
    required this.title,
    required this.album,
    required this.artist,
    required this.source,
    required this.image,
    required this.duration,
    this.lyrics,
    this.lyricsData,
    this.isFavorite = false
  });
  factory Song.fromJson(Map<String, dynamic> map) { 
                                                   
    return Song(
      id: map['id'],
      title: map['title'],
      album: map['album'],
      artist: map['artist'],
      source: map['source'],
      image: map['image'],
      duration: map['duration'],
      lyrics: map['lyrics'],
      lyricsData: map['lyricsData'] != null 
          ? LyricsData.fromJson(map['lyricsData']) 
          : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'album': album,
      'artist': artist,
      'source': source,
      'image': image,
      'duration': duration,
      'lyrics': lyrics,
      'lyricsData': lyricsData?.toJson(),
    };
  }

  // Chuyển thành map để lưu Firestore nếu cần
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'lyrics': lyrics,
    };
  }

  String id;
  String title;
  String album;
  String artist;
  String source;
  String image;
  int duration;
  String? lyrics; // Lời bài hát dạng text thuần
  LyricsData? lyricsData; // Lời bài hát có timestamp cho karaoke
  bool isFavorite;


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Song{id: $id, title: $title, album: $album, artist: $artist, '
        'source: $source, image: $image, duration: $duration}';
  }
  
}

