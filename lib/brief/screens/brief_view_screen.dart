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
  DateTime? _dateSelectionnee; // ✅ Une seule date

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
      if (user.isTechnicien) {
        setState(() {
          _agenceSelectionneeId = user.agenceId;
        });
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
        briefs = await _briefService.getBriefsByReferent(user.uid);
      } else {
        briefs = await _briefService.getBriefsWithFilters(
          agenceId: _agenceSelectionneeId,
          siteId: _siteSelectionneId,
          dateIntervention: _dateSelectionnee, // ✅ Une seule date
        );
      }

      setState(() {
        _briefs = briefs;
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
                backgroundColor: Colors.red, foregroundColor: Colors.white),
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
              content: Text('Brief supprimé'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _resetFiltres() {
    setState(() {
      _siteSelectionneId = null;
      _dateSelectionnee = null;
    });
    _loadBriefs();
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
      _loadBriefs();
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
        title: const Text('Liste des Briefs',
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
            onPressed: _loadBriefs,
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
                _loadBriefs();
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
                _loadBriefs();
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
                    color: isDark ? Colors.grey[500] : Colors.grey[600])),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadBriefs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _briefs.length,
        itemBuilder: (context, index) => _buildBriefItem(_briefs[index]),
      ),
    );
  }

  Widget _buildBriefItem(BriefModel brief) {
    final briefId = brief.id!;
    final user = context.read<UserProvider>();

    return Column(
      children: [
        Stack(
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
            if (!brief.estVerrouille)
              Positioned(
                top: 4,
                right: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 18, color: Color(0xFF33A1C9)),
                      tooltip: 'Modifier',
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  BriefCreateScreen(briefExistant: brief)),
                        );
                        _loadBriefs();
                      },
                    ),
                    if (user.isReferent)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.redAccent),
                        tooltip: 'Supprimer',
                        onPressed: () => _deleteBrief(brief),
                      ),
                    IconButton(
                      icon: const Icon(Icons.assignment_turned_in_outlined,
                          size: 18, color: Colors.green),
                      tooltip: 'Créer débrief',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DebriefCreateScreen(
                            briefId: briefId,
                            numBt: brief.numBt,
                            referentNom: brief.referentNom,
                            typeInterventionNom: brief.typeInterventionNom,
                            agenceId: brief.agenceId,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}