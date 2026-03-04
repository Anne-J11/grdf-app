// lib/debrief/screens/debrief_view_screen.dart
// Fichier créé (était vide).
// Sélecteur d'agence (agence de l'utilisateur par défaut, modifiable).
// Tap sur une carte → bottom sheet de détail (style identique à brief_details_modal).

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

  Future<void> _loadDebriefs() async {
    setState(() => _isLoading = true);
    try {
      List<DebriefModel> debriefs = [];
      if (_agenceSelectionneeId != null) {
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
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
                  _loadDebriefs();
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
    if (_debriefs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Aucun débrief trouvé',
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
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
            _buildDebriefCard(_debriefs[index]),
      ),
    );
  }

  Widget _buildDebriefCard(DebriefModel debrief) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDetails(debrief),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
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
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: Colors.green.withOpacity(0.3)),
                      ),
                      child: const Text('Terminé',
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  Text(
                    '${debrief.dateIntervention.day.toString().padLeft(2, '0')}/${debrief.dateIntervention.month.toString().padLeft(2, '0')}/${debrief.dateIntervention.year}',
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              if (debrief.aleasRencontres != null &&
                  debrief.aleasRencontres!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.warning_amber_outlined,
                      size: 14, color: Colors.orange[700]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(debrief.aleasRencontres!,
                        style: TextStyle(
                            color: Colors.grey[700], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ],
              if (debrief.travauxStatut != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.build_outlined,
                      size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('Travaux : ${debrief.travauxStatut}',
                      style: TextStyle(
                          color: Colors.grey[700], fontSize: 12)),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(DebriefModel debrief) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Débrief BT ${debrief.numBt}',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF33A1C9))),
                    const SizedBox(height: 4),
                    Text(
                        'Créé le ${debrief.dateCreation.day.toString().padLeft(2, '0')}/${debrief.dateCreation.month.toString().padLeft(2, '0')}/${debrief.dateCreation.year}',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[500])),
                    const Divider(height: 32),
                    _buildDetailItem(
                        "Date d'intervention",
                        '${debrief.dateIntervention.day.toString().padLeft(2, '0')}/${debrief.dateIntervention.month.toString().padLeft(2, '0')}/${debrief.dateIntervention.year}',
                        Icons.calendar_today_outlined),
                    if (debrief.aleasRencontres != null &&
                        debrief.aleasRencontres!.isNotEmpty)
                      _buildDetailItem('Aléas rencontrés',
                          debrief.aleasRencontres!, Icons.warning_amber_outlined),
                    if (debrief.travauxStatut != null)
                      _buildDetailItem('Statut travaux',
                          debrief.travauxStatut!, Icons.build_circle_outlined),
                    if (debrief.commentaires != null &&
                        debrief.commentaires!.isNotEmpty)
                      _buildDetailItem('Commentaires',
                          debrief.commentaires!, Icons.chat_bubble_outline),
                    if (debrief.champsSpecifiques != null) ...[
                      const Divider(height: 32),
                      const Text('INFORMATIONS SPÉCIFIQUES',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF33A1C9),
                              letterSpacing: 1.1)),
                      const SizedBox(height: 12),
                      ...debrief.champsSpecifiques!.entries
                          .where((e) =>
                              e.key != 'aleas_rencontres' &&
                              e.key != 'travaux_statut')
                          .map((e) => _buildDetailItem(
                              e.key.replaceAll('_', ' '),
                              e.value.toString(),
                              Icons.info_outline)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF33A1C9).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF33A1C9)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, color: Colors.black87, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
