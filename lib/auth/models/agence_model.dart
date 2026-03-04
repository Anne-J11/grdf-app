// lib/auth/models/agence_model.dart

class AgenceModel {
  final String id;
  final String nom;

  AgenceModel({
    required this.id,
    required this.nom,
  });

  // Créer depuis Firestore
  factory AgenceModel.fromFirestore(Map<String, dynamic> data, String id) {
    return AgenceModel(
      id: id,
      nom: data['nom'] ?? '',
    );
  }

  // Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
    };
  }

  @override
  String toString() => 'AgenceModel(id: $id, nom: $nom)';
}