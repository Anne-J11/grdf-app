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
      if (user.isTechnicien) {
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateSelectionnee ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF33A1C9),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateSelectionnee = picked;
      });
      _loadDebriefs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final user = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF33A1C9),
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

  Widget _buildFiltresBar(bool isDark) {
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildAgenceDropdown(textColor, bgColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildSiteDropdown(textColor, bgColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildDateFilter(textColor, bgColor),
        ],
      ),
    );
  }

  Widget _buildAgenceDropdown(Color textColor, Color bgColor) {
    if (_agences.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(Icons.business_outlined, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _agenceSelectionneeId,
              isExpanded: true,
              isDense: true,
              dropdownColor: bgColor,
              style: TextStyle(fontSize: 12, color: textColor),
              hint: Text('Agence',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              items: _agences
                  .map((a) => DropdownMenuItem<String?>(
                value: a.id,
                child: Text(a.nom, style: TextStyle(color: textColor)),
              ))
                  .toList(),
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
    );
  }

  Widget _buildSiteDropdown(Color textColor, Color bgColor) {
    return Row(
      children: [
        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
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
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Tous les sites',
                      style: TextStyle(color: textColor)),
                ),
                ..._sitesFiltres.map((s) => DropdownMenuItem<String?>(
                  value: s.id,
                  child: Text(s.nom, style: TextStyle(color: textColor)),
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
    );
  }

  Widget _buildDateFilter(Color textColor, Color bgColor) {
    String dateText = 'Toutes les dates';
    if (_dateSelectionnee != null) {
      dateText =
      '${_dateSelectionnee!.day.toString().padLeft(2, '0')}/${_dateSelectionnee!.month.toString().padLeft(2, '0')}/${_dateSelectionnee!.year}';
    }

    return InkWell(
      onTap: _selectionnerDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                dateText,
                style: TextStyle(fontSize: 12, color: textColor),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF33A1C9)));
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
                    color: isDark ? Colors.grey[500] : Colors.grey[600])),
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
            _buildDebriefCard(_debriefs[index], isDark),
      ),
    );
  }

  Widget _buildDebriefCard(DebriefModel debrief, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 0 : 1,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark
            ? BorderSide(color: Colors.grey[800]!, width: 1)
            : BorderSide.none,
      ),
      // ✅ AJOUTER InkWell ICI
      child: InkWell(
        onTap: () => DebriefDetailsModal.show(context, debrief),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF33A1C9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('BT ${debrief.numBt}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF33A1C9),
                            fontSize: 13)),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Terminé',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.calendar_today_outlined,
                    size: 13, color: subtitleColor),
                const SizedBox(width: 4),
                Text(
                  '${debrief.dateIntervention.day.toString().padLeft(2, '0')}/${debrief.dateIntervention.month.toString().padLeft(2, '0')}/${debrief.dateIntervention.year}',
                  style: TextStyle(fontSize: 12, color: subtitleColor),
                ),
              ]),
              if (debrief.commentaires != null &&
                  debrief.commentaires!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  debrief.commentaires!,
                  style: TextStyle(fontSize: 12, color: textColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}