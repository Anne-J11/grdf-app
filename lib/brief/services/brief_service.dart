// lib/brief/services/brief_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/brief_model.dart';

class BriefService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Créer un brief
  Future<String> createBrief(BriefModel brief) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('briefs')
          .add(brief.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du brief: $e');
    }
  }

  // Récupérer un brief par ID
  Future<BriefModel?> getBriefById(String briefId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('briefs')
          .doc(briefId)
          .get();

      if (!doc.exists) return null;

      return BriefModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération du brief: $e');
    }
  }

  // Récupérer un brief par numéro BT
  Future<BriefModel?> getBriefByNumBT(String numBt) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('briefs')
          .where('num_bt', isEqualTo: numBt)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return BriefModel.fromFirestore(
        snapshot.docs.first.data() as Map<String, dynamic>,
        snapshot.docs.first.id,
      );
    } catch (e) {
      throw Exception('Erreur lors de la recherche du brief: $e');
    }
  }

  // Récupérer tous les briefs d'un site
  Future<List<BriefModel>> getBriefsBySite(String siteId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('briefs')
          .where('site_id', isEqualTo: siteId)
          .orderBy('date_brief', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BriefModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      ))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des briefs: $e');
    }
  }

  // Récupérer tous les briefs d'une agence
  Future<List<BriefModel>> getBriefsByAgence(String agenceId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('briefs')
          .where('agence_id', isEqualTo: agenceId)
          .orderBy('date_brief', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BriefModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      ))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des briefs: $e');
    }
  }

  // Récupérer les briefs par référent
  Future<List<BriefModel>> getBriefsByReferent(String referentId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('briefs')
          .where('referent_id', isEqualTo: referentId)
          .orderBy('date_brief', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => BriefModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      ))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des briefs: $e');
    }
  }

  // Mettre à jour un brief
  Future<void> updateBrief(String briefId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('briefs').doc(briefId).update(data);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du brief: $e');
    }
  }

  // Verrouiller un brief après validation du débrief
  Future<void> verrouillerBrief(String briefId) async {
    try {
      await _firestore.collection('briefs').doc(briefId).update({
        'est_verrouille': true,
        'statut': 'termine',
      });
    } catch (e) {
      throw Exception('Erreur lors du verrouillage du brief: $e');
    }
  }

  // Supprimer un brief
  Future<void> deleteBrief(String briefId) async {
    try {
      await _firestore.collection('briefs').doc(briefId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du brief: $e');
    }
  }

  // Rechercher des briefs par date
  Future<List<BriefModel>> getBriefsByDate(DateTime date, String siteId) async {
    try {
      DateTime startOfDay = DateTime(date.year, date.month, date.day);
      DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      QuerySnapshot snapshot = await _firestore
          .collection('briefs')
          .where('site_id', isEqualTo: siteId)
          .where('date_intervention', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date_intervention', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('date_intervention')
          .get();

      return snapshot.docs
          .map((doc) => BriefModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      ))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche par date: $e');
    }
  }
}