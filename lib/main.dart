import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:music_app/firebase_options.dart';
import 'package:music_app/state%20management/provider.dart';
import 'package:music_app/ui/auth_form/login_screen.dart';
import 'package:music_app/ui/home/viewmodel.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp( // Khởi tạo Firebase
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Google Sign In with serverClientId
  await GoogleSignIn.instance.initialize(
    serverClientId: '857871605367-kaubjl12u1h99mgj3v566h7gn41p1h25.apps.googleusercontent.com',
  );

  final providerStateManagement = ProviderStateManagement();

  runApp(
    MultiProvider(// Sử dụng cung cấp đa dạng để quản lý trạng thái
      providers: [
        ChangeNotifierProvider(create: (_) => providerStateManagement),
        Provider<MusicAppViewModel>(
          create: (_) => MusicAppViewModel()..loadSongs(),
          dispose: (_, viewModel) => viewModel.songStream.close(),
        ),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Music App',
        home: LoginScreen(),
      ),
    ),
  );
}