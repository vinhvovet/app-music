import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:music_app/firebase_options.dart';
import 'package:music_app/state%20management/provider.dart';
import 'package:music_app/ui/auth_form/login_screen.dart';
import 'package:music_app/ui/home/viewmodel.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final providerStateManagement = ProviderStateManagement();

  runApp(
    MultiProvider(
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