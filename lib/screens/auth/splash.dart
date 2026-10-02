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
    // Mengambil ukuran lebar layar HP
    final double screenWidth = MediaQuery.of(context).size.width;

    // Kalkulasi ukuran proporsional berdasarkan lebar layar
    final double logoSize = screenWidth * 0.38; // 38% lebar layar
    final double titleFontSize = screenWidth * 0.088; // Ukuran font HELPER BANUA
    final double mitraFontSize = screenWidth * 0.105; // Ukuran font MITRA

    return Scaffold(
      body: Stack(
        children: [
          // 1. BACKGROUND DUA WARNA DENGAN TRANSISI PUDAR HALUS
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

          // 2. KONTEN UTAMA DENGAN RESPONSIF PREVENTIF
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: MediaQuery.withNoTextScaling(
                // Mencegah font membesar dari settingan font size HP
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo Kotak Proporsional
                    SizedBox(
                      width: logoSize,
                      height: logoSize,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(logoSize * 0.14),
                        child: Image.asset(
                          'assets/img/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.build_circle,
                                size: logoSize * 0.4,
                                color: const Color(0xFFFFD600),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    SizedBox(width: screenWidth * 0.03),

                    // Kolom Teks Terbagi 2 Sesuai Garis Tengah
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Teks HELPER BANUA (Disesuaikan Skalanya jika Layar Sempit)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'HELPER',
                                  style: TextStyle(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    letterSpacing: 0.5,
                                    height: 0.95,
                                  ),
                                ),
                                Text(
                                  'BANUA',
                                  style: TextStyle(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    letterSpacing: 0.5,
                                    height: 1.00,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: screenWidth * 0.02),

                          // Badge / Teks MITRA (FittedBox Mencegah "MITR" + "A" Kebawah)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.025,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'MITRA',
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: mitraFontSize,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: 1.5,
                                  height: 1.0,
                                ),
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
          ),
        ],
      ),
    );
  }
}