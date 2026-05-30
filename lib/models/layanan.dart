import 'tukang.dart';

class Layanan {
  final String idLayanan;
  final String namaLayanan;

  Layanan({required this.idLayanan, required this.namaLayanan});

  factory Layanan.fromJson(Map<String, dynamic> j) => Layanan(
        idLayanan: j['id_layanan'].toString(),
        namaLayanan: j['nama_layanan'] ?? '',
      );
}

class LayananWithTukang {
  final Layanan layanan;
  final List<Tukang> tukangList;

  LayananWithTukang({required this.layanan, required this.tukangList});

  factory LayananWithTukang.fromJson(Map<String, dynamic> j) =>
      LayananWithTukang(
        layanan: Layanan.fromJson(j['layanan']),
        tukangList: (j['tukang'] as List)
            .map((t) => Tukang.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}