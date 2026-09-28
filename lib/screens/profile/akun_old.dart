import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../auth/login.dart';
import '../../widgets/background.dart';

class AkunScreen extends StatefulWidget {
  const AkunScreen({super.key});

  @override
  State<AkunScreen> createState() => _AkunScreenState();
}

class _AkunScreenState extends State<AkunScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _mapsController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _photoUrl;
  bool _isLoading = false;
  bool _isObscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _mapsController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Pengecekan apakah pengguna login menggunakan provider Google
  bool _isGoogleUser() {
    User? user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((info) => info.providerId == 'google.com');
  }

  // 1. Memuat Data Pengguna dari Firebase Auth & Firestore
  Future<void> _loadUserData() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      _emailController.text = currentUser.email ?? '';
      _namaController.text = currentUser.displayName ?? '';
      _photoUrl = currentUser.photoURL;

      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _namaController.text = data['nama'] ?? _namaController.text;
            _phoneController.text = data['phone'] ?? '';
            _mapsController.text = data['alamat'] ?? '';
            if (data['photoUrl'] != null &&
                data['photoUrl'].toString().isNotEmpty) {
              _photoUrl = data['photoUrl'];
            }
          });
        }
      } catch (e) {
        debugPrint("Error loading user data: $e");
      }
    }
  }

  // 2. Simpan Perubahan Data Profil
  Future<void> _saveProfileChanges() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Update Nama di Firebase Auth
      if (_namaController.text.trim() != user.displayName) {
        await user.updateDisplayName(_namaController.text.trim());
      }

      // Update Password (Hanya jika bukan login via Google dan field diisi)
      if (!_isGoogleUser() && _passwordController.text.trim().isNotEmpty) {
        await user.updatePassword(_passwordController.text.trim());
      }

      // Update Data Tambahan di Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'nama': _namaController.text.trim(),
        'phone': _phoneController.text.trim(),
        'alamat': _mapsController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _passwordController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui profil: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 3. Unggah Foto ke Firebase Storage & Update Document Firestore
  Future<void> _pickAndUploadImage(ImageSource source) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() => _isLoading = true);

      File file = File(pickedFile.path);

      Reference storageRef =
          _storage.ref().child('profile_pictures/${user.uid}.jpg');
      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();

      await user.updatePhotoURL(downloadUrl);
      await _firestore.collection('users').doc(user.uid).set({
        'photoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _photoUrl = downloadUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui foto: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 4. FUNGSI MENGHAPUS SEMUA DATA ORDERS DI FIRESTORE
  Future<void> _cleanUpAllOrders() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFCB05)),
      ),
    );

    try {
      QuerySnapshot snapshot = await _firestore.collection('orders').get();
      WriteBatch batch = _firestore.batch();

      for (DocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil menghapus ${snapshot.docs.length} data orderan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showConfirmCleanUpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Reset Data Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Apakah Anda yakin ingin menghapus SELURUH data pesanan di Firebase?\n\n'
            'Tindakan ini akan mengosongkan bursa orderan untuk keperluan pengujian.',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                Navigator.pop(dialogContext);
                _cleanUpAllOrders();
              },
              child: const Text('Hapus Semua', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // 5. FUNGSI HAPUS AKUN PERMANEN (FIRESTORE & FIREBASE AUTH)
  Future<void> _deleteAccountPermanently() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.red),
      ),
    );

    try {
      String uid = user.uid;

      // 1. Hapus dokumen profil user di Firestore
      await _firestore.collection('users').doc(uid).delete();

      // 2. Hapus akun pengguna dari Firebase Authentication
      await user.delete();

      if (mounted) Navigator.pop(context); // Tutup Loading

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun berhasil dihapus permanen! Silakan daftar ulang.'),
            backgroundColor: Colors.green,
          ),
        );

        // Arahkan kembali ke Halaman Login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Tutup Loading jika error

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus akun: ${e.toString().contains('requires-recent-login') ? 'Sesi habis, silakan login ulang terlebih dahulu.' : e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showConfirmDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.red),
              SizedBox(width: 8),
              Text('Hapus Akun Permanen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Apakah Anda yakin ingin menghapus AKUN INI secara permanen?\n\n'
            'Data user di Firestore dan akun Authentication akan dihapus. Anda dapat meregistrasikan ulang email ini dengan role pilihan Anda.',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteAccountPermanently();
              },
              child: const Text('Hapus Akun', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Wrap(
              children: [
                const ListTile(
                  title: Text(
                    'Ubah Foto Profil',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.black),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.black),
                  title: const Text('Ambil dari Kamera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFieldCard({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    bool isPassword = false,
    String? hintText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: readOnly ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        obscureText: isPassword ? _isObscurePassword : false,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: readOnly ? Colors.grey.shade700 : Colors.black,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          labelStyle: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.normal,
          ),
          prefixIcon: Icon(icon, color: Colors.black87, size: 22),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isObscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscurePassword = !_isObscurePassword;
                    });
                  },
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? profileImage;
    if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      profileImage = NetworkImage(_photoUrl!);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Akun Saya',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 1. HEADER AVATAR PROFIL
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFCB05),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.black,
                                )
                              : CircleAvatar(
                                  radius: 40,
                                  backgroundColor: const Color(0xFFFFCB05),
                                  backgroundImage: profileImage,
                                  child: profileImage == null
                                      ? Text(
                                          _namaController.text.isNotEmpty
                                              ? _namaController.text[0]
                                                  .toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        )
                                      : null,
                                ),
                        ),
                        GestureDetector(
                          onTap: _isLoading ? null : _showImageSourceDialog,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 14,
                              color: Color(0xFFFFCB05),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _namaController.text.isNotEmpty
                          ? _namaController.text
                          : 'Memuat...',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      _emailController.text,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. FIELD INFORMASI AKUN
              _buildFieldCard(
                icon: Icons.person_outline,
                label: 'Nama Lengkap',
                controller: _namaController,
                readOnly: false,
              ),
              _buildFieldCard(
                icon: Icons.email_outlined,
                label: 'Alamat Email',
                controller: _emailController,
                readOnly: true,
              ),

              if (!_isGoogleUser())
                _buildFieldCard(
                  icon: Icons.lock_outline,
                  label: 'Password Baru',
                  controller: _passwordController,
                  readOnly: false,
                  isPassword: true,
                  hintText: 'Isi jika ingin mengganti password',
                ),

              _buildFieldCard(
                icon: Icons.phone_outlined,
                label: 'Nomor WhatsApp',
                controller: _phoneController,
                readOnly: false,
              ),
              _buildFieldCard(
                icon: Icons.location_on_outlined,
                label: 'Alamat Utama',
                controller: _mapsController,
                readOnly: false,
              ),

              const SizedBox(height: 16),

              // 3. TOMBOL SIMPAN PERUBAHAN
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveProfileChanges,
                  icon: const Icon(Icons.save_outlined,
                      color: Colors.black, size: 18),
                  label: const Text(
                    'SIMPAN PERUBAHAN',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCB05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 4. TOMBOL PEMBERSIH DATA ORDERS (TESTING TOOL)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _showConfirmCleanUpDialog,
                  icon: const Icon(Icons.cleaning_services, color: Colors.orange, size: 18),
                  label: const Text(
                    'BERSIHKAN DATA ORDER (TESTING)',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade50,
                    side: const BorderSide(color: Colors.orange, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 5. TOMBOL HAPUS AKUN PERMANEN
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _showConfirmDeleteAccountDialog,
                  icon: const Icon(Icons.person_remove, color: Colors.red, size: 18),
                  label: const Text(
                    'HAPUS AKUN PERMANEN',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 6. TOMBOL LOGOUT
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _auth.signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.white, size: 18),
                  label: const Text(
                    'KELUAR DARI AKUN',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
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