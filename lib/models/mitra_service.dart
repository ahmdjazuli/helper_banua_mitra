class MitraServiceModel {
  final String kategori;
  final String namaLayanan;
  final String deskripsi;
  final String? pengalaman;
  final String? sertifikatUrl;
  final List<Map<String, dynamic>> durasiDanHarga;

  MitraServiceModel({
    required this.kategori,
    required this.namaLayanan,
    required this.deskripsi,
    this.pengalaman,
    this.sertifikatUrl,
    required this.durasiDanHarga,
  });

  Map<String, dynamic> toMap() {
    return {
      'kategori': kategori,
      'namaLayanan': namaLayanan,
      'deskripsi': deskripsi,
      'pengalaman': pengalaman ?? '',
      'sertifikatUrl': sertifikatUrl ?? '',
      'durasiDanHarga': durasiDanHarga,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}