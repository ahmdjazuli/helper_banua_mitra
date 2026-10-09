import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerScreen extends StatefulWidget {
  final String? initialAddress;
  final double? initialLatitude;
  final double? initialLongitude;

  const MapPickerScreen({
    super.key,
    this.initialAddress,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _currentCenter = const LatLng(-3.4400, 114.8300); // Default Banjarbaru
  String _selectedAddress = "Mencari lokasi...";
  bool _isFetchingAddress = false;
  final TextEditingController _searchMapController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initStartingPosition();
  }

  @override
  void dispose() {
    _searchMapController.dispose();
    super.dispose();
  }

  Future<void> _initStartingPosition() async {
    setState(() => _isFetchingAddress = true);

    // PRIORITAS 1: Gunakan koordinat LatLng persis jika sudah ada
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      LatLng savedLatLng = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _moveCameraToPosition(savedLatLng);
      _getAddressFromLatLng(savedLatLng);
      return;
    }

    // PRIORITAS 2: Konversi dari string alamat tersimpan
    if (widget.initialAddress != null && widget.initialAddress!.trim().isNotEmpty) {
      try {
        List<Location> locations = await Geocoding()
            .locationFromAddress(widget.initialAddress!.trim());

        if (locations.isNotEmpty) {
          Location loc = locations.first;
          LatLng savedLatLng = LatLng(loc.latitude, loc.longitude);
          _moveCameraToPosition(savedLatLng);
          _getAddressFromLatLng(savedLatLng);
          return;
        }
      } catch (e) {
        debugPrint("Gagal geocoding alamat tersimpan: $e");
      }
    }

    // PRIORITAS 3: Posisi GPS saat ini
    _initCurrentGPSPosition();
  }

  Future<void> _initCurrentGPSPosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      LatLng userLatLng = LatLng(position.latitude, position.longitude);
      _moveCameraToPosition(userLatLng);
      _getAddressFromLatLng(userLatLng);
    } catch (_) {
      setState(() => _isFetchingAddress = false);
    }
  }

  void _moveCameraToPosition(LatLng latLng) {
    _currentCenter = latLng;
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 17));
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() => _isFetchingAddress = true);
    try {
      List<Placemark> placemarks = await Geocoding()
          .placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String fullAddress = [
          place.street,
          place.subLocality,
          place.locality,
          place.subAdministrativeArea,
          place.administrativeArea
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        setState(() {
          _selectedAddress = fullAddress.isNotEmpty
              ? fullAddress
              : "Lat: ${position.latitude.toStringAsFixed(5)}, Long: ${position.longitude.toStringAsFixed(5)}";
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = "Gagal memuat nama jalan.";
      });
    } finally {
      setState(() => _isFetchingAddress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Titik Lokasi',
            style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          // GOOGLE MAPS
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentCenter,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentCenter, 17));
            },
            onCameraMove: (position) {
              _currentCenter = position.target;
            },
            onCameraIdle: () {
              _getAddressFromLatLng(_currentCenter);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // FIX PIN DI TENGAH LAYAR
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36.0),
              child: Icon(
                Icons.location_pin,
                size: 48,
                color: Colors.red.shade600,
              ),
            ),
          ),

          // FLOATING AUTOCOMPLETE SEARCH BAR
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GooglePlaceAutoCompleteTextField(
                  textEditingController: _searchMapController,
                  googleAPIKey: dotenv.env['MAPS_API_KEY'] ?? '',
                  inputDecoration: const InputDecoration(
                    hintText: 'Cari jalan, gedung, atau area...',
                    prefixIcon: Icon(Icons.search, color: Colors.black54),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  debounceTime: 800,
                  countries: const ["id"],
                  getPlaceDetailWithLatLng: (Prediction prediction) {
                    if (prediction.lat != null && prediction.lng != null) {
                      double lat = double.parse(prediction.lat!);
                      double lng = double.parse(prediction.lng!);
                      LatLng searchedLatLng = LatLng(lat, lng);

                      _moveCameraToPosition(searchedLatLng);
                      _getAddressFromLatLng(searchedLatLng);
                    }
                  },
                  itemClick: (Prediction prediction) {
                    _searchMapController.text = prediction.description ?? '';
                    _searchMapController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _searchMapController.text.length),
                    );
                  },
                ),
              ),
            ),
          ),

          // TOMBOL GPS SAYA
          Positioned(
            right: 16,
            bottom: 160,
            child: FloatingActionButton(
              heroTag: 'gps_fab',
              backgroundColor: Colors.white,
              mini: true,
              onPressed: _initCurrentGPSPosition,
              child: const Icon(Icons.my_location, color: Colors.black87),
            ),
          ),

          // CARD DETAIL LOKASI TERPILIH
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LOKASI TERPILIH',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _isFetchingAddress
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : Text(
                                _selectedAddress,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFCB05),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: _isFetchingAddress
                          ? null
                          : () => Navigator.pop(context, {
                                'address': _selectedAddress,
                                'latitude': _currentCenter.latitude,
                                'longitude': _currentCenter.longitude,
                              }),
                      child: const Text(
                        'PILIH LOKASI INI',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
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