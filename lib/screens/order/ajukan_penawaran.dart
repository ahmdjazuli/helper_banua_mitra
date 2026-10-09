import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/background.dart';
import '../../widgets/format_angka.dart';

class AjukanPenawaranScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const AjukanPenawaranScreen({super.key, required this.item});

  @override
  State<AjukanPenawaranScreen> createState() => _AjukanPenawaranScreenState();
}

class _AjukanPenawaranScreenState extends State<AjukanPenawaranScreen> {
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _estimasiAngkaController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  
  String _satuanEstimasi = 'Jam';

  Timer? _countdownTimer;
  bool _isLoading = false;
  bool _isFetchingExistingBid = true;
  bool _hasExistingBid = false;
  bool _hasExpiredNotified = false;

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
    _checkExistingBidAndPrefill();
  }

  // Mengecek apakah Mitra sudah pernah mengajukan bid di order ini
  Future<void> _checkExistingBidAndPrefill() async {
    final userMitra = FirebaseAuth.instance.currentUser;
    String orderId = widget.item['id'] ?? widget.item['orderId'] ?? widget.item['docId'] ?? '';

    if (userMitra != null && orderId.isNotEmpty) {
      String customBidId = "${orderId}_${userMitra.uid}";
      try {
        DocumentSnapshot bidDoc = await FirebaseFirestore.instance
            .collection('bids')
            .doc(customBidId)
            .get();

        if (bidDoc.exists && mounted) {
          Map<String, dynamic> data = bidDoc.data() as Map<String, dynamic>;
          _hasExistingBid = true;

          // Prefill Harga
          String rawHarga = (data['harga'] ?? '').toString().replaceAll('Rp', '').trim();
          _hargaController.text = rawHarga;

          // Prefill Catatan
          _catatanController.text = data['catatan'] ?? '';

          // Prefill Estimasi (misal: "8 Jam")
          String durasi = data['durasi'] ?? '';
          if (durasi.isNotEmpty) {
            List<String> parts = durasi.split(' ');
            if (parts.isNotEmpty) {
              _estimasiAngkaController.text = parts[0];
            }
            if (parts.length > 1 && ['Menit', 'Jam', 'Hari'].contains(parts[1])) {
              _satuanEstimasi = parts[1];
            }
          }
        }
      } catch (e) {
        debugPrint("Gagal memuat penawaran sebelumnya: $e");
      }
    }

    // Jika belum pernah bid, pasang default dari item order
    if (!_hasExistingBid) {
      _hargaController.text = widget.item['startingBid'] ?? '';
      _estimasiAngkaController.text = widget.item['estSelesaiJumlah']?.toString() ?? '8';
      if (widget.item['estSelesaiSatuan'] != null) {
        String unit = widget.item['estSelesaiSatuan'].toString();
        if (['Menit', 'Jam', 'Hari'].contains(unit)) {
          _satuanEstimasi = unit;
        }
      }
    }

    if (mounted) {
      setState(() => _isFetchingExistingBid = false);
    }
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      DateTime? targetTime = widget.item['targetTime'] as DateTime?;
      if (targetTime != null) {
        Duration sisaDurasi = targetTime.difference(DateTime.now());

        if (sisaDurasi.isNegative || sisaDurasi.inSeconds <= 0) {
          _countdownTimer?.cancel();
          _handleExpiredExit();
        } else {
          setState(() {});
        }
      }
    });
  }

  void _handleExpiredExit() {
    if (_hasExpiredNotified) return;
    _hasExpiredNotified = true;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waktu penawaran telah habis! Halaman ditutup.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.pop(context);
    }
  }

  String _getFormattedRemainingTime() {
    DateTime? targetTime = widget.item['targetTime'] as DateTime?;
    if (targetTime == null) return "00:00";

    Duration sisaDurasi = targetTime.difference(DateTime.now());

    if (sisaDurasi.isNegative || sisaDurasi.inSeconds <= 0) {
      return "00:00";
    }

    String menit = sisaDurasi.inMinutes.remainder(60).toString().padLeft(2, '0');
    String detik = sisaDurasi.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$menit:$detik';
  }

  void _showImagePreviewDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image, color: Colors.grey, size: 48),
                        SizedBox(height: 8),
                        Text('Gambar gagal dimuat'),
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _hargaController.dispose();
    _estimasiAngkaController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _kirimPenawaran() async {
    final userMitra = FirebaseAuth.instance.currentUser;
    if (userMitra == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda belum login sebagai mitra.')),
      );
      return;
    }

    final String hargaTeks = _hargaController.text.trim();
    final String durasiAngka = _estimasiAngkaController.text.trim();
    final String catatanTeks = _catatanController.text.trim();

    if (hargaTeks.isEmpty || durasiAngka.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi harga dan estimasi waktu!')),
      );
      return;
    }

    final String estimasiLengkap = '$durasiAngka $_satuanEstimasi';

    setState(() => _isLoading = true);

    try {
      String orderId = widget.item['id'] ?? widget.item['orderId'] ?? widget.item['docId'] ?? '';

      if (orderId.isEmpty) {
        throw Exception("ID Order tidak ditemukan");
      }

      DocumentSnapshot mitraDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userMitra.uid)
          .get();

      String namaMitra = mitraDoc.exists && (mitraDoc.data() as Map)['nama'] != null
          ? (mitraDoc.data() as Map)['nama']
          : (userMitra.displayName ?? 'Mitra Helper');
      
      String fotoMitra = mitraDoc.exists && (mitraDoc.data() as Map)['photoUrl'] != null
          ? (mitraDoc.data() as Map)['photoUrl']
          : (userMitra.photoURL ?? 'https://i.pravatar.cc/150?img=11');

      String customBidId = "${orderId}_${userMitra.uid}";

      await FirebaseFirestore.instance
          .collection('bids')
          .doc(customBidId)
          .set({
        'bidId': customBidId,
        'mitraId': userMitra.uid,
        'mitraNama': namaMitra,
        'mitraFoto': fotoMitra,
        'harga': hargaTeks.startsWith('Rp') ? hargaTeks : 'Rp$hargaTeks',
        'durasi': estimasiLengkap,
        'catatan': catatanTeks,
        'pekerjaan': widget.item['judul'] ?? widget.item['jenisJasa'] ?? 'PEMBERSIHAN LAHAN',
        'orderId': orderId,
        'userId': widget.item['userId'] ?? widget.item['user_id'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_hasExistingBid ? 'Perubahan penawaran disimpan!' : 'Penawaran berhasil dikirim!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan penawaran: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Fungsi membatalkan/menarik penawaran
  Future<void> _batalkanPenawaran() async {
    final userMitra = FirebaseAuth.instance.currentUser;
    if (userMitra == null) return;

    String orderId = widget.item['id'] ?? widget.item['orderId'] ?? widget.item['docId'] ?? '';
    String customBidId = "${orderId}_${userMitra.uid}";

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('bids').doc(customBidId).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Penawaran Anda berhasil ditarik/dibatalkan.'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membatalkan penawaran: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetchingExistingBid) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFCB05),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Ajukan Penawaran',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFCB05)),
        ),
      );
    }

    String alamatUser = widget.item['alamat'] ?? 'Titik Lokasi Google Maps Belum Diisi';
    List<dynamic> rawFoto = widget.item['fotoUrls'] ?? widget.item['fotoPekerjaan'] ?? [];
    List<String> fotoPekerjaan = rawFoto.map((e) => e.toString()).toList();

    String deskripsiUser = (widget.item['deskripsi'] != null && widget.item['deskripsi'].toString().trim().isNotEmpty)
        ? widget.item['deskripsi']
        : 'Tidak ada deskripsi pekerjaan yang dilampirkan.';

    String sisaWaktuTeks = _getFormattedRemainingTime();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFCB05),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _hasExistingBid ? 'Edit Penawaran' : 'Ajukan Penawaran',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item['judul'] ?? widget.item['jenisJasa'] ?? 'Pembersihan Lahan',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          widget.item['kategori'] ?? 'Jasa Borongan',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: const Color(0xFFFFCB05), width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lokasi Pekerjaan:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            alamatUser,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (fotoPekerjaan.isNotEmpty)
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: fotoPekerjaan.length,
                    itemBuilder: (context, index) {
                      String imgUrl = fotoPekerjaan[index];
                      return GestureDetector(
                        onTap: () => _showImagePreviewDialog(imgUrl),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFCB05), width: 1.5),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  imgUrl,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.zoom_in,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Center(
                    child: Text(
                      'Pengguna tidak melampirkan foto',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              const Text(
                'Deskripsi Pekerjaan :',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(minHeight: 80),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFFFCB05), width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  deskripsiUser,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Harga Penawaran Anda (Biding)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _hargaController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  CurrencyInputFormatter(),
                ],
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: Colors.black,
                ),
                onChanged: (_) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  prefixText: 'Rp ',
                  prefixStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                  hintText: 'Masukkan nominal penawaran',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _hargaController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                          onPressed: () {
                            setState(() {
                              _hargaController.clear();
                            });
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Estimasi Selesai',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _estimasiAngkaController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        hintText: 'Jumlah',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _satuanEstimasi,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          items: ['Menit', 'Jam', 'Hari'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _satuanEstimasi = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'Catatan / Pesan Tambahan (Opsional)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _catatanController,
                maxLines: 3,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  hintText: 'Contoh: Sudah termasuk alat & bahan pembersih, siap meluncur lokasi...',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _kirimPenawaran,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCB05),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _hasExistingBid ? 'SIMPAN PERUBAHAN PENAWARAN' : 'KIRIM PENAWARAN',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),

              if (_hasExistingBid) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _batalkanPenawaran,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'BATALKAN / TARIK PENAWARAN',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}