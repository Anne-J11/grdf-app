// lib/brief/screens/brief_create_screen.dart

import 'package:flutter/material.dart';
import 'package:grdf_app/welcome_screen.dart';
import '../../debrief/screens/debrief_create_screen_old.dart';
import '../controllers/brief_form_controller.dart';
import '../widgets/app_header.dart';
import '../widgets/dynamic_fields_section.dart';
import '../widgets/form_fields_old.dart';

class BriefCreateScreen extends StatefulWidget {
  const BriefCreateScreen({super.key});

  @override
  State<BriefCreateScreen> createState() => _BriefCreateScreenState();
}

class _BriefCreateScreenState extends State<BriefCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = BriefFormController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveBrief() async {
    if (!_formKey.currentState!.validate()) {
      _showMessage('Veuillez remplir tous les champs obligatoires', isError: true);
      return;
    }

    if (_controller.selectedType == null) {
      _showMessage('Veuillez sélectionner un type d\'intervention', isError: true);
      return;
    }

    final success = await _controller.saveBrief(
      referentId: 'USER_ID_TEMP', // TODO: Remplacer par l'utilisateur connecté
      agenceId: 'AGENCE_ID_TEMP',
      siteId: 'SITE_ID_TEMP',
    );

    if (success) {
      _showMessage('Brief enregistré avec succès !');
    } else {
      _showMessage('Erreur lors de l\'enregistrement', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF33A1C9)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header
                AppHeader(
                  onVisualisationPressed: () {},
                  onDeconnexionPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                          (route) => false,
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Formulaire
                _buildFormContainer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF33A1C9).withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(),
          const SizedBox(height: 25),
          _buildTopRow(),
          const SizedBox(height: 20),
          _buildMainFields(),
          if (_controller.selectedType != null) ...[
            const SizedBox(height: 25),
            DynamicFieldsSection(
              typeIntervention: _controller.selectedType!,
              controllers: _controller.dynamicControllers,
            ),
          ],
          const SizedBox(height: 30),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nouveau Brief',
              style: TextStyle(
                color: Color(0xFF33A1C9),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 3,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DebriefCreateScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Créer un debrief',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        Expanded(
          child: FormFields.buildSmallField(
            label: 'Numéro BT',
            controller: _controller.numBtController,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FormFields.buildDateField(
            context: context,
            label: 'Date d\'intervention',
            selectedDate: _controller.dateIntervention,
            onDateSelected: _controller.setDate,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FormFields.buildSmallFieldStatic(
            label: 'Référent d\'équipe',
            value: 'Nom du référent',
          ),
        ),
      ],
    );
  }

  Widget _buildMainFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type d'intervention
        FormFields.buildLabel('Type d\'intervention *'),
        DropdownButtonFormField(
          value: _controller.selectedType,
          decoration: _dropdownDecoration(),
          hint: const Text('Sélectionner un type'),
          items: _controller.typesIntervention.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.nom),
            );
          }).toList(),
          onChanged: _controller.onTypeChanged,
          validator: (value) => value == null ? 'Requis' : null,
        ),
        const SizedBox(height: 15),

        // Localisation
        FormFields.buildLabel('Localisation du chantier *'),
        FormFields.buildTextField(
          controller: _controller.lieuController,
          hint: "Ex: Rue de la Paix, Paris",
        ),
        const SizedBox(height: 15),

        // Risques
        FormFields.buildLabel('Vérification des risques *'),
        FormFields.buildTextField(
          controller: _controller.risquesController,
        ),
        const SizedBox(height: 15),

        // Matériel
        FormFields.buildLabel('État du matériel *'),
        FormFields.buildTextField(
          controller: _controller.materielController,
        ),
        const SizedBox(height: 15),

        // Consignes
        FormFields.buildLabel('Consigne du jour *'),
        FormFields.buildTextField(
          controller: _controller.consignesController,
        ),
        const SizedBox(height: 15),

        // Commentaires
        FormFields.buildLabel('Commentaires'),
        FormFields.buildTextField(
          controller: _controller.commentairesController,
          maxLines: 3,
          isRequired: false,
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 20,
      runSpacing: 20,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FormFields.buildSignatureBox('Signature du référent'),
            const SizedBox(width: 15),
            FormFields.buildSignatureBox('Signature du technicien'),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Importer une photo'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF33A1C9),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _controller.isSaving ? null : _saveBrief,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _controller.isSaving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Enregistrer le Brief',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      isDense: true,
      fillColor: Colors.white,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF33A1C9), width: 1.5),
      ),
    );
  }
}
