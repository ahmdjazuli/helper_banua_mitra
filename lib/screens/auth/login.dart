import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../navigation/mitra_navigation.dart';
import 'register.dart';
import '../../widgets/auth_dialogs.dart';
import '../../widgets/custom_input_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Counter untuk melacak percobaan password salah
  int _wrongPasswordCount = 0;
  static const int _maxWrongAttempts = 3;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fungsi Login Email & Password
  Future<void> _loginWithEmail() async {
    String emailInput = _emailController.text.trim();
    String passwordInput = _passwordController.text.trim();

    if (emailInput.isEmpty || passwordInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan Password wajib diisi!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: emailInput,
        password: passwordInput,
      );

      User? user = userCredential.user;

      // Jika berhasil login, reset counter percobaan salah
      _wrongPasswordCount = 0;

      if (user != null && !user.emailVerified) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange[800],
            duration: const Duration(seconds: 6),
            content: const Text(
              'Email Anda belum diverifikasi! Silakan cek Inbox/Spam email Anda.',
            ),
            action: SnackBarAction(
              label: 'Kirim Ulang',
              textColor: Colors.white,
              onPressed: () async {
                try {
                  await user.sendEmailVerification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.green,
                        content: Text('Link verifikasi berhasil dikirim ulang!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal mengirim ulang: $e')),
                    );
                  }
                }
              },
            ),
          ),
        );

        await FirebaseAuth.instance.signOut();
        return;
      }

      // ENSURE ROLE MITRA TERSET DI FIRESTORE
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'role': 'mitra',
        }, SetOptions(merge: true));
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MitraMainScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content: Text('Akun tidak ditemukan! Mohon periksa kembali email Anda.'),
            ),
          );
        }
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        bool isEmailExists = false;
        try {
          // Cek apakah email terdaftar di Firebase Auth
          List<String> signInMethods = await FirebaseAuth.instance
              .fetchSignInMethodsForEmail(emailInput);
          if (signInMethods.isNotEmpty) {
            isEmailExists = true;
          }
        } catch (_) {
          isEmailExists = true;
        }

        if (!isEmailExists) {
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.red,
                content: Text('Akun tidak ditemukan! Mohon periksa kembali email Anda.'),
              ),
            );
          }
        } else {
          // Email terdaftar tapi password salah
          _wrongPasswordCount++;

          if (_wrongPasswordCount >= _maxWrongAttempts) {
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();

              AuthDialogs.showTooManyWrongPasswordDialog(
                context: context,
                wrongPasswordCount: _wrongPasswordCount,
                emailText: emailInput,
                onResetSuccess: () {
                  setState(() {
                    _wrongPasswordCount = 0;
                  });
                },
              );
            }
          } else {
            int remaining = _maxWrongAttempts - _wrongPasswordCount;
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.red,
                  content: Text(
                    'Password salah! Sisa percobaan: $remaining.',
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        }
      } else if (e.code == 'invalid-email') {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content: Text('Format email tidak valid!'),
            ),
          );
        }
      } else if (e.code == 'too-many-requests') {
        if (mounted) {
          AuthDialogs.showTooManyWrongPasswordDialog(
            context: context,
            wrongPasswordCount: _wrongPasswordCount,
            emailText: emailInput,
            onResetSuccess: () {
              setState(() {
                _wrongPasswordCount = 0;
              });
            },
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text('Login gagal: ${e.message ?? e.code}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Fungsi Login Google
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.standard(
        scopes: ['email', 'profile'],
      );

      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      User? user = userCredential.user;

      // SET AKUN & ROLE MITRA DI FIRESTORE UNTUK GOOGLE LOGIN
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'uid': user.uid,
          'nama': user.displayName ?? '',
          'email': user.email ?? '',
          'role': 'mitra',
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MitraMainScreen(),
        ),
      );
    } catch (e) {
      debugPrint('Error Google Sign-In: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal Login Google: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFD600),
                  Color(0xFFFFD600),
                  Colors.black,
                  Colors.black,
                ],
                stops: [
                  0.0,
                  0.48,
                  0.52,
                  1.0,
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 170,
                        height: 170,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/img/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.build_circle,
                                  size: 60,
                                  color: Color(0xFFFFD600),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -5),
                              child: const Text(
                                'HELPER',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: 0.5,
                                  height: 0.95,
                                ),
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(0, -5),
                              child: const Text(
                                'BANUA',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: 0.5,
                                  height: 1.00,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'MITRA',
                                style: TextStyle(
                                  fontSize: 47,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: 2.0,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Input Field Email (CustomInputField)
                  CustomInputField(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    hintText: 'Masukkan email Anda',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  // Input Field Password (CustomInputField dengan Toggle View)
                  CustomInputField(
                    icon: Icons.lock_outline,
                    label: 'Password',
                    hintText: 'Masukkan password Anda',
                    controller: _passwordController,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),

                  // Lupa Password (Menggunakan AuthDialogs)
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        AuthDialogs.showResetPasswordDialog(
                          context: context,
                          initialEmail: _emailController.text.trim(),
                          onSuccess: () {
                            setState(() {
                              _wrongPasswordCount = 0;
                            });
                          },
                        );
                      },
                      child: const Text(
                        'Lupa Password ?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Tombol Login Email
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _loginWithEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD600),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'LOGIN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tombol Login Google
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                            height: 20,
                            width: 20,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.g_mobiledata, color: Colors.black, size: 28),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Login dengan Google',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun? ',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Register disini',
                          style: TextStyle(
                            color: Color(0xFFFFD600),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFFFFD600),
                          ),
                        ),
                      ),
                    ],
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