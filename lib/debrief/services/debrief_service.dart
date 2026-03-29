// lib/debrief/services/debrief_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/debrief_model.dart';
import '../../brief/services/brief_service.dart';

class DebriefService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BriefService _briefService = BriefService();

  // Récupérer les débriefs avec filtres combinés (référent / manager)
  Future<List<DebriefModel>> getDebriefsWithFilters({
    String? agenceId,
    String? siteId,
    DateTime? dateIntervention,
  }) async {
    try {
      Query query = _firestore.collection('debriefs');

      if (agenceId != null) {
        query = query.where('agence_id', isEqualTo: agenceId);
      }

      if (siteId != null) {
        query = query.where('site_id', isEqualTo: siteId);
      }

      if (dateIntervention != null) {
        final startOfDay = DateTime(
          dateIntervention.year,
          dateIntervention.month,
          dateIntervention.day,
        );
        final endOfDay = DateTime(
          dateIntervention.year,
          dateIntervention.month,
          dateIntervention.day,
          23,
          59,
          59,
        );
        query = query
            .where('date_intervention',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('date_intervention',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
      }

      query = query.orderBy('date_intervention', descending: true);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => DebriefModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      ))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des débriefs: $e');
    }
  }

  /// Débriefs visibles par un technicien :
  /// — débriefs du site cible (siteIdFiltre s'il a choisi un site dans le
  ///   dropdown, sinon son site par défaut),
  /// — débriefs pour lesquels technicien_id == uid.
  /// Les deux ensembles sont fusionnés et dédupliqués, puis filtrés
  /// optionnellement par date. Miroir exact de getBriefsForTechnicien.
  Future<List<DebriefModel>> getDebriefsForTechnicien({
    required String uid,
    required String siteId,     // site par défaut du technicien
    String? siteIdFiltre,       // site choisi via le dropdown (peut être null)
    DateTime? dateIntervention,
  }) async {
    try {
      final String siteEffectif = siteIdFiltre ?? siteId;

      // Requête 1 : débriefs du site effectif
      final Query querySite = _firestore
          .collection('debriefs')
          .where('site_id', isEqualTo: siteEffectif);

      // Requête 2 : débriefs explicitement liés au technicien
      final Query queryAssigne = _firestore
          .collection('debriefs')
          .where('technicien_id', isEqualTo: uid);

      final results = await Future.wait([
        querySite.get(),
        queryAssigne.get(),
      ]);

      // Fusion + déduplication par ID de document
      final Map<String, DebriefModel> map = {};
      for (final snapshot in results) {
        for (final doc in snapshot.docs) {
          if (!map.containsKey(doc.id)) {
            map[doc.id] = DebriefModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }
        }
      }

      List<DebriefModel> debriefs = map.values.toList();

      // Filtre optionnel par date côté client
      if (dateIntervention != null) {
        final start = DateTime(
          dateIntervention.year,
          dateIntervention.month,
          dateIntervention.day,
        );
        final end = DateTime(
          dateIntervention.year,
          dateIntervention.month,
          dateIntervention.day,
          23,
          59,
          59,
        );
        debriefs = debriefs
            .where((d) =>
        !d.dateIntervention.isBefore(start) &&
            !d.dateIntervention.isAfter(end))
            .toList();
      }

      // Tri anti-chronologique
      debriefs.sort(
              (a, b) => b.dateIntervention.compareTo(a.dateIntervention));

      return debriefs;
    } catch (e) {
      throw Exception(
          'Erreur lors du chargement des débriefs technicien: $e');
    }
  }

  // Créer un debrief ET verrouiller automatiquement le brief associé
  Future<String> createDebrief(DebriefModel debrief) async {
    try {
      final DocumentReference docRef =
      await _firestore.collection('debriefs').add(debrief.toFirestore());

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
      final DocumentSnapshot doc =
      await _firestore.collection('debriefs').doc(debriefId).get();
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
      final QuerySnapshot snapshot = await _firestore
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
      final QuerySnapshot snapshot = await _firestore
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
      final QuerySnapshot snapshot = await _firestore
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
  Future<void> updateDebrief(
      String debriefId, Map<String, dynamic> data) async {
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