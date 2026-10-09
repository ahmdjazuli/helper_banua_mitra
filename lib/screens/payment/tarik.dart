import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../widgets/background.dart';
import '../../widgets/format_angka.dart';
import '../../widgets/pin.dart';

class TarikSaldoMitraScreen extends StatefulWidget {
  const TarikSaldoMitraScreen({super.key});

  @override
  State<TarikSaldoMitraScreen> createState() => _TarikSaldoMitraScreenState();
}

class _TarikSaldoMitraScreenState extends State<TarikSaldoMitraScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();

  String _selectedBank = 'Bank BCA';
  int? _selectedNominal;
  bool _isLoading = false;

  bool _isVerifyingAccount = false;
  bool _isAccountVerified = false;
  String _accountHolderName = '';

  static const String _xenditSecretKey = 'xnd_development_20ELPVmtJGJv9cIG58zeVfWJv8WYJkGM6IQmpaYSV5FYnjapyDqqbGM78qUPdYL'; 

  final List<String> _bankList = [
    'Bank BCA',
    'Bank Mandiri',
    'Bank BRI',
    'Bank BNI',
    'GoPay',
    'OVO',
    'DANA',
    'ShopeePay',
  ];

  final List<int> _quickNominals = [
    20000,
    50000,
    100000,
    200000,
    500000,
    1000000,
  ];

  String _getBankCode(String bankName) {
    switch (bankName) {
      case 'Bank BCA': return 'BCA';
      case 'Bank Mandiri': return 'MANDIRI';
      case 'Bank BNI': return 'BNI';
      case 'Bank BRI': return 'BRI';
      case 'GoPay': return 'GOPAY';
      case 'OVO': return 'OVO';
      case 'DANA': return 'DANA';
      case 'ShopeePay': return 'SHOPEEPAY';
      default: return 'BCA';
    }
  }

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      final String cleanText = _amountController.text.replaceAll('.', '').trim();
      final val = int.tryParse(cleanText);
      if (val != _selectedNominal) {
        setState(() {
          _selectedNominal = val;
        });
      }
    });

    _accountNumberController.addListener(() {
      if (_isAccountVerified) {
        setState(() {
          _isAccountVerified = false;
          _accountHolderName = '';
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  void _selectQuickNominal(int nominal) {
    setState(() {
      _selectedNominal = nominal;
      _amountController.text = _formatCurrency(nominal);
    });
  }

  void _resetAmount() {
    setState(() {
      _amountController.clear();
      _selectedNominal = null;
    });
  }

  Future<void> _verifyAccountName() async {
    String accountNumber = _accountNumberController.text.trim();
    if (accountNumber.isEmpty) {
      _showSnackBar('Masukkan nomor rekening / HP terlebih dahulu', isError: true);
      return;
    }

    final bool isEWallet = ['GoPay', 'OVO', 'DANA', 'ShopeePay'].contains(_selectedBank);
    if (isEWallet && accountNumber.startsWith('0')) {
      accountNumber = '62${accountNumber.substring(1)}';
    }

    FocusScope.of(context).unfocus();
    setState(() => _isVerifyingAccount = true);

    try {
      final String basicAuth = 'Basic ${base64Encode(utf8.encode('$_xenditSecretKey:'))}';

      final response = await http.post(
        Uri.parse('https://api.xendit.co/bank_account_data_requests'),
        headers: {
          'Authorization': basicAuth,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'bank_code': _getBankCode(_selectedBank),
          'account_number': accountNumber,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String fetchedName = responseData['bank_account_holder_name'] ?? 
                                  responseData['account_holder_name'] ?? 
                                  'NAMA TERVERIFIKASI';
        
        setState(() {
          _isAccountVerified = true;
          _accountHolderName = fetchedName;
        });
        _showSnackBar('Rekening/E-Wallet berhasil diverifikasi!');
      } else {
        String errMessage = responseData['message'] ?? 'Nomor tidak ditemukan.';
        if (response.statusCode == 404) {
          errMessage = 'Akun $_selectedBank dengan nomor tersebut tidak ditemukan atau belum terdaftar.';
        }

        _showSnackBar('Verifikasi Gagal: $errMessage', isError: true);
        setState(() {
          _isAccountVerified = false;
          _accountHolderName = '';
        });
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan verifikasi: $e', isError: true);
      setState(() {
        _isAccountVerified = false;
        _accountHolderName = '';
      });
    } finally {
      if (mounted) setState(() => _isVerifyingAccount = false);
    }
  }

  void _validateAndPromptPin(num currentBalance) {
    final String rawAmountText = _amountController.text.replaceAll('.', '').trim();
    final String accountNumber = _accountNumberController.text.trim();

    if (accountNumber.isEmpty) {
      _showSnackBar('Harap isi nomor rekening / E-Wallet tujuan', isError: true);
      return;
    }

    if (!_isAccountVerified) {
      _showSnackBar('Silakan verifikasi nomor rekening/E-Wallet terlebih dahulu!', isError: true);
      return;
    }

    if (rawAmountText.isEmpty) {
      _showSnackBar('Harap isi nominal penarikan', isError: true);
      return;
    }

    final num? amount = num.tryParse(rawAmountText);
    if (amount == null || amount <= 0) {
      _showSnackBar('Masukkan nominal penarikan yang valid', isError: true);
      return;
    }

    if (amount < 10000) {
      _showSnackBar('Minimal penarikan saldo adalah Rp 10.000', isError: true);
      return;
    }

    if (amount > currentBalance) {
      _showSnackBar('Saldo Anda tidak mencukupi untuk melakukan penarikan ini', isError: true);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinVerificationDialog(
        onPinConfirmed: (enteredPin) {
          _verifyAndProcessTarik(enteredPin, currentBalance, amount);
        },
        onLupaPin: () {
          PinResetFlowDialog.startResetFlow(context, _showSnackBar);
        },
      ),
    );
  }

  Future<void> _verifyAndProcessTarik(String enteredPin, num currentBalance, num amount) async {
    setState(() => _isLoading = true);

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Sesi pengguna tidak ditemukan, silakan login kembali', isError: true);
        return;
      }

      final String currentUid = user.uid;

      final mitraDoc = await FirebaseFirestore.instance.collection('mitra').doc(currentUid).get();
      if (!mitraDoc.exists || !mitraDoc.data()!.containsKey('pin') || mitraDoc.data()!['pin'].toString().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Anda belum mengatur PIN transaksi.'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'ATUR PIN',
                textColor: const Color(0xFFFFCB05),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          );
        }
        return;
      }

      final String savedPin = mitraDoc.data()!['pin'].toString();
      if (enteredPin != savedPin) {
        _showSnackBar('PIN yang Anda masukkan salah!', isError: true);
        return;
      }

      final String accountNumber = _accountNumberController.text.trim();
      final String transactionId = 'WD-${DateTime.now().millisecondsSinceEpoch}';
      final String basicAuth = 'Basic ${base64Encode(utf8.encode('$_xenditSecretKey:'))}';

      final response = await http.post(
        Uri.parse('https://api.xendit.co/disbursements'),
        headers: {
          'Authorization': basicAuth,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'external_id': transactionId,
          'amount': amount,
          'bank_code': _getBankCode(_selectedBank),
          'account_holder_name': _accountHolderName.isNotEmpty ? _accountHolderName : (user.displayName ?? 'Mitra Helper Banua'),
          'account_number': accountNumber,
          'description': 'Penarikan Saldo Mitra Helper Banua ke $_selectedBank',
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String xenditStatus = responseData['status'] ?? 'PENDING';
        String finalStatus = xenditStatus == 'FAILED' ? 'FAILED' : (xenditStatus == 'PENDING' ? 'PENDING' : 'SUCCESS');

        await FirebaseFirestore.instance.collection('transactions').doc(transactionId).set({
          'transactionId': transactionId,
          'userId': currentUid,
          'role': 'MITRA',
          'type': 'WITHDRAW',
          'amount': amount,
          'status': finalStatus,
          'bankName': _selectedBank,
          'accountNumber': accountNumber,
          'accountHolderName': _accountHolderName,
          'xenditDisbursementId': responseData['id'],
          'description': 'Penarikan Saldo ke $_selectedBank ($accountNumber - $_accountHolderName)',
          'createdAt': FieldValue.serverTimestamp(),
        });

        await FirebaseFirestore.instance.collection('mitra').doc(currentUid).update({
          'balance': FieldValue.increment(-amount),
        });

        if (!mounted) return;

        _showSnackBar('Penarikan saldo sebesar Rp ${_formatCurrency(amount)} berhasil diproses!');
        Navigator.pop(context);
      } else {
        final String errorMessage = responseData['message'] ?? 'Gagal memproses pencairan via Xendit.';
        _showSnackBar('Gagal: $errorMessage', isError: true);
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String currentUid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AppBackground(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Tarik Saldo Pendapatan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('mitra').doc(currentUid).snapshots(),
                  builder: (context, snapshot) {
                    num currentBalance = 0;
                    if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                      final Map<String, dynamic>? data = snapshot.data!.data() as Map<String, dynamic>?;
                      if (data != null && data.containsKey('balance')) {
                        currentBalance = data['balance'] ?? 0;
                      }
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFCB05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Saldo Pendapatan',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rp ${_formatCurrency(currentBalance)}',
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black),
                                    ),
                                  ],
                                ),
                                if (currentBalance > 0)
                                  GestureDetector(
                                    onTap: () => _selectQuickNominal(currentBalance.toInt()),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Tarik Semua',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          const Text(
                            'Pilih Bank / E-Wallet Tujuan',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedBank,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            items: _bankList.map((String bank) {
                              return DropdownMenuItem<String>(
                                value: bank,
                                child: Text(bank, style: const TextStyle(fontSize: 14, color: Colors.black)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedBank = value;
                                  _isAccountVerified = false;
                                  _accountHolderName = '';
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'Nomor Rekening / Nomor HP',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _accountNumberController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: InputDecoration(
                                    hintText: 'Masukkan nomor rekening / HP',
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _isVerifyingAccount ? null : _verifyAccountName,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFCB05),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isVerifyingAccount
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                        )
                                      : const Text('Cek', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),

                          if (_isAccountVerified) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pemilik Rekening Terverifikasi:',
                                          style: TextStyle(fontSize: 11, color: Colors.green.shade900),
                                        ),
                                        Text(
                                          _accountHolderName,
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          const Text(
                            'Pilih Nominal Cepat',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 10),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2.3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: _quickNominals.length,
                            itemBuilder: (context, index) {
                              final amount = _quickNominals[index];
                              final isSelected = _selectedNominal == amount;

                              return InkWell(
                                onTap: () => _selectQuickNominal(amount),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFFFCB05) : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? Colors.black : Colors.grey.shade300,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    'Rp ${_formatCurrency(amount)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'Atau Masukkan Nominal Lain (Rp)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 8),
                          
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              CurrencyInputFormatter(),
                            ],
                            decoration: InputDecoration(
                              hintText: 'Contoh: 50.000',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              suffixIcon: _amountController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                                      onPressed: _resetAmount,
                                    )
                                  : null,
                            ),
                          ),

                          const SizedBox(height: 28),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () => _validateAndPromptPin(currentBalance),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : const Text(
                                      'AJUKAN PENARIKAN',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(num amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}