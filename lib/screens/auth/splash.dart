import 'package:flutter/material.dart';
import '../../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AuthWrapper(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. BACKGROUND DUA WARNA DENGAN TRANSISI PUDAR HALUS DI GARIS TENGAH
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFD600), // Kuning
                  Color(0xFFFFD600),
                  Colors.black,
                  Colors.black,      // Hitam
                ],
                stops: [
                  0.0,
                  0.48, // Mulai pudar tepat sebelum 50%
                  0.52, // Selesai pudar tepat setelah 50%
                  1.0,
                ],
              ),
            ),
          ),

          // 2. KONTEN UTAMA DENGAN TAMPILAN PRESISI
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo Kotak
                  SizedBox(
                    width: 170,
                    height: 170,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/img/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.build_circle,
                              size: 60,
                              color: Color(0xFFFFD600),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Kolom Teks Terbagi 2 Sesuai Garis Tengah
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Teks HELPER BANUA
                        Transform.translate(
                          offset: const Offset(0, -5),
                          child: const Text(
                            'HELPER',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 0.5,
                              height: 0.95,
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -5),
                          child: const Text(
                            'BANUA',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 0.5,
                              height: 1.00,
                            ),
                          ),
                        ),

                        // Jarak Pemisah antara Kuning & Hitam
                        const SizedBox(height: 10),

                        // Badge / Teks MITRA
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'MITRA',
                            style: TextStyle(
                              fontSize: 47,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 2.0,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}