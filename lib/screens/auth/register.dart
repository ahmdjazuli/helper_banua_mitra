import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:helper_banua/widgets/custom_input_field.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _isAgreed = false;
  bool _obscurePassword = true;

  // Konfigurasi ActionCodeSettings untuk Deep Linking kembali ke aplikasi
  final ActionCodeSettings _actionCodeSettings = ActionCodeSettings(
    url: 'https://helper-banua.firebaseapp.com',
    handleCodeInApp: true,
    androidPackageName: 'com.bial.helperbanua',
    androidInstallApp: true,
    androidMinimumVersion: '12',
  );

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _mapsController.dispose();
    super.dispose();
  }

  // Validasi & Formatter Nomor Telepon Indonesia (08... / +62... -> 628...)
  String? _validateAndFormatPhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    if (cleaned.startsWith('08')) {
      cleaned = '628${cleaned.substring(2)}';
    } else if (cleaned.startsWith('+62')) {
      cleaned = cleaned.substring(1);
    } else if (cleaned.startsWith('8') && !cleaned.startsWith('62')) {
      cleaned = '62$cleaned';
    }

    final phoneRegex = RegExp(r'^628[1-9][0-9]{7,10}$');

    if (!phoneRegex.hasMatch(cleaned)) {
      return null;
    }

    return cleaned;
  }

  // Fungsi untuk Membuka Aplikasi Email di Android/iOS
  Future<void> _openEmailApp() async {
    if (Platform.isAndroid) {
      final intent = const AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.APP_EMAIL',
        flags: [268435456],
      );
      try {
        await intent.launch();
      } catch (e) {
        final Uri emailLaunchUri = Uri(scheme: 'mailto');
        if (await canLaunchUrl(emailLaunchUri)) {
          await launchUrl(emailLaunchUri);
        }
      }
    } else if (Platform.isIOS) {
      final Uri emailLaunchUri = Uri(scheme: 'message:');
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      }
    }
  }

  // Fungsi Kirim Ulang Email Verifikasi jika Email Sudah Terdaftar
  Future<void> _resendVerificationEmail(String email, String password) async {
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        if (user.emailVerified) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email ini sudah diverifikasi. Silakan login ke akun Anda.'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        } else {
          await user.sendEmailVerification(_actionCodeSettings);
          await FirebaseAuth.instance.signOut();

          if (mounted) {
            _showVerificationDialog(email);
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Gagal mengirim ulang email verifikasi.';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        msg = 'Password tidak cocok dengan akun terdaftar!';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Dialog Opsi Email Sudah Terdaftar
  void _showAlreadyRegisteredDialog(String email, String password) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text('Email Sudah Terdaftar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Text(
            'Email $email sudah terdaftar di sistem. Jika Anda belum memverifikasinya, kami dapat mengirimkan ulang link verifikasi ke email tersebut.',
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _resendVerificationEmail(email, password);
                  },
                  icon: const Icon(Icons.send_rounded, color: Colors.black, size: 18),
                  label: const Text(
                    'Kirim Ulang Link Verifikasi',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCB05),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Ke Halaman Login',
                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Proses Pendaftaran Akun Mitra
  Future<void> _registerUser() async {
    if (!_isAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus menyetujui Kebijakan dan Privasi terlebih dahulu!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_namaController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua bidang form!')),
      );
      return;
    }

    final rawPhone = _phoneController.text.trim();
    final formattedPhone = _validateAndFormatPhone(rawPhone);

    if (formattedPhone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor telepon tidak valid! Gunakan format Indonesia (contoh: 08123456789).'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    User? user;

    try {
      // 1. BUAT USER DI FIREBASE AUTH
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Koneksi timeout. Periksa internet Anda.'),
          );

      user = userCredential.user;

      if (user != null) {
        // 2. CEK DUPLIKASI NOMOR TELEPON DI FIRESTORE
        final phoneQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: formattedPhone)
            .limit(1)
            .get()
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw Exception('Koneksi timeout saat mengecek nomor telepon.'),
            );

        if (phoneQuery.docs.isNotEmpty) {
          await user.delete();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nomor telepon sudah terdaftar! Gunakan nomor lain.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        // 3. SIMPAN DATA PROFIL MITRA KE FIRESTORE
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
              'uid': user.uid,
              'nama': _namaController.text.trim(),
              'email': _emailController.text.trim(),
              'phone': formattedPhone,
              'almat_maps': _mapsController.text.trim(),
              'roles': ['mitra'],
              'isMitraActive': true,
              'createdAt': FieldValue.serverTimestamp(),
            })
            .timeout(const Duration(seconds: 5));

        // 4. KIRIM EMAIL VERIFIKASI DENGAN DEEP LINKING
        await user.sendEmailVerification(_actionCodeSettings);

        if (!mounted) return;

        _showVerificationDialog(user.email ?? _emailController.text.trim());
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        if (mounted) {
          _showAlreadyRegisteredDialog(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
        }
      } else {
        String message = 'Terjadi kesalahan.';
        if (e.code == 'weak-password') {
          message = 'Password terlalu lemah (minimal 6 karakter).';
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
      }
    } catch (e) {
      if (user != null) {
        try {
          await user.delete();
        } catch (_) {}
      }

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

  // Dialog Instruksi Verifikasi Email
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
              Icon(Icons.mark_email_read, color: Color(0xFFFFCB05), size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verifikasi Email Mitra',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
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
              const SizedBox(height: 10),
              const Text(
                'Silakan buka kotak masuk (Inbox/Spam) email Anda dan klik link tersebut untuk memverifikasi akun Mitra Anda.',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.access_time_filled, size: 16, color: Colors.amber),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Catatan: Link verifikasi berlaku terbatas (maksimal 3 hari). Segera lakukan verifikasi.',
                        style: TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _openEmailApp();
                  },
                  icon: const Icon(Icons.email, color: Colors.black, size: 18),
                  label: const Text(
                    'Buka Aplikasi Email',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCB05),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Lanjut ke Login',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Dialog Kebijakan dan Privasi
  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
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
                    color: const Color(0xFFFFCB05),
                    width: 2,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Kebijakan dan Privasi Mitra',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Selamat datang di Helper Banua Mitra. Kami berkomitmen untuk melindungi data pribadi Anda.\n\n'
                        '1. Pengumpulan Informasi\n'
                        'Kami mengumpulkan nama, email, nomor telepon, dan lokasi untuk keperluan akun dan layanan mitra.\n\n'
                        '2. Penggunaan Informasi\n'
                        'Data digunakan untuk verifikasi akun mitra, menghubungkan transaksi layanan, serta penerimaan pesanan.\n\n'
                        '3. Keamanan Data\n'
                        'Kami menjamin data Anda disimpan dengan aman dan tidak diperjualbelikan kepada pihak manapun.\n\n'
                        '4. Hak Pengguna\n'
                        'Anda berhak memperbarui atau menghapus data pribadi Anda melalui pengaturan aplikasi.',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isAgreed = true;
                            });
                            Navigator.of(dialogContext).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFCB05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Saya Setuju',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daftar Mitra',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Buat akun mitra baru untuk mulai menerima pesanan layanan',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 24),

              CustomInputField(
                icon: Icons.person_outline,
                label: 'Nama Lengkap',
                hintText: 'Masukkan nama lengkap Anda',
                controller: _namaController,
                labelColor: Colors.black,
              ),
              CustomInputField(
                icon: Icons.email_outlined,
                label: 'Email',
                hintText: 'Contoh: mitra.banua@gmail.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                labelColor: Colors.black,
              ),
              CustomInputField(
                icon: Icons.phone_outlined,
                label: 'Nomor Telepon',
                hintText: 'Contoh: 08123456789',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                labelColor: Colors.black,
              ),
              CustomInputField(
                icon: Icons.lock_outline,
                label: 'Password',
                hintText: 'Masukkan password Anda',
                controller: _passwordController,
                isPassword: true,
                obscureText: _obscurePassword,
                labelColor: Colors.black,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.black54,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              CustomInputField(
                icon: Icons.location_on_outlined,
                label: 'Lokasi (Maps)',
                hintText: 'Pilih Lokasi dari Maps',
                controller: _mapsController,
                readOnly: true,
                labelColor: Colors.black,
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

              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _isAgreed,
                    activeColor: const Color(0xFFFFCB05),
                    checkColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (bool? value) {
                      setState(() {
                        _isAgreed = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Saya membaca dan menyetujui ',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        GestureDetector(
                          onTap: _showPrivacyPolicyDialog,
                          child: const Text(
                            'Kebijakan dan Privasi Mitra',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isLoading || !_isAgreed) ? null : _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCB05),
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Daftar Mitra',
                          style: TextStyle(
                            color: _isAgreed ? Colors.black : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Sudah punya akun? ',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Kembali ke login',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}