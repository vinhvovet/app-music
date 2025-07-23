import 'dart:convert';
import 'package:music_app/album.dart';
import 'package:http/http.dart' as http;


Future <List<Album>> fetchAlbums() async {
  Uri url = Uri.parse("https://thantrieu.com/resources/braniumapis/songs.json");

  // Gửi yêu cầu GET đến URL
  http.Response response = await http.get(url);

  // Kiểm tra mã trạng thái của phản hồi
if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['songs'] != null && data['songs'].isNotEmpty) {
      return List<Album>.from(data['songs'].map((song) => Album.fromJson(song)));
    } else {
      throw Exception('No songs found');
    }
}
else {
    throw Exception('Failed to load albums');
  }
}