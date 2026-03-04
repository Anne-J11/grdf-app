// lib/debrief/screens/debrief_create_screen.dart

import 'package:flutter/material.dart';
import 'package:grdf_app/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'package:grdf_app/auth/providers/user_provider.dart';
import '../../brief/widgets/app_header.dart';
import '../../brief/widgets/form_fields.dart';
import '../../brief/widgets/dynamic_fields_section.dart';
import '../../brief/models/type_intervention_model.dart';
import '../models/debrief_model.dart';
import '../services/debrief_service.dart';
import '../services/type_intervention_debrief_service.dart';

class DebriefCreateScreen extends StatefulWidget {
  final String? briefId;
  final String? numBt;
  final String? referentNom;
  final String? typeInterventionNom;
  final String? agenceId;

  const DebriefCreateScreen({
    super.key,
    this.briefId,
    this.numBt,
    this.referentNom,
    this.typeInterventionNom,
    this.agenceId,
  });

  @override
  State<DebriefCreateScreen> createState() => _DebriefCreateScreenState();
}

class _DebriefCreateScreenState extends State<DebriefCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _debriefService = DebriefService();
  final _typeDebriefService = TypeInterventionDebriefService();

  final _commentairesController = TextEditingController();

  // Champs dynamiques (INCLUT aleas_rencontres, travaux_statut, etc.)
  TypeInterventionModel? _typeDebrief;
  final Map<String, TextEditingController> _dynamicControllers = {};

  DateTime _dateIntervention = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    if (widget.typeInterventionNom != null) {
      _typeDebrief = await _typeDebriefService.getTypeDebriefByNom(widget.typeInterventionNom!);
      if (_typeDebrief != null) {
        // Créer un contrôleur pour chaque champ spécifique
        for (var champ in _typeDebrief!.champsSpecifiques) {
          _dynamicControllers[champ] = TextEditingController();

          // Initialiser travaux_statut avec valeur par défaut
          if (champ == 'travaux_statut') {
            _dynamicControllers[champ]!.text = 'Entier';
          }
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  /// Vérifie si le type nécessite le champ travaux_statut
  bool get hasTravauxStatut => _dynamicControllers.containsKey('travaux_statut');

  @override
  void dispose() {
    _commentairesController.dispose();
    _dynamicControllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  Future<void> _saveDebrief() async {
    if (!_formKey.currentState!.validate()) {
      _showMessage('Veuillez remplir tous les champs obligatoires', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      Map<String, dynamic> specifiques = {};

      // Récupérer tous les champs dynamiques (y compris aleas_rencontres)
      _dynamicControllers.forEach((key, controller) {
        specifiques[key] = controller.text;
      });

      final debrief = DebriefModel(
        briefId: widget.briefId ?? '',
        numBt: widget.numBt ?? '',
        typeInterventionId: _typeDebrief?.id ?? '',
        referentId: context.read<UserProvider>().uid,
        agenceId: widget.agenceId ?? context.read<UserProvider>().agenceId,
        dateIntervention: _dateIntervention,
        commentaires: _commentairesController.text.trim(),
        champsSpecifiques: specifiques.isEmpty ? null : specifiques,
      );

      await _debriefService.createDebrief(debrief);
      _showMessage('Debrief enregistré avec succès !');
      Navigator.pop(context);
    } catch (e) {
      _showMessage('Erreur : $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppHeader(
                  onDeconnexionPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                          (route) => false,
                    );
                  },
                ),
                const SizedBox(height: 10),
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
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF33A1C9).withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(),
          const SizedBox(height: 15),
          _buildTopRow(),
          const SizedBox(height: 15),

          // Section des champs dynamiques bleutés
          // INCLUT automatiquement aleas_rencontres pour Clientèle et Travaux
          if (_typeDebrief != null && _dynamicControllers.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF33A1C9).withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DynamicFieldsSection(
                key: ValueKey(_typeDebrief!.id),
                typeIntervention: _typeDebrief!,
                controllers: _dynamicControllers,
              ),
            ),
            const SizedBox(height: 15),
          ],

          // Travaux réalisés (UNIQUEMENT si travaux_statut existe dans champs_specifiques)
          if (hasTravauxStatut) ...[
            const Text(
              'Travaux réalisés *',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            _buildTravauxStatus(),
            const SizedBox(height: 15),
          ],

          // Commentaires
          FormFields.buildLabel('Commentaires'),
          FormFields.buildTextField(
            controller: _commentairesController,
            maxLines: 2,
            isRequired: false,
          ),
          const SizedBox(height: 20),

          _buildFooterActions(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nouveau Debrief${_typeDebrief != null ? " - ${_typeDebrief!.nom}" : ""}',
          style: const TextStyle(
            color: Color(0xFF33A1C9),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Container(height: 3, width: 60, color: Colors.orange),
      ],
    );
  }

  Widget _buildTopRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildInfoItem('Numéro BT', widget.numBt ?? '-'),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: FormFields.buildDateField(
            context: context,
            label: 'Date',
            selectedDate: _dateIntervention,
            onDateSelected: (d) => setState(() => _dateIntervention = d),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: _buildInfoItem('Chef d\'équipe', widget.referentNom ?? 'Inconnu'),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey[400],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTravauxStatus() {
    final controller = _dynamicControllers['travaux_statut']!;
    return Wrap(
      spacing: 10,
      runSpacing: 5,
      children: ["Entier", "Partiel", "non réalisé"]
          .map((statut) => _buildStatusItem(statut, controller))
          .toList(),
    );
  }

  Widget _buildStatusItem(String label, TextEditingController controller) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11)),
        Checkbox(
          value: controller.text == label,
          onChanged: (v) => setState(() => controller.text = label),
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
      spacing: 10,
      runSpacing: 10,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSmallSignatureBox('Signature chef'),
            const SizedBox(width: 8),
            _buildSmallSignatureBox('Signature tech.'),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.image, size: 14),
              label: const Text('Photo', style: TextStyle(fontSize: 10)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF33A1C9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(height: 5),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveDebrief,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA5D6A7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: _isSaving
                  ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Enregistrer',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallSignatureBox(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey[400],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 50,
          width: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Icon(Icons.edit_outlined, color: Colors.grey[300], size: 18),
        ),
      ],
    );
  }
}
