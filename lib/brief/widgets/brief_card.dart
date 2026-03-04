// lib/brief/widgets/brief_card.dart
// Modification : ajout du badge 🔒 "Verrouillé" si brief.estVerrouille == true.
// Le reste est identique au code de ta collègue.

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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // Fond légèrement grisé si verrouillé
      color: brief.estVerrouille ? Colors.grey[50] : Colors.white,
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
                          color: const Color(0xFF33A1C9).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          brief.numBt,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF33A1C9),
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
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: Colors.orange[200]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock,
                                    size: 10,
                                    color: Colors.orange[700]),
                                const SizedBox(width: 3),
                                Text(
                                  'Verrouillé',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.orange[700],
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
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    brief.referentNom,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.build_outlined,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      brief.materiel,
                      style: TextStyle(
                          color: Colors.grey[700], fontSize: 13),
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
