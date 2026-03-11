// lib/brief/widgets/brief_details_modal.dart
import 'package:flutter/material.dart';
import '../models/brief_model.dart';

class BriefDetailsModal extends StatelessWidget {
  final BriefModel brief;

  const BriefDetailsModal({super.key, required this.brief});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400]! : Colors.grey[500]!;
    final dividerColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

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
                  _buildHeader(textColor, subtitleColor),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Informations générales'),
                  const SizedBox(height: 12),
                  _buildDetailItem('Chef d\'équipe', brief.referentNom,
                      Icons.person_outline, textColor, subtitleColor),
                  if (brief.typeInterventionNom != null)
                    _buildDetailItem(
                        'Type d\'intervention',
                        brief.typeInterventionNom!,
                        Icons.category_outlined,
                        textColor,
                        subtitleColor),
                  _buildDetailItem(
                      'Date d\'intervention',
                      '${brief.dateIntervention.day.toString().padLeft(2, '0')}/${brief.dateIntervention.month.toString().padLeft(2, '0')}/${brief.dateIntervention.year}',
                      Icons.calendar_today_outlined,
                      textColor,
                      subtitleColor),

                  Divider(color: dividerColor, height: 32),
                  _buildSectionTitle('Détails de l\'intervention'),
                  const SizedBox(height: 12),

                  if (brief.risques.isNotEmpty)
                    _buildDetailItem('Analyse des risques', brief.risques,
                        Icons.warning_amber_outlined, textColor, subtitleColor),
                  if (brief.materiel.isNotEmpty)
                    _buildDetailItem('État du matériel', brief.materiel,
                        Icons.build_outlined, textColor, subtitleColor),
                  if (brief.consignes.isNotEmpty)
                    _buildDetailItem('Consigne du jour', brief.consignes,
                        Icons.checklist_outlined, textColor, subtitleColor),
                  if (brief.commentaires != null &&
                      brief.commentaires!.isNotEmpty)
                    _buildDetailItem('Commentaires', brief.commentaires!,
                        Icons.comment_outlined, textColor, subtitleColor),

                  // Champs dynamiques
                  if (brief.champsSpecifiques != null &&
                      brief.champsSpecifiques!.isNotEmpty) ...[
                    Divider(color: dividerColor, height: 32),
                    _buildSectionTitle('Champs spécifiques'),
                    const SizedBox(height: 12),
                    ...brief.champsSpecifiques!.entries
                        .where((e) =>
                    !['signature_referent', 'signature_technicien']
                        .contains(e.key))
                        .map((entry) => _buildDetailItem(
                      _formatFieldName(entry.key),
                      entry.value?.toString() ?? '—',
                      Icons.info_outline,
                      textColor,
                      subtitleColor,
                    )),
                  ],

                  // Signatures (noms)
                  if (brief.champsSpecifiques?['signature_referent'] != null ||
                      brief.champsSpecifiques?['signature_technicien'] != null) ...[
                    Divider(color: dividerColor, height: 32),
                    _buildSectionTitle('Signatures'),
                    const SizedBox(height: 12),
                    if (brief.champsSpecifiques?['signature_referent'] != null)
                      _buildSignatureItem(
                          'Référent',
                          brief.champsSpecifiques!['signature_referent'],
                          isDark),
                    if (brief.champsSpecifiques?['signature_technicien'] != null)
                      _buildSignatureItem(
                          'Technicien',
                          brief.champsSpecifiques!['signature_technicien'],
                          isDark),
                  ],

                  const SizedBox(height: 16),
                  _buildStatusBadge(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[600] : Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color subtitleColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BT ${brief.numBt}',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor),
            ),
            Text(
              'Créé le ${brief.dateCreation.day.toString().padLeft(2, '0')}/${brief.dateCreation.month.toString().padLeft(2, '0')}/${brief.dateCreation.year}',
              style: TextStyle(fontSize: 12, color: subtitleColor),
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

  Widget _buildDetailItem(String label, String value, IconData icon,
      Color textColor, Color subtitleColor) {
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
                        color: subtitleColor,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 14, color: textColor, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureItem(String role, String valeur, bool isDark) {
    final bgColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey[50]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400]! : Colors.grey[500]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_user_outlined,
                size: 16, color: Colors.green[600]),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role,
                    style:
                    TextStyle(fontSize: 10, color: subtitleColor)),
                Text(valeur,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor)),
              ],
            ),
            const Spacer(),
            Text('Signé',
                style: TextStyle(fontSize: 11, color: Colors.green[600])),
          ],
        ),
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
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  String _formatFieldName(String fieldName) {
    return fieldName
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
    word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}