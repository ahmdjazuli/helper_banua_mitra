import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../auth/login.dart';
import '../../widgets/background.dart';
import '../../widgets/custom_input_field.dart';
import '../../services/fcm_service.dart';
import 'setup_layanan.dart';

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
  
  // Controller Password Lama & Baru
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

  bool _isGoogleUser() {
    User? user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((info) => info.providerId == 'google.com');
  }

  // 1. Memuat Data Pengguna
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

  // 2. Simpan Perubahan Data Profil & Ubah Password Aman
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

      if (_namaController.text.trim() != user.displayName) {
        await user.updateDisplayName(_namaController.text.trim());
      }

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

  // 3. Fitur Hapus Akun Permanen dengan Input PIN Transaksi
  Future<void> _confirmAndDeleteAccount() async {
    final List<TextEditingController> pinControllers = List.generate(6, (_) => TextEditingController());
    final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Konfirmasi Hapus Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tindakan ini tidak dapat dibatalkan. Masukkan 6 digit PIN Transaksi Anda untuk memverifikasi penghapusan akun:',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 36,
                    height: 46,
                    child: TextField(
                      controller: pinControllers[index],
                      focusNode: focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      obscureText: true,
                      maxLength: 1,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && index < 5) {
                          focusNodes[index + 1].requestFocus();
                        } else if (val.isEmpty && index > 0) {
                          focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final String inputPin = pinControllers.map((c) => c.text).join();
                if (inputPin.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Masukkan 6 digit PIN Transaksi dengan lengkap!')),
                  );
                  return;
                }

                Navigator.pop(context);
                _executeDeleteAccountWithPin(inputPin);
              },
              child: const Text('Hapus Akun', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeDeleteAccountWithPin(String inputPin) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists || userDoc.data() == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: Colors.red, content: Text('Data pengguna tidak ditemukan.')),
          );
        }
        return;
      }

      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      String? savedPin = data['pin'];

      if (savedPin == null || savedPin.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.orange,
              content: Text('Anda belum mengatur PIN Transaksi! Silakan atur PIN terlebih dahulu.'),
            ),
          );
        }
        return;
      }

      if (savedPin != inputPin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: Colors.red, content: Text('PIN Transaksi salah! Penghapusan akun dibatalkan.')),
          );
        }
        return;
      }

      await FCMService.removeFCMTokenOnLogout();
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Akun Anda berhasil dihapus secara permanen.'),
          ),
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

  // 4. Unggah Foto Profil
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

      Reference storageRef = _storage.ref().child('profile_pictures/${user.uid}.jpg');
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

  // 5. Atur PIN Transaksi
  void _showAturPinDialog() {
    final List<TextEditingController> pinControllers = List.generate(6, (_) => TextEditingController());
    final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: Color(0xFFFFCB05)),
              SizedBox(width: 8),
              Text('Atur PIN Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Buat 6 digit PIN untuk mengamankan transaksi dan keamanan akun Anda.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 36,
                    height: 46,
                    child: TextField(
                      controller: pinControllers[index],
                      focusNode: focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      obscureText: true,
                      maxLength: 1,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && index < 5) {
                          focusNodes[index + 1].requestFocus();
                        } else if (val.isEmpty && index > 0) {
                          focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCB05),
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final String newPin = pinControllers.map((c) => c.text).join();
                if (newPin.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN harus terdiri dari 6 digit angka!')),
                  );
                  return;
                }

                User? user = _auth.currentUser;
                if (user != null) {
                  await _firestore.collection('users').doc(user.uid).set({
                    'pin': newPin,
                    'updatedAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.green,
                        content: Text('PIN Transaksi berhasil disimpan!'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Simpan PIN', style: TextStyle(fontWeight: FontWeight.bold)),
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

              // TOMBOL PENGATURAN LAYANAN SAYA
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SetupLayananMitraScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.build_circle_outlined, color: Colors.black, size: 20),
                  label: const Text(
                    'PENGATURAN LAYANAN SAYA',
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

              const SizedBox(height: 16),

              // FIELD INFORMASI AKUN
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

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showAturPinDialog();
                  },
                  icon: const Icon(Icons.shield_outlined, color: Colors.black, size: 20),
                  label: const Text(
                    'ATUR / UBAH PIN TRANSAKSI',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // TOMBOL SIMPAN PERUBAHAN
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

              // TOMBOL LOGOUT
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() => _isLoading = true);
                          try {
                            await FCMService.removeFCMTokenOnLogout();
                            await _auth.signOut();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            debugPrint("Error saat logout: $e");
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
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

              // TOMBOL HAPUS AKUN (DENGAN VERIFIKASI PIN)
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