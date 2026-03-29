// lib/brief/screens/brief_view_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/models/agence_model.dart';
import '../../auth/models/site_model.dart';
import '../../firestore_service.dart';
import '../models/brief_model.dart';
import '../services/brief_service.dart';
import '../widgets/brief_card.dart';
import '../widgets/brief_details_modal.dart';
import '../screens/brief_create_screen.dart';
import '../../debrief/screens/debrief_create_screen.dart';

class BriefViewScreen extends StatefulWidget {
  const BriefViewScreen({super.key});

  @override
  State<BriefViewScreen> createState() => _BriefViewScreenState();
}

class _BriefViewScreenState extends State<BriefViewScreen> {
  final BriefService _briefService = BriefService();
  final FirestoreService _firestoreService = FirestoreService();

  List<BriefModel> _briefs = [];
  List<AgenceModel> _agences = [];
  List<SiteModel> _sites = [];
  List<SiteModel> _sitesFiltres = [];

  // Filtres
  String? _agenceSelectionneeId;
  String? _siteSelectionneId;
  DateTime? _dateSelectionnee;
  DateTime? _dateFinSelectionnee;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadAgences();
      await _loadSites();
      await _loadBriefs();
    });
  }

  Future<void> _loadAgences() async {
    try {
      final user = context.read<UserProvider>();

      // Technicien et référent : agence fixée au profil, pas de dropdown agence.
      // Manager seul peut naviguer entre les agences.
      if (!user.isManager) {
        setState(() => _agenceSelectionneeId = user.agenceId);
        return;
      }

      final agences = await _firestoreService.getAgences();
      setState(() {
        _agences = agences;
        _agenceSelectionneeId =
        user.agenceId.isNotEmpty ? user.agenceId : null;
      });
    } catch (e) {
      debugPrint('Erreur chargement agences : $e');
    }
  }

  Future<void> _loadSites() async {
    try {
      final sites = await _firestoreService.getAllSites();
      setState(() {
        _sites = sites;
        _filtrerSitesParAgence();
      });
    } catch (e) {
      debugPrint('Erreur chargement sites : $e');
    }
  }

  void _filtrerSitesParAgence() {
    if (_agenceSelectionneeId == null) {
      _sitesFiltres = _sites;
    } else {
      _sitesFiltres = _sites
          .where((site) => site.agenceId == _agenceSelectionneeId)
          .toList();
    }
    if (_siteSelectionneId != null &&
        !_sitesFiltres.any((s) => s.id == _siteSelectionneId)) {
      _siteSelectionneId = null;
    }
  }

  Future<void> _loadBriefs() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<UserProvider>();
      List<BriefModel> briefs = [];

      if (user.isTechnicien) {
        // Le technicien voit les briefs du site sélectionné (ou son site par
        // défaut si aucun filtre) + les briefs qui lui sont assignés.
        briefs = await _briefService.getBriefsForTechnicien(
          uid: user.uid,
          siteId: user.siteId,
          siteIdFiltre: _siteSelectionneId,
          dateIntervention: _dateSelectionnee,
        );

        // Filtre plage de dates (date fin) côté client
        if (_dateSelectionnee != null && _dateFinSelectionnee != null) {
          final fin = DateTime(
            _dateFinSelectionnee!.year,
            _dateFinSelectionnee!.month,
            _dateFinSelectionnee!.day,
            23,
            59,
            59,
          );
          briefs = briefs
              .where((b) =>
          !b.dateIntervention.isBefore(_dateSelectionnee!) &&
              !b.dateIntervention.isAfter(fin))
              .toList();
        }
      } else {
        // Référent : agenceId verrouillé à user.agenceId (fixé dans _loadAgences).
        // Manager : agenceId choisi via le dropdown (peut être null = toutes).
        briefs = await _briefService.getBriefsWithFilters(
          agenceId: _agenceSelectionneeId,
          siteId: _siteSelectionneId,
          dateIntervention: _dateSelectionnee,
        );

        // Filtre plage de dates (date fin) côté client
        if (_dateSelectionnee != null && _dateFinSelectionnee != null) {
          final fin = DateTime(
            _dateFinSelectionnee!.year,
            _dateFinSelectionnee!.month,
            _dateFinSelectionnee!.day,
            23,
            59,
            59,
          );
          briefs = briefs
              .where((b) =>
          !b.dateIntervention.isBefore(_dateSelectionnee!) &&
              !b.dateIntervention.isAfter(fin))
              .toList();
        }
      }

      setState(() {
        _briefs = briefs;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBrief(BriefModel brief) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce brief ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _briefService.deleteBrief(brief.id!);
      await _loadBriefs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Brief supprimé'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _resetFiltres() {
    setState(() {
      _siteSelectionneId = null;
      _dateSelectionnee = null;
      _dateFinSelectionnee = null;
    });
    _loadBriefs();
  }

  Future<void> _selectionnerDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
    isDark ? const Color(0xFF4DB8D9) : const Color(0xFF33A1C9);

    final DateTime? debut = await showDatePicker(
      context: context,
      initialDate: _dateSelectionnee ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Date de début',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark
              ? ColorScheme.dark(
              primary: primaryColor, onPrimary: Colors.black)
              : ColorScheme.light(
              primary: primaryColor, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (debut == null) return;

    final DateTime? fin = await showDatePicker(
      context: context,
      initialDate: _dateFinSelectionnee ?? debut,
      firstDate: debut,
      lastDate: DateTime(2030),
      helpText: 'Date de fin',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark
              ? ColorScheme.dark(
              primary: primaryColor, onPrimary: Colors.black)
              : ColorScheme.light(
              primary: primaryColor, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );

    setState(() {
      _dateSelectionnee = debut;
      _dateFinSelectionnee = fin;
    });
    _loadBriefs();
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<UserProvider>();
    final appBarColor =
    isDark ? const Color(0xFF1E1E1E) : const Color(0xFF33A1C9);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: const Text('Liste des Briefs',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_siteSelectionneId != null ||
              _dateSelectionnee != null ||
              _dateFinSelectionnee != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off, color: Colors.white),
              tooltip: 'Réinitialiser les filtres',
              onPressed: _resetFiltres,
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadBriefs,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltresBar(isDark, user),
          Expanded(child: _buildBody(isDark)),
        ],
      ),
    );
  }

  // ── BARRE DE FILTRES ───────────────────────────────────────────────────────

  Widget _buildFiltresBar(bool isDark, UserProvider user) {
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Colonne gauche : agence (manager = dropdown, référent = libellé,
              // technicien = libellé de son agence)
              if (user.isManager)
                Expanded(
                    child:
                    _buildAgenceDropdown(textColor, bgColor, isDark))
              else
                Expanded(child: _buildAgenceLabel(textColor, isDark)),
              const SizedBox(width: 12),
              // Dropdown site : visible pour tous les rôles.
              // Pour le technicien, _sitesFiltres contient les sites de son
              // agence (chargés via _filtrerSitesParAgence).
              Expanded(
                  child: _buildSiteDropdown(textColor, bgColor, isDark)),
            ],
          ),
          const SizedBox(height: 8),
          // Filtre date : visible pour tous les rôles
          _buildDateFilter(textColor, bgColor, isDark),
        ],
      ),
    );
  }

  /// Libellé non interactif affichant l'agence de l'utilisateur (référent
  /// ou technicien). Identique au comportement de debrief_view_screen.
  Widget _buildAgenceLabel(Color textColor, bool isDark) {
    final user = context.read<UserProvider>();
    final nom = _agences.isNotEmpty
        ? _agences
        .firstWhere(
          (a) => a.id == user.agenceId,
      orElse: () =>
          AgenceModel(id: user.agenceId, nom: user.agenceId),
    )
        .nom
        : user.agenceId;

    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.business_outlined, size: 15, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              nom,
              style: TextStyle(fontSize: 12, color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgenceDropdown(Color textColor, Color bgColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.business_outlined, size: 15, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Expanded(
            child: _agences.isEmpty
                ? Text(
              'Agence',
              style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? Colors.grey[500]
                      : Colors.grey[400]),
            )
                : DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _agenceSelectionneeId,
                isExpanded: true,
                isDense: true,
                dropdownColor: bgColor,
                style: TextStyle(fontSize: 12, color: textColor),
                hint: Text('Toutes les agences',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey[500]
                            : Colors.grey[500])),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Toutes les agences',
                        style: TextStyle(color: textColor)),
                  ),
                  ..._agences.map((a) => DropdownMenuItem<String?>(
                    value: a.id,
                    child: Text(a.nom,
                        style: TextStyle(color: textColor)),
                  )),
                ],
                onChanged: (val) {
                  setState(() {
                    _agenceSelectionneeId = val;
                    _filtrerSitesParAgence();
                  });
                  _loadBriefs();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiteDropdown(Color textColor, Color bgColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined,
              size: 15, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _siteSelectionneId,
                isExpanded: true,
                isDense: true,
                dropdownColor: bgColor,
                style: TextStyle(fontSize: 12, color: textColor),
                hint: Text('Tous les sites',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey[500]
                            : Colors.grey[500])),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Tous les sites',
                        style: TextStyle(color: textColor)),
                  ),
                  ..._sitesFiltres.map((s) => DropdownMenuItem<String?>(
                    value: s.id,
                    child: Text(s.nom,
                        style: TextStyle(color: textColor)),
                  )),
                ],
                onChanged: (val) {
                  setState(() => _siteSelectionneId = val);
                  _loadBriefs();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter(Color textColor, Color bgColor, bool isDark) {
    String dateText = 'Toutes les dates';
    if (_dateSelectionnee != null && _dateFinSelectionnee != null) {
      final d = _dateSelectionnee!;
      final f = _dateFinSelectionnee!;
      dateText =
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}'
          ' → '
          '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
    } else if (_dateSelectionnee != null) {
      final d = _dateSelectionnee!;
      dateText =
      'Dès le ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }

    return InkWell(
      onTap: _selectionnerDate,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.date_range, size: 15, color: Colors.grey[500]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                dateText,
                style: TextStyle(fontSize: 12, color: textColor),
              ),
            ),
            Icon(Icons.arrow_drop_down,
                color:
                isDark ? Colors.grey[500] : Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  // ── CORPS DE LA LISTE ──────────────────────────────────────────────────────

  Widget _buildBody(bool isDark) {
    final primaryColor =
    isDark ? const Color(0xFF4DB8D9) : const Color(0xFF33A1C9);

    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator(color: primaryColor));
    }
    if (_briefs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open,
                size: 80,
                color: isDark ? Colors.grey[700] : Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Aucun brief trouvé',
                style: TextStyle(
                    fontSize: 18,
                    color:
                    isDark ? Colors.grey[500] : Colors.grey[600])),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadBriefs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _briefs.length,
        itemBuilder: (context, index) =>
            _buildBriefItem(_briefs[index], isDark),
      ),
    );
  }

  // ── ITEM BRIEF ─────────────────────────────────────────────────────────────

  Widget _buildBriefItem(BriefModel brief, bool isDark) {
    final user = context.read<UserProvider>();
    final primaryColor =
    isDark ? const Color(0xFF4DB8D9) : const Color(0xFF33A1C9);

    final bool peutSupprimer = user.isReferent && !brief.estVerrouille;
    final bool peutModifier = !brief.estVerrouille;
    final bool peutDebriefer = !brief.estVerrouille;
    final bool afficherBarre =
        peutModifier || peutSupprimer || peutDebriefer;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BriefCard(
            brief: brief,
            onTap: () {
              if (brief.estVerrouille) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          BriefCreateScreen(briefExistant: brief)),
                );
              } else {
                BriefDetailsModal.show(context, brief);
              }
            },
          ),
          if (afficherBarre)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(
                  horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color:
                isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? Colors.grey[800]!
                      : Colors.grey[200]!,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (peutModifier)
                    _buildActionButton(
                      icon: Icons.edit_outlined,
                      label: 'Modifier',
                      color: primaryColor,
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => BriefCreateScreen(
                                  briefExistant: brief)),
                        );
                        _loadBriefs();
                      },
                    ),
                  if (peutSupprimer) ...[
                    const SizedBox(width: 4),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      label: 'Supprimer',
                      color: Colors.redAccent,
                      onPressed: () => _deleteBrief(brief),
                    ),
                  ],
                  if (peutDebriefer) ...[
                    const SizedBox(width: 4),
                    _buildActionButton(
                      icon: Icons.assignment_turned_in_outlined,
                      label: 'Débrief',
                      color: Colors.green,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DebriefCreateScreen(
                            briefId: brief.id!,
                            numBt: brief.numBt,
                            referentNom: brief.referentNom,
                            typeInterventionNom:
                            brief.typeInterventionNom,
                            agenceId: brief.agenceId,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15, color: color),
      label: Text(
        label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
      style: TextButton.styleFrom(
        padding:
        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}