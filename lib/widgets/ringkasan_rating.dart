import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatingSummarySection extends StatelessWidget {
  const RatingSummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: user != null
          ? FirebaseFirestore.instance
              .collection('users') // Sesuaikan dengan nama koleksi mitra Anda (misal: 'mitra' atau 'users')
              .doc(user.uid)
              .snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {
        String ratingText = '0.0';
        String totalCompletedText = '0';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data != null) {
            // Mengambil rating mitra (default 0.0 jika belum ada)
            double rating = (data['rating'] ?? 0.0).toDouble();
            ratingText = rating > 0 ? rating.toStringAsFixed(1) : '0.0';

            // Mengambil total pekerjaan selesai
            int completedOrders = (data['completed_orders'] ?? 0) as int;
            totalCompletedText = completedOrders.toString();
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFCB05),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Rating',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ratingText,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1.5, height: 60, color: Colors.black),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Pekerjaan Selesai',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      totalCompletedText,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}