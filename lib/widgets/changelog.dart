import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangelogMitraDialog {
  static const String _currentAppVersion = '1.0.1'; 
  
  static final List<String> _changelogList = [
    'Style UI input disamakan dengan Helper Banua',
    'Tampilan Awal Helper Banua Mitra diperbaiki',
    'Token FCM untuk notifikasi',
    'Setup Layanan di Halaman Utama Mitra',
    'Akun > Pin Transaksi + Hapus Akun',
    'Saldo Pendapatan > Tarik, Riwayat Transaksi, dan Pin Transaksi',
  ];

  static Future<void> checkAndShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeenVersion = prefs.getString('last_seen_mitra_app_version');

    if (lastSeenVersion != _currentAppVersion) {
      if (!context.mounted) return;
      _showUpdateDialog(context, prefs);
    }
  }

  static void _showUpdateDialog(BuildContext context, SharedPreferences prefs) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  await prefs.setString(
                    'last_seen_mitra_app_version',
                    _currentAppVersion,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text(
                  'Mengerti',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}