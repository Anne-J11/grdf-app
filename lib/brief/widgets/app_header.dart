// lib/brief/widgets/app_header.dart

import 'package:flutter/material.dart';
import '../screens/brief_view_screen.dart';

/// Widget d'en-tête d'application réutilisable
///
/// Affiche :
/// - Le logo de l'application (à gauche)
/// - Un bouton "Visualisation des briefs" (toujours visible)
/// - Un bouton "Déconnexion" (à droite)
class AppHeader extends StatelessWidget {
  final VoidCallback? onVisualisationPressed;
  final VoidCallback onDeconnexionPressed;

  const AppHeader({
    super.key,
    this.onVisualisationPressed,
    required this.onDeconnexionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset('assets/img/logo.png', height: 40),
        const Spacer(),

        // Bouton "Visualisation des briefs"
        _buildHeaderButton(
          'Visualisation des briefs',
          onVisualisationPressed ?? () {
            // Par défaut : naviguer vers BriefViewScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BriefViewScreen(),
              ),
            );
          },
        ),
        const SizedBox(width: 8),

        // Bouton "Déconnexion"
        _buildHeaderButton('Déconnexion', onDeconnexionPressed),
      ],
    );
  }

  Widget _buildHeaderButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF33A1C9),
        elevation: 0,
        side: const BorderSide(color: Color(0xFF33A1C9), width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}