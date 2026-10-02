import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthDialogs {
  /// Dialog Reset Password Manual
  static void showResetPasswordDialog({
    required BuildContext context,
    String? initialEmail,
    VoidCallback? onSuccess,
  }) {
    final TextEditingController resetEmailController =
        TextEditingController(text: initialEmail ?? '');
    bool isSending = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.lock_reset_rounded, color: Color(0xFFFFD600), size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Reset Password',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masukkan email terdaftar Anda. Kami akan mengirimkan instruksi untuk me-reset password Anda.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Masukkan Email Anda',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final email = resetEmailController.text.trim();
                          if (email.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Harap masukkan email Anda!'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSending = true);

                          try {
                            await FirebaseAuth.instance.sendPasswordResetEmail(
                              email: email,
                            );

                            if (!context.mounted) return;
                            Navigator.pop(dialogContext);

                            if (onSuccess != null) {
                              onSuccess();
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Colors.green,
                                content: Text(
                                  'Link reset password telah dikirim ke email Anda. Silakan cek Inbox/Spam.',
                                ),
                              ),
                            );
                          } on FirebaseAuthException catch (e) {
                            String message = 'Gagal mengirim email reset password.';
                            if (e.code == 'user-not-found') {
                              message = 'Email ini belum terdaftar!';
                            } else if (e.code == 'invalid-email') {
                              message = 'Format email tidak valid!';
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red,
                                content: Text(message),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red,
                                content: Text('Error: ${e.toString()}'),
                              ),
                            );
                          } finally {
                            setDialogState(() => isSending = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD600),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Kirim Link',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Dialog Otomatis ketika terlalu sering salah password
  static void showTooManyWrongPasswordDialog({
    required BuildContext context,
    required int wrongPasswordCount,
    required String emailText,
    required VoidCallback onResetSuccess,
  }) {
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
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Terlalu Banyak Percobaan',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            'Anda telah memasukkan password yang salah sebanyak $wrongPasswordCount kali. Apakah Anda lupa password akun Anda?',
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
                    showResetPasswordDialog(
                      context: context,
                      initialEmail: emailText,
                      onSuccess: onResetSuccess,
                    );
                  },
                  icon: const Icon(Icons.lock_reset, color: Colors.black, size: 18),
                  label: const Text(
                    'Lupa / Reset Password',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD600),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Coba Lagi Nanti',
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
}