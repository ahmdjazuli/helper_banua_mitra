import 'dart:io';

class OrderModel {
  final String pekerjaan;
  final String deskripsi;
  final String alamat;
  final String jumlahLuas;
  final String satuanJumlah;
  final String estSelesai;
  final String satuanSelesai;
  final String waktuPenawaran;
  final String hasilDiharapkan;
  final List<File> photos;
  final String status;

  OrderModel({
    required this.pekerjaan,
    required this.deskripsi,
    required this.alamat,
    required this.jumlahLuas,
    required this.satuanJumlah,
    required this.estSelesai,
    required this.satuanSelesai,
    required this.waktuPenawaran,
    required this.hasilDiharapkan,
    required this.photos,
    this.status = 'Mencari Penawaran',
  });
}