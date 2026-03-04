// lib/brief/screens/brief_view_screen.dart
// Modifications v2 :
//   - Boutons Modifier et Supprimer sur chaque brief (si non verrouillé)
//   - Débrief affiché visuellement lié sous son brief (expandable)
//   - Sélecteur d'agence (inchangé)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/models/agence_model.dart';
import '../../firestore_service.dart';
import '../models/brief_model.dart';
import '../services/brief_service.dart';
import '../../debrief/models/debrief_model.dart';
import '../../debrief/services/debrief_service.dart';
import '../widgets/brief_card.dart';
import '../widgets/brief_details_modal.dart';
import 'brief_create_screen.dart';

class BriefViewScreen extends StatefulWidget {
  const BriefViewScreen({super.key});

  @override
  State<BriefViewScreen> createState() => _BriefViewScreenState();
}

class _BriefViewScreenState extends State<BriefViewScreen> {
  final BriefService _briefService = BriefService();
  final DebriefService _debriefService = DebriefService();
  final FirestoreService _firestoreService = FirestoreService();

  List<BriefModel> _briefs = [];
  List<AgenceModel> _agences = [];
  // Cache des débriefs chargés par briefId
  final Map<String, DebriefModel?> _debriefCache = {};
  // Briefs dont le panneau débrief est ouvert
  final Set<String> _expanded = {};
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
      final agences = await _firestoreService.getAgences();
      final user = context.read<UserProvider>();
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
      List<BriefModel> briefs = [];
      if (_agenceSelectionneeId != null) {
        briefs =
            await _briefService.getBriefsByAgence(_agenceSelectionneeId!);
      }
      setState(() {
        _briefs = briefs;
        _debriefCache.clear();
        _expanded.clear();
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

  // Charge le débrief d'un brief (avec cache)
  Future<void> _loadDebrief(String briefId) async {
    if (_debriefCache.containsKey(briefId)) return;
    try {
      final debrief = await _debriefService.getDebriefByBriefId(briefId);
      setState(() => _debriefCache[briefId] = debrief);
    } catch (_) {
      setState(() => _debriefCache[briefId] = null);
    }
  }

  Future<void> _supprimerBrief(BriefModel brief) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Supprimer le brief'),
        content: Text(
            'Supprimer le brief BT ${brief.numBt} ? Cette action est irréversible.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
          _buildAgenceSelector(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildAgenceSelector() {
    if (_agences.isEmpty) return const SizedBox.shrink();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Icon(Icons.business_outlined, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _agenceSelectionneeId,
                isExpanded: true,
                isDense: true,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                items: _agences
                    .map((a) => DropdownMenuItem<String?>(
                          value: a.id,
                          child: Text(a.nom),
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF33A1C9)));
    }
    if (_briefs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Aucun brief trouvé',
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
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
    final isExpanded = _expanded.contains(briefId);
    final user = context.read<UserProvider>();

    return Column(
      children: [
        // ── Carte brief + actions ──────────────────────────────────
        Stack(
          children: [
            BriefCard(
              brief: brief,
              onTap: () {
                if (brief.estVerrouille) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            BriefCreateScreen(briefExistant: brief)),
                  );
                } else {
                  BriefDetailsModal.show(context, brief);
                }
              },
            ),
            // Boutons Modifier / Supprimer (si non verrouillé)
            if (!brief.estVerrouille)
              Positioned(
                top: 4,
                right: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      icon: Icons.edit_outlined,
                      color: const Color(0xFF33A1C9),
                      tooltip: 'Modifier',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                BriefCreateScreen(briefExistant: brief)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      color: Colors.red,
                      tooltip: 'Supprimer',
                      onTap: () => _supprimerBrief(brief),
                    ),
                  ],
                ),
              ),
          ],
        ),

        // ── Bandeau débrief lié ────────────────────────────────────
        if (brief.estVerrouille)
          _buildDebriefBandeau(brief, isExpanded),

        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1))
            ],
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }

  Widget _buildDebriefBandeau(BriefModel brief, bool isExpanded) {
    final briefId = brief.id!;

    return GestureDetector(
      onTap: () async {
        if (!isExpanded) await _loadDebrief(briefId);
        setState(() {
          if (isExpanded) {
            _expanded.remove(briefId);
          } else {
            _expanded.add(briefId);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
        decoration: BoxDecoration(
          color: isExpanded
              ? const Color(0xFF33A1C9).withOpacity(0.05)
              : Colors.white,
          borderRadius: isExpanded
              ? const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12))
              : BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF33A1C9).withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            // En-tête du bandeau
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.assignment_turned_in_outlined,
                      size: 14, color: const Color(0xFF33A1C9)),
                  const SizedBox(width: 6),
                  const Text(
                    'Débrief associé',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF33A1C9)),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: const Color(0xFF33A1C9),
                  ),
                ],
              ),
            ),
            // Contenu débrief (si déplié)
            if (isExpanded) _buildDebriefContenu(briefId),
          ],
        ),
      ),
    );
  }

  Widget _buildDebriefContenu(String briefId) {
    if (!_debriefCache.containsKey(briefId)) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
            child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF33A1C9)))),
      );
    }

    final debrief = _debriefCache[briefId];
    if (debrief == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Text('Aucun débrief trouvé',
            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Date
          _buildDebriefRow(
            Icons.calendar_today_outlined,
            'Date',
            '${debrief.dateIntervention.day.toString().padLeft(2, '0')}/${debrief.dateIntervention.month.toString().padLeft(2, '0')}/${debrief.dateIntervention.year}',
          ),
          // Aléas
          if (debrief.aleasRencontres != null &&
              debrief.aleasRencontres!.isNotEmpty)
            _buildDebriefRow(
                Icons.warning_amber_outlined,
                'Aléas rencontrés',
                debrief.aleasRencontres!),
          // Travaux
          if (debrief.travauxStatut != null)
            _buildDebriefRow(
                Icons.build_outlined,
                'Travaux',
                debrief.travauxStatut!),
          // Commentaires
          if (debrief.commentaires != null &&
              debrief.commentaires!.isNotEmpty)
            _buildDebriefRow(
                Icons.chat_bubble_outline,
                'Commentaires',
                debrief.commentaires!),
          // Champs spécifiques restants
          if (debrief.champsSpecifiques != null)
            ...debrief.champsSpecifiques!.entries
                .where((e) =>
                    e.key != 'aleas_rencontres' &&
                    e.key != 'travaux_statut' &&
                    e.value.toString().isNotEmpty)
                .map((e) => _buildDebriefRow(
                      Icons.info_outline,
                      e.key.replaceAll('_', ' '),
                      e.value.toString(),
                    )),
        ],
      ),
    );
  }

  Widget _buildDebriefRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Text('$label : ',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600])),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 11, color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
