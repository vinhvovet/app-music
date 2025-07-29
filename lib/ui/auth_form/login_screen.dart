import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:music_app/state%20management/provider.dart';
import 'package:music_app/ui/home/home.dart';
import 'package:music_app/ui/auth_form/register_screen.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _loading = false;

 Future<void> _login() async {
  setState(() {
    _error = null;
    _loading = true;
  });

  try {
    final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (context.mounted) {
      final provider = context.read<ProviderStateManagement>();
      await provider.loadFavorites(); // Tải danh sách yêu thích từ Firestore

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MusicApp()),
      );
    }
  } on FirebaseAuthException catch (e) {
    setState(() => _error = e.message);
  } finally {
    setState(() => _loading = false);
  }
}

Future<void> signInWithGoogle() async {
  setState(() {
    _error = null;
    _loading = true;
  });

  try {
    // Trigger the authentication flow
    final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);

    // Once signed in, sign in with Firebase
    await FirebaseAuth.instance.signInWithCredential(credential);

    if (context.mounted) {
      final provider = context.read<ProviderStateManagement>();
      await provider.loadFavorites(); // Load favorites from local storage

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MusicApp()),
      );
    }
  } on FirebaseAuthException catch (e) {
    setState(() => _error = e.message);
  } on GoogleSignInException catch (e) {
    setState(() => _error = 'Google Sign In Error: ${e.toString()}');
  } catch (e) {
    setState(() => _error = 'An error occurred: $e');
  } finally {
    setState(() => _loading = false);
  }
}


  @override
  Widget build(BuildContext context) {
     final provider = context.read<ProviderStateManagement>();
    return Scaffold(

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.music_note, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 20),
              const Text(
                ' nghe nhạc',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 32),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.black),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  labelStyle: const TextStyle(color: Colors.black),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Color(0xFF3EA513),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _login,
                        child: const Text(
                          'Đăng nhập',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async{
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                  await provider.loadFavorites(); // Tải danh sách yêu thích từ Firestore
              
                },
                child: const Text(
                  'Chưa có tài khoản? Đăng ký',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                 signInWithGoogle();
                    
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Đăng nhập bằng Google', style: TextStyle(color: Colors.black)),
                    SizedBox(width: 8),
                    Image(
                      image: AssetImage('assets/image.png'),
                      height: 24,
                      width: 20,
                    ),
                  ],
                ),
              )

            ],
          ),
        ),
      ),
    );
  }
}
