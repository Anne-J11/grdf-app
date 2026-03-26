// lib/debrief/screens/debrief_view_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/models/agence_model.dart';
import '../../auth/models/site_model.dart';
import '../../firestore_service.dart';
import '../models/debrief_model.dart';
import '../services/debrief_service.dart';
import '../widgets/debrief_details_modal.dart';

class DebriefViewScreen extends StatefulWidget {
  const DebriefViewScreen({super.key});

  @override
  State<DebriefViewScreen> createState() => _DebriefViewScreenState();
}

class _DebriefViewScreenState extends State<DebriefViewScreen> {
  final DebriefService _debriefService = DebriefService();
  final FirestoreService _firestoreService = FirestoreService();

  List<DebriefModel> _debriefs = [];
  List<AgenceModel> _agences = [];
  List<SiteModel> _sites = [];
  List<SiteModel> _sitesFiltres = [];

  // Filtres
  String? _agenceSelectionneeId;
  String? _siteSelectionneId;
  DateTime? _dateSelectionnee;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadAgences();
      await _loadSites();
      await _loadDebriefs();
    });
  }

  Future<void> _loadAgences() async {
    try {
      final user = context.read<UserProvider>();
      // Technicien et référent : agenceId fixe depuis UserProvider.
      // Seul le manager peut changer d'agence.
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

  Future<void> _loadDebriefs() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<UserProvider>();
      List<DebriefModel> debriefs = [];

      if (user.isTechnicien) {
        debriefs = await _debriefService.getDebriefsByReferent(user.uid);
      } else {
        debriefs = await _debriefService.getDebriefsWithFilters(
          agenceId: _agenceSelectionneeId,
          siteId: _siteSelectionneId,
          dateIntervention: _dateSelectionnee,
        );
      }

      setState(() {
        _debriefs = debriefs;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _resetFiltres() {
    setState(() {
      _siteSelectionneId = null;
      _dateSelectionnee = null;
    });
    _loadDebriefs();
  }

  Future<void> _selectionnerDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
    isDark ? const Color(0xFF4DB8D9) : const Color(0xFF33A1C9);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateSelectionnee ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                primary: primaryColor, onPrimary: Colors.black)
                : ColorScheme.light(
                primary: primaryColor, onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dateSelectionnee = picked);
      _loadDebriefs();
    }
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
        title: const Text('Liste des Débriefs',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_siteSelectionneId != null || _dateSelectionnee != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off, color: Colors.white),
              tooltip: 'Réinitialiser les filtres',
              onPressed: _resetFiltres,
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDebriefs,
          ),
        ],
      ),
      body: Column(
        children: [
          if (!user.isTechnicien) _buildFiltresBar(isDark),
          Expanded(child: _buildBody(isDark)),
        ],
      ),
    );
  }

  // ── BARRE DE FILTRES ───────────────────────────────────────────────────────
  Widget _buildFiltresBar(bool isDark) {
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
      child: Builder(builder: (context) {
        final user = context.read<UserProvider>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne 1 : Agence (manager uniquement) + Site
            Row(
              children: [
                if (user.isManager) ...[
                  Expanded(
                      child: _buildAgenceDropdown(textColor, bgColor, isDark)),
                  const SizedBox(width: 12),
                ],
                Expanded(child: _buildSiteDropdown(textColor, bgColor, isDark)),
              ],
            ),
            const SizedBox(height: 8),
            // Ligne 2 : Date
            _buildDateFilter(textColor, bgColor, isDark),
          ],
        );
      }),
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
                  color:
                  isDark ? Colors.grey[500] : Colors.grey[400]),
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
                  _loadDebriefs();
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
          Icon(Icons.location_on_outlined, size: 15, color: Colors.grey[500]),
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
                    child:
                    Text(s.nom, style: TextStyle(color: textColor)),
                  )),
                ],
                onChanged: (val) {
                  setState(() => _siteSelectionneId = val);
                  _loadDebriefs();
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
    if (_dateSelectionnee != null) {
      final d = _dateSelectionnee!;
      dateText =
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }

    return InkWell(
      onTap: _selectionnerDate,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 15, color: Colors.grey[500]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                dateText,
                style: TextStyle(fontSize: 12, color: textColor),
              ),
            ),
            Icon(Icons.arrow_drop_down,
                color: isDark ? Colors.grey[500] : Colors.grey[600]),
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
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }
    if (_debriefs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined,
                size: 80,
                color: isDark ? Colors.grey[700] : Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Aucun débrief trouvé',
                style: TextStyle(
                    fontSize: 18,
                    color:
                    isDark ? Colors.grey[500] : Colors.grey[600])),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadDebriefs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _debriefs.length,
        itemBuilder: (context, index) =>
            _buildDebriefItem(_debriefs[index], isDark),
      ),
    );
  }

  // ── ITEM DÉBRIEF : carte + bouton détails ──────────────────────────────────
  Widget _buildDebriefItem(DebriefModel debrief, bool isDark) {
    final primaryColor =
    isDark ? const Color(0xFF4DB8D9) : const Color(0xFF33A1C9);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Carte principale ──
          Card(
            margin: EdgeInsets.zero,
            elevation: isDark ? 0 : 1,
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isDark
                  ? BorderSide(color: Colors.grey[800]!, width: 1)
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ligne 1 : numéro BT + date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF33A1C9).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          debrief.numBt,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFF4DB8D9)
                                : const Color(0xFF33A1C9),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        '${debrief.dateIntervention.day.toString().padLeft(2, '0')}/'
                            '${debrief.dateIntervention.month.toString().padLeft(2, '0')}/'
                            '${debrief.dateIntervention.year}',
                        style:
                        TextStyle(color: subtitleColor, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Ligne 2 : technicien
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 16, color: subtitleColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          debrief.champsSpecifiques?[
                          'signature_technicien'] ??
                              'Technicien',
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // Commentaire (si présent)
                  if (debrief.commentaires != null &&
                      debrief.commentaires!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      debrief.commentaires!,
                      style:
                      TextStyle(color: subtitleColor, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Barre d'actions sous la carte ──
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () =>
                      DebriefDetailsModal.show(context, debrief),
                  icon: Icon(Icons.visibility_outlined,
                      size: 15, color: primaryColor),
                  label: Text(
                    'Voir les détails',
                    style: TextStyle(
                        fontSize: 11,
                        color: primaryColor,
                        fontWeight: FontWeight.w500),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}