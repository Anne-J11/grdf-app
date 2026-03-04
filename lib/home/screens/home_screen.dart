// lib/home/screens/home_screen.dart
// Modifications :
//   - Affiche le nom + rôle de l'utilisateur connecté (via UserProvider)
//   - Ajoute le bouton "Visualisation des débriefs"
//   - Ajoute le bouton "Paramètres" (pour l'archivage manuel)
//   - La déconnexion vide maintenant le UserProvider

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grdf_app/welcome_screen.dart';
import 'package:grdf_app/auth/providers/user_provider.dart';
import 'package:grdf_app/brief/screens/brief_create_screen.dart';
import '../../brief/screens/brief_view_screen.dart';
import '../../debrief/screens/debrief_view_screen.dart';
import '../../core/screens/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/img/logo.png',
                    height: 60,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image, size: 60, color: Colors.grey),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Nom + rôle de l'utilisateur connecté
                      if (user.nomComplet.isNotEmpty) ...[
                        Text(user.nomComplet,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF33A1C9))),
                        Text(
                            user.isManager ? 'Manager' : user.isReferent ? 'Référent' : 'Technicien',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600])),
                        const SizedBox(height: 6),
                      ],
                      Row(
                        children: [
                          // Bouton Paramètres
                          OutlinedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const SettingsScreen()),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF33A1C9),
                              side: const BorderSide(
                                  color: Color(0xFF33A1C9)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              minimumSize: const Size(0, 28),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('Paramètres',
                                style: TextStyle(fontSize: 11)),
                          ),
                          const SizedBox(width: 8),
                          // Bouton Déconnexion
                          ElevatedButton(
                            onPressed: () {
                              context.read<UserProvider>().clearUser();
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const WelcomeScreen()),
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF33A1C9),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 4),
                              minimumSize: const Size(0, 28),
                            ),
                            child: const Text('Déconnexion',
                                style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 60),

              // Carte centrale
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: const Color(0xFF33A1C9), width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHomeButton(
                      text: 'Créer un brief',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const BriefCreateScreen()),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildHomeButton(
                      text: 'Visualisation des briefs',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const BriefViewScreen()),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildHomeButton(
                      text: 'Visualisation des débriefs',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const DebriefViewScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeButton(
      {required String text, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF33A1C9),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center),
    );
  }
}
