// lib/debrief/models/debrief_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant un débrief d'intervention
///
/// Un débrief est créé après la réalisation d'un brief pour documenter
/// ce qui s'est réellement passé sur le terrain.
class DebriefModel {
  // ============================================================================
  // IDENTIFIANTS ET RÉFÉRENCES
  // ============================================================================

  /// ID du document Firestore (généré automatiquement)
  final String? id;

  /// ID du brief associé (lien avec le brief d'origine)
  final String briefId;

  /// Numéro du Bon de Travail (dupliqué depuis le brief)
  final String numBt;

  /// ID du type d'intervention
  final String typeInterventionId;

  /// ID du référent qui a créé le brief
  final String referentId;

  /// ID du technicien qui a réalisé l'intervention (optionnel)
  final String? technicienId;

  /// ID de l'agence — stocké pour le filtrage par agence
  final String agenceId;

  /// ID du site d'intervention
  final String siteId;

  // ============================================================================
  // DÉTAILS DE L'INTERVENTION RÉALISÉE
  // ============================================================================

  /// Date à laquelle l'intervention a été réalisée
  final DateTime dateIntervention;

  /// Commentaires additionnels (optionnel)
  final String? commentaires;


  // ============================================================================
  // CHAMPS DYNAMIQUES ET STATUT
  // ============================================================================

  /// Champs spécifiques selon le type d'intervention
  /// Exemple pour "Travaux" : {"aleas_rencontres": "...", "travaux_statut": "Entier"}
  /// Exemple pour "Clientèle" : {"aleas_rencontres": "..."}
  final Map<String, dynamic>? champsSpecifiques;

  /// Statut du débrief
  /// Valeur par défaut : 'termine'
  final String statut;

  /// Date de création du débrief
  final DateTime dateCreation;

  /// true si archivé automatiquement (> 2 ans)
  final bool archived;

  // ============================================================================
  // CONSTRUCTEUR
  // ============================================================================

  DebriefModel({
    this.id,
    required this.briefId,
    required this.numBt,
    required this.typeInterventionId,
    required this.referentId,
    this.technicienId,
    required this.agenceId,
    required this.siteId,
    required this.dateIntervention,
    this.commentaires,
    this.champsSpecifiques,
    this.statut = 'termine',
    DateTime? dateCreation,
    this.archived = false,
  }) : dateCreation = dateCreation ?? DateTime.now();

  // ============================================================================
  // FACTORY - DEPUIS FIRESTORE
  // ============================================================================

  /// Crée une instance de DebriefModel depuis les données Firestore
  ///
  /// [data] : Map contenant les données du document Firestore
  /// [id] : ID du document Firestore
  factory DebriefModel.fromFirestore(Map<String, dynamic> data, String id) {
    return DebriefModel(
      id: id,
      briefId: data['brief_id'] ?? '',
      numBt: data['num_bt'] ?? '',
      typeInterventionId: data['type_intervention_id'] ?? '',
      referentId: data['referent_id'] ?? '',
      technicienId: data['technicien_id'],
      agenceId: data['agence_id'] ?? '',
      siteId: data['site_id'] ?? '',
      dateIntervention: (data['date_intervention'] as Timestamp).toDate(),
      commentaires: data['commentaires'],
      champsSpecifiques: data['champs_specifiques'] as Map<String, dynamic>?,
      statut: data['statut'] ?? 'termine',
      dateCreation: (data['date_debrief'] as Timestamp?)?.toDate() ?? DateTime.now(),
      archived: data['archived'] ?? false,
    );
  }

  // ============================================================================
  // CONVERSION VERS FIRESTORE
  // ============================================================================

  /// Convertit l'instance en Map pour Firestore
  ///
  /// Utilise FieldValue.serverTimestamp() pour date_debrief
  /// afin de garantir la cohérence des timestamps côté serveur
  Map<String, dynamic> toFirestore() {
    return {
      'brief_id': briefId,
      'num_bt': numBt,
      'type_intervention_id': typeInterventionId,
      'referent_id': referentId,
      'technicien_id': technicienId,
      'agence_id': agenceId,
      'site_id': siteId,
      'date_intervention': Timestamp.fromDate(dateIntervention),
      'commentaires': commentaires,
      'champs_specifiques': champsSpecifiques,
      'statut': statut,
      'date_debrief': FieldValue.serverTimestamp(),
      'archived': archived,
    };
  }

  // ============================================================================
  // HELPERS - RÉCUPÉRER DES CHAMPS SPÉCIFIQUES
  // ============================================================================

  /// Récupère les aléas rencontrés depuis champs_specifiques
  /// Retourne null si pas présent (types autres que "Travaux" ou "Clientèle")
  String? get aleasRencontres {
    return champsSpecifiques?['aleas_rencontres'] as String?;
  }

  /// Récupère le statut des travaux depuis champs_specifiques
  /// Retourne null si pas présent (types autres que "Travaux")
  String? get travauxStatut {
    return champsSpecifiques?['travaux_statut'] as String?;
  }

  // ============================================================================
  // MÉTHODE COPYWITH
  // ============================================================================

  /// Crée une copie du DebriefModel avec les champs modifiés
  ///
  /// Tous les paramètres sont optionnels. Seuls les champs fournis
  /// seront modifiés, les autres conserveront leur valeur actuelle.
  DebriefModel copyWith({
    String? id,
    String? briefId,
    String? numBt,
    String? typeInterventionId,
    String? referentId,
    String? technicienId,
    String? agenceId,
    String? siteId,
    DateTime? dateIntervention,
    String? commentaires,
    Map<String, dynamic>? champsSpecifiques,
    String? statut,
    DateTime? dateCreation,
    bool? archived,
  }) {
    return DebriefModel(
      id: id ?? this.id,
      briefId: briefId ?? this.briefId,
      numBt: numBt ?? this.numBt,
      typeInterventionId: typeInterventionId ?? this.typeInterventionId,
      referentId: referentId ?? this.referentId,
      technicienId: technicienId ?? this.technicienId,
      agenceId: agenceId ?? this.agenceId,
      siteId: siteId ?? this.siteId,
      dateIntervention: dateIntervention ?? this.dateIntervention,
      commentaires: commentaires ?? this.commentaires,
      champsSpecifiques: champsSpecifiques ?? this.champsSpecifiques,
      statut: statut ?? this.statut,
      dateCreation: dateCreation ?? this.dateCreation,
      archived: archived ?? this.archived,
    );
  }

  // ============================================================================
  // MÉTHODE toString (pour le débogage)
  // ============================================================================

  @override
  String toString() {
    return 'DebriefModel(id: $id, numBt: $numBt, statut: $statut)';
  }
}