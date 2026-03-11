// lib/home/screens/home_screen.dart
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryColor = isDark ? const Color(0xFF4DB8D9) : const Color(0xFF33A1C9);
    final subtitleColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/img/logo.png',
                    height: 60,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.image, size: 60, color: Colors.grey[400]),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (user.nomComplet.isNotEmpty) ...[
                        Text(
                          user.nomComplet,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          user.isManager
                              ? 'Manager'
                              : user.isReferent
                              ? 'Référent'
                              : 'Technicien',
                          style: TextStyle(fontSize: 11, color: subtitleColor),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen()),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              minimumSize: const Size(0, 28),
                              elevation: 0,
                            ),
                            child: const Icon(Icons.settings, size: 14),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            onPressed: () {
                              user.clearUser();
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const WelcomeScreen()),
                                    (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 4),
                              minimumSize: const Size(0, 28),
                              elevation: 0,
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

              // ── Carte centrale ───────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: primaryColor, width: 2),
                  boxShadow: isDark
                      ? []
                      : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHomeButton(
                      text: 'Créer un brief',
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const BriefCreateScreen())),
                      color: primaryColor,
                    ),
                    const SizedBox(height: 30),
                    _buildHomeButton(
                      text: 'Visualisation des briefs',
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const BriefViewScreen())),
                      color: primaryColor,
                    ),
                    const SizedBox(height: 30),
                    _buildHomeButton(
                      text: 'Visualisation des débriefs',
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const DebriefViewScreen())),
                      color: primaryColor,
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

  Widget _buildHomeButton({
    required String text,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center),
    );
  }
}