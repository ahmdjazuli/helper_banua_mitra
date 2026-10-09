import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// WIDGET MODULAR DIALOG INPUT PIN TRANSAKSI
class PinVerificationDialog extends StatefulWidget {
  final Function(String) onPinConfirmed;
  final VoidCallback onLupaPin;

  const PinVerificationDialog({
    super.key,
    required this.onPinConfirmed,
    required this.onLupaPin,
  });

  @override
  State<PinVerificationDialog> createState() => _PinVerificationDialogState();
}

class _PinVerificationDialogState extends State<PinVerificationDialog> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Konfirmasi PIN',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Masukkan 6 digit PIN keamanan transaksi Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 36,
                height: 46,
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
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
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFFFCB05), width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) {
                      _focusNodes[index + 1].requestFocus();
                    } else if (value.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                    }
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onLupaPin();
              },
              child: const Text(
                'Lupa PIN?',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('BATAL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            final String enteredPin = _controllers.map((c) => c.text).join();
            if (enteredPin.length < 6) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Harap masukkan 6 digit PIN secara lengkap')),
              );
              return;
            }

            Navigator.pop(context);
            widget.onPinConfirmed(enteredPin);
          },
          child: const Text('KONFIRMASI', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// HELPER LOGIKA RESET PIN, KODE OTP & FORM PIN BARU
class PinResetFlowDialog {
  static void startResetFlow(BuildContext context, Function(String, {bool isError}) showSnackBar) {
    final User? user = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_reset, color: Color(0xFFFFCB05)),
              SizedBox(width: 8),
              Text('Reset PIN Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Text(
            'Kami akan mengirimkan Kode OTP 6 digit ke email terdaftar Anda (${user?.email}) untuk memverifikasi permintaan reset PIN.',
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCB05),
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                if (user == null || user.email == null) return;

                final String generatedOtp = (100000 + Random().nextInt(900000)).toString();
                
                await FirebaseFirestore.instance.collection('mitra').doc(user.uid).set({
                  'resetOtp': generatedOtp,
                  'otpCreatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if (!context.mounted) return;
                Navigator.pop(context);
                
                showSnackBar('Kode OTP telah dikirimkan ke ${user.email}');
                _showOtpVerificationDialog(context, generatedOtp, showSnackBar);
              },
              child: const Text('Kirim Kode OTP', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  static void _showOtpVerificationDialog(
    BuildContext context, 
    String expectedOtp, 
    Function(String, {bool isError}) showSnackBar,
  ) {
    final List<TextEditingController> otpControllers = List.generate(6, (_) => TextEditingController());
    final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Input Kode OTP Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Masukkan 6 digit kode OTP yang telah dikirimkan ke email Anda.',
                textAlign: TextAlign.center,
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
                      controller: otpControllers[index],
                      focusNode: focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCB05),
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                final String enteredOtp = otpControllers.map((c) => c.text).join();
                if (enteredOtp.length < 6) {
                  showSnackBar('Masukkan 6 digit kode OTP!', isError: true);
                  return;
                }

                if (enteredOtp != expectedOtp) {
                  showSnackBar('Kode OTP salah / tidak sesuai!', isError: true);
                  return;
                }

                Navigator.pop(context);
                _showFormPinBaruDialog(context, showSnackBar);
              },
              child: const Text('Verifikasi OTP', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  static void _showFormPinBaruDialog(
    BuildContext context, 
    Function(String, {bool isError}) showSnackBar,
  ) {
    final List<TextEditingController> pinControllers = List.generate(6, (_) => TextEditingController());
    final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Buat PIN Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Verifikasi OTP berhasil. Masukkan 6 digit PIN transaksi baru Anda.',
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCB05),
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final String newPin = pinControllers.map((c) => c.text).join();
                if (newPin.length < 6) {
                  showSnackBar('PIN baru harus 6 digit angka!', isError: true);
                  return;
                }

                final User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance.collection('mitra').doc(user.uid).set({
                    'pin': newPin,
                    'resetOtp': FieldValue.delete(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));

                  if (context.mounted) {
                    Navigator.pop(context);
                    showSnackBar('PIN Transaksi berhasil diperbarui! Silakan ulangi penarikan.');
                  }
                }
              },
              child: const Text('Simpan PIN Baru', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}