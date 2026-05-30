class Tukang {
  final String idTukang;
  final String nama;
  final String? kategori;
  final String? lokasi;
  final String? alamat;
  final String? bio;
  final String? noHp;
  final double? tarif;
  final bool statusAktif;
  final String? fotoUrl;
  final double rating;
  final double? latitude;
  final double? longitude;

  Tukang({
    required this.idTukang,
    required this.nama,
    this.kategori,
    this.lokasi,
    this.alamat,
    this.bio,
    this.noHp,
    this.tarif,
    required this.statusAktif,
    this.fotoUrl,
    this.rating = 4.7,
    this.latitude,
    this.longitude,
  });

  factory Tukang.fromJson(Map<String, dynamic> j) => Tukang(
        idTukang: j['id_tukang'].toString(),
        nama: j['nama'] ?? '',
        kategori: j['kategori'],
        lokasi: j['lokasi'],
        alamat: j['alamat'],
        bio: j['bio'],
        noHp: j['no_hp'],
        tarif: j['tarif'] != null
            ? (j['tarif'] as num).toDouble()
            : null,
        statusAktif:
            j['status_aktif'] == true || j['status_aktif'] == 1,
        fotoUrl: j['foto_url'],
        rating: ((j['rating'] ?? 4.7) as num).toDouble(),
        latitude: j['latitude'] != null
            ? (j['latitude'] as num).toDouble()
            : null,
        longitude: j['longitude'] != null
            ? (j['longitude'] as num).toDouble()
            : null,
      );
}