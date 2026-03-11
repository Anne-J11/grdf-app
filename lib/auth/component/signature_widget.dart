// lib/auth/component/signature_widget.dart
// Affiche le nom du signataire (utilisateur connecté) au lieu d'une zone de dessin.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

/// Widget de signature simplifié : affiche le rôle + le nom du signataire.
/// - [roleLabel]  : ex. "Référent" ou "Technicien"
/// - [forceNom]   : si fourni, écrase le nom du UserProvider
/// - [onSignatureChanged] : callback appelé avec le nom du signataire (ou null)
/// - [readOnly]   : true = lecture seule
class SignatureWidget extends StatefulWidget {
  final String roleLabel;
  final String? forceNom;
  final String? initialSignatureBase64; // conservé pour compatibilité
  final ValueChanged<String?> onSignatureChanged;
  final bool readOnly;
  final double width;
  final double height;

  const SignatureWidget({
    super.key,
    required this.roleLabel,
    required this.onSignatureChanged,
    this.forceNom,
    this.initialSignatureBase64,
    this.readOnly = false,
    this.width = 150,
    this.height = 90,
  });

  @override
  State<SignatureWidget> createState() => _SignatureWidgetState();
}

class _SignatureWidgetState extends State<SignatureWidget> {
  bool _aSigne = false;

  @override
  void initState() {
    super.initState();
    // Si une signature existante est fournie, considérer comme déjà signé
    if (widget.initialSignatureBase64 != null &&
        widget.initialSignatureBase64!.isNotEmpty) {
      _aSigne = true;
    }
  }

  String _resolveNom(UserProvider user) {
    if (widget.forceNom != null && widget.forceNom!.isNotEmpty) {
      return widget.forceNom!;
    }
    return user.nomComplet.isNotEmpty ? user.nomComplet : '—';
  }

  void _signer(String nom) {
    setState(() => _aSigne = true);
    widget.onSignatureChanged(nom); // on passe le nom comme valeur de signature
  }

  void _annuler() {
    setState(() => _aSigne = false);
    widget.onSignatureChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nom = _resolveNom(user);
    final primaryColor = isDark ? const Color(0xFF4DB8D9) : const Color(0xFF33A1C9);
    final bgColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey[50]!;
    final borderColor = _aSigne
        ? primaryColor
        : (isDark ? Colors.grey[600]! : Colors.grey[300]!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Label rôle
        Text(
          widget.roleLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.grey[300] : const Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 4),

        // ── Boîte signature
        Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: _aSigne ? 1.5 : 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _aSigne ? Icons.verified_user_outlined : Icons.person_outline,
                size: 16,
                color: _aSigne ? Colors.green[600] : (isDark ? Colors.grey[400] : Colors.grey[500]),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nom,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _aSigne ? FontWeight.w600 : FontWeight.normal,
                    color: _aSigne
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!widget.readOnly) ...[
                const SizedBox(width: 6),
                if (!_aSigne)
                  GestureDetector(
                    onTap: () => _signer(nom),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Signer',
                        style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _annuler,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 11, color: Colors.white),
                    ),
                  ),
              ],
            ],
          ),
        ),

        // ── Indicateur signé
        if (_aSigne) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 10, color: Colors.green[500]),
              const SizedBox(width: 3),
              Text('Signé',
                  style: TextStyle(fontSize: 9, color: Colors.green[500])),
            ],
          ),
        ],
      ],
    );
  }
}