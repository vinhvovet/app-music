import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/model/song.dart';

class FavoriteService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Tham chiếu tới subcollection favorites của user hiện tại
  CollectionReference<Map<String, dynamic>> get _favRef {
    final uid = _auth.currentUser!.uid;
    return _db.collection('users').doc(uid).collection('favorites');
  }

  // Lấy danh sách bài hát yêu thích
  Future<List<Song>> getFavorites() async {
    final snapshot = await _favRef.get();
    return snapshot.docs.map((doc) => Song.fromJson(doc.data())).toList();
  }

  // Thêm bài hát vào danh sách yêu thích
  Future<void> addFavorite(Song song) async {
    await _favRef.doc(song.id).set(song.toJson());
  }

  // Xóa bài hát khỏi danh sách yêu thích
  Future<void> removeFavorite(String songId) async {
    await _favRef.doc(songId).delete();
  }

  // Kiểm tra xem bài hát có trong danh sách yêu thích không
  Future<bool> isFavorite(String songId) async {
    final doc = await _favRef.doc(songId).get();
    return doc.exists;
  }
}