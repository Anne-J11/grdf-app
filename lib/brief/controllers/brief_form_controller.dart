// lib/brief/controllers/brief_form_controller.dart
// Ajouts v3 :
//   - saveBriefWithExtras() : inclut les signatures dans champsSpecifiques
//   - autoSaveSignatures()  : met à jour les signatures en Firestore sans refaire tout le brief

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/brief_model.dart';
import '../models/type_intervention_model.dart';
import '../services/brief_service.dart';
import '../services/type_intervention_service.dart';
import 'dart:developer' as dev;

class BriefFormController extends ChangeNotifier {
  final BriefService _briefService = BriefService();
  final TypeInterventionService _typeService = TypeInterventionService();

  final TextEditingController numBtController = TextEditingController();
  final TextEditingController lieuController = TextEditingController();
  final TextEditingController risquesController = TextEditingController();
  final TextEditingController materielController = TextEditingController();
  final TextEditingController consignesController = TextEditingController();
  final TextEditingController commentairesController = TextEditingController();
  final TextEditingController referentController = TextEditingController();

  List<TypeInterventionModel> typesIntervention = [];
  TypeInterventionModel? selectedType;
  DateTime dateIntervention = DateTime.now();
  bool isLoading = true;
  bool isSaving = false;
  bool isAutoSaving = false;
  String? lastSavedBriefId;

  Map<String, TextEditingController> dynamicControllers = {};

  Timer? _debounceTimer;

  Future<void> init() async {
    isLoading = true;
    notifyListeners();
    typesIntervention = await _typeService.getAllTypes();
    isLoading = false;
    notifyListeners();
  }

  void invalidateSavedBrief() {
    if (lastSavedBriefId != null) {
      lastSavedBriefId = null;
      notifyListeners();
    }
  }

  void scheduleAutoSave() {
    if (lastSavedBriefId == null) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _autoSave();
    });
  }

  Future<void> _autoSave() async {
    if (lastSavedBriefId == null) return;
    try {
      isAutoSaving = true;
      notifyListeners();

      final Map<String, dynamic> champsSpecifiques = {};
      dynamicControllers.forEach((key, controller) {
        champsSpecifiques[key] = controller.text;
      });

      await _briefService.updateBrief(lastSavedBriefId!, {
        'num_bt': numBtController.text,
        'referent_nom': referentController.text,
        'risques': risquesController.text,
        'materiel': materielController.text,
        'consignes': consignesController.text,
        'commentaires': commentairesController.text.isNotEmpty
            ? commentairesController.text
            : null,
        'champs_specifiques':
        champsSpecifiques.isNotEmpty ? champsSpecifiques : null,
      });
    } catch (e) {
      dev.log('Erreur auto-save : $e');
    } finally {
      isAutoSaving = false;
      notifyListeners();
    }
  }

  /// Met à jour uniquement les signatures dans Firestore
  Future<void> autoSaveSignatures({
    required String briefId,
    String? signatureReferent,
    String? signatureTechnicien,
  }) async {
    try {
      final Map<String, dynamic> update = {};
      // On utilise une mise à jour partielle des champs spécifiques
      if (signatureReferent != null) {
        update['champs_specifiques.signature_referent'] = signatureReferent;
      }
      if (signatureTechnicien != null) {
        update['champs_specifiques.signature_technicien'] = signatureTechnicien;
      }
      if (update.isNotEmpty) {
        await _briefService.updateBrief(briefId, update);
      }
    } catch (e) {
      dev.log('Erreur auto-save signatures : $e');
    }
  }

  void onTypeChanged(TypeInterventionModel? newType) {
    final oldControllers =
    Map<String, TextEditingController>.from(dynamicControllers);
    dynamicControllers.clear();
    selectedType = newType;
    if (newType != null) {
      for (var champ in newType.champsSpecifiques) {
        dynamicControllers[champ] = TextEditingController()
          ..addListener(scheduleAutoSave);
      }
    }
    invalidateSavedBrief();
    notifyListeners();
    oldControllers.forEach((_, c) => c.dispose());
  }

  void setDate(DateTime date) {
    dateIntervention = date;
    scheduleAutoSave();
    notifyListeners();
  }

  /// Sauvegarde classique (sans extras)
  Future<bool> saveBrief({
    required String referentId,
    required String agenceId,
    required String siteId,
  }) async {
    return saveBriefWithExtras(
      referentId: referentId,
      agenceId: agenceId,
      siteId: siteId,
    );
  }

  /// Sauvegarde avec champs extras (signatures, etc.)
  Future<bool> saveBriefWithExtras({
    required String referentId,
    required String agenceId,
    required String siteId,
    Map<String, dynamic>? extraChamps,
  }) async {
    if (selectedType == null) return false;
    isSaving = true;
    notifyListeners();

    try {
      final Map<String, dynamic> champsSpecifiques = {};

      // Champs dynamiques du type d'intervention
      dynamicControllers.forEach((key, controller) {
        champsSpecifiques[key] = controller.text;
      });

      // Champs extras (signatures, etc.)
      if (extraChamps != null) {
        champsSpecifiques.addAll(extraChamps);
      }

      final brief = BriefModel(
        numBt: numBtController.text,
        typeInterventionId: selectedType!.id,
        referentId: referentId,
        referentNom: referentController.text,
        typeInterventionNom: selectedType!.nom,
        agenceId: agenceId,
        siteId: siteId,
        dateIntervention: dateIntervention,
        risques: risquesController.text,
        materiel: materielController.text,
        consignes: consignesController.text,
        commentaires: commentairesController.text.isNotEmpty
            ? commentairesController.text
            : null,
        champsSpecifiques:
        champsSpecifiques.isNotEmpty ? champsSpecifiques : null,
      );

      if (lastSavedBriefId != null) {
        // Mise à jour si déjà sauvegardé
        await _briefService.updateBrief(lastSavedBriefId!, brief.toFirestore());
      } else {
        // Création
        lastSavedBriefId = await _briefService.createBrief(brief);
        _attachAutoSaveListeners();
      }

      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      dev.log('Erreur sauvegarde brief: $e');
      isSaving = false;
      notifyListeners();
      return false;
    }
  }

  void _attachAutoSaveListeners() {
    risquesController.addListener(scheduleAutoSave);
    materielController.addListener(scheduleAutoSave);
    consignesController.addListener(scheduleAutoSave);
    commentairesController.addListener(scheduleAutoSave);
    dynamicControllers.forEach((_, c) => c.addListener(scheduleAutoSave));
  }

  void resetForm() {
    _debounceTimer?.cancel();
    numBtController.clear();
    lieuController.clear();
    risquesController.clear();
    materielController.clear();
    consignesController.clear();
    commentairesController.clear();
    referentController.clear();
    dynamicControllers.forEach((_, c) => c.clear());
    selectedType = null;
    lastSavedBriefId = null;
    dateIntervention = DateTime.now();
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    numBtController.dispose();
    lieuController.dispose();
    risquesController.dispose();
    materielController.dispose();
    consignesController.dispose();
    commentairesController.dispose();
    referentController.dispose();
    dynamicControllers.forEach((_, c) => c.dispose());
    super.dispose();
  }
}