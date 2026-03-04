// lib/debrief/screens/debrief_create_screen_old.dart

import 'package:flutter/material.dart';
import '../../welcome_screen.dart';
import '../../brief/widgets/app_header.dart';
import '../../brief/widgets/form_fields_old.dart';

class DebriefCreateScreen extends StatefulWidget {
  const DebriefCreateScreen({super.key});

  @override
  State<DebriefCreateScreen> createState() => _DebriefCreateScreenState();
}

class _DebriefCreateScreenState extends State<DebriefCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs
  final TextEditingController _btController = TextEditingController(text: "1235");
  final TextEditingController _referentController = TextEditingController(text: "Nom du référent");
  final TextEditingController _realiseController = TextEditingController();
  final TextEditingController _materielController = TextEditingController();
  final TextEditingController _problemeController = TextEditingController();
  final TextEditingController _incidentsController = TextEditingController();
  final TextEditingController _commentairesController = TextEditingController();
  
  DateTime _dateIntervention = DateTime.now();
  String _travauxStatut = "Entier"; // Par défaut

  @override
  void dispose() {
    _btController.dispose();
    _referentController.dispose();
    _realiseController.dispose();
    _materielController.dispose();
    _problemeController.dispose();
    _incidentsController.dispose();
    _commentairesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 15),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
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
                const SizedBox(height: 15),
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF33A1C9).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(),
          const SizedBox(height: 20),
          _buildTopRow(),
          const SizedBox(height: 20),
          FormFields.buildLabel('Indication de ce qui a été réalisé ou non*'),
          FormFields.buildTextField(
            controller: _realiseController,
            hint: "Saisir ici...",
          ),
          const SizedBox(height: 20),
          const Text(
            'Aléas rencontré(s) *',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          _buildAleasRow(),
          const SizedBox(height: 20),
          const Text(
            'Travaux réalisés *',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          _buildTravauxStatus(),
          const SizedBox(height: 20),
          FormFields.buildLabel('Commentaires'),
          FormFields.buildTextField(
            controller: _commentairesController,
            maxLines: 2,
            isRequired: false,
          ),
          const SizedBox(height: 25),
          _buildFooterActions(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nouveau Debrief',
          style: TextStyle(
            color: Color(0xFF33A1C9),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 3,
          width: 100,
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(10),
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
            label: 'numero BT',
            controller: _btController,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FormFields.buildDateField(
            context: context,
            label: 'Date d\'intervention',
            selectedDate: _dateIntervention,
            onDateSelected: (date) => setState(() => _dateIntervention = date),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FormFields.buildSmallField(
            label: 'Référent d\'équipe',
            controller: _referentController,
          ),
        ),
      ],
    );
  }

  Widget _buildAleasRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildAleasColumn('Materiel endommagé', _materielController)),
        const SizedBox(width: 8),
        Expanded(child: _buildAleasColumn('Problème sur chantier', _problemeController)),
        const SizedBox(width: 8),
        Expanded(child: _buildAleasColumn('incidents éventuels', _incidentsController, isBold: true)),
      ],
    );
  }

  Widget _buildAleasColumn(String label, TextEditingController controller, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontStyle: FontStyle.italic,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 5),
        _buildCompactField(controller),
      ],
    );
  }

  Widget _buildCompactField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        isDense: true,
        fillColor: const Color(0xFFE9ECEF),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }

  Widget _buildTravauxStatus() {
    return Wrap(
      spacing: 15,
      runSpacing: 5,
      children: [
        _buildStatusItem("Entier"),
        _buildStatusItem("Partiel"),
        _buildStatusItem("non réalisé"),
      ],
    );
  }

  Widget _buildStatusItem(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Checkbox(
          value: _travauxStatut == label,
          onChanged: (val) {
            if (val == true) setState(() => _travauxStatut = label);
          },
          activeColor: const Color(0xFF33A1C9),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildFooterActions() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 15,
      runSpacing: 15,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FormFields.buildSignatureBox('Signature du referent'),
            const SizedBox(width: 10),
            FormFields.buildSignatureBox('Signature du technicien'),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.image, size: 16),
              label: const Text('Importer une photo', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF33A1C9),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Debrief enregistré !')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA5D6A7),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Enregistrer le Debrief',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
