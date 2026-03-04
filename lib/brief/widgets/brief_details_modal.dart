// lib/brief/widgets/brief_details_modal.dart

import 'package:flutter/material.dart';
import '../models/brief_model.dart';

class BriefDetailsModal extends StatelessWidget {
  final BriefModel brief;

  const BriefDetailsModal({
    super.key,
    required this.brief,
  });

  static void show(BuildContext context, BriefModel brief) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BriefDetailsModal(brief: brief),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),

                  // Section : Informations principales
                  _buildSectionTitle('Informations générales'),
                  const SizedBox(height: 12),
                  _buildDetailItem('Chef d\'équipe', brief.referentNom, Icons.person_outline),
                  // ✅ AJOUT : Type d'intervention
                  _buildDetailItem(
                    'Type d\'intervention',
                    brief.typeInterventionNom ?? 'Non spécifié',
                    Icons.category_outlined,
                  ),
                  _buildDetailItem('Date d\'intervention',
                      '${brief.dateIntervention.day.toString().padLeft(2, '0')}/${brief.dateIntervention.month.toString().padLeft(2, '0')}/${brief.dateIntervention.year}',
                      Icons.calendar_today_outlined),

                  const Divider(height: 32),

                  // Section : Préparation
                  _buildSectionTitle('Préparation et consignes'),
                  const SizedBox(height: 12),
                  _buildDetailItem('Vérification des risques', brief.risques, Icons.warning_amber_rounded),
                  _buildDetailItem('État du matériel', brief.materiel, Icons.build_circle_outlined),
                  _buildDetailItem('Consignes du jour', brief.consignes, Icons.assignment_outlined),

                  if (brief.commentaires != null && brief.commentaires!.isNotEmpty) ...[
                    _buildDetailItem('Commentaires', brief.commentaires!, Icons.chat_bubble_outline),
                  ],

                  // Section : Champs spécifiques (si présents)
                  if (brief.champsSpecifiques != null && brief.champsSpecifiques!.isNotEmpty) ...[
                    const Divider(height: 32),
                    _buildSectionTitle('Informations spécifiques'),
                    const SizedBox(height: 12),
                    ...brief.champsSpecifiques!.entries.map((entry) {
                      return _buildDetailItem(
                        _formatFieldName(entry.key),
                        entry.value.toString(),
                        Icons.info_outline,
                      );
                    }).toList(),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Brief ${brief.numBt}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF33A1C9),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: ${brief.id?.substring(0, 8) ?? 'N/A'}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF33A1C9),
        letterSpacing: 1.1,
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
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String label;

    switch (brief.statut.toLowerCase()) {
      case 'envoye':
        color = Colors.orange;
        label = 'Envoyé';
        break;
      case 'termine':
        color = Colors.green;
        label = 'Terminé';
        break;
      case 'en_cours':
        color = Colors.blue;
        label = 'En cours';
        break;
      default:
        color = Colors.grey;
        label = brief.statut;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Formate le nom du champ : "lieu_chantier" → "Lieu Chantier"
  String _formatFieldName(String fieldName) {
    return fieldName
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
        ? ''
        : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}