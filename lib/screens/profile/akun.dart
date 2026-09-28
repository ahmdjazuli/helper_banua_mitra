import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package0cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../auth/login.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_input_field.dart';

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
  
  // Controller Password Lama & Baru (Disamakan dengan File 1)
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  String? _photoUrl;
  bool _isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;

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
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
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

  // 2. Simpan Perubahan Data Profil & Ubah Password Aman (Disamakan dengan File 1)
  Future<void> _saveProfileChanges() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    String oldPass = _oldPasswordController.text.trim();
    String newPass = _newPasswordController.text.trim();

    // Validasi jika user mencoba mengisi password baru tanpa password lama
    if (!_isGoogleUser() && newPass.isNotEmpty) {
      if (oldPass.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Masukkan password lama Anda untuk mengganti password baru!'),
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Re-autentikasi & ganti password jika diketikkan
      if (!_isGoogleUser() && newPass.isNotEmpty && oldPass.isNotEmpty) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: oldPass,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPass);
      }

      // Update Nama di Firebase Auth
      if (_namaController.text.trim() != user.displayName) {
        await user.updateDisplayName(_namaController.text.trim());
      }

      // Update Data Tambahan di Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'nama': _namaController.text.trim(),
        'phone': _phoneController.text.trim(),
        'alamat': _mapsController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _oldPasswordController.clear();
      _newPasswordController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Profil berhasil diperbarui!'),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = 'Gagal memperbarui profil!';
        if (e.code == 'wrong-password') {
          msg = 'Password lama salah! Mohon periksa kembali.';
        } else if (e.code == 'weak-password') {
          msg = 'Password baru terlalu lemah (minimal 6 karakter).';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text(msg)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  // 4. FUNGSI MENGHAPUS SEMUA DATA ORDERS DI FIRESTORE (Khusus Mitra)
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              child: const Text('Batal', style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                Navigator.pop(dialogContext);
                _cleanUpAllOrders();
              },
              child: const Text('Hapus Semua', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // 5. Fitur Hapus Akun Permanen dengan Konfirmasi (Disamakan dengan File 1)
  Future<void> _confirmAndDeleteAccount() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Hapus Akun?', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Apakah Anda yakin ingin menghapus akun ini secara permanen? Data Anda yang tersimpan akan dihapus dan tidak dapat dikembalikan.',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _executeDeleteAccount();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Ya, Hapus Akun', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeDeleteAccount() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Hapus dokumen di Firestore
      await _firestore.collection('users').doc(user.uid).delete();
      // Hapus akun Authentication
      await user.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun Anda berhasil dihapus.')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Demi keamanan, silakan Logout & Login ulang terlebih dahulu untuk menghapus akun.'),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Gagal menghapus akun: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              // HEADER AVATAR PROFIL
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
                              ? const CircularProgressIndicator(color: Colors.black)
                              : CircleAvatar(
                                  radius: 40,
                                  backgroundColor: const Color(0xFFFFCB05),
                                  backgroundImage: profileImage,
                                  child: profileImage == null
                                      ? Text(
                                          _namaController.text.isNotEmpty
                                              ? _namaController.text[0].toUpperCase()
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
                      _namaController.text.isNotEmpty ? _namaController.text : 'Memuat...',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      _emailController.text,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // FIELD INFORMASI AKUN (Menggunakan CustomInputField seperti File 1)
              CustomInputField(
                icon: Icons.person_outline,
                label: 'Nama Lengkap',
                hintText: 'Masukkan nama lengkap',
                controller: _namaController,
                labelColor: Colors.black87,
              ),

              CustomInputField(
                icon: Icons.email_outlined,
                label: 'Alamat Email',
                hintText: 'Email Anda',
                controller: _emailController,
                readOnly: true,
                labelColor: Colors.black87,
              ),

              if (!_isGoogleUser()) ...[
                CustomInputField(
                  icon: Icons.lock_outline,
                  label: 'Password Lama',
                  hintText: 'Masukkan password lama untuk konfirmasi',
                  controller: _oldPasswordController,
                  isPassword: true,
                  obscureText: _obscureOldPassword,
                  labelColor: Colors.black87,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureOldPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureOldPassword = !_obscureOldPassword;
                      });
                    },
                  ),
                ),
                CustomInputField(
                  icon: Icons.lock_clock_outlined,
                  label: 'Password Baru',
                  hintText: 'Isi jika ingin mengganti password',
                  controller: _newPasswordController,
                  isPassword: true,
                  obscureText: _obscureNewPassword,
                  labelColor: Colors.black87,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
              ],

              CustomInputField(
                icon: Icons.phone_outlined,
                label: 'Nomor WhatsApp',
                hintText: 'Masukkan nomor WhatsApp',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                labelColor: Colors.black87,
              ),

              CustomInputField(
                icon: Icons.location_on_outlined,
                label: 'Alamat Utama',
                hintText: 'Masukkan alamat lengkap',
                controller: _mapsController,
                labelColor: Colors.black87,
              ),

              const SizedBox(height: 12),

              // TOMBOL SIMPAN PERUBAHAN (BorderRadius 12)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveProfileChanges,
                  icon: const Icon(Icons.save_outlined, color: Colors.black, size: 18),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // TOMBOL PEMBERSIH DATA ORDERS (TESTING TOOL KHUSUS MITRA - BorderRadius 12)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
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
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.orange.shade50,
                    side: const BorderSide(color: Colors.orange, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // TOMBOL LOGOUT (BorderRadius 12)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _auth.signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // TOMBOL HAPUS AKUN (BorderRadius 12 & Dialog File 1)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _confirmAndDeleteAccount,
                  icon: const Icon(Icons.delete_forever, color: Colors.red, size: 18),
                  label: const Text(
                    'HAPUS AKUN',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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