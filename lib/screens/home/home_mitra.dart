import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/background.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/performa_harian.dart';
import '../../widgets/orderan_terdekat.dart';
import '../../widgets/ringkasan_rating.dart';
import '../../widgets/orderan_aktif.dart';

// -----------------------------------------------------------------------------
// GLOBAL NOTIFIER UNTUK STATUS ONLINE/OFFLINE
// -----------------------------------------------------------------------------
final ValueNotifier<bool> onlineStatusNotifier = ValueNotifier<bool>(false);

Future<void> setMitraOnlineStatus(bool isOnline) async {
  onlineStatusNotifier.value = isOnline;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('is_mitra_online', isOnline);
}

class WalletBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint lightYellowPaint = Paint()
      ..color = const Color(0xFFFFCB05)
      ..style = PaintingStyle.fill;

    final Paint darkYellowPaint = Paint()
      ..color = const Color(0xFFFFB800)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), lightYellowPaint);

    final Path path = Path();
    path.moveTo(size.width * 0.62, 0);
    
    path.cubicTo(
      size.width * 0.45, size.height * 0.30,
      size.width * 0.54, size.height * 0.70,
      size.width * 0.44, size.height,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, darkYellowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// HALAMAN HOME MITRA
// -----------------------------------------------------------------------------
class HomeMitraScreen extends StatefulWidget {
  const HomeMitraScreen({super.key});

  @override
  State<HomeMitraScreen> createState() => _HomeMitraScreenState();
}

class _HomeMitraScreenState extends State<HomeMitraScreen> 
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  static const String _currentAppVersion = '1.0.0'; 
  final List<String> _changelogList = [
    'Penawaran Pekerjaan Countdown Realtime. Jika Waktu Habis, Penawaran Hilang',
    'Halaman Ajukan Penawaran',
    'Mode Online/Offline',
    'Tampilan Desain pada Halaman Awal Sebelum Login dan Login',
    'Halaman Bantuan Mitra',
    'Widget Orderan Aktif',
    'Widget Orderan Terdekat',
    'Widget Performa Hari Ini',
    'Widget Banner Informasi/Pengumuman Sistem'
  ];

  @override
  void initState() {
    super.initState();
    _initOnlineStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUpdateChangelog();
    });
  }

  Future<void> _initOnlineStatus() async {
    final prefs = await SharedPreferences.getInstance();
    onlineStatusNotifier.value = prefs.getBool('is_mitra_online') ?? false;
  }

  Future<void> _checkUpdateChangelog() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeenVersion = prefs.getString('last_seen_mitra_app_version');

    if (lastSeenVersion != _currentAppVersion) {
      if (!mounted) return;
      _showUpdateDialog(prefs);
    }
  }

  void _showUpdateDialog(SharedPreferences prefs) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFCB05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.new_releases, color: Colors.black, size: 24),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Pembaruan v$_currentAppVersion',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Berikut daftar pembaruan terbaru aplikasi:',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              ..._changelogList.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFCB05),
                          fontSize: 16,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(fontSize: 12, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCB05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  await prefs.setString('last_seen_mitra_app_version', _currentAppVersion);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text(
                  'Mengerti',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final User? user = FirebaseAuth.instance.currentUser;

    return AppBackground(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HEADER MITRA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                color: Color(0xFFFFCB05),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.black26,
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: user?.photoURL == null
                            ? const Icon(Icons.person, size: 30, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Halo,',
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          Text(
                            user?.displayName ?? 'Mitra Helper',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Image.asset('assets/img/logo.png', width: 32, height: 32, fit: BoxFit.contain),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'MITRA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. CARD SALDO PENDAPATAN
            Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 12,
                        margin: const EdgeInsets.symmetric(vertical: 14),
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                      ),
                      Container(
                        width: 12,
                        margin: const EdgeInsets.symmetric(vertical: 14),
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CustomPaint(
                      painter: WalletBackgroundPainter(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Saldo Pendapatan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Image.asset(
                                  'assets/img/icon dompet saldo.png',
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Rp 15.200.000',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    child: const Text(
                                      'TARIK',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    child: const Text(
                                      'RIWAYAT',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 3. CARD RATING & PEKERJAAN SELESAI
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 34.0),
              child: RatingSummarySection(),
            ),

            const SizedBox(height: 24),

            // 4. SWITCH OFFLINE / ONLINE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34.0),
              child: ValueListenableBuilder<bool>(
                valueListenable: onlineStatusNotifier,
                builder: (context, isOnline, child) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.black : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            isOnline ? 'Online' : 'Offline',
                            key: ValueKey<bool>(isOnline),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isOnline ? const Color(0xFFFFCB05) : Colors.black,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setMitraOnlineStatus(!isOnline);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 64,
                            height: 32,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isOnline ? const Color(0xFFFFCB05) : Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              alignment: isOnline ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 3,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // 5. KARTU PEKERJAAN AKTIF / BERLANGSUNG (PRIORITAS UTAMA - OTOMATIS HILANG JIKA KOSONG)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 34.0),
              child: ActiveOrderCardSection(),
            ),

            // 6. DAFTAR ORDERAN TERDEKAT REALTIME
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34.0),
              child: ValueListenableBuilder<bool>(
                valueListenable: onlineStatusNotifier,
                builder: (context, isOnline, child) {
                  return NearestOrdersSection(isOnline: isOnline);
                },
              ),
            ),

            const SizedBox(height: 24),

            // 7. RINGKASAN PERFORMA HARI INI
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 34.0),
              child: TodayPerformanceSection(),
            ),

            const SizedBox(height: 24),

            // 8. BANNER INFORMASI MITRA
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 34.0),
              child: InfoBannerSection(),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}