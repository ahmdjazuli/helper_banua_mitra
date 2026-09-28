import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../order/maps.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _mapsController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _mapsController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (_namaController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua bidang form!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Koneksi timeout. Periksa internet Anda.'),
          );

      User? user = userCredential.user;

      if (user != null) {
        await user.sendEmailVerification();

        // SIMPAN PROFIL DAN SET ROLE 'mitra' KE FIRESTORE
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'uid': user.uid,
                'nama': _namaController.text.trim(),
                'email': _emailController.text.trim(),
                'phone': _phoneController.text.trim(),
                'almat_maps': _mapsController.text.trim(),
                'role': 'mitra', // Set role sebagai mitra
                'createdAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true))
              .timeout(const Duration(seconds: 5));
        } catch (e) {
          debugPrint("Perhatian: Profil Firestore belum bisa ditulis: $e");
        }

        if (!mounted) return;

        _showVerificationDialog(user.email ?? _emailController.text.trim());
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Terjadi kesalahan.';
      if (e.code == 'weak-password') {
        message = 'Password terlalu lemah (minimal 6 karakter).';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email ini sudah terdaftar!';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid.';
      } else if (e.code == 'network-request-failed') {
        message = 'Gagal terhubung ke jaringan/internet.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showVerificationDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.mark_email_read, color: Color(0xFF8C6D13), size: 28),
              SizedBox(width: 8),
              Text('Verifikasi Email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Link verifikasi telah dikirimkan ke:\n$email',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Text(
                'Silakan buka kotak masuk (Inbox/Spam) email Anda dan klik link tersebut untuk memverifikasi akun sebelum melakukan login.',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8C6D13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Mengerti & Ke Login', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF8C6D13),
                    width: 2,
                  ),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Kebijakan dan Privasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Selamat datang di Helper Banua. Kami berkomitmen untuk melindungi data pribadi Anda.\n\n'
                      '1. Pengumpulan Informasi\n'
                      'Kami mengumpulkan nama, email, nomor telepon, dan lokasi untuk keperluan akun dan layanan.\n\n'
                      '2. Penggunaan Informasi\n'
                      'Data digunakan untuk verifikasi akun, menghubungkan transaksi layanan, serta notifikasi pesanan.\n\n'
                      '3. Keamanan Data\n'
                      'Kami menjamin data Anda disimpan dengan aman dan tidak diperjualbelikan kepada pihak manapun.\n\n'
                      '4. Hak Pengguna\n'
                      'Anda berhak memperbarui atau menghapus data pribadi Anda melalui pengaturan aplikasi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 40),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 180,
                height: 42,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF8C6D13), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Setuju',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String hintText,
    TextEditingController? controller,
    bool readOnly = false,
    bool isPassword = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Colors.black87),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              obscureText: isPassword,
              onTap: onTap,
              decoration: InputDecoration(
                hintText: hintText,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF8C6D13)),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF8C6D13)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Register',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              _buildInputField(
                icon: Icons.account_circle,
                hintText: 'Nama Lengkap',
                controller: _namaController,
              ),
              _buildInputField(
                icon: Icons.email,
                hintText: 'rudi.walid@gmail.com',
                controller: _emailController,
              ),
              _buildInputField(
                icon: Icons.phone,
                hintText: '081234567899',
                controller: _phoneController,
              ),
              _buildInputField(
                icon: Icons.lock,
                hintText: 'Password',
                controller: _passwordController,
                isPassword: true,
              ),
              _buildInputField(
                icon: Icons.location_on,
                hintText: 'Maps',
                controller: _mapsController,
                readOnly: true,
                onTap: () async {
                  final selectedLocation = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SelectLocationScreen(),
                    ),
                  );

                  if (selectedLocation != null) {
                    setState(() {
                      _mapsController.text = selectedLocation.toString();
                    });
                  }
                },
              ),

              const SizedBox(height: 10),

              OutlinedButton(
                onPressed: _showPrivacyPolicyDialog,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                  side: const BorderSide(color: Color(0xFF8C6D13)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child: const Text(
                  'Kebijakan dan Privasi',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              OutlinedButton(
                onPressed: _isLoading ? null : _registerUser,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                  side: const BorderSide(color: Color(0xFF8C6D13)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Color(0xFF8C6D13),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Verifikasi',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8C6D13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Sudah punya akun? kembali ke login',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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