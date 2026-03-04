// lib/brief/models/brief_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant un brief d'intervention GRDF
///
/// Contient toutes les informations nécessaires pour une intervention :
/// - Informations du BT et du type d'intervention
/// - Référent et technicien assigné
/// - Détails de l'intervention (date, lieu, consignes)
/// - Statut et suivi
class BriefModel {
  // ============================================================================
  // IDENTIFIANTS ET RÉFÉRENCES
  // ============================================================================

  /// ID du document Firestore (généré automatiquement)
  final String? id;

  /// Numéro du Bon de Travail
  final String numBt;

  /// ID du type d'intervention (référence vers la collection types_intervention)
  final String typeInterventionId;

  /// Nom du type d'intervention (dénormalisé pour faciliter l'affichage)
  final String? typeInterventionNom;

  /// ID du référent qui a créé le brief
  final String referentId;

  /// Nom complet du référent (dénormalisé pour faciliter l'affichage)
  final String referentNom;

  /// ID du technicien assigné (optionnel, peut être null si pas encore assigné)
  final String? technicienId;

  /// ID de l'agence concernée
  final String agenceId;

  /// ID du site d'intervention
  final String siteId;

  // ============================================================================
  // DÉTAILS DE L'INTERVENTION
  // ============================================================================

  /// Date prévue de l'intervention
  final DateTime dateIntervention;

  /// Description des risques identifiés sur le chantier
  final String risques;

  /// Liste du matériel nécessaire pour l'intervention
  final String materiel;

  /// Consignes de sécurité et instructions spécifiques
  final String consignes;

  /// Commentaires additionnels (optionnel)
  final String? commentaires;

  // ============================================================================
  // CHAMPS DYNAMIQUES ET STATUT
  // ============================================================================

  /// Champs spécifiques selon le type d'intervention
  /// Permet d'ajouter des données personnalisées par type
  final Map<String, dynamic>? champsSpecifiques;

  /// Statut actuel du brief
  /// Valeurs possibles : 'envoye', 'lu', 'en_cours', 'termine'
  final String statut;

  /// Date de création du brief
  final DateTime dateCreation;

  /// true si un débrief a été validé → le brief est en lecture seule
  final bool estVerrouille;

  /// true si archivé automatiquement (> 2 ans)
  final bool archived;

  // ============================================================================
  // CONSTRUCTEUR
  // ============================================================================

  BriefModel({
    this.id,
    required this.numBt,
    required this.typeInterventionId,
    this.typeInterventionNom,
    required this.referentId,
    required this.referentNom,
    this.technicienId,
    required this.agenceId,
    required this.siteId,
    required this.dateIntervention,
    required this.risques,
    required this.materiel,
    required this.consignes,
    this.commentaires,
    this.champsSpecifiques,
    this.statut = 'envoye',
    DateTime? dateCreation,
    this.estVerrouille = false,
    this.archived = false,
  }) : dateCreation = dateCreation ?? DateTime.now();

  // ============================================================================
  // FACTORY - DEPUIS FIRESTORE
  // ============================================================================

  /// Crée une instance de BriefModel depuis les données Firestore
  ///
  /// [data] : Map contenant les données du document Firestore
  /// [id] : ID du document Firestore
  factory BriefModel.fromFirestore(Map<String, dynamic> data, String id) {
    return BriefModel(
      id: id,
      numBt: data['num_bt'] ?? '',
      typeInterventionId: data['type_intervention_id'] ?? '',
      typeInterventionNom: data['type_intervention_nom'],
      referentId: data['referent_id'] ?? '',
      referentNom: data['referent_nom'] ?? '',
      technicienId: data['technicien_id'],
      agenceId: data['agence_id'] ?? '',
      siteId: data['site_id'] ?? '',
      dateIntervention: (data['date_intervention'] as Timestamp).toDate(),
      risques: data['risques'] ?? '',
      materiel: data['materiel'] ?? '',
      consignes: data['consignes'] ?? '',
      commentaires: data['commentaires'],
      champsSpecifiques: data['champs_specifiques'] as Map<String, dynamic>?,
      statut: data['statut'] ?? 'envoye',
      dateCreation: (data['date_brief'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estVerrouille: data['est_verrouille'] ?? false,
      archived: data['archived'] ?? false,
    );
  }

  // ============================================================================
  // CONVERSION VERS FIRESTORE
  // ============================================================================

  /// Convertit l'instance en Map pour Firestore
  ///
  /// Utilise FieldValue.serverTimestamp() pour date_brief
  /// afin de garantir la cohérence des timestamps côté serveur
  Map<String, dynamic> toFirestore() {
    return {
      'num_bt': numBt,
      'type_intervention_id': typeInterventionId,
      'type_intervention_nom': typeInterventionNom,
      'referent_id': referentId,
      'referent_nom': referentNom,
      'technicien_id': technicienId,
      'agence_id': agenceId,
      'site_id': siteId,
      'date_intervention': Timestamp.fromDate(dateIntervention),
      'risques': risques,
      'materiel': materiel,
      'consignes': consignes,
      'commentaires': commentaires,
      'champs_specifiques': champsSpecifiques,
      'statut': statut,
      'date_brief': FieldValue.serverTimestamp(),
      'est_verrouille': estVerrouille,
      'archived': archived,
    };
  }

  // ============================================================================
  // MÉTHODE COPYWITH
  // ============================================================================

  /// Crée une copie du BriefModel avec les champs modifiés
  ///
  /// Tous les paramètres sont optionnels. Seuls les champs fournis
  /// seront modifiés, les autres conserveront leur valeur actuelle.
  BriefModel copyWith({
    String? id,
    String? numBt,
    String? typeInterventionId,
    String? typeInterventionNom,
    String? referentId,
    String? referentNom,
    String? technicienId,
    String? agenceId,
    String? siteId,
    DateTime? dateIntervention,
    String? risques,
    String? materiel,
    String? consignes,
    String? commentaires,
    Map<String, dynamic>? champsSpecifiques,
    String? statut,
    DateTime? dateCreation,
    bool? estVerrouille,
    bool? archived,
  }) {
    return BriefModel(
      id: id ?? this.id,
      numBt: numBt ?? this.numBt,
      typeInterventionId: typeInterventionId ?? this.typeInterventionId,
      typeInterventionNom: typeInterventionNom ?? this.typeInterventionNom,
      referentId: referentId ?? this.referentId,
      referentNom: referentNom ?? this.referentNom,
      technicienId: technicienId ?? this.technicienId,
      agenceId: agenceId ?? this.agenceId,
      siteId: siteId ?? this.siteId,
      dateIntervention: dateIntervention ?? this.dateIntervention,
      risques: risques ?? this.risques,
      materiel: materiel ?? this.materiel,
      consignes: consignes ?? this.consignes,
      commentaires: commentaires ?? this.commentaires,
      champsSpecifiques: champsSpecifiques ?? this.champsSpecifiques,
      statut: statut ?? this.statut,
      dateCreation: dateCreation ?? this.dateCreation,
      estVerrouille: estVerrouille ?? this.estVerrouille,
      archived: archived ?? this.archived,
    );
  }

  // ============================================================================
  // MÉTHODE toString (pour le débogage)
  // ============================================================================

  @override
  String toString() {
    return 'BriefModel(id: $id, numBt: $numBt, statut: $statut, referentNom: $referentNom)';
  }
}