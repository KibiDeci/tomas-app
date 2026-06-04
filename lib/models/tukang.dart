class Tukang {
  final String idTukang;
  final String nama;
  final String? kategori;
  final String? lokasi;
  final String? alamat;
  final String? bio;
  final String? pengalaman;
  final String? noHp;
  final double? tarif;
  final int? jumlahOrder;
  final bool statusAktif;
  final String? fotoUrl;
  final double rating;
  final double? latitude;
  final double? longitude;
  final List<String>? fotoPortfolioUrls;

  /// URL portfolio tunggal (PDF atau gambar) yang diupload via admin panel.
  /// Di-mapping dari field [portfolio_url] di Firestore.
  final String? portfolioUrl;

  Tukang({
    required this.idTukang,
    required this.nama,
    this.kategori,
    this.lokasi,
    this.alamat,
    this.bio,
    this.pengalaman,
    this.noHp,
    this.tarif,
    this.jumlahOrder,
    required this.statusAktif,
    this.fotoUrl,
    this.rating = 4.7,
    this.latitude,
    this.longitude,
    this.fotoPortfolioUrls,
    this.portfolioUrl,
  });

  factory Tukang.fromJson(Map<String, dynamic> j) => Tukang(
        idTukang: j['id_tukang'].toString(),
        nama: j['nama'] ?? '',
        kategori: j['kategori'],
        lokasi: j['lokasi'],
        alamat: j['alamat'],
        bio: j['bio'],
        pengalaman: j['pengalaman'],
        noHp: j['no_hp'],
        tarif: j['tarif'] != null ? (j['tarif'] as num).toDouble() : null,
        jumlahOrder: j['jumlah_order'] != null
            ? (j['jumlah_order'] as num).toInt()
            : null,
        statusAktif: j['status_aktif'] == true || j['status_aktif'] == 1,
        fotoUrl: j['foto_url'],
        rating: ((j['rating'] ?? 4.7) as num).toDouble(),
        latitude:
            j['latitude'] != null ? (j['latitude'] as num).toDouble() : null,
        longitude:
            j['longitude'] != null ? (j['longitude'] as num).toDouble() : null,
        fotoPortfolioUrls: j['foto_portfolio'] != null
            ? List<String>.from(j['foto_portfolio'] as List)
            : null,

        // Field baru: portfolio_url (string tunggal, bisa PDF atau gambar)
        portfolioUrl: j['portfolio_url'] as String?,
      );
}
