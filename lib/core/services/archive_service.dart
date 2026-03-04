// lib/core/services/archive_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ArchiveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Archive automatiquement tous les briefs et débriefs de plus de 2 ans.
  /// Appelé au lancement de l'app ET manuellement depuis les Paramètres.
  Future<void> lancerArchivageAutomatique() async {
    try {
      final dateLimit = DateTime.now().subtract(const Duration(days: 365 * 2));
      final tsLimit = Timestamp.fromDate(dateLimit);

      // Archiver les briefs
      final briefs = await _firestore
          .collection('briefs')
          .where('archived', isEqualTo: false)
          .where('date_brief', isLessThan: tsLimit)
          .get();
      for (var doc in briefs.docs) {
        await doc.reference.update({'archived': true});
      }

      // Archiver les débriefs
      final debriefs = await _firestore
          .collection('debriefs')
          .where('archived', isEqualTo: false)
          .where('date_debrief', isLessThan: tsLimit)
          .get();
      for (var doc in debriefs.docs) {
        await doc.reference.update({'archived': true});
      }

      final total = briefs.docs.length + debriefs.docs.length;
      if (total > 0) {
        debugPrint(
            '📦 Archivage : ${briefs.docs.length} brief(s) et ${debriefs.docs.length} débrief(s) archivé(s)');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur archivage : $e');
    }
  }
}
