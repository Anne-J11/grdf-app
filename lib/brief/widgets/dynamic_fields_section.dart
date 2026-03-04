// lib/brief/widgets/dynamic_fields_section.dart
// Modification : ajout du paramètre readOnly pour le mode verrouillé.
// Le reste est identique au code de ta collègue.

import 'package:flutter/material.dart';
import '../models/type_intervention_model.dart';
import './form_fields.dart';

class DynamicFieldsSection extends StatelessWidget {
  final TypeInterventionModel typeIntervention;
  final Map<String, TextEditingController> controllers;
  final bool readOnly;

  const DynamicFieldsSection({
    super.key,
    required this.typeIntervention,
    required this.controllers,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (typeIntervention.champsSpecifiques.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: typeIntervention.champsSpecifiques.map((champ) {
        final controller = controllers[champ];
        if (controller == null) {
          return Text('Erreur: contrôleur manquant pour "$champ"');
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormFields.buildLabel(champ),
              FormFields.buildTextField(
                controller: controller,
                isRequired: false,
                readOnly: readOnly,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
