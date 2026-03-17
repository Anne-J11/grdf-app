// lib/debrief/widgets/debrief_details_modal.dart

import 'dart:convert';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHandle(isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDark),
                  const SizedBox(height: 24),
                  _buildInfoSection(isDark),
                  const SizedBox(height: 20),
                  if (debrief.commentaires != null &&
                      debrief.commentaires!.isNotEmpty)
                    _buildCommentsSection(isDark),
                  if (debrief.champsSpecifiques != null &&
                      debrief.champsSpecifiques!.isNotEmpty)
                    _buildChampsSpecifiques(isDark),

                  // Affichage des photos si présentes
                  if (debrief.champsSpecifiques?.containsKey('photos') ?? false)
                    _buildPhotosInfo(isDark),

                  // Affichage de la signature si présente
                  if (debrief.champsSpecifiques?.containsKey('signature_technicien') ?? false)
                    _buildSignatureInfo(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[700] : Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Débrief ${debrief.numBt}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF4DB8D9) : const Color(0xFF33A1C9),
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

  Widget _buildInfoSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Informations générales', isDark),
        const SizedBox(height: 12),
        _buildDetailItem(
          'Date d\'intervention',
          '${debrief.dateIntervention.day.toString().padLeft(2, '0')}/'
              '${debrief.dateIntervention.month.toString().padLeft(2, '0')}/'
              '${debrief.dateIntervention.year}',
          Icons.calendar_today_outlined,
          isDark,
        ),
        if (debrief.travauxStatut != null)
          _buildDetailItem(
            'Statut des travaux',
            debrief.travauxStatut!,
            Icons.construction_outlined,
            isDark,
          ),
      ],
    );
  }

  Widget _buildCommentsSection(bool isDark) {
    final bgColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF8F9FA);
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final textColor = isDark ? Colors.grey[300]! : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 32, color: isDark ? Colors.grey[800] : null),
        _buildSectionTitle('Commentaires', isDark),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            debrief.commentaires!,
            style: TextStyle(fontSize: 14, color: textColor),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildChampsSpecifiques(bool isDark) {
    final champsAffichables = Map<String, dynamic>.from(debrief.champsSpecifiques!)
      ..remove('travaux_statut')
      ..remove('signature_technicien')
      ..remove('photos');

    if (champsAffichables.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 32, color: isDark ? Colors.grey[800] : null),
        _buildSectionTitle('Informations spécifiques', isDark),
        const SizedBox(height: 12),
        ...champsAffichables.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildDetailItem(
              _formatFieldName(entry.key),
              entry.value?.toString() ?? '-',
              Icons.info_outlined,
              isDark,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPhotosInfo(bool isDark) {
    final List<dynamic> photosBase64 = debrief.champsSpecifiques!['photos'] ?? [];
    if (photosBase64.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 32, color: isDark ? Colors.grey[800] : null),
        _buildSectionTitle('Photos', isDark),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: photosBase64.length,
            itemBuilder: (context, index) {
              return Container(
                width: 90,
                margin: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    base64Decode(photosBase64[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureInfo(bool isDark) {
    final signature = debrief.champsSpecifiques!['signature_technicien'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 32, color: isDark ? Colors.grey[800] : null),
        _buildSectionTitle('Signature', isDark),
        const SizedBox(height: 12),
        _buildDetailItem(
          'Signé par (Technicien)',
          signature?.toString() ?? '-',
          Icons.verified_user_outlined,
          isDark,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isDark ? const Color(0xFF4DB8D9) : const Color(0xFF33A1C9),
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, bool isDark) {
    final iconBgColor = isDark
        ? const Color(0xFF4DB8D9).withOpacity(0.1)
        : const Color(0xFF33A1C9).withOpacity(0.05);
    final iconColor = isDark ? const Color(0xFF4DB8D9) : const Color(0xFF33A1C9);
    final textColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.grey[400] : Colors.grey[500];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
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
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
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
