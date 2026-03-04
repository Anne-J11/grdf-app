// lib/debrief/services/debrief_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/debrief_model.dart';
import '../../brief/services/brief_service.dart';

class DebriefService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BriefService _briefService = BriefService();

  // Créer un debrief ET verrouiller automatiquement le brief associé
  Future<String> createDebrief(DebriefModel debrief) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('debriefs')
          .add(debrief.toFirestore());

      // Verrouiller le brief associé
      if (debrief.briefId.isNotEmpty) {
        await _briefService.verrouillerBrief(debrief.briefId);
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du debrief: $e');
    }
  }

  // Récupérer un debrief par ID
  Future<DebriefModel?> getDebriefById(String debriefId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('debriefs')
          .doc(debriefId)
          .get();

      if (!doc.exists) return null;

      return DebriefModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération du debrief: $e');
    }
  }

  // Récupérer le debrief d'un brief spécifique
  Future<DebriefModel?> getDebriefByBriefId(String briefId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('debriefs')
          .where('brief_id', isEqualTo: briefId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return DebriefModel.fromFirestore(
        snapshot.docs.first.data() as Map<String, dynamic>,
        snapshot.docs.first.id,
      );
    } catch (e) {
      throw Exception('Erreur lors de la recherche du debrief: $e');
    }
  }

  // Récupérer tous les debriefs d'une agence
  Future<List<DebriefModel>> getDebriefsByAgence(String agenceId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('debriefs')
          .where('agence_id', isEqualTo: agenceId)
          .orderBy('date_debrief', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DebriefModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      ))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des debriefs: $e');
    }
  }

  // Récupérer tous les debriefs d'un référent
  Future<List<DebriefModel>> getDebriefsByReferent(String referentId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('debriefs')
          .where('referent_id', isEqualTo: referentId)
          .orderBy('date_debrief', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DebriefModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      ))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des debriefs: $e');
    }
  }

  // Mettre à jour un debrief
  Future<void> updateDebrief(String debriefId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('debriefs').doc(debriefId).update(data);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du debrief: $e');
    }
  }

  // Supprimer un debrief
  Future<void> deleteDebrief(String debriefId) async {
    try {
      await _firestore.collection('debriefs').doc(debriefId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du debrief: $e');
    }
  }
}