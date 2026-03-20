// lib/brief/widgets/app_header.dart

import 'package:flutter/material.dart';
import '../screens/brief_view_screen.dart';

/// Widget d'en-tête d'application réutilisable
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
        // Utilisation de logo_icon.png plus adaptée pour le header
        Image.asset(
          'assets/img/logo_icon.png', 
          height: 40,
          errorBuilder: (_, __, ___) => Image.asset('assets/img/logo.png', height: 40),
        ),
        const Spacer(),

        _buildHeaderButton(
          'Visualisation des briefs',
          onVisualisationPressed ?? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BriefViewScreen(),
              ),
            );
          },
        ),
        const SizedBox(width: 8),

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