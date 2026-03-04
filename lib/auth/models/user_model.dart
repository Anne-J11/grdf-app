// lib/auth/models/user_model.dart

class UserModel {
  final String uid;
  final String email;
  final String nom;
  final String prenom;
  final String role; // 'referent', 'technicien' ou 'manager'
  final String agenceId;
  final String siteId;
  final bool actif;
  final DateTime? dateCreation;

  UserModel({
    required this.uid,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.role,
    required this.agenceId,
    required this.siteId,
    this.actif = true,
    this.dateCreation,
  });

  // Créer un UserModel depuis les données Firestore
  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      role: data['role'] ?? '',
      agenceId: data['agence_id'] ?? '',
      siteId: data['site_id'] ?? '',
      actif: data['actif'] ?? true,
      dateCreation: data['date_creation']?.toDate(),
    );
  }

  // Convertir le UserModel en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'role': role,
      'agence_id': agenceId,
      'site_id': siteId,
      'actif': actif,
      'date_creation': dateCreation,
    };
  }

  // Copier avec modifications
  UserModel copyWith({
    String? uid,
    String? email,
    String? nom,
    String? prenom,
    String? role,
    String? agenceId,
    String? siteId,
    bool? actif,
    DateTime? dateCreation,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      role: role ?? this.role,
      agenceId: agenceId ?? this.agenceId,
      siteId: siteId ?? this.siteId,
      actif: actif ?? this.actif,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }

  // Manager a les mêmes droits que référent
  bool get isReferent => role == 'referent' || role == 'manager';

  // Vérifier si l'utilisateur est un manager
  bool get isManager => role == 'manager';

  // Vérifier si l'utilisateur est un technicien
  bool get isTechnicien => role == 'technicien';

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, nom: $nom, prenom: $prenom, role: $role)';
  }
}