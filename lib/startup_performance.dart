import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'services/youtube_music_complete_api.dart';

class StartupPerformance {
  static bool _initialized = false;
  static YouTubeMusicCompleteAPI? _musicAPI;
  
  /// Khởi tạo Firebase, Google Sign In và YouTube Music Complete API
  static Future<void> initializeServices() async {
    if (_initialized) return;
    
    try {
      // Khởi tạo Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Khởi tạo YouTube Music Complete API
      print('[INFO] Initializing YouTube Music Complete API...');
      _musicAPI = YouTubeMusicCompleteAPI();
      await _musicAPI!.initialize();
      print('[INFO] ✅ YouTube Music Complete API initialized successfully');
      
      _initialized = true;
      print('✅ All services initialized successfully');
    } catch (e) {
      print('❌ Lỗi khởi tạo services: $e');
      // Không throw error để app vẫn có thể chạy
    }
  }
  
  /// Lấy Google Sign In instance  
  static GoogleSignIn get googleSignIn => GoogleSignIn();
  
  /// Lấy YouTube Music Complete API instance
  static YouTubeMusicCompleteAPI get musicAPI {
    if (!_initialized || _musicAPI == null) {
      throw StateError('YouTube Music API chưa được khởi tạo. Gọi initializeServices() trước.');
    }
    return _musicAPI!;
  }
  
  /// Kiểm tra trạng thái khởi tạo
  static bool get isInitialized => _initialized;
  
  /// Preload các tài nguyên quan trọng
  static Future<void> preloadResources() async {
    // Có thể thêm preload cho images, fonts, v.v.
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  /// Memory cleanup
  static void cleanup() {
    _musicAPI?.dispose();
    _musicAPI = null;
    _initialized = false;
  }
}
