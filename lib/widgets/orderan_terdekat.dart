import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../screens/order/orderan_terdekat_detail.dart';

class NearestOrdersSection extends StatelessWidget {
  final bool isOnline;

  const NearestOrdersSection({
    super.key,
    required this.isOnline,
  });

  Future<Position?> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Widget _buildEmptyOrdersState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Orderan Terdekat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              '0 Ditemukan',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Center(
            child: Text(
              'Belum ada orderan baru di sekitar Anda.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isOnline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Orderan Terdekat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.grey.shade500, size: 28),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Aktifkan status Online untuk melihat penawaran orderan terdekat.',
                    style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return FutureBuilder<Position?>(
      future: _determinePosition(),
      builder: (context, posSnapshot) {
        if (posSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Color(0xFFFFCB05)),
            ),
          );
        }

        final Position? mitraPos = posSnapshot.data;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('status', isEqualTo: 'Proses Bidding')
              .snapshots(),
          builder: (context, orderSnapshot) {
            if (orderSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: Color(0xFFFFCB05)),
                ),
              );
            }

            if (!orderSnapshot.hasData || orderSnapshot.data!.docs.isEmpty) {
              return _buildEmptyOrdersState();
            }

            List<Map<String, dynamic>> processedOrders = [];

            for (var doc in orderSnapshot.data!.docs) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              data['order_id'] = doc.id;
              data['id'] = doc.id;

              double userLat = (data['latitude'] ?? data['lat'] ?? 0.0).toDouble();
              double userLng = (data['longitude'] ?? data['lng'] ?? 0.0).toDouble();

              if (mitraPos != null && userLat != 0.0 && userLng != 0.0) {
                double distanceInMeters = Geolocator.distanceBetween(
                  mitraPos.latitude,
                  mitraPos.longitude,
                  userLat,
                  userLng,
                );
                double distanceInKm = distanceInMeters / 1000;
                data['calculated_distance'] = distanceInKm;
                data['distance_display'] = '${distanceInKm.toStringAsFixed(1)} km';
              } else {
                data['calculated_distance'] = 999.0;
                data['distance_display'] = '- km';
              }

              if (data['calculated_distance'] <= 10.0) {
                processedOrders.add(data);
              }
            }

            processedOrders.sort((a, b) =>
                (a['calculated_distance'] as double)
                    .compareTo(b['calculated_distance'] as double));

            if (processedOrders.isEmpty) {
              return _buildEmptyOrdersState();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Orderan Terdekat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '${processedOrders.length} Ditemukan',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: processedOrders.length,
                  itemBuilder: (context, index) {
                    final order = processedOrders[index];
                    final isLastItem = index == processedOrders.length - 1;

                    String namaJasa = order['jenisJasa'] ?? order['service_name'] ?? 'Layanan';
                    String namaPelanggan = order['userName'] ?? order['customer_name'] ?? order['namaPelanggan'] ?? 'Pelanggan';
                    String alamatPelanggan = order['alamat'] ?? order['address'] ?? 'Alamat tidak tersedia';
                    dynamic hargaRaw = order['startingBid'] ?? order['hargaBidding'] ?? order['price'] ?? 0;

                    String teksHarga = 'Rp $hargaRaw';
                    if (hargaRaw is num) {
                      teksHarga = 'Rp ${hargaRaw.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
                    }

                    return Container(
                      margin: EdgeInsets.only(bottom: isLastItem ? 0 : 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFCB05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  namaJasa,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.near_me_rounded, size: 14, color: Colors.black54),
                                  const SizedBox(width: 4),
                                  Text(
                                    order['distance_display'] ?? '-',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            namaPelanggan,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            alamatPelanggan,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Divider(height: 20, thickness: 1),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                teksHarga,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailOrderanTerdekatScreen(
                                        orderData: order,
                                        mitraPosition: mitraPos,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Lihat Detail',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}