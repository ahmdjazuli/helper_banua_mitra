import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'ajukan_penawaran.dart';

class DetailOrderanTerdekatScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final Position? mitraPosition;

  const DetailOrderanTerdekatScreen({
    super.key,
    required this.orderData,
    this.mitraPosition,
  });

  @override
  State<DetailOrderanTerdekatScreen> createState() => _DetailOrderanTerdekatScreenState();
}

class _DetailOrderanTerdekatScreenState extends State<DetailOrderanTerdekatScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initMapMarkers();
  }

  void _initMapMarkers() {
    double userLat = (widget.orderData['latitude'] ?? widget.orderData['lat'] ?? 0.0).toDouble();
    double userLng = (widget.orderData['longitude'] ?? widget.orderData['lng'] ?? 0.0).toDouble();

    if (userLat != 0.0 && userLng != 0.0) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(userLat, userLng),
          infoWindow: InfoWindow(
            title: 'Lokasi Pekerjaan',
            snippet: widget.orderData['userName'] ?? 'Pelanggan',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    if (widget.mitraPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('mitra_location'),
          position: LatLng(widget.mitraPosition!.latitude, widget.mitraPosition!.longitude),
          infoWindow: const InfoWindow(title: 'Lokasi Anda (Mitra)'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        ),
      );
    }
  }

  // Mengatur kamera peta agar mencakup kedua marker (Pelanggan & Mitra)
  void _fitBounds() {
    if (_mapController == null) return;

    double userLat = (widget.orderData['latitude'] ?? widget.orderData['lat'] ?? 0.0).toDouble();
    double userLng = (widget.orderData['longitude'] ?? widget.orderData['lng'] ?? 0.0).toDouble();

    if (userLat != 0.0 && userLng != 0.0 && widget.mitraPosition != null) {
      double southLat = userLat < widget.mitraPosition!.latitude ? userLat : widget.mitraPosition!.latitude;
      double northLat = userLat > widget.mitraPosition!.latitude ? userLat : widget.mitraPosition!.latitude;
      double westLng = userLng < widget.mitraPosition!.longitude ? userLng : widget.mitraPosition!.longitude;
      double eastLng = userLng > widget.mitraPosition!.longitude ? userLng : widget.mitraPosition!.longitude;

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(southLat, westLng),
        northeast: LatLng(northLat, eastLng),
      );

      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
    }
  }

  @override
  Widget build(BuildContext context) {
    double userLat = (widget.orderData['latitude'] ?? widget.orderData['lat'] ?? 0.0).toDouble();
    double userLng = (widget.orderData['longitude'] ?? widget.orderData['lng'] ?? 0.0).toDouble();

    LatLng initialCenter = userLat != 0.0 && userLng != 0.0
        ? LatLng(userLat, userLng)
        : (widget.mitraPosition != null
            ? LatLng(widget.mitraPosition!.latitude, widget.mitraPosition!.longitude)
            : const LatLng(-3.440232, 114.830722));

    String namaJasa = widget.orderData['jenisJasa'] ?? widget.orderData['service_name'] ?? 'Layanan';
    String namaKategori = widget.orderData['kategori'] ?? 'Kategori';
    String namaPelanggan = widget.orderData['userName'] ?? widget.orderData['customer_name'] ?? 'Pelanggan';
    String alamat = widget.orderData['alamat'] ?? widget.orderData['address'] ?? 'Alamat tidak tersedia';
    String deskripsi = widget.orderData['deskripsi'] ?? 'Tidak ada deskripsi.';
    String jarakDisplay = widget.orderData['distance_display'] ?? '- km';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFCB05),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Detail Peta Orderan',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: userLat != 0.0 && userLng != 0.0
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: initialCenter,
                      zoom: 14.5,
                    ),
                    markers: _markers,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _fitBounds();
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  )
                : Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Text(
                        'Titik koordinat peta tidak tersedia',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
          ),
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(namaJasa, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                          Text(namaKategori, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.near_me, color: Color(0xFFFFCB05), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              jarakDisplay,
                              style: const TextStyle(color: Color(0xFFFFCB05), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text('Pelanggan & Lokasi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(namaPelanggan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(alamat, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  const SizedBox(height: 12),
                  const Text('Deskripsi Pekerjaan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(deskripsi, style: const TextStyle(fontSize: 12, color: Colors.black87), maxLines: 3, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AjukanPenawaranScreen(item: widget.orderData),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFCB05),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text(
                        'AJUKAN PENAWARAN SEKARANG',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}