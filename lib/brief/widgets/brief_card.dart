// lib/brief/widgets/brief_card.dart

import 'package:flutter/material.dart';
import '../models/brief_model.dart';

class BriefCard extends StatelessWidget {
  final BriefModel brief;
  final VoidCallback onTap;

  const BriefCard({
    super.key,
    required this.brief,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Adaptation des couleurs pour le dark mode
    final cardColor = brief.estVerrouille
        ? (isDark ? Colors.grey[900] : Colors.grey[50])
        : Theme.of(context).cardColor;

    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final primaryColor = const Color(0xFF33A1C9);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark ? BorderSide(color: Colors.grey[800]!, width: 1) : BorderSide.none,
      ),
      color: cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne 1 : BT, Statut, Cadenas, Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          brief.numBt,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF4DB8D9) : primaryColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(),
                      // Badge cadenas
                      if (brief.estVerrouille) ...[
                        const SizedBox(width: 6),
                        Tooltip(
                          message: 'Brief verrouillé — débrief validé',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.orange.withOpacity(0.1) : Colors.orange[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: isDark ? Colors.orange.withOpacity(0.3) : Colors.orange[200]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock,
                                    size: 10,
                                    color: isDark ? Colors.orange[300] : Colors.orange[700]),
                                const SizedBox(width: 3),
                                Text(
                                  'Verrouillé',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: isDark ? Colors.orange[300] : Colors.orange[700],
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '${brief.dateIntervention.day.toString().padLeft(2, '0')}/${brief.dateIntervention.month.toString().padLeft(2, '0')}/${brief.dateIntervention.year}',
                    style: TextStyle(color: subtitleColor, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 16, color: subtitleColor),
                  const SizedBox(width: 6),
                  Text(
                    brief.referentNom,
                    style: TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.build_outlined,
                      size: 16, color: subtitleColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      brief.materiel,
                      style: TextStyle(
                          color: isDark ? Colors.grey[300] : Colors.grey[700], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
