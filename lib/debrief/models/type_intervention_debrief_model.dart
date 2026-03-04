// lib/debrief/models/type_intervention_debrief_model.dart

class TypeInterventionDebriefModel {
  final String id;
  final String nom;
  final List<String> champsSpecifiques;

  TypeInterventionDebriefModel({
    required this.id,
    required this.nom,
    required this.champsSpecifiques,
  });

  factory TypeInterventionDebriefModel.fromFirestore(Map<String, dynamic> data, String id) {
    return TypeInterventionDebriefModel(
      id: id,
      nom: data['nom'] ?? '',
      champsSpecifiques: (data['champs_specifiques'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }
}