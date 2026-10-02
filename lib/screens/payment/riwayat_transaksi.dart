import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../widgets/background.dart';

class RiwayatTransaksiMitraScreen extends StatefulWidget {
  const RiwayatTransaksiMitraScreen({super.key});

  @override
  State<RiwayatTransaksiMitraScreen> createState() => _RiwayatTransaksiMitraScreenState();
}

class _RiwayatTransaksiMitraScreenState extends State<RiwayatTransaksiMitraScreen> {
  int _currentPage = 0;
  static const int _itemsPerPage = 8;

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String currentUid = user?.uid ?? '';

    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AppBackground(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Riwayat Transaksi Mitra',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: currentUid.isEmpty
                    ? const Center(
                        child: Text(
                          'Pengguna tidak ditemukan',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('transactions')
                            .where('userId', isEqualTo: currentUid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(color: Colors.black),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text(
                                'Belum ada riwayat transaksi',
                                style: TextStyle(color: Colors.black54),
                              ),
                            );
                          }

                          final docs = List<QueryDocumentSnapshot>.from(snapshot.data!.docs);
                          docs.sort((a, b) {
                            final dataA = a.data() as Map<String, dynamic>;
                            final dataB = b.data() as Map<String, dynamic>;
                            final Timestamp? timeA = dataA['createdAt'] as Timestamp?;
                            final Timestamp? timeB = dataB['createdAt'] as Timestamp?;

                            if (timeA == null || timeB == null) return 0;
                            return timeB.compareTo(timeA);
                          });

                          final int totalItems = docs.length;
                          final int totalPages = (totalItems / _itemsPerPage).ceil();

                          if (_currentPage >= totalPages && totalPages > 0) {
                            _currentPage = totalPages - 1;
                          }

                          final int startIndex = _currentPage * _itemsPerPage;
                          final int endIndex = (startIndex + _itemsPerPage < totalItems)
                              ? startIndex + _itemsPerPage
                              : totalItems;

                          final pageDocs = docs.sublist(startIndex, endIndex);

                          return Column(
                            children: [
                              Expanded(
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  itemCount: pageDocs.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final data = pageDocs[index].data() as Map<String, dynamic>;
                                    final String type = data['type'] ?? 'WITHDRAW';
                                    final num amount = data['amount'] ?? 0;
                                    final String status = data['status'] ?? 'PENDING';
                                    final String title = data['description'] ??
                                        (type == 'INCOME' ? 'Pendapatan Jasa' : 'Penarikan Saldo');

                                    final Timestamp? timestamp = data['createdAt'] as Timestamp?;
                                    final DateTime date = timestamp != null
                                        ? timestamp.toDate().toLocal()
                                        : DateTime.now();
                                    final String formattedDate =
                                        DateFormat('dd MMM yyyy, HH:mm').format(date);

                                    bool isMasuk = type.toUpperCase() == 'INCOME' || type.toUpperCase() == 'TOPUP';

                                    return Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: isMasuk ? Colors.green.shade50 : Colors.red.shade50,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              isMasuk ? Icons.account_balance_wallet_rounded : Icons.outbox_rounded,
                                              color: isMasuk ? Colors.green.shade700 : Colors.red.shade700,
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  formattedDate,
                                                  style: TextStyle(
                                                      fontSize: 11, color: Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
                                          ),

                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${isMasuk ? "+" : "-"} Rp ${currencyFormatter.format(amount)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 14,
                                                  color: isMasuk
                                                      ? Colors.green.shade700
                                                      : Colors.red.shade700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              _buildStatusBadge(status),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                              if (totalPages > 1)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, -2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        onPressed: _currentPage > 0
                                            ? () {
                                                setState(() {
                                                  _currentPage--;
                                                });
                                              }
                                            : null,
                                        icon: const Icon(Icons.arrow_back_ios_rounded),
                                        iconSize: 18,
                                        color: Colors.black,
                                        disabledColor: Colors.grey.shade300,
                                      ),
                                      Text(
                                        'Halaman ${_currentPage + 1} dari $totalPages',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _currentPage < totalPages - 1
                                            ? () {
                                                setState(() {
                                                  _currentPage++;
                                                });
                                              }
                                            : null,
                                        icon: const Icon(Icons.arrow_forward_ios_rounded),
                                        iconSize: 18,
                                        color: Colors.black,
                                        disabledColor: Colors.grey.shade300,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label = status.toUpperCase();

    switch (label) {
      case 'SUCCESS':
      case 'BERHASIL':
      case 'PAID':
      case 'COMPLETED':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        label = 'Berhasil';
        break;
      case 'PENDING':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        label = 'Pending';
        break;
      default:
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        label = 'Gagal';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}