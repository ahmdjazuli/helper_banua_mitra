import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/background.dart';

class SetupLayananMitraScreen extends StatefulWidget {
  const SetupLayananMitraScreen({super.key});

  @override
  State<SetupLayananMitraScreen> createState() => _SetupLayananMitraScreenState();
}

class _SetupLayananMitraScreenState extends State<SetupLayananMitraScreen> {
  final _formKey = GlobalKey<FormState>();

  // Data Kategori & Sub-Layanan
  final Map<String, List<String>> _daftarLayanan = {
    'Kebersihan Harian': [
      'Bersih Rumah Standar',
      'Cuci Piring',
      'Cuci Baju',
      'Setrika Baju',
      'Bersihkan Dapur',
      'Paket 1. Standar ART Harian',
      'Paket 2. Premium ART Harian',
    ],
    'Kebersihan Khusus': [
      'Bersihkan Sofa',
      'Bersihkan Tungau',
      'Cuci Mobil',
      'Cuci Motor',
      'Cuci Kamar Mandi/WC',
      'Bersihkan Tandon',
      'Bersihkan Rumput Halaman',
      'Bersihkan Gudang',
      'Bersihkan Kolam',
      'Pembersihan Taman',
      'Pekerjaan lainnya Kebersihan Khusus',
    ],
    'Jasa Borongan': [
      'Bersihkan Lahan',
      'Bersihkan Rumah Kosong',
      'Bersihkan Rumah Pasca Renovasi',
      'Bersihkan Setelah Acara',
      'Rumah Pasca Banjir',
      'Tebang Pohon',
      'Bersihkan Kolam Renang',
      'Bersihkan Drainase/Parit',
      'Pekerjaan Lainnya',
    ],
    'Layanan Tukang': [
      'Perbaikan Ringan Bangunan',
      'Perbaikan Atap',
      'Perbaikan Plafon',
      'Perbaikan Keramik',
      'Pengecatan Ruangan',
      'Pekerjaan Konstruksi Ringan Lainnya',
      'Layanan Tukang Lainnya',
    ],
    'Layanan Personal': [
      'Driver Harian',
      'Jasa Fotografi',
      'Layanan Personal Lainnya',
    ],
    'Insidentil': [
      'Bocor Ban',
      'Aki Drop',
      'Mogok Perjalanan',
      'Jasa Towing',
    ],
    'Kelistrikan': [
      'Instalasi Listrik Baru',
      'Penambahan Titik Listrik',
      'Pergantian MCB/Sekring',
      'Pemeriksaan Instalasi Kelistrikan',
      'Pekerjaan Instalasi Layanan Listrik Lainnya',
    ],
    'Layanan AC': [
      'Pasang Baru',
      'Pembersihan Berkala',
      'Service Kerusakan',
      'Tambah Freon',
      'Bongkar Pasang AC',
      'Layanan AC Lainnya',
    ],
    'Pindah Rumah': [
      'Jasa Pindah Barang',
      'Mobil Angkutan Barang',
      'Paket Pindah',
    ],
    'Sanitasi': [
      'Sedot WC',
      'Layanan Sanitasi Lainnya',
    ],
    'Instalasi Air': [
      'Pasang Instalasi Air',
      'Perbaikan Saluran Instalasi',
      'Gali Sumur',
      'Layanan Instalasi Air Lainnya',
    ],
  };

  String? _selectedKategori;
  final Map<String, Set<String>> _selectedLayananPerKategori = {};

  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _pengalamanController = TextEditingController();

  final List<File> _sertifikatImages = [];
  List<String> _existingSertifikatUrls = [];
  
  String? _serviceStatus; // Menyimpan status persetujuan layanan
  bool _isLoading = false;
  bool _isAgreed = false;
  bool _isSummaryExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadExistingServiceData();
  }

  // Fetch data layanan dari Firestore saat halaman pertama kali dibuka
  Future<void> _loadExistingServiceData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Ambil langsung dokumen 'main_service' di subkoleksi mitra -> services
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('mitra')
          .doc(user.uid)
          .collection('services')
          .doc('main_service')
          .get();

      // Fallback: Jika 'main_service' tidak ada, coba ambil dokumen pertama dari subkoleksi services
      if (!doc.exists) {
        QuerySnapshot servicesSnap = await FirebaseFirestore.instance
            .collection('mitra')
            .doc(user.uid)
            .collection('services')
            .limit(1)
            .get();

        if (servicesSnap.docs.isNotEmpty) {
          doc = servicesSnap.docs.first;
        }
      }

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        setState(() {
          _serviceStatus = data['status']; // Mengambil status layanan
          _deskripsiController.text = data['deskripsi'] ?? '';
          _pengalamanController.text = data['pengalaman'] ?? '';

          if (data['sertifikatUrls'] != null) {
            _existingSertifikatUrls = List<String>.from(data['sertifikatUrls']);
          }

          // Parsing layanan yang dipilih
          if (data['layananDipilih'] != null && data['layananDipilih'] is List) {
            List dynamicList = data['layananDipilih'];
            for (var item in dynamicList) {
              if (item is Map) {
                String kat = item['kategori'] ?? '';
                List nLayanan = item['namaLayanan'] ?? [];
                if (kat.isNotEmpty) {
                  _selectedLayananPerKategori[kat] =
                      Set<String>.from(nLayanan.map((e) => e.toString()));
                }
              }
            }
          }

          if (_selectedLayananPerKategori.isNotEmpty) {
            _selectedKategori = _selectedLayananPerKategori.keys.first;
            _isAgreed = true; // Set true jika sudah pernah mengisi
          }
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat data layanan tersimpan: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _deskripsiController.dispose();
    _pengalamanController.dispose();
    super.dispose();
  }

  // Hitung total layanan terpilih
  int get _totalSelectedCount {
    int total = 0;
    _selectedLayananPerKategori.forEach((_, setLayanan) {
      total += setLayanan.length;
    });
    return total;
  }

  // Reset Pilihan
  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Form?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin mengosongkan seluruh pilihan layanan dan form?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _selectedLayananPerKategori.clear();
                _selectedKategori = null;
                _sertifikatImages.clear();
                _existingSertifikatUrls.clear();
                _deskripsiController.clear();
                _pengalamanController.clear();
                _isAgreed = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Seluruh pilihan berhasil direset.')),
              );
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Pick Image Sertifikat
  Future<void> _pickImage() async {
    int totalCount = _sertifikatImages.length + _existingSertifikatUrls.length;
    if (totalCount >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal upload 2 sertifikat!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _sertifikatImages.add(File(pickedFile.path));
      });
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _sertifikatImages.removeAt(index);
    });
  }

  void _removeExistingUrl(int index) {
    setState(() {
      _existingSertifikatUrls.removeAt(index);
    });
  }

  // Preview Image Fullscreen
  void _showImagePreview({File? file, String? url}) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: file != null
                  ? Image.file(file, fit: BoxFit.contain)
                  : Image.network(url!, fit: BoxFit.contain),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  // Modal Detail Perjanjian
  void _showTermsDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(fontSize: 13, height: 1.4)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          )
        ],
      ),
    );
  }

  // Submit Data
  Future<void> _submitLayanan() async {
    if (_totalSelectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu layanan!'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (!_isAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus menyetujui Perjanjian Mitra dan Potongan Fee Layanan!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      List<String> sertifikatUrls = List.from(_existingSertifikatUrls);
      for (int i = 0; i < _sertifikatImages.length; i++) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('sertifikat_mitra/${user.uid}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        await storageRef.putFile(_sertifikatImages[i]);
        String downloadUrl = await storageRef.getDownloadURL();
        sertifikatUrls.add(downloadUrl);
      }

      List<Map<String, dynamic>> structuredServices = [];
      List<String> kategoriAktifList = [];

      _selectedLayananPerKategori.forEach((kategori, setLayanan) {
        if (setLayanan.isNotEmpty) {
          kategoriAktifList.add(kategori);
          structuredServices.add({
            'kategori': kategori,
            'namaLayanan': setLayanan.toList(),
          });
        }
      });

      await FirebaseFirestore.instance
          .collection('mitra')
          .doc(user.uid)
          .collection('services')
          .doc('main_service')
          .set({
        'layananDipilih': structuredServices,
        'deskripsi': _deskripsiController.text.trim(),
        'pengalaman': _pengalamanController.text.trim(),
        'sertifikatUrls': sertifikatUrls,
        'status': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('mitra').doc(user.uid).set({
        'isSetupCompleted': true,
        'statusMitra': 'approved',
        'kategoriAktif': kategoriAktifList,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setup Layanan Mitra berhasil disimpan!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> subLayananOptions = _selectedKategori != null
        ? _daftarLayanan[_selectedKategori!] ?? []
        : [];

    bool isAllSelectedInCurrentKategori = _selectedKategori != null &&
        subLayananOptions.isNotEmpty &&
        (_selectedLayananPerKategori[_selectedKategori!]?.length ?? 0) == subLayananOptions.length;

    int totalSertifikatCount = _existingSertifikatUrls.length + _sertifikatImages.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header Kustom
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFCB05),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Layanan Mitra (Setup Wajib)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: _confirmReset,
                      icon: const Icon(Icons.refresh, color: Colors.black, size: 18),
                      label: const Text('Reset', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),

              // Content Body
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.black))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- BANNER INFORMASI STATUS PENGAJUAN DISERUTUJI/DITERIMA ---
                              if (_serviceStatus == 'approved' || _serviceStatus == 'diterima') ...[
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.green.shade400, width: 1.2),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.verified, color: Colors.green, size: 28),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: const [
                                            Text(
                                              'Pengajuan Layanan Disetujui',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.green,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Pengajuan layanan Anda sebelumnya telah diterima dan aktif. Jika ingin mengajukan ulang (mengganti pilihan layanan, ubah deskripsi, pengalaman layanan, atau upload sertifikat), silakan sesuaikan form di bawah lalu klik tombol "Ajukan Ulang Layanan".',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.black87,
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // 1. Ringkasan Total + Expandable Chips Summary
                              if (_totalSelectedCount > 0) ...[
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.green.shade300),
                                  ),
                                  child: Column(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _isSummaryExpanded = !_isSummaryExpanded;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Total $_totalSelectedCount layanan terpilih dari ${_selectedLayananPerKategori.entries.where((e) => e.value.isNotEmpty).length} kategori.',
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                                                ),
                                              ),
                                              Icon(
                                                _isSummaryExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                                color: Colors.green,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (_isSummaryExpanded) ...[
                                        const Divider(height: 1, color: Colors.black12),
                                        Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: _selectedLayananPerKategori.entries.expand((entry) {
                                              return entry.value.map((layanan) => Chip(
                                                    label: Text('$layanan (${entry.key})', style: const TextStyle(fontSize: 10)),
                                                    backgroundColor: Colors.white,
                                                    deleteIcon: const Icon(Icons.close, size: 12),
                                                    onDeleted: () {
                                                      setState(() {
                                                        _selectedLayananPerKategori[entry.key]?.remove(layanan);
                                                      });
                                                    },
                                                    visualDensity: VisualDensity.compact,
                                                  ));
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],

                              // 2. Kategori Dropdown
                              const Text('Pilih Kategori Layanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  hintText: 'Pilih Kategori Layanan',
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black26)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFFFCB05), width: 2)),
                                ),
                                value: _selectedKategori,
                                items: _daftarLayanan.keys.map((String kategori) {
                                  final count = _selectedLayananPerKategori[kategori]?.length ?? 0;
                                  return DropdownMenuItem<String>(
                                    value: kategori,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(kategori, style: const TextStyle(fontSize: 14)),
                                        if (count > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: const Color(0xFFFFCB05), borderRadius: BorderRadius.circular(10)),
                                            child: Text('$count dipilih', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedKategori = val;
                                  });
                                },
                              ),
                              const SizedBox(height: 18),

                              // 3. Sub-Layanan Checklist + Select All
                              if (_selectedKategori != null) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text('Pilih Layanan di $_selectedKategori', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          if (!_selectedLayananPerKategori.containsKey(_selectedKategori!)) {
                                            _selectedLayananPerKategori[_selectedKategori!] = {};
                                          }
                                          if (isAllSelectedInCurrentKategori) {
                                            _selectedLayananPerKategori[_selectedKategori!]!.clear();
                                          } else {
                                            _selectedLayananPerKategori[_selectedKategori!]!.addAll(subLayananOptions);
                                          }
                                        });
                                      },
                                      child: Text(
                                        isAllSelectedInCurrentKategori ? 'Hapus Semua' : 'Pilih Semua',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.black26),
                                  ),
                                  child: Column(
                                    children: subLayananOptions.map((layanan) {
                                      final currentSet = _selectedLayananPerKategori[_selectedKategori!] ?? {};
                                      final isChecked = currentSet.contains(layanan);

                                      return CheckboxListTile(
                                        title: Text(layanan, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                        value: isChecked,
                                        activeColor: const Color(0xFFFFCB05),
                                        checkColor: Colors.black,
                                        controlAffinity: ListTileControlAffinity.leading,
                                        dense: true,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            if (!_selectedLayananPerKategori.containsKey(_selectedKategori!)) {
                                              _selectedLayananPerKategori[_selectedKategori!] = {};
                                            }
                                            if (value == true) {
                                              _selectedLayananPerKategori[_selectedKategori!]!.add(layanan);
                                            } else {
                                              _selectedLayananPerKategori[_selectedKategori!]!.remove(layanan);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ],

                              // 4. Upload Sertifikat + Preview Fullscreen
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Sertifikat (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                                  Text('$totalSertifikatCount/2 File', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    // Sertifikat dari Firestore URL
                                    ..._existingSertifikatUrls.asMap().entries.map((entry) {
                                      int idx = entry.key;
                                      String url = entry.value;
                                      return Stack(
                                        children: [
                                          GestureDetector(
                                            onTap: () => _showImagePreview(url: url),
                                            child: Container(
                                              width: 100,
                                              height: 100,
                                              margin: const EdgeInsets.only(right: 12),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                                                border: Border.all(color: Colors.black26),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 16,
                                            child: GestureDetector(
                                              onTap: () => _removeExistingUrl(idx),
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),

                                    // Sertifikat File Baru
                                    ..._sertifikatImages.asMap().entries.map((entry) {
                                      int idx = entry.key;
                                      File file = entry.value;
                                      return Stack(
                                        children: [
                                          GestureDetector(
                                            onTap: () => _showImagePreview(file: file),
                                            child: Container(
                                              width: 100,
                                              height: 100,
                                              margin: const EdgeInsets.only(right: 12),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
                                                border: Border.all(color: Colors.black26),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 16,
                                            child: GestureDetector(
                                              onTap: () => _removeNewImage(idx),
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),

                                    if (totalSertifikatCount < 2)
                                      GestureDetector(
                                        onTap: _pickImage,
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.black26),
                                          ),
                                          child: const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.add_a_photo, color: Colors.black54, size: 28),
                                              SizedBox(height: 4),
                                              Text('Tambah', style: TextStyle(color: Colors.black54, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // 5. Deskripsi Layanan
                              const Text('Deskripsi Layanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _deskripsiController,
                                maxLines: 3,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Contoh: Layanan pembersihan rumah mencakup sweeping, mopping, dan perapihan perabot...',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black26)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFFFCB05), width: 2)),
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Deskripsi layanan wajib diisi' : null,
                              ),
                              const SizedBox(height: 18),

                              // 6. Pengalaman Layanan
                              const Text('Pengalaman Layanan (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _pengalamanController,
                                maxLines: 2,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Contoh: Berpengalaman 3 tahun di bidang kebersihan rumah tangga...',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black26)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFFFCB05), width: 2)),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // 7. Checkbox Perjanjian Mitra & Clickable Modal
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFFCB05)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Checkbox(
                                      value: _isAgreed,
                                      activeColor: const Color(0xFFFFCB05),
                                      checkColor: Colors.black,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      onChanged: (bool? val) {
                                        setState(() {
                                          _isAgreed = val ?? false;
                                        });
                                      },
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                                            children: [
                                              const TextSpan(text: 'Saya menyatakan telah membaca, memahami, dan menyetujui seluruh '),
                                              TextSpan(
                                                text: 'Perjanjian Mitra',
                                                style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline, color: Colors.blue),
                                                recognizer: TapGestureRecognizer()
                                                  ..onTap = () => _showTermsDialog(
                                                        'Perjanjian Mitra',
                                                        'Mitra bersedia memberikan layanan sesuai standar K3, bersikap profesional, dan mematuhi seluruh kode etik Helper Banua.',
                                                      ),
                                              ),
                                              const TextSpan(text: ', '),
                                              TextSpan(
                                                text: 'Kebijakan Privasi',
                                                style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline, color: Colors.blue),
                                                recognizer: TapGestureRecognizer()
                                                  ..onTap = () => _showTermsDialog(
                                                        'Kebijakan Privasi',
                                                        'Data diri dan dokumen pendukung hanya digunakan untuk verifikasi kualifikasi layanan mitra di sistem Helper Banua.',
                                                      ),
                                              ),
                                              const TextSpan(text: ', serta skema '),
                                              TextSpan(
                                                text: 'Potongan Fee Layanan 10%',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                                                recognizer: TapGestureRecognizer()
                                                  ..onTap = () => _showTermsDialog(
                                                        'Potongan Fee Layanan 10%',
                                                        'Setiap transaksi pesanan yang diselesaikan melalui aplikasi akan dikenakan biaya komisi platform sebesar 10% dari total nilai transaksi.',
                                                      ),
                                              ),
                                              const TextSpan(text: ' untuk setiap transaksi pesanan selesai.'),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // 8. Tombol Submit (Ajukan / Ajukan Ulang Layanan)
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFCB05),
                                    disabledBackgroundColor: Colors.grey.shade300,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: _isAgreed ? _submitLayanan : null,
                                  child: Text(
                                    (_serviceStatus == 'approved' || _serviceStatus == 'diterima')
                                        ? 'Ajukan Ulang Layanan'
                                        : 'Ajukan Layanan',
                                    style: TextStyle(
                                      color: _isAgreed ? Colors.black : Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}