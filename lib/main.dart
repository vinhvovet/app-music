import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:music_app/ui/auth_form/login_screen.dart';
import 'firebase_options.dart';
import 'package:music_app/ui/home/home.dart';
import 'package:music_app/ui/home/viewmodel.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const RootApp());
}

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MusicAppViewModel>(
          create: (_) => MusicAppViewModel()..loadSongs(),
          dispose: (_, viewModel) => viewModel.songStream.close(),
        )
      ],
      child: MaterialApp(
        title: 'Music App',
        debugShowCheckedModeBanner: false,
        home: FirebaseAuth.instance.currentUser == null
            ? const LoginScreen()
            : const MusicApp(),
      ),
    );
  }
}
