import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/background.dart';
import '../../widgets/changelog.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/orderan_aktif.dart';
import '../../widgets/orderan_terdekat.dart';
import '../../widgets/performa_harian.dart';
import '../../widgets/ringkasan_rating.dart';
import '../profile/setup_layanan.dart';
import '../payment/tarik.dart';
import '../payment/riwayat_transaksi.dart';
import '../../widgets/format_angka.dart';

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
      size.width * 0.45,
      size.height * 0.30,
      size.width * 0.54,
      size.height * 0.70,
      size.width * 0.44,
      size.height,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, darkYellowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HomeMitraScreen extends StatefulWidget {
  final VoidCallback? onTapProfile;

  const HomeMitraScreen({super.key, this.onTapProfile});

  @override
  State<HomeMitraScreen> createState() => _HomeMitraScreenState();
}

class _HomeMitraScreenState extends State<HomeMitraScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initOnlineStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChangelogMitraDialog.checkAndShow(context);
    });
  }

  Future<void> _initOnlineStatus() async {
    final prefs = await SharedPreferences.getInstance();
    onlineStatusNotifier.value = prefs.getBool('is_mitra_online') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User tidak ditemukan. Silakan login ulang.')),
      );
    }

    return AppBackground(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('mitra').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          bool isSetupCompleted = false;
          String statusMitra = 'pending';

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            isSetupCompleted = data['isSetupCompleted'] ?? false;
            statusMitra = data['statusMitra'] ?? 'pending';
          }

          final bool isApproved = isSetupCompleted && (statusMitra == 'approved');

          return SingleChildScrollView(
            child: Column(
              children: [
                // 1. HEADER MITRA (Dengan gesture tap menuju Tab Akun)
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
                      InkWell(
                        onTap: widget.onTapProfile,
                        borderRadius: BorderRadius.circular(30),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.black26,
                                backgroundImage: user.photoURL != null
                                    ? NetworkImage(user.photoURL!)
                                    : null,
                                child: user.photoURL == null
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
                                    user.displayName ?? 'Mitra Helper',
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
                        ),
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

                // 1.5 SPANDUK APABILA BELUM MELAKUKAN SETUP LAYANAN
                if (!isApproved) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(25, 16, 25, 0),
                    child: Card(
                      color: Colors.amber.shade50,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.amber.shade700, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  'Fitur Terkunci (Setup Wajib)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Anda belum memilih jenis layanan yang ditawarkan. Silakan lengkapi setup layanan agar ketersediaan dan pencarian pesanan dapat diaktifkan.',
                              style: TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFCB05),
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SetupLayananMitraScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.build_circle_outlined, size: 18),
                                label: const Text(
                                  'Lengkapi Setup Layanan',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // 2. CARD SALDO PENDAPATAN
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('mitra').doc(user.uid).snapshots(),
                  builder: (context, snapshot) {
                    num balance = 0;
                    if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      balance = data['balance'] ?? 0;
                    }

                    final String formattedBalance = balance.toStringAsFixed(0).replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]}.',
                        );

                    return Stack(
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
                                    Text(
                                      'Rp $formattedBalance',
                                      style: const TextStyle(
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
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const TarikSaldoMitraScreen(),
                                                ),
                                              );
                                            },
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
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const RiwayatTransaksiMitraScreen(),
                                                ),
                                              );
                                            },
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
                    );
                  },
                ),

                const SizedBox(height: 20),

                // 3. CARD RATING & PEKERJAAN SELESAI
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 34.0),
                  child: RatingSummarySection(),
                ),

                const SizedBox(height: 24),

                // 4. SWITCH OFFLINE / ONLINE (DILINDUNGI STATUS SETUP/APPROVED)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 34.0),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: onlineStatusNotifier,
                    builder: (context, isOnline, child) {
                      final bool canToggle = isApproved;
                      final bool activeOnlineState = canToggle && isOnline;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: activeOnlineState
                                  ? Colors.black
                                  : (canToggle ? Colors.grey.shade300 : Colors.grey.shade200),
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
                                    activeOnlineState ? 'Online' : 'Offline',
                                    key: ValueKey<bool>(activeOnlineState),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: activeOnlineState
                                          ? const Color(0xFFFFCB05)
                                          : (canToggle ? Colors.black : Colors.grey.shade500),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: canToggle
                                      ? () => setMitraOnlineStatus(!isOnline)
                                      : () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Lengkapi setup layanan terlebih dahulu untuk mengaktifkan ketersediaan.'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    width: 64,
                                    height: 32,
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: activeOnlineState
                                          ? const Color(0xFFFFCB05)
                                          : Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: AnimatedAlign(
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeInOut,
                                      alignment: activeOnlineState
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
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
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // 5. KARTU PEKERJAAN AKTIF / BERLANGSUNG
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
                      return NearestOrdersSection(isOnline: isApproved && isOnline);
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
          );
        },
      ),
    );
  }
}