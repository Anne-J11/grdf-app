import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/type_intervention_model.dart';
// lib/brief/services/type_intervention_service.dart

class TypeInterventionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer tous les types d'intervention (sans doublons par nom)
  Future<List<TypeInterventionModel>> getAllTypes() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('type_intervention')
          .get();

      final List<TypeInterventionModel> tous = snapshot.docs
          .map((doc) => TypeInterventionModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      ))
          .toList();

      // Déduplication : on ne garde que le premier document rencontré
      // pour chaque nom de type (évite les doublons issus d'initialisations répétées).
      final seen = <String>{};
      final List<TypeInterventionModel> uniques = [];
      for (final type in tous) {
        final nomNormalise = type.nom.trim().toLowerCase();
        if (seen.add(nomNormalise)) {
          uniques.add(type);
        }
      }

      // Tri alphabétique pour un affichage cohérent
      uniques.sort((a, b) => a.nom.compareTo(b.nom));
      return uniques;
    } catch (e) {
      print('Erreur chargement types: $e');
      return [];
    }
  }
}