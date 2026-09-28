import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth/splash.dart';
import 'screens/auth/login.dart'; 
import 'screens/navigation/mitra_navigation.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Helper Banua Mitra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      // 2. Arahkan home ke SplashScreen
      home: const SplashScreen(), 
    );
  }
}

// Widget pembantu untuk mengecek status login setelah Splash Screen selesai
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFFFCB05)),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const MitraMainScreen();
        }

        return const LoginScreen(); 
      },
    );
  }
}