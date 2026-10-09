import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'ajukan_penawaran.dart';
import '../home/home_mitra.dart';
import '../../widgets/background.dart';

class LayarOrderanMitra extends StatefulWidget {
  final bool isEmbeddedInNav;

  const LayarOrderanMitra({super.key, this.isEmbeddedInNav = true});

  @override
  State<LayarOrderanMitra> createState() => _LayarOrderanMitraState();
}

class _LayarOrderanMitraState extends State<LayarOrderanMitra> {
  String _kategoriFilter = 'penawaran';

  Widget _buildFilterTab(String label, String value, {int badgeCount = 0}) {
    bool isSelected = _kategoriFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _kategoriFilter = value;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFCB05) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              left: 2,
              top: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = ValueListenableBuilder<bool>(
      valueListenable: onlineStatusNotifier,
      builder: (context, isOnline, child) {
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: const Color(0xFFFFCB05),
              child: const Center(
                child: Text(
                  'Bursa Orderan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where('status', isEqualTo: 'Proses Bidding')
                        .snapshots(),
                    builder: (context, snapshot) {
                      int totalPenawaran = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return _buildFilterTab(
                        'Penawaran Pekerjaan',
                        'penawaran',
                        badgeCount: isOnline ? totalPenawaran : 0,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterTab('Riwayat Pekerjaan', 'riwayat'),
                  const SizedBox(width: 8),
                  _buildFilterTab('Pekerjaan Aktif', 'aktif', badgeCount: 1),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _buildContentBody(isOnline),
            ),
          ],
        );
      },
    );

    if (widget.isEmbeddedInNav) {
      return AppBackground(
        child: SafeArea(child: content),
      );
    }

    return Scaffold(
      body: AppBackground(
        child: SafeArea(child: content),
      ),
    );
  }

  Widget _buildContentBody(bool isOnline) {
    if (_kategoriFilter == 'penawaran') {
      if (!isOnline) {
        return _buildOfflineStateUI();
      }
      return _buildPenawaranList();
    } else if (_kategoriFilter == 'riwayat') {
      return _buildRiwayatList();
    }
    return const Center(
      child: Text(
        'Tidak ada data untuk Pekerjaan Aktif',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildOfflineStateUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_rounded,
                size: 56,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Anda Sedang Offline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aktifkan mode Online untuk melihat penawaran pekerjaan terbaru di sekitar Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 220,
              height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCB05),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  setMitraOnlineStatus(true);
                },
                child: const Text(
                  'Ubah ke Online',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPenawaranList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'Proses Bidding')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFCB05)),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Gagal memuat data penawaran',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'Tidak ada penawaran pekerjaan saat ini',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            DateTime? targetTime;
            if (data['expiredAt'] != null && data['expiredAt'] is Timestamp) {
              targetTime = (data['expiredAt'] as Timestamp).toDate();
            } else if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
              int durasiMenit = data['waktuPenawaran'] is int
                  ? data['waktuPenawaran']
                  : int.tryParse(data['waktuPenawaran']?.toString() ?? '') ?? 30;
              targetTime = (data['createdAt'] as Timestamp).toDate().add(Duration(minutes: durasiMenit));
            }

            final Map<String, dynamic> itemData = {
              'id': doc.id,
              'judul': data['jenisJasa'] ?? data['layanan_nama'] ?? data['judul'] ?? 'Jasa',
              'kategori': data['kategori'] ?? 'Kebersihan Harian',
              'userId': data['userId'] ?? data['user_id'] ?? data['idPengguna'],
              'namaPelanggan': data['userName'] ?? data['user_name'] ?? data['namaPelanggan'],
              'foto': data['userPhoto'] ?? data['user_photo'],
              'targetTime': targetTime,
              ...data,
            };

            return KartuPenawaranItem(
              key: ValueKey(doc.id),
              item: itemData,
              onExpired: () {},
            );
          },
        );
      },
    );
  }

  Widget _buildRiwayatList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'selesai')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFCB05)),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Gagal memuat riwayat pekerjaan',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada riwayat pekerjaan',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final item = doc.data() as Map<String, dynamic>;

            String tanggalTeks = '';
            if (item['completed_at'] != null && item['completed_at'] is Timestamp) {
              DateTime completedDate = (item['completed_at'] as Timestamp).toDate();
              tanggalTeks = DateFormat('d MMMM yyyy', 'id_ID').format(completedDate);
            } else if (item['created_at'] != null && item['created_at'] is Timestamp) {
              DateTime createdDate = (item['created_at'] as Timestamp).toDate();
              tanggalTeks = DateFormat('d MMMM yyyy', 'id_ID').format(createdDate);
            } else {
              tanggalTeks = item['tanggal'] ?? '';
            }

            String hargaTeks = 'Rp0';
            var rawHarga = item['deal_price'] ?? item['harga'] ?? 0;

            if (rawHarga is String) {
              hargaTeks = rawHarga;
            } else if (rawHarga is num) {
              hargaTeks = NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp',
                decimalDigits: 0,
              ).format(rawHarga);
            } else {
              hargaTeks = rawHarga.toString();
            }

            String userId = item['userId'] ?? item['user_id'] ?? '';

            return FutureBuilder<DocumentSnapshot>(
              future: userId.isNotEmpty
                  ? FirebaseFirestore.instance.collection('users').doc(userId).get()
                  : null,
              builder: (context, userSnapshot) {
                String namaUser = item['user_name'] ?? item['namaPelanggan'] ?? 'Pelanggan';
                String? photoUser = item['user_photo'] ?? item['foto'];

                if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
                  Map<String, dynamic>? userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  if (userData != null) {
                    if (userData['nama'] != null && userData['nama'].toString().isNotEmpty) {
                      namaUser = userData['nama'];
                    }
                    if (userData['photoUrl'] != null && userData['photoUrl'].toString().isNotEmpty) {
                      photoUser = userData['photoUrl'];
                    }
                  }
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['layanan_nama'] ?? item['judul'] ?? 'Jasa',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              item['kategori'] ?? 'Kebersihan Harian',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFFFFCB05),
                                  backgroundImage: (photoUser != null && photoUser.isNotEmpty)
                                      ? NetworkImage(photoUser)
                                      : null,
                                  child: (photoUser == null || photoUser.isEmpty)
                                      ? Text(
                                          namaUser.isNotEmpty ? namaUser[0].toUpperCase() : 'U',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        namaUser,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (tanggalTeks.isNotEmpty)
                                        Text(
                                          tanggalTeks,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 10,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Harga',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      hargaTeks,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFFFCB05), width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                ),
                                child: const Text(
                                  'Lihat Ulasan',
                                  style: TextStyle(
                                    color: Color(0xFFFFCB05),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFCB05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item['status'] != null
                                ? '${item['status'][0].toUpperCase()}${item['status'].substring(1)}'
                                : 'Selesai',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class KartuPenawaranItem extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onExpired;

  const KartuPenawaranItem({
    super.key,
    required this.item,
    required this.onExpired,
  });

  @override
  State<KartuPenawaranItem> createState() => _KartuPenawaranItemState();
}

class _KartuPenawaranItemState extends State<KartuPenawaranItem> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        DateTime? targetTime = widget.item['targetTime'] as DateTime?;
        if (targetTime != null) {
          Duration sisaDurasi = targetTime.difference(DateTime.now());
          if (sisaDurasi.isNegative || sisaDurasi.inSeconds <= 0) {
            _timer?.cancel();
            widget.onExpired();
          } else {
            setState(() {});
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getFormattedRemainingTime() {
    DateTime? targetTime = widget.item['targetTime'] as DateTime?;
    if (targetTime == null) return "00:00";

    Duration sisaDurasi = targetTime.difference(DateTime.now());

    if (sisaDurasi.isNegative) {
      return "00:00";
    }

    String menit = sisaDurasi.inMinutes.remainder(60).toString().padLeft(2, '0');
    String detik = sisaDurasi.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$menit:$detik';
  }

  @override
  Widget build(BuildContext context) {
    String sisaWaktuTeks = _getFormattedRemainingTime();
    String userId = widget.item['userId'] ?? widget.item['user_id'] ?? '';
    String orderId = widget.item['id'] ?? widget.item['orderId'] ?? widget.item['docId'] ?? '';
    final User? currentUser = FirebaseAuth.instance.currentUser;
    String customBidId = "${orderId}_${currentUser?.uid ?? ''}";

    return StreamBuilder<DocumentSnapshot>(
      stream: (currentUser != null && orderId.isNotEmpty)
          ? FirebaseFirestore.instance.collection('bids').doc(customBidId).snapshots()
          : const Stream.empty(),
      builder: (context, bidSnapshot) {
        bool hasSubmittedBid = bidSnapshot.hasData && bidSnapshot.data != null && bidSnapshot.data!.exists;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFCB05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.item['judul'] ?? 'Jasa',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            if (hasSubmittedBid) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade800,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Penawaran Terkirim',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          widget.item['kategori'] ?? 'Kategori',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),

                        FutureBuilder<DocumentSnapshot>(
                          future: userId.isNotEmpty
                              ? FirebaseFirestore.instance.collection('users').doc(userId).get()
                              : null,
                          builder: (context, userSnapshot) {
                            String namaPelanggan = widget.item['namaPelanggan'] ?? 'Pelanggan';
                            String? fotoPelanggan = widget.item['foto'];

                            if (userSnapshot.hasData &&
                                userSnapshot.data != null &&
                                userSnapshot.data!.exists) {
                              Map<String, dynamic>? userData =
                                  userSnapshot.data!.data() as Map<String, dynamic>?;
                              if (userData != null) {
                                if (userData['nama'] != null && userData['nama'].toString().isNotEmpty) {
                                  namaPelanggan = userData['nama'];
                                }
                                if (userData['photoUrl'] != null && userData['photoUrl'].toString().isNotEmpty) {
                                  fotoPelanggan = userData['photoUrl'];
                                }
                              }
                            }

                            return Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.black,
                                  backgroundImage: (fotoPelanggan != null && fotoPelanggan.isNotEmpty)
                                      ? NetworkImage(fotoPelanggan)
                                      : null,
                                  child: (fotoPelanggan == null || fotoPelanggan.isEmpty)
                                      ? Text(
                                          namaPelanggan.isNotEmpty
                                              ? namaPelanggan[0].toUpperCase()
                                              : 'P',
                                          style: const TextStyle(
                                            color: Color(0xFFFFCB05),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    namaPelanggan,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sisaWaktuTeks,
                          style: const TextStyle(
                            color: Color(0xFFFFCB05),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: 200,
                height: 36,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AjukanPenawaranScreen(item: widget.item),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    hasSubmittedBid ? 'Lihat / Edit Penawaran' : 'Lihat Detail',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}