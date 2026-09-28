import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AjukanPenawaranScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const AjukanPenawaranScreen({super.key, required this.item});

  @override
  State<AjukanPenawaranScreen> createState() => _AjukanPenawaranScreenState();
}

class _AjukanPenawaranScreenState extends State<AjukanPenawaranScreen> {
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _estimasiController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _hargaController.text = widget.item['startingBid'] ?? '';
    _estimasiController.text = '8 JAM';
  }

  @override
  void dispose() {
    _hargaController.dispose();
    _estimasiController.dispose();
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
    final String estimasiTeks = _estimasiController.text.trim();

    if (hargaTeks.isEmpty || estimasiTeks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi harga dan estimasi waktu!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String orderId = widget.item['id'] ?? widget.item['docId'] ?? '';

      if (orderId.isEmpty) {
        throw Exception("ID Order tidak ditemukan");
      }

      // Ambil data profil mitra dari Firestore/Auth
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

      // (Top-level Collection - TANPA perlunya Index Console):
      String customBidId = "${orderId}_${userMitra.uid}"; // Kombinasi ID Order & ID Mitra

      await FirebaseFirestore.instance
          .collection('bids')
          .doc(customBidId)
          .set({
        'bidId': customBidId,
        'mitraId': userMitra.uid,
        'mitraNama': namaMitra,
        'mitraFoto': fotoMitra,
        'harga': hargaTeks.startsWith('Rp') ? hargaTeks : 'Rp$hargaTeks',
        'durasi': estimasiTeks,
        'pekerjaan': widget.item['judul'] ?? widget.item['layanan_nama'] ?? 'PEMBERSIHAN LAHAN',
        'orderId': orderId,
        'userId': widget.item['userId'] ?? widget.item['user_id'] ?? '', // ID Pemilik Order
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Penawaran berhasil dikirim!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim penawaran: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String mapImageUrl = 'https://maps.googleapis.com/maps/api/staticmap?center=-3.4400,114.8300&zoom=15&size=600x300&markers=color:red%7C-3.4400,114.8300&key=YOUR_API_KEY';
    List<String> fotoPekerjaan = widget.item['fotoPekerjaan'] ?? [
      'https://images.unsplash.com/photo-1558904541-efa843a96f01?q=80&w=400&auto=format&fit=crop',
    ];

    String deskripsiUser = widget.item['deskripsi'] ?? 
        'Pembersihan rumput liar dan pembabatan lahan seluas 10x15m. Sampah sisa pembabatan dikumpulkan rapi di sudut depan.';

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
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item['judul'] ?? widget.item['layanan_nama'] ?? 'Pembersihan Lahan',
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
            const SizedBox(height: 12),

            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFFCB05), width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  mapImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on, color: Colors.red),
                            SizedBox(width: 6),
                            Text(
                              'Titik Lokasi Google Maps',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: fotoPekerjaan.map((imgUrl) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(imgUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }).toList(),
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
              constraints: const BoxConstraints(minHeight: 90),
              decoration: BoxDecoration(
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
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Estimasi Selesai (Jam/Hari)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _estimasiController,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    : const Text(
                        'KIRIM PENAWARAN',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}