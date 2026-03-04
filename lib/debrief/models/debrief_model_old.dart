// lib/debrief/models/debrief_model_old.dart

class DebriefModel {
  final String? id;
  final String numeroBt;
  final DateTime dateIntervention;
  final String referentNom;
  final String indicationRealise;
  final String materielEndommage;
  final String problemeChantier;
  final String incidentsEventuels;
  final String travauxStatut; // 'Entier', 'Partiel', 'Non réalisé'
  final String? commentaires;
  final DateTime createdAt;

  DebriefModel({
    this.id,
    required this.numeroBt,
    required this.dateIntervention,
    required this.referentNom,
    required this.indicationRealise,
    required this.materielEndommage,
    required this.problemeChantier,
    required this.incidentsEventuels,
    required this.travauxStatut,
    this.commentaires,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'numeroBt': numeroBt,
      'dateIntervention': dateIntervention.toIso8601String(),
      'referentNom': referentNom,
      'indicationRealise': indicationRealise,
      'materielEndommage': materielEndommage,
      'problemeChantier': problemeChantier,
      'incidentsEventuels': incidentsEventuels,
      'travauxStatut': travauxStatut,
      'commentaires': commentaires,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DebriefModel.fromMap(Map<String, dynamic> map, String id) {
    return DebriefModel(
      id: id,
      numeroBt: map['numeroBt'] ?? '',
      dateIntervention: DateTime.parse(map['dateIntervention']),
      referentNom: map['referentNom'] ?? '',
      indicationRealise: map['indicationRealise'] ?? '',
      materielEndommage: map['materielEndommage'] ?? '',
      problemeChantier: map['problemeChantier'] ?? '',
      incidentsEventuels: map['incidentsEventuels'] ?? '',
      travauxStatut: map['travauxStatut'] ?? 'Entier',
      commentaires: map['commentaires'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }
}
