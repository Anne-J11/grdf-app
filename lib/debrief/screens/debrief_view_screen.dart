// lib/debrief/screens/debrief_view_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/models/agence_model.dart';
import '../../firestore_service.dart';
import '../models/debrief_model.dart';
import '../services/debrief_service.dart';

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
  String? _agenceSelectionneeId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadAgences();
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

  Future<void> _loadDebriefs() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<UserProvider>();
      List<DebriefModel> debriefs = [];

      if (user.isTechnicien) {
        // Technicien : uniquement ses propres débriefs
        debriefs = await _debriefService.getDebriefsByReferent(user.uid);
      } else if (_agenceSelectionneeId != null) {
        debriefs =
        await _debriefService.getDebriefsByAgence(_agenceSelectionneeId!);
      }

      setState(() {
        _debriefs = debriefs;
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDebriefs,
          ),
        ],
      ),
      body: Column(
        children: [
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
                  _loadDebriefs();
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
        itemBuilder: (context, index) => _buildDebriefCard(_debriefs[index], isDark),
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
    );
  }
}