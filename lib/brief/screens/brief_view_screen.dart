// lib/brief/screens/brief_view_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/models/agence_model.dart';
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
  String? _agenceSelectionneeId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadAgences();
      await _loadBriefs();
    });
  }

  Future<void> _loadAgences() async {
    try {
      final user = context.read<UserProvider>();
      // Technicien : ne voit que son agence, pas de sélecteur
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

  Future<void> _loadBriefs() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<UserProvider>();
      List<BriefModel> briefs = [];

      if (user.isTechnicien) {
        // Technicien : uniquement ses propres briefs (par referentId = son uid)
        briefs = await _briefService.getBriefsByReferent(user.uid);
      } else if (_agenceSelectionneeId != null) {
        briefs = await _briefService.getBriefsByAgence(_agenceSelectionneeId!);
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadBriefs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Sélecteur agence uniquement pour référents/managers
          if (!user.isTechnicien) _buildAgenceSelector(isDark),
          Expanded(child: _buildBody(isDark)),
        ],
      ),
    );
  }

  Widget _buildAgenceSelector(bool isDark) {
    if (_agences.isEmpty) return const SizedBox.shrink();
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Icon(Icons.business_outlined,
              size: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _agenceSelectionneeId,
                isExpanded: true,
                isDense: true,
                dropdownColor: bgColor,
                style: TextStyle(fontSize: 13, color: textColor),
                items: _agences
                    .map((a) => DropdownMenuItem<String?>(
                  value: a.id,
                  child: Text(a.nom,
                      style: TextStyle(color: textColor)),
                ))
                    .toList(),
                onChanged: (val) {
                  setState(() => _agenceSelectionneeId = val);
                  _loadBriefs();
                },
              ),
            ),
          ),
        ],
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
                    // Modifier
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
                    // Supprimer (référent/manager uniquement)
                    if (user.isReferent)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.redAccent),
                        tooltip: 'Supprimer',
                        onPressed: () => _deleteBrief(brief),
                      ),
                    // Créer débrief
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