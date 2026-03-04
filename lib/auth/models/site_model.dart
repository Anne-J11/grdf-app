// lib/auth/models/site_model.dart

class SiteModel {
  final String id;
  final String nom;
  final String agenceId;

  SiteModel({
    required this.id,
    required this.nom,
    required this.agenceId,
  });

  // Créer depuis Firestore
  factory SiteModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SiteModel(
      id: id,
      nom: data['nom'] ?? '',
      agenceId: data['agence_id'] ?? '',
    );
  }

  // Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'agence_id': agenceId,
    };
  }

  @override
  String toString() => 'SiteModel(id: $id, nom: $nom, agenceId: $agenceId)';
}