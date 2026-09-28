import 'package:flutter/material.dart';
import '../home/home_mitra.dart';
import '../order/order_mitra.dart';
import '../profile/akun.dart';
import '../profile/bantuan.dart';

class MitraMainScreen extends StatefulWidget {
  const MitraMainScreen({super.key});

  @override
  State<MitraMainScreen> createState() => _MitraMainScreenState();
}

class _MitraMainScreenState extends State<MitraMainScreen> {
  int _currentIndex = 0;

  // Daftar halaman yang dipertahankan
  final List<Widget> _pages = [
    const HomeMitraScreen(),      // Indeks 0: Beranda
    const LayarOrderanMitra(),    // Indeks 1: Orderan
    const LayarBantuanMitra(), // Indeks 2: Placeholder Bantuan
    const AkunScreen(),           // Indeks 3: Akun
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavMitra(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class BottomNavMitra extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int badgeCount;

  const BottomNavMitra({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badgeCount = 4,
  });

  // Helper method untuk membuat container latar belakang ikon yang aktif
  Widget _buildNavIcon({
    required IconData iconData,
    required bool isActive,
    Widget? badge,
  }) {
    Widget iconWidget = Icon(
      iconData,
      color: Colors.black,
    );

    if (badge != null) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          badge,
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFCB05) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: iconWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          // 0. Beranda
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              iconData: currentIndex == 0 ? Icons.home : Icons.home_outlined,
              isActive: currentIndex == 0,
            ),
            label: 'Beranda',
          ),

          // 1. Orderan
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              iconData: currentIndex == 1 ? Icons.assignment : Icons.assignment_outlined,
              isActive: currentIndex == 1,
            ),
            label: 'Orderan',
          ),

          // 2. Bantuan
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              iconData: currentIndex == 2 ? Icons.headset_mic : Icons.headset_mic_outlined,
              isActive: currentIndex == 2,
            ),
            label: 'Bantuan',
          ),

          // 3. Akun
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              iconData: currentIndex == 3 ? Icons.person : Icons.person_outline,
              isActive: currentIndex == 3,
            ),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}