import 'package:flutter/material.dart';
import '../../widgets/background.dart';

class LayarBantuanMitra extends StatefulWidget {
  final bool isEmbeddedInNav;

  const LayarBantuanMitra({super.key, this.isEmbeddedInNav = true});

  @override
  State<LayarBantuanMitra> createState() => _LayarBantuanMitraState();
}

class _LayarBantuanMitraState extends State<LayarBantuanMitra> {
  // Daftar Pertanyaan & Jawaban Khusus Mitra
  final List<Map<String, String>> _faqList = [
    {
      'question': 'Bagaimana cara mengambil orderan di Bursa Orderan?',
      'answer': 'Pastikan status Anda sedang "Online". Masuk ke menu "Orderan", pilih tab "Penawaran Pekerjaan", lalu tekan tombol "Lihat Detail" untuk mengajukan nilai penawaran jasa Anda kepada pelanggan.',
    },
    {
      'question': 'Kapan dan bagaimana saldo hasil pekerjaan dapat dicairkan?',
      'answer': 'Saldo pendapatan dari pekerjaan yang telah selesai akan langsung masuk ke Saldo Mitra. Penarikan saldo (Withdraw) dapat dilakukan kapan saja ke rekening bank atau e-wallet terdaftar dengan minimum penarikan Rp50.000.',
    },
    {
      'question': 'Apa yang harus dilakukan jika pelanggan membatalkan pesanan?',
      'answer': 'Jika pelanggan membatalkan pesanan setelah Anda mengonfirmasi perjalanan, sistem akan mencatat pembatalan tersebut. Apabila terjadi kendala, Anda dapat menghubungi Customer Service Mitra.',
    },
    {
      'question': 'Bagaimana cara menjaga rating dan performa akun Mitra?',
      'answer': 'Selesaikan pekerjaan sesuai spesifikasi dan tenggat waktu yang disepakati, tiba di lokasi pelanggan tepat waktu, serta berikan pelayanan yang ramah dan profesional.',
    },
    {
      'question': 'Apa yang terjadi jika saya membatalkan pesanan yang sudah diterima?',
      'answer': 'Pembatalan pesanan secara sepihak oleh Mitra dapat mempengaruhi tingkat performa akun dan dapat menyebabkan pembatasan penerimaan orderan secara otomatis.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    Widget content = AppBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CARD HUBUNGI CS / LOKAL SUPPORT KHUSUS MITRA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFCB05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: Color(0xFFFFCB05),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Pusat Bantuan Mitra 24/7',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Mengalami kendala pekerjaan atau kendala transaksi? Tim CS Mitra siap membantu.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // TOMBOL CS WHATSAPP MITRA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Integrasi ke WhatsApp CS Mitra
                },
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  'HUBUNGI CS MITRA VIA WHATSAPP',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 2. JUDUL FAQ
            const Text(
              'Pertanyaan Sering Diajukan (FAQ Mitra)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),

            // LIST ACCORDION FAQ
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _faqList.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    clipBehavior: Clip.antiAlias,
                    child: ExpansionTile(
                      collapsedShape: const RoundedRectangleBorder(
                        side: BorderSide.none,
                      ),
                      shape: const RoundedRectangleBorder(
                        side: BorderSide.none,
                      ),
                      title: Text(
                        _faqList[index]['question']!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            _faqList[index]['answer']!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );

    if (widget.isEmbeddedInNav) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Pusat Bantuan Mitra',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(child: content),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Pusat Bantuan Mitra',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(child: content),
    );
  }
}