// lib/core/screens/settings_screen.dart
// Modifications :
//   - Affiche uniquement les infos du compte connecté (nom, rôle, agence, site, email)
//   - Suppression de la section "Comptes de test"
//   - Note sur le hashage automatique des mots de passe par Firebase Auth

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/archive_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isArchiving = false;

  Future<void> _archiverManuellement() async {
    setState(() => _isArchiving = true);
    try {
      await ArchiveService().lancerArchivageAutomatique();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Archivage terminé avec succès'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isArchiving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final theme = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final primaryColor = colorScheme.primary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Paramètres'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Mon compte ───────────────────────────────────────────────
            _buildSectionTitle('Mon compte', subtitleColor),
            _buildCard(cardColor, isDark, children: [
              _buildInfoRow(
                  Icons.person_outline,
                  'Nom',
                  user.nomComplet.isNotEmpty ? user.nomComplet : '—',
                  primaryColor,
                  subtitleColor),
              _divider(isDark),
              _buildInfoRow(
                  Icons.badge_outlined,
                  'Rôle',
                  _roleLabel(user.role),
                  primaryColor,
                  subtitleColor),
              _divider(isDark),
              _buildInfoRow(
                  Icons.business_outlined,
                  'Agence',
                  user.agenceId.isNotEmpty ? user.agenceId : '—',
                  primaryColor,
                  subtitleColor),
              _divider(isDark),
              _buildInfoRow(
                  Icons.location_on_outlined,
                  'Site',
                  user.siteId.isNotEmpty ? user.siteId : '—',
                  primaryColor,
                  subtitleColor),
            ]),
            const SizedBox(height: 16),

            // ── Sécurité mot de passe ────────────────────────────────────
            _buildCard(cardColor, isDark, children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.green[600], size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mot de passe sécurisé',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700])),
                          const SizedBox(height: 2),
                          Text(
                            'Votre mot de passe est automatiquement hashé par Firebase Authentication (bcrypt). Il n\'est jamais stocké en clair.',
                            style: TextStyle(
                                fontSize: 12, color: subtitleColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 28),

            // ── Apparence ────────────────────────────────────────────────
            _buildSectionTitle('Apparence', subtitleColor),
            _buildCard(cardColor, isDark, children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(theme.modeIcon, color: primaryColor, size: 22),
                      const SizedBox(width: 10),
                      Text('Thème : ${theme.modeLabel}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ]),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _themeButton(context,
                            label: 'Système',
                            icon: Icons.brightness_auto_outlined,
                            selected: theme.mode == AppThemeMode.system,
                            onTap: () => theme.setMode(AppThemeMode.system),
                            primaryColor: primaryColor,
                            cardColor: cardColor,
                            isDark: isDark),
                        const SizedBox(width: 8),
                        _themeButton(context,
                            label: 'Clair',
                            icon: Icons.light_mode_outlined,
                            selected: theme.mode == AppThemeMode.light,
                            onTap: () => theme.setMode(AppThemeMode.light),
                            primaryColor: primaryColor,
                            cardColor: cardColor,
                            isDark: isDark),
                        const SizedBox(width: 8),
                        _themeButton(context,
                            label: 'Sombre',
                            icon: Icons.dark_mode_outlined,
                            selected: theme.mode == AppThemeMode.dark,
                            onTap: () => theme.setMode(AppThemeMode.dark),
                            primaryColor: primaryColor,
                            cardColor: cardColor,
                            isDark: isDark),
                      ],
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 28),

            // ── Archivage ────────────────────────────────────────────────
            if (user.isReferent) ...[
              _buildSectionTitle('Gestion des archives', subtitleColor),
              _buildCard(cardColor, isDark, children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.archive_outlined,
                            color: Colors.orange[700], size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('Archivage manuel',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Text(
                        'Archive manuellement tous les briefs et débriefs de plus de 2 ans. '
                            "L'archivage automatique se déclenche aussi au lancement de l'application.",
                        style:
                        TextStyle(fontSize: 13, color: subtitleColor),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                          _isArchiving ? null : _archiverManuellement,
                          icon: _isArchiving
                              ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.archive_outlined),
                          label: Text(_isArchiving
                              ? 'Archivage en cours...'
                              : "Lancer l'archivage"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[700],
                            foregroundColor: Colors.white,
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ],

            if (!user.isReferent) ...[
              _buildSectionTitle('Archives', subtitleColor),
              _buildCard(cardColor, isDark, children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Icon(Icons.info_outline, color: subtitleColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "L'archivage automatique des documents de plus de 2 ans est géré par votre référent.",
                        style:
                        TextStyle(fontSize: 13, color: subtitleColor),
                      ),
                    ),
                  ]),
                ),
              ]),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _roleLabel(String role) {
    switch (role) {
      case 'manager':
        return 'Manager';
      case 'referent':
        return 'Référent';
      case 'technicien':
        return 'Technicien';
      default:
        return role.isNotEmpty ? role : '—';
    }
  }

  Widget _divider(bool isDark) => Divider(
      height: 1,
      color: isDark ? Colors.grey[800] : Colors.grey[200]);

  Widget _buildSectionTitle(String title, Color? color) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title.toUpperCase(),
      style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.8),
    ),
  );

  Widget _buildCard(Color cardColor, bool isDark,
      {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      Color primaryColor, Color? subtitleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: primaryColor),
        const SizedBox(width: 12),
        Text('$label :',
            style: TextStyle(fontSize: 13, color: subtitleColor)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right),
        ),
      ]),
    );
  }

  Widget _themeButton(
      BuildContext context, {
        required String label,
        required IconData icon,
        required bool selected,
        required VoidCallback onTap,
        required Color primaryColor,
        required Color cardColor,
        required bool isDark,
      }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? primaryColor
                : (isDark ? Colors.grey[800] : Colors.grey[100]),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 20,
                  color: selected
                      ? Colors.white
                      : (isDark ? Colors.grey[400] : Colors.grey[600])),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: selected
                        ? Colors.white
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}