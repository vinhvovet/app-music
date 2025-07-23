class Album {
  final String title;
  final String artist;
  final String id;
  final String album;
  final String source;
  final String image;
  final int duration;
  final bool favorite;
  final int counter;
  final int replay;
  Album(
    this.title,
    this.artist,
    this.id,
    this.album,
    this.source,
    this.image,
    this.duration,
    this.favorite,
    this.counter,
    this.replay,
  );
  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      json['title'] ,
      json['artist'] ,
      json['id'] ,
      json['album'] ,
      json['source'] ,
      json['image'],
      int.parse(json['duration'].toString()),
      json['favorite'] == true || json['favorite'] == 'true' ,
      int.parse(json['counter'].toString()),
      int.parse(json['replay'].toString()),
    );
  }
}
