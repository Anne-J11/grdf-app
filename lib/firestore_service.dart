// lib/core/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grdf_app/auth/models/agence_model.dart';
import 'package:grdf_app/auth/models/site_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== AGENCES ====================

  // Récupérer toutes les agences
  Future<List<AgenceModel>> getAgences() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('agences')
          .orderBy('nom')
          .get();

      return snapshot.docs
          .map((doc) => AgenceModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      ))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des agences: $e');
    }
  }

  // Récupérer une agence par ID
  Future<AgenceModel?> getAgenceById(String agenceId) async {
    try {
      DocumentSnapshot doc =
      await _firestore.collection('agences').doc(agenceId).get();

      if (!doc.exists) return null;

      return AgenceModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'agence: $e');
    }
  }

  // ==================== SITES ====================

  // Récupérer tous les sites
  Future<List<SiteModel>> getAllSites() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('sites')
          .orderBy('nom')
          .get();

      return snapshot.docs
          .map((doc) => SiteModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      ))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des sites: $e');
    }
  }

  // Récupérer les sites d'une agence spécifique
  Future<List<SiteModel>> getSitesByAgence(String agenceId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('sites')
          .where('agence_id', isEqualTo: agenceId)
          .orderBy('nom')
          .get();

      return snapshot.docs
          .map((doc) => SiteModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      ))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des sites: $e');
    }
  }

  // Récupérer un site par ID
  Future<SiteModel?> getSiteById(String siteId) async {
    try {
      DocumentSnapshot doc =
      await _firestore.collection('sites').doc(siteId).get();

      if (!doc.exists) return null;

      return SiteModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération du site: $e');
    }
  }

  // ==================== TYPES INTERVENTION ====================

  // Récupérer tous les types d'intervention
  Future<List<Map<String, dynamic>>> getTypesIntervention() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('type_intervention')
          .orderBy('nom')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'nom': data['nom'],
          'champs_specifiques': data['champs_specifiques'],
        };
      }).toList();
    } catch (e) {
      throw Exception(
          'Erreur lors du chargement des types d\'intervention: $e');
    }
  }
}