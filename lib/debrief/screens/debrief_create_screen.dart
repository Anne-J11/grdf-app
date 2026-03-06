// lib/debrief/screens/debrief_create_screen.dart
// Modifications :
//   1. Signature digitale du technicien (zone tactile)
//   2. Signature sauvegardée en base64 dans Firestore avec le débrief

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:grdf_app/welcome_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:grdf_app/auth/providers/user_provider.dart';
import '../../brief/widgets/app_header.dart';
import '../../brief/widgets/form_fields.dart';
import '../../brief/widgets/dynamic_fields_section.dart';
import '../../brief/models/type_intervention_model.dart';
import '../models/debrief_model.dart';
import '../services/debrief_service.dart';
import '../services/type_intervention_debrief_service.dart';
import '../../auth/component/signature_widget.dart';

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
  final _imagePicker = ImagePicker();

  final _commentairesController = TextEditingController();

  TypeInterventionModel? _typeDebrief;
  final Map<String, TextEditingController> _dynamicControllers = {};

  DateTime _dateIntervention = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;

  // Photos
  final List<File> _photos = [];

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

  // ── Gestion photos ────────────────────────────────────────────────────────

  Future<void> _ajouterPhoto(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
      );
      if (image != null) {
        setState(() => _photos.add(File(image.path)));
      }
    } catch (e) {
      _showMessage(
          'Impossible d\'accéder à la ${source == ImageSource.camera ? "caméra" : "galerie"} : $e',
          isError: true);
    }
  }

  void _supprimerPhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  void _afficherChoixPhoto() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined,
                    color: Color(0xFF33A1C9)),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _ajouterPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: Color(0xFF33A1C9)),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(ctx);
                  _ajouterPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sauvegarde ────────────────────────────────────────────────────────────

  Future<void> _saveDebrief() async {
    if (!_formKey.currentState!.validate()) {
      _showMessage('Veuillez remplir tous les champs obligatoires', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      Map<String, dynamic> specifiques = {};
      _dynamicControllers.forEach((key, controller) {
        specifiques[key] = controller.text;
      });

      // Ajouter la signature technicien dans les champs spécifiques
      if (_signatureTechnicien != null) {
        specifiques['signature_technicien'] = _signatureTechnicien;
      }

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
      _showMessage(
        'Débrief enregistré !'
            '${_photos.isNotEmpty ? ' (${_photos.length} photo${_photos.length > 1 ? 's' : ''})' : ''}'
            '${_signatureTechnicien != null ? ' ✍️' : ''}',
      );
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF33A1C9),
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
                _buildFormContainer(cardColor, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContainer(Color cardColor, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border:
        Border.all(color: const Color(0xFF33A1C9).withOpacity(0.1)),
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
          _buildTitle(),
          const SizedBox(height: 15),
          _buildTopRow(),
          const SizedBox(height: 15),

          // Champs dynamiques
          if (_typeDebrief != null &&
              _dynamicControllers.isNotEmpty) ...[
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

          // Travaux réalisés
          if (hasTravauxStatut) ...[
            const Text('Travaux réalisés *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

          // Photos
          _buildPhotosSection(isDark),
          const SizedBox(height: 20),

          // ── Signature technicien ─────────────────────────────────
          _buildSignatureSection(isDark),
          const SizedBox(height: 20),

          _buildFooterActions(),
        ],
      ),
    );
  }

  // ── Section signature ─────────────────────────────────────────────────────

  Widget _buildSignatureSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.draw_outlined,
                size: 16, color: const Color(0xFF33A1C9)),
            const SizedBox(width: 6),
            const Text(
              'Signature',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Nom et rôle récupérés automatiquement via UserProvider
        SignatureWidget(
          roleLabel: 'Technicien',
          initialSignatureBase64: _signatureTechnicien,
          width: double.infinity,
          height: 100,
          onSignatureChanged: (b64) {
            setState(() => _signatureTechnicien = b64);
          },
        ),
      ],
    );
  }

  // ── Section photos ────────────────────────────────────────────────────────

  Widget _buildPhotosSection(bool isDark) {
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(Icons.photo_library_outlined,
                  size: 16, color: const Color(0xFF33A1C9)),
              const SizedBox(width: 6),
              Text(
                'Photos${_photos.isNotEmpty ? ' (${_photos.length})' : ''}',
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ]),
            TextButton.icon(
              onPressed: _afficherChoixPhoto,
              icon: const Icon(Icons.add_a_photo_outlined, size: 16),
              label:
              const Text('Ajouter', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF33A1C9),
                visualDensity: VisualDensity.compact,
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_photos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey[800]!.withOpacity(0.3)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
            ),
            child: Column(children: [
              Icon(Icons.add_photo_alternate_outlined,
                  size: 32, color: Colors.grey[400]),
              const SizedBox(height: 6),
              Text('Aucune photo ajoutée',
                  style: TextStyle(fontSize: 12, color: subtitleColor)),
            ]),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length + 1,
              itemBuilder: (ctx, i) {
                if (i == _photos.length) {
                  return GestureDetector(
                    onTap: _afficherChoixPhoto,
                    child: Container(
                      width: 90,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey[800]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: isDark
                                ? Colors.grey[600]!
                                : Colors.grey[300]!),
                      ),
                      child: Icon(Icons.add_a_photo_outlined,
                          color: Colors.grey[400], size: 28),
                    ),
                  );
                }
                return _buildPhotoThumbnail(i, isDark);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoThumbnail(int index, bool isDark) {
    return Container(
      width: 90,
      height: 110,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(_photos[index], fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _supprimerPhoto(index),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child:
                const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('${index + 1}',
                  style: const TextStyle(
                      fontSize: 10, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widgets helpers ───────────────────────────────────────────────────────

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nouveau Débrief${_typeDebrief != null ? " — ${_typeDebrief!.nom}" : ""}',
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
          child: _buildInfoItem("Chef d'équipe", widget.referentNom ?? 'Inconnu'),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey[400])),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(value,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
              overflow: TextOverflow.ellipsis),
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
          .map((s) => _buildStatusItem(s, controller))
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