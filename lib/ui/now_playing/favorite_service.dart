import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/model/song.dart';

class FavoriteService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Kiểm tra xem user có đăng nhập không
  bool get isUserAuthenticated => _auth.currentUser != null;

  // Tham chiếu tới subcollection favorites của user hiện tại
  CollectionReference<Map<String, dynamic>>? get _favRef {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _db.collection('users').doc(user.uid).collection('favorites');
  }

  // Lấy danh sách bài hát yêu thích
  Future<List<Song>> getFavorites() async {
    final favRef = _favRef;
    if (favRef == null) return [];
    
    final snapshot = await favRef.get();
    return snapshot.docs.map((doc) => Song.fromJson(doc.data())).toList();
  }

  // Thêm bài hát vào danh sách yêu thích
  Future<void> addFavorite(Song song) async {
    final favRef = _favRef;
    if (favRef == null) return;
    
    await favRef.doc(song.id).set(song.toJson());
  }

  // Xóa bài hát khỏi danh sách yêu thích
  Future<void> removeFavorite(String songId) async {
    final favRef = _favRef;
    if (favRef == null) return;
    
    await favRef.doc(songId).delete();
  }

  // Kiểm tra xem bài hát có trong danh sách yêu thích không
  Future<bool> isFavorite(String songId) async {
    final favRef = _favRef;
    if (favRef == null) return false;
    
    final doc = await favRef.doc(songId).get();
    return doc.exists;
  }
}