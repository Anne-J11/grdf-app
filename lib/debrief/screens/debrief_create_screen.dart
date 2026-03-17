// lib/debrief/screens/debrief_create_screen.dart

import 'package:flutter/material.dart';
import 'package:grdf_app/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'package:grdf_app/auth/providers/user_provider.dart';
import '../../brief/services/brief_service.dart';
import '../../brief/widgets/app_header.dart';
import '../../brief/widgets/form_fields.dart';
import '../../brief/widgets/dynamic_fields_section.dart';
import '../../brief/models/type_intervention_model.dart';
import '../models/debrief_model.dart';
import '../services/debrief_service.dart';
import '../services/type_intervention_debrief_service.dart';
import '../../auth/component/signature_widget.dart';
import '../../auth/component/photo_selection_widget.dart';

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

  TypeInterventionModel? _typeDebrief;
  final Map<String, TextEditingController> _dynamicControllers = {};

  DateTime _dateIntervention = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;

  // Photos (Base64)
  List<String> _photosBase64 = [];

  // Signature technicien
  String? _signatureTechnicien;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    if (widget.typeInterventionNom != null) {
      _typeDebrief = await _typeDebriefService
          .getTypeDebriefByNom(widget.typeInterventionNom!);
      if (_typeDebrief != null) {
        for (var champ in _typeDebrief!.champsSpecifiques) {
          _dynamicControllers[champ] = TextEditingController();
          if (champ == 'travaux_statut') {
            _dynamicControllers[champ]!.text = 'Entier';
          }
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  bool get hasTravauxStatut =>
      _dynamicControllers.containsKey('travaux_statut');

  @override
  void dispose() {
    _commentairesController.dispose();
    _dynamicControllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  // ── Sauvegarde ────────────────────────────────────────────────────────────
  Future<void> _saveDebrief() async {
    if (!_formKey.currentState!.validate()) {
      _showMessage('Veuillez remplir tous les champs obligatoires', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      String siteId = context.read<UserProvider>().siteId;
      String agenceId = widget.agenceId ?? context.read<UserProvider>().agenceId;

      if (widget.briefId != null && widget.briefId!.isNotEmpty) {
        try {
          final briefService = BriefService();
          final brief = await briefService.getBriefById(widget.briefId!);
          if (brief != null) {
            siteId = brief.siteId;
            agenceId = brief.agenceId;
          }
        } catch (e) {
          debugPrint('Impossible de récupérer le brief: $e');
        }
      }

      Map<String, dynamic> specifiques = {};
      _dynamicControllers.forEach((key, controller) {
        specifiques[key] = controller.text;
      });

      if (_signatureTechnicien != null) {
        specifiques['signature_technicien'] = _signatureTechnicien;
      }
      
      // Ajout des photos dans les champs spécifiques
      if (_photosBase64.isNotEmpty) {
        specifiques['photos'] = _photosBase64;
      }

      final debrief = DebriefModel(
        briefId: widget.briefId ?? '',
        numBt: widget.numBt ?? '',
        typeInterventionId: _typeDebrief?.id ?? '',
        referentId: context.read<UserProvider>().uid,
        agenceId: agenceId,
        siteId: siteId,
        dateIntervention: _dateIntervention,
        commentaires: _commentairesController.text.trim(),
        champsSpecifiques: specifiques.isEmpty ? null : specifiques,
      );

      await _debriefService.createDebrief(debrief);
      _showMessage('Débrief enregistré !');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF4DB8D9) : const Color(0xFF33A1C9);

    if (_isLoading) {
      return Scaffold(
          body: Center(child: CircularProgressIndicator(color: primaryColor)));
    }

    final cardColor = Theme.of(context).cardColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF33A1C9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Retour',
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Nouveau Débrief',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        elevation: 0,
      ),
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
                      MaterialPageRoute(
                          builder: (context) => const WelcomeScreen()),
                          (route) => false,
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildFormContainer(cardColor, isDark, primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContainer(Color cardColor, bool isDark, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border:
        Border.all(color: primaryColor.withOpacity(0.1)),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(primaryColor),
          const SizedBox(height: 15),
          _buildTopRow(isDark),
          const SizedBox(height: 15),

          if (_typeDebrief != null &&
              _dynamicControllers.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
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

          if (hasTravauxStatut) ...[
            Text('Travaux réalisés *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.grey[300] : Colors.black87)),
            const SizedBox(height: 8),
            _buildTravauxStatus(isDark, primaryColor),
            const SizedBox(height: 15),
          ],

          FormFields.buildLabel('Commentaires', context: context),
          FormFields.buildTextField(
            controller: _commentairesController,
            maxLines: 2,
            isRequired: false,
            context: context,
          ),
          const SizedBox(height: 20),

          // Utilisation du composant réutilisable
          PhotoSelectionWidget(
            initialPhotosBase64: _photosBase64,
            onPhotosChanged: (photos) => setState(() => _photosBase64 = photos),
          ),
          const SizedBox(height: 20),

          _buildSignatureSection(isDark, primaryColor),
          const SizedBox(height: 20),

          _buildFooterActions(primaryColor),
        ],
      ),
    );
  }

  Widget _buildSignatureSection(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.draw_outlined,
                size: 16, color: primaryColor),
            const SizedBox(width: 6),
            Text(
              'Signature',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.grey[300] : Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SignatureWidget(
          roleLabel: 'Technicien',
          initialSignatureBase64: _signatureTechnicien,
          width: double.infinity,
          height: 100,
          onSignatureChanged: (val) {
            setState(() => _signatureTechnicien = val);
          },
        ),
      ],
    );
  }

  Widget _buildTitle(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nouveau Débrief${_typeDebrief != null ? " — ${_typeDebrief!.nom}" : ""}',
          style: TextStyle(
            color: primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Container(height: 3, width: 60, color: Colors.orange),
      ],
    );
  }

  Widget _buildTopRow(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildInfoItem('Numéro BT', widget.numBt ?? '-', isDark),
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
          child: _buildInfoItem("Chef d'équipe", widget.referentNom ?? 'Inconnu', isDark),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[500] : Colors.blueGrey[400])),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(value,
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildTravauxStatus(bool isDark, Color primaryColor) {
    final controller = _dynamicControllers['travaux_statut']!;
    return Wrap(
      spacing: 10,
      runSpacing: 5,
      children: ["Entier", "Partiel", "non réalisé"]
          .map((s) => _buildStatusItem(s, controller, isDark, primaryColor))
          .toList(),
    );
  }

  Widget _buildStatusItem(String label, TextEditingController controller, bool isDark, Color primaryColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[300] : Colors.black87)),
        Checkbox(
          value: controller.text == label,
          onChanged: (v) => setState(() => controller.text = label),
          activeColor: primaryColor,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildFooterActions(Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: _isSaving ? null : _saveDebrief,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSaving
              ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
              : const Text('Enregistrer le Débrief',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }
}
