// lib/brief/models/type_intervention_model.dart

import 'package:flutter/foundation.dart';

class TypeInterventionModel {
  final String id;
  final String nom;
  final List<String> champsSpecifiques;

  TypeInterventionModel({
    required this.id,
    required this.nom,
    required this.champsSpecifiques,
  });

  factory TypeInterventionModel.fromFirestore(Map<String, dynamic> data, String id) {
    return TypeInterventionModel(
      id: id,
      nom: data['nom'] ?? '',
      champsSpecifiques: (data['champs_specifiques'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is TypeInterventionModel &&
      other.id == id &&
      other.nom == nom &&
      listEquals(other.champsSpecifiques, champsSpecifiques);
  }

  @override
  int get hashCode => id.hashCode ^ nom.hashCode ^ champsSpecifiques.hashCode;
}
