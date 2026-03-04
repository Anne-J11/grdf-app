// lib/core/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/user_provider.dart';
import '../services/archive_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isArchiving = false;
  String? _lastArchiveMessage;

  Future<void> _archiverManuellement() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.archive_outlined, color: Colors.orange[700]),
            const SizedBox(width: 10),
            const Text('Archivage manuel'),
          ],
        ),
        content: const Text(
          'Cette action archivera tous les briefs et débriefs de plus de 2 ans.\n\n'
          'Ils resteront en base mais ne seront plus visibles dans les listes. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF33A1C9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Archiver'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isArchiving = true;
      _lastArchiveMessage = null;
    });
    try {
      await ArchiveService().lancerArchivageAutomatique();
      setState(() => _lastArchiveMessage = 'Archivage effectué avec succès ✅');
    } catch (e) {
      setState(() => _lastArchiveMessage = 'Erreur : $e');
    } finally {
      setState(() => _isArchiving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF33A1C9),
        title: const Text('Paramètres', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Mon compte ───────────────────────────────────────────
            _buildSectionTitle('Mon compte'),
            _buildCard(children: [
              _buildInfoRow(Icons.person_outline, 'Nom', user.nomComplet.isNotEmpty ? user.nomComplet : '—'),
              const Divider(height: 1),
              _buildInfoRow(Icons.badge_outlined, 'Rôle', user.isReferent ? 'Référent' : 'Technicien'),
              const Divider(height: 1),
              _buildInfoRow(Icons.business_outlined, 'Agence', user.agenceId.isNotEmpty ? user.agenceId : '—'),
            ]),
            const SizedBox(height: 28),

            // ── Archivage (référents uniquement) ─────────────────────
            if (user.isReferent) ...[
              _buildSectionTitle('Gestion des archives'),
              _buildCard(children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.archive_outlined, color: Colors.orange[700], size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('Archivage manuel',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Text(
                        'Archive manuellement tous les briefs et débriefs de plus de 2 ans. '
                        "L'archivage automatique se déclenche aussi au lancement de l'application.",
                        style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      if (_lastArchiveMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _lastArchiveMessage!.contains('Erreur')
                                ? Colors.red[50]
                                : Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _lastArchiveMessage!.contains('Erreur')
                                  ? Colors.red[200]!
                                  : Colors.green[200]!,
                            ),
                          ),
                          child: Text(
                            _lastArchiveMessage!,
                            style: TextStyle(
                              fontSize: 13,
                              color: _lastArchiveMessage!.contains('Erreur')
                                  ? Colors.red[700]
                                  : Colors.green[700],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isArchiving ? null : _archiverManuellement,
                          icon: _isArchiving
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.archive_outlined),
                          label: Text(_isArchiving ? 'Archivage en cours...' : "Lancer l'archivage"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ],

            if (!user.isReferent) ...[
              _buildSectionTitle('Archives'),
              _buildCard(children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Icon(Icons.info_outline, color: Colors.grey[500], size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "L'archivage automatique des documents de plus de 2 ans est géré par votre référent.",
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ),
                  ]),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
            color: Colors.grey[500], letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: const Color(0xFF33A1C9)),
        const SizedBox(width: 12),
        Text('$label :', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right),
        ),
      ]),
    );
  }
}
