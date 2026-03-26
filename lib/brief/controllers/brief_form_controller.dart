// lib/brief/controllers/brief_form_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/brief_model.dart';
import '../models/type_intervention_model.dart';
import '../services/brief_service.dart';
import '../services/type_intervention_service.dart';
import '../../auth/models/agence_model.dart';
import '../../auth/models/site_model.dart';
import '../../firestore_service.dart';
import 'dart:developer' as dev;

class BriefFormController extends ChangeNotifier {
  final BriefService _briefService = BriefService();
  final TypeInterventionService _typeService = TypeInterventionService();
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController numBtController = TextEditingController();
  final TextEditingController lieuController = TextEditingController();
  final TextEditingController risquesController = TextEditingController();
  final TextEditingController materielController = TextEditingController();
  final TextEditingController consignesController = TextEditingController();
  final TextEditingController commentairesController = TextEditingController();
  final TextEditingController referentController = TextEditingController();

  // Types d'intervention — dédupliqués par id pour éviter les doublons
  // si Firestore retourne plusieurs fois les mêmes documents (index en cours).
  List<TypeInterventionModel> typesIntervention = [];
  TypeInterventionModel? selectedType;
  DateTime dateIntervention = DateTime.now();
  bool isLoading = true;
  bool isSaving = false;
  bool isAutoSaving = false;
  String? lastSavedBriefId;

  // ── Agence / Site ────────────────────────────────────────────────────────
  List<AgenceModel> agences = [];
  List<SiteModel> sitesFiltres = [];
  String? selectedAgenceId;
  String? selectedSiteId;
  bool isLoadingAgences = false;
  bool isLoadingSites = false;

  Map<String, TextEditingController> dynamicControllers = {};

  Timer? _debounceTimer;

  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    // Chargement séquentiel pour éviter les doubles notifyListeners()
    // qui causaient des rebuilds successifs et des doublons dans le dropdown.
    try {
      final types = await _typeService.getAllTypes();
      // Déduplication par id : si Firestore retourne deux fois le même
      // document (ex. index manquant), on ne garde qu'un exemplaire.
      final seen = <String>{};
      typesIntervention = types
          .where((t) => seen.add(t.id))
          .toList();
    } catch (e) {
      dev.log('Erreur chargement types : $e');
    }

    try {
      isLoadingAgences = true;
      agences = await _firestoreService.getAgences();
      isLoadingAgences = false;
    } catch (e) {
      dev.log('Erreur chargement agences : $e');
      isLoadingAgences = false;
    }

    isLoading = false;
    notifyListeners(); // un seul appel à la fin
  }

  /// Pré-sélectionne l'agence et le site (utilisateur connecté ou brief existant).
  Future<void> initAgenceSite({
    required String agenceId,
    required String siteId,
  }) async {
    selectedAgenceId = agenceId.isNotEmpty ? agenceId : null;
    selectedSiteId = null;
    if (selectedAgenceId != null) {
      await _loadSitesByAgence(selectedAgenceId!, preselectSiteId: siteId);
    }
    notifyListeners();
  }

  Future<void> onAgenceChanged(String? agenceId) async {
    selectedAgenceId = agenceId;
    selectedSiteId = null;
    sitesFiltres = [];
    notifyListeners();
    if (agenceId != null) {
      await _loadSitesByAgence(agenceId);
    }
    invalidateSavedBrief();
    notifyListeners();
  }

  Future<void> _loadSitesByAgence(String agenceId,
      {String? preselectSiteId}) async {
    try {
      isLoadingSites = true;
      notifyListeners();
      sitesFiltres = await _firestoreService.getSitesByAgence(agenceId);
      if (preselectSiteId != null &&
          sitesFiltres.any((s) => s.id == preselectSiteId)) {
        selectedSiteId = preselectSiteId;
      }
      isLoadingSites = false;
    } catch (e) {
      dev.log('Erreur chargement sites : $e');
      isLoadingSites = false;
    }
  }

  void onSiteChanged(String? siteId) {
    selectedSiteId = siteId;
    invalidateSavedBrief();
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
    _debounceTimer = Timer(const Duration(milliseconds: 500), _autoSave);
  }

  Future<void> _autoSave() async {
    if (lastSavedBriefId == null) return;
    try {
      isAutoSaving = true;
      notifyListeners();
      final Map<String, dynamic> champs = {};
      dynamicControllers.forEach((key, c) => champs[key] = c.text);
      await _briefService.updateBrief(lastSavedBriefId!, {
        'num_bt': numBtController.text,
        'referent_nom': referentController.text,
        'risques': risquesController.text,
        'materiel': materielController.text,
        'consignes': consignesController.text,
        'commentaires': commentairesController.text.isNotEmpty
            ? commentairesController.text
            : null,
        'champs_specifiques': champs.isNotEmpty ? champs : null,
      });
    } catch (e) {
      dev.log('Erreur auto-save : $e');
    } finally {
      isAutoSaving = false;
      notifyListeners();
    }
  }

  Future<void> autoSaveExtras({
    required String briefId,
    String? signatureReferent,
    String? signatureTechnicien,
    List<String>? photos,
  }) async {
    try {
      final Map<String, dynamic> update = {};
      if (signatureReferent != null) {
        update['champs_specifiques.signature_referent'] = signatureReferent;
      }
      if (signatureTechnicien != null) {
        update['champs_specifiques.signature_technicien'] = signatureTechnicien;
      }
      if (photos != null) {
        update['champs_specifiques.photos'] = photos;
      }
      if (update.isNotEmpty) {
        await _briefService.updateBrief(briefId, update);
      }
    } catch (e) {
      dev.log('Erreur auto-save extras : $e');
    }
  }

  void onTypeChanged(TypeInterventionModel? newType) {
    final old = Map<String, TextEditingController>.from(dynamicControllers);
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
    old.forEach((_, c) => c.dispose());
  }

  void setDate(DateTime date) {
    dateIntervention = date;
    scheduleAutoSave();
    notifyListeners();
  }

  Future<bool> saveBriefWithExtras({
    required String referentId,
    String? agenceIdFallback,
    String? siteIdFallback,
    Map<String, dynamic>? extraChamps,
  }) async {
    if (selectedType == null) return false;

    final agenceId = selectedAgenceId ?? agenceIdFallback ?? '';
    final siteId = selectedSiteId ?? siteIdFallback ?? '';
    if (siteId.isEmpty) return false;

    isSaving = true;
    notifyListeners();

    try {
      final Map<String, dynamic> champs = {};
      dynamicControllers.forEach((key, c) => champs[key] = c.text);
      if (extraChamps != null) champs.addAll(extraChamps);

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
        champsSpecifiques: champs.isNotEmpty ? champs : null,
      );

      if (lastSavedBriefId != null) {
        await _briefService.updateBrief(lastSavedBriefId!, brief.toFirestore());
      } else {
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
    selectedAgenceId = null;
    selectedSiteId = null;
    sitesFiltres = [];
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