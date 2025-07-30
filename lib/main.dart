import 'package:flutter/material.dart';
import 'package:music_app/state%20management/provider.dart';
import 'package:music_app/ui/auth_form/login_screen.dart';
import 'package:music_app/ui/home/viewmodel.dart';
import 'package:music_app/ui/youtube_music_test_page.dart';
import 'package:provider/provider.dart';
import 'package:music_app/startup_performance.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Sử dụng StartupPerformance để tối ưu khởi tạo
  await StartupPerformance.initializeServices();

  runApp(const MusicApp());
}

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProviderStateManagement(),
          lazy: false, // Load immediately for better UX
        ),
        Provider<MusicAppViewModel>(
          create: (_) => MusicAppViewModel(), // Remove immediate loadSongs() call
          dispose: (_, viewModel) => viewModel.dispose(), // Use proper dispose method
          lazy: true, // Load only when needed to reduce startup time
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Music App',
        routes: {
          '/': (context) => const LoginScreen(),
          '/test-api': (context) => const YouTubeMusicTestPage(),
        },
        initialRoute: '/',
        // Performance optimizations
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling, // Prevent text scaling issues
            ),
            child: child!,
          );
        },
        // Reduce unnecessary rebuilds
        theme: ThemeData(
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
      ),
    );
  }
}