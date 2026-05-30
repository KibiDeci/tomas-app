class UserModel {
  final int idUser;
  final String nama;
  final String noHp;
  final String? token;

  UserModel({required this.idUser, required this.nama, required this.noHp, this.token});

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        idUser: j['id_user'],
        nama: j['nama'],
        noHp: j['no_hp'],
        token: j['token'],
      );
}
