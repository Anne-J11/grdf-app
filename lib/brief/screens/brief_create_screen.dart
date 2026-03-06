// lib/brief/screens/brief_create_screen.dart
// Modifications :
//   1. Bouton retour (AppBar flèche + bouton Accueil dans header) vers HomeScreen
//   2. Signatures digitales référent + technicien (zone tactile)
//   3. Signatures sauvegardées en base64 dans Firestore avec le brief

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grdf_app/welcome_screen.dart';
import 'package:grdf_app/auth/providers/user_provider.dart';
import 'package:grdf_app/home/screens/home_screen.dart';
import '../../debrief/screens/debrief_create_screen.dart';
import '../controllers/brief_form_controller.dart';
import '../models/brief_model.dart';
import '../widgets/app_header.dart';
import '../widgets/dynamic_fields_section.dart';
import '../widgets/form_fields.dart';
import '../models/type_intervention_model.dart';
import '../../auth/component/signature_widget.dart';

class BriefCreateScreen extends StatefulWidget {
  /// null → mode création | fourni → mode consultation (verrouillé si estVerrouille)
  final BriefModel? briefExistant;

  const BriefCreateScreen({super.key, this.briefExistant});

  @override
  State<BriefCreateScreen> createState() => _BriefCreateScreenState();
}

class _BriefCreateScreenState extends State<BriefCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = BriefFormController();

  // Signatures base64
  String? _signatureReferent;
  String? _signatureTechnicien;

  bool get _estVerrouille =>
      widget.briefExistant != null && widget.briefExistant!.estVerrouille;

  @override
  void initState() {
    super.initState();
    _controller.init().then((_) {
      if (widget.briefExistant != null) _preRemplir(widget.briefExistant!);
    });
    _controller.addListener(_onControllerChange);
    _controller.numBtController.addListener(_controller.invalidateSavedBrief);
    _controller.referentController.addListener(_controller.invalidateSavedBrief);
  }

  void _preRemplir(BriefModel brief) {
    _controller.numBtController.text = brief.numBt;
    _controller.referentController.text = brief.referentNom;
    _controller.risquesController.text = brief.risques;
    _controller.materielController.text = brief.materiel;
    _controller.consignesController.text = brief.consignes;
    _controller.commentairesController.text = brief.commentaires ?? '';
    _controller.dateIntervention = brief.dateIntervention;
    // Charger signatures existantes
    _signatureReferent = brief.champsSpecifiques?['signature_referent'];
    _signatureTechnicien = brief.champsSpecifiques?['signature_technicien'];
    if (brief.typeInterventionId.isNotEmpty) {
      try {
        final type = _controller.typesIntervention
            .firstWhere((t) => t.id == brief.typeInterventionId);
        _controller.onTypeChanged(type);
        brief.champsSpecifiques?.forEach((key, value) {
          _controller.dynamicControllers[key]?.text = value.toString();
        });
      } catch (_) {}
    }
    setState(() {});
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveBrief() async {
    if (_estVerrouille) return;
    if (!_formKey.currentState!.validate()) {
      _showMessage('Veuillez remplir tous les champs obligatoires', isError: true);
      return;
    }

    final user = context.read<UserProvider>();

    // Inclure les signatures dans les champs spécifiques
    final signaturesExtra = <String, dynamic>{};
    if (_signatureReferent != null) {
      signaturesExtra['signature_referent'] = _signatureReferent;
    }
    if (_signatureTechnicien != null) {
      signaturesExtra['signature_technicien'] = _signatureTechnicien;
    }

    final success = await _controller.saveBriefWithExtras(
      referentId: user.uid,
      agenceId: user.agenceId,
      siteId: user.siteId,
      extraChamps: signaturesExtra,
    );

    if (success) {
      _showMessage('Brief enregistré avec succès !');
    } else {
      _showMessage("Erreur lors de l'enregistrement", isError: true);
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

  void _retourAccueil() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF33A1C9))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // AppBar avec flèche retour
      appBar: AppBar(
        backgroundColor: const Color(0xFF33A1C9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Retour accueil',
          onPressed: _retourAccueil,
        ),
        title: Text(
          widget.briefExistant != null ? 'Consultation Brief' : 'Nouveau Brief',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header avec bouton Accueil
                _buildHeader(),
                const SizedBox(height: 20),
                if (_estVerrouille) _buildBandeauVerrouillage(),
                if (_estVerrouille) const SizedBox(height: 12),
                _buildFormContainer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Header avec logo + bouton Accueil + bouton Visualisation + Déconnexion
  Widget _buildHeader() {
    return Row(
      children: [
        Image.asset('assets/img/logo.png', height: 40,
            errorBuilder: (_, __, ___) => const SizedBox(width: 40)),
        const Spacer(),
        _buildHeaderBtn('Accueil', Icons.home_outlined, _retourAccueil),
        const SizedBox(width: 6),
        _buildHeaderBtn('Briefs', Icons.list_alt_outlined, () {
          Navigator.pushNamed(context, '/briefs');
        }),
        const SizedBox(width: 6),
        _buildHeaderBtn('Déconnexion', Icons.logout, () {
          context.read<UserProvider>().clearUser();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
          );
        }),
      ],
    );
  }

  Widget _buildHeaderBtn(String text, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 12),
      label: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF33A1C9),
        elevation: 0,
        side: const BorderSide(color: Color(0xFF33A1C9), width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(0, 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildBandeauVerrouillage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[300]!, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.lock, color: Colors.orange[700], size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Brief verrouillé — lecture seule',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.orange[800]),
                ),
                const SizedBox(height: 2),
                Text(
                  'Un débrief a été validé pour ce brief.',
                  style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                ),
              ],
            ),
          ),
        ],
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
          color: _estVerrouille
              ? Colors.orange.withOpacity(0.3)
              : const Color(0xFF33A1C9).withOpacity(0.1),
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
              key: ValueKey(_controller.selectedType!.id),
              typeIntervention: _controller.selectedType!,
              controllers: _controller.dynamicControllers,
              readOnly: _estVerrouille,
            ),
          ],
          const SizedBox(height: 30),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    final bool isBriefSaved = _controller.lastSavedBriefId != null;
    final user = context.read<UserProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.briefExistant != null ? 'Consultation Brief' : 'Nouveau Brief',
                  style: const TextStyle(
                      color: Color(0xFF33A1C9),
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 3,
                  width: 60,
                  decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10)),
                ),
              ],
            ),
            if (widget.briefExistant == null)
              ElevatedButton(
                onPressed: isBriefSaved
                    ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DebriefCreateScreen(
                      briefId: _controller.lastSavedBriefId!,
                      numBt: _controller.numBtController.text,
                      typeInterventionNom: _controller.selectedType?.nom,
                      referentNom: _controller.referentController.text.isNotEmpty
                          ? _controller.referentController.text
                          : user.nomComplet,
                      agenceId: user.agenceId,
                    ),
                  ),
                )
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBriefSaved ? Colors.orange : Colors.grey[300],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[200],
                  disabledForegroundColor: Colors.grey[400],
                  elevation: isBriefSaved ? 2 : 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  isBriefSaved ? 'Créer un débrief' : "Enregistrer d'abord",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
          ],
        ),
        if (isBriefSaved && !_estVerrouille) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              if (_controller.isAutoSaving) ...[
                const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: Color(0xFF33A1C9))),
                const SizedBox(width: 5),
                Text('Sauvegarde...', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              ] else ...[
                Icon(Icons.check_circle_outline, size: 12, color: Colors.green[400]),
                const SizedBox(width: 4),
                Text('Sauvegardé automatiquement',
                    style: TextStyle(fontSize: 10, color: Colors.green[400])),
              ]
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTopRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              FormFields.buildSmallField(
                label: 'Numéro BT *',
                controller: _controller.numBtController,
                isRequired: true,
                readOnly: _estVerrouille,
              ),
              const SizedBox(height: 12),
              FormFields.buildSmallField(
                label: "Chef d'équipe *",
                controller: _controller.referentController,
                isRequired: true,
                readOnly: _estVerrouille,
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          flex: 3,
          child: FormFields.buildDateField(
            context: context,
            label: "Date d'intervention *",
            selectedDate: _controller.dateIntervention,
            onDateSelected: _estVerrouille ? (_) {} : _controller.setDate,
            isRequired: true,
            readOnly: _estVerrouille,
          ),
        ),
      ],
    );
  }

  Widget _buildMainFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFields.buildLabel("Type d'intervention"),
        DropdownButtonFormField<TypeInterventionModel>(
          value: _controller.selectedType,
          decoration: _dropdownDecoration(),
          hint: const Text('Sélectionner un type'),
          items: _controller.typesIntervention.map((type) {
            return DropdownMenuItem<TypeInterventionModel>(
              value: type,
              child: Text(type.nom),
            );
          }).toList(),
          onChanged: _estVerrouille
              ? null
              : (val) {
            _controller.onTypeChanged(val);
            _controller.invalidateSavedBrief();
          },
        ),
        const SizedBox(height: 15),
        FormFields.buildLabel('Analyse des risques'),
        FormFields.buildTextField(
            controller: _controller.risquesController,
            isRequired: false,
            readOnly: _estVerrouille),
        const SizedBox(height: 15),
        FormFields.buildLabel('État du matériel'),
        FormFields.buildTextField(
            controller: _controller.materielController,
            isRequired: false,
            readOnly: _estVerrouille),
        const SizedBox(height: 15),
        FormFields.buildLabel('Consigne du jour'),
        FormFields.buildTextField(
            controller: _controller.consignesController,
            isRequired: false,
            readOnly: _estVerrouille),
        const SizedBox(height: 15),
        FormFields.buildLabel('Commentaires'),
        FormFields.buildTextField(
            controller: _controller.commentairesController,
            maxLines: 3,
            isRequired: false,
            readOnly: _estVerrouille),
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
        // ── Signatures digitales ─────────────────────────────────
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Signature référent : nom auto depuis UserProvider
            SignatureWidget(
              roleLabel: 'Référent',
              initialSignatureBase64: _signatureReferent,
              readOnly: _estVerrouille,
              width: 140,
              height: 80,
              onSignatureChanged: (b64) {
                setState(() => _signatureReferent = b64);
                if (_controller.lastSavedBriefId != null && b64 != null) {
                  _controller.autoSaveSignatures(
                    briefId: _controller.lastSavedBriefId!,
                    signatureReferent: b64,
                    signatureTechnicien: _signatureTechnicien,
                  );
                }
              },
            ),
            const SizedBox(width: 15),
            // Signature technicien : nom saisi dans le champ "Chef d'équipe"
            SignatureWidget(
              roleLabel: 'Technicien',
              forceNom: _controller.referentController.text.isNotEmpty
                  ? _controller.referentController.text
                  : null,
              initialSignatureBase64: _signatureTechnicien,
              readOnly: _estVerrouille,
              width: 140,
              height: 80,
              onSignatureChanged: (b64) {
                setState(() => _signatureTechnicien = b64);
                if (_controller.lastSavedBriefId != null && b64 != null) {
                  _controller.autoSaveSignatures(
                    briefId: _controller.lastSavedBriefId!,
                    signatureReferent: _signatureReferent,
                    signatureTechnicien: b64,
                  );
                }
              },
            ),
          ],
        ),

        // ── Bouton Enregistrer ───────────────────────────────────
        if (!_estVerrouille)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: _controller.isSaving ? null : _saveBrief,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _controller.isSaving
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Enregistrer le Brief',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text('Modification impossible',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
      ],
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      isDense: true,
      fillColor: _estVerrouille ? Colors.grey[100] : Colors.white,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!)),
      disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF33A1C9), width: 1.5)),
    );
  }
}