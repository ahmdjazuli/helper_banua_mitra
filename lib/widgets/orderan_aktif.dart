import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActiveOrderCardSection extends StatelessWidget {
  const ActiveOrderCardSection({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      // Mengambil orderan mitra yang statusnya sedang berlangsung
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('mitra_id', isEqualTo: user.uid)
          .where('status', whereIn: ['diproses', 'menuju_lokasi', 'sedang_dikerjakan'])
          .limit(1) // Mengambil 1 pekerjaan aktif utama
          .snapshots(),
      builder: (context, snapshot) {
        // Jika sedang loading atau tidak ada pekerjaan aktif, tidak menampilkan apa-apa
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink(); 
        }

        final orderDoc = snapshot.data!.docs.first;
        final orderData = orderDoc.data() as Map<String, dynamic>;

        final String serviceName = orderData['service_name'] ?? 'Layanan Helper';
        final String customerName = orderData['customer_name'] ?? 'Pelanggan';
        final String address = orderData['address'] ?? 'Alamat tidak tersedia';
        final String status = orderData['status'] ?? 'diproses';

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER KARTU
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'PEKERJAAN BERLANGSUNG',
                        style: TextStyle(
                          color: Color(0xFFFFCB05),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCB05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 20),

              // DETAIL PEKERJAAN
              Text(
                serviceName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    customerName,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // TOMBOL AKSI CEPAT
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCB05),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // Navigasi ke Halaman Detail / Progres Pekerjaan
                  },
                  icon: const Icon(Icons.directions_run),
                  label: const Text(
                    'LIHAT DETAIL PEKERJAAN',
                    style: TextStyle(fontWeight: FontWeight.bold),
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