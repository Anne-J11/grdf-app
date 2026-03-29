// lib/brief/services/brief_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/brief_model.dart';

class BriefService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer les briefs avec filtres combinés (référent / manager)
  Future<List<BriefModel>> getBriefsWithFilters({
    String? agenceId,
    String? siteId,
    DateTime? dateIntervention,
  }) async {
    try {
      Query query = _firestore.collection('briefs');

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
          .map((doc) => BriefModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      ))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des briefs: $e');
    }
  }

  /// Briefs visibles par un technicien :
  /// — briefs du site cible (siteIdFiltre s'il a choisi un site dans le
  ///   dropdown, sinon son site par défaut),
  /// — briefs pour lesquels technicien_id == uid.
  /// Les deux ensembles sont fusionnés et dédupliqués, puis filtrés
  /// optionnellement par date.
  Future<List<BriefModel>> getBriefsForTechnicien({
    required String uid,
    required String siteId,       // site par défaut du technicien
    String? siteIdFiltre,         // site choisi via le dropdown (peut être null)
    DateTime? dateIntervention,
  }) async {
    try {
      // Le site effectivement utilisé pour la requête par site :
      // si le technicien a sélectionné un site dans le filtre on l'utilise,
      // sinon on utilise son site d'appartenance.
      final String siteEffectif = siteIdFiltre ?? siteId;

      // Requête 1 : briefs du site effectif
      final Query querySite = _firestore
          .collection('briefs')
          .where('site_id', isEqualTo: siteEffectif);

      // Requête 2 : briefs explicitement assignés au technicien
      final Query queryAssigne = _firestore
          .collection('briefs')
          .where('technicien_id', isEqualTo: uid);

      final results = await Future.wait([
        querySite.get(),
        queryAssigne.get(),
      ]);

      // Fusion + déduplication par ID de document
      final Map<String, BriefModel> map = {};
      for (final snapshot in results) {
        for (final doc in snapshot.docs) {
          if (!map.containsKey(doc.id)) {
            map[doc.id] = BriefModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }
        }
      }

      List<BriefModel> briefs = map.values.toList();

      // Filtre optionnel par date (côté client, car les deux requêtes
      // sont indépendantes et ne peuvent pas partager un orderBy Firestore)
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
        briefs = briefs
            .where((b) =>
        !b.dateIntervention.isBefore(start) &&
            !b.dateIntervention.isAfter(end))
            .toList();
      }

      // Tri anti-chronologique
      briefs.sort(
              (a, b) => b.dateIntervention.compareTo(a.dateIntervention));

      return briefs;
    } catch (e) {
      throw Exception(
          'Erreur lors du chargement des briefs technicien: $e');
    }
  }

  // Créer un brief
  Future<String> createBrief(BriefModel brief) async {
    try {
      final DocumentReference docRef =
      await _firestore.collection('briefs').add(brief.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création du brief: $e');
    }
  }

  // Récupérer un brief par ID
  Future<BriefModel?> getBriefById(String briefId) async {
    try {
      final DocumentSnapshot doc =
      await _firestore.collection('briefs').doc(briefId).get();
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
      final QuerySnapshot snapshot = await _firestore
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
      final QuerySnapshot snapshot = await _firestore
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
      final QuerySnapshot snapshot = await _firestore
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
      final QuerySnapshot snapshot = await _firestore
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
  Future<List<BriefModel>> getBriefsByDate(
      DateTime date, String siteId) async {
    try {
      final DateTime startOfDay =
      DateTime(date.year, date.month, date.day);
      final DateTime endOfDay =
      DateTime(date.year, date.month, date.day, 23, 59, 59);
      final QuerySnapshot snapshot = await _firestore
          .collection('briefs')
          .where('site_id', isEqualTo: siteId)
          .where('date_intervention',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date_intervention',
          isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
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