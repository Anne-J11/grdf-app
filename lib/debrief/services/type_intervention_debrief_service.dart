// lib/debrief/services/type_intervention_debrief_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../brief/models/type_intervention_model.dart';

class TypeInterventionDebriefService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<TypeInterventionModel?> getTypeDebriefByNom(String nom) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('type_intervention_debrief')
          .where('nom', isEqualTo: nom)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      return TypeInterventionModel.fromFirestore(data, snapshot.docs.first.id);
    } catch (e) {
      print('Erreur chargement type debrief: $e');
      return null;
    }
  }
}
