// lib/debrief/widgets/debrief_details_modal.dart

import 'package:flutter/material.dart';
import '../models/debrief_model.dart';

class DebriefDetailsModal extends StatelessWidget {
  final DebriefModel debrief;

  const DebriefDetailsModal({
    super.key,
    required this.debrief,
  });

  static void show(BuildContext context, DebriefModel debrief) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DebriefDetailsModal(debrief: debrief),
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
                  _buildInfoSection(),
                  const SizedBox(height: 20),
                  if (debrief.commentaires != null &&
                      debrief.commentaires!.isNotEmpty)
                    _buildCommentsSection(),
                  if (debrief.champsSpecifiques != null &&
                      debrief.champsSpecifiques!.isNotEmpty)
                    _buildChampsSpecifiques(),
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
              'Débrief ${debrief.numBt}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF33A1C9),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: ${debrief.id?.substring(0, 8) ?? 'N/A'}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Text(
        'Terminé',
        style: TextStyle(
          color: Colors.green[700],
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Informations générales'),
        const SizedBox(height: 12),
        _buildDetailItem(
          'Date d\'intervention',
          '${debrief.dateIntervention.day.toString().padLeft(2, '0')}/'
              '${debrief.dateIntervention.month.toString().padLeft(2, '0')}/'
              '${debrief.dateIntervention.year}',
          Icons.calendar_today_outlined,
        ),
        if (debrief.travauxStatut != null)
          _buildDetailItem(
            'Statut des travaux',
            debrief.travauxStatut!,
            Icons.construction_outlined,
          ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        _buildSectionTitle('Commentaires'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            debrief.commentaires!,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildChampsSpecifiques() {
    // Filtrer pour ne pas afficher travaux_statut et signature deux fois
    final champsAffichables = Map<String, dynamic>.from(debrief.champsSpecifiques!)
      ..remove('travaux_statut')
      ..remove('signature_technicien');

    if (champsAffichables.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        _buildSectionTitle('Informations spécifiques'),
        const SizedBox(height: 12),
        ...champsAffichables.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildDetailItem(
              _formatFieldName(entry.key),
              entry.value?.toString() ?? '-',
              Icons.info_outlined,
            ),
          );
        }).toList(),
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