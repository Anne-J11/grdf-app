import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/type_intervention_model.dart';
// lib/brief/services/type_intervention_service.dart

class TypeInterventionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer tous les types d'intervention
  Future<List<TypeInterventionModel>> getAllTypes() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('type_intervention')
          .get();

      return snapshot.docs
          .map((doc) => TypeInterventionModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      print('Erreur chargement types: $e');
      return [];
    }
  }
}
