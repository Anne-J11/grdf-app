// lib/auth/component/signature_widget.dart
// Widget de signature digitale tactile.
// Récupère automatiquement le nom et le rôle de l'utilisateur connecté
// via UserProvider pour les afficher sous la zone de signature.

import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modèle interne d'un point de tracé
// ─────────────────────────────────────────────────────────────────────────────
class _SignaturePoint {
  final Offset? offset; // null = fin de trait
  _SignaturePoint(this.offset);
}

// ─────────────────────────────────────────────────────────────────────────────
// Painter
// ─────────────────────────────────────────────────────────────────────────────
class _SignaturePainter extends CustomPainter {
  final List<_SignaturePoint> points;

  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].offset != null && points[i + 1].offset != null) {
        canvas.drawLine(points[i].offset!, points[i + 1].offset!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget principal
// ─────────────────────────────────────────────────────────────────────────────

/// Signature digitale tactile adaptée à l'utilisateur connecté.
///
/// Paramètres :
/// - [roleLabel]  : ex. "Référent" ou "Technicien" — affiché comme titre
/// - [forceNom]   : si non null, écrase le nom du UserProvider (utile pour
///                  la signature technicien dont on ne connaît pas le compte)
/// - [initialSignatureBase64] : signature déjà existante (mode lecture)
/// - [onSignatureChanged] : callback avec la valeur base64 (null si effacée)
/// - [readOnly]   : true = lecture seule (brief verrouillé)
/// - [width] / [height] : dimensions de la vignette miniature
class SignatureWidget extends StatefulWidget {
  final String roleLabel;
  final String? forceNom;
  final String? initialSignatureBase64;
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
  String? _currentBase64;
  bool _hasSigned = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSignatureBase64 != null &&
        widget.initialSignatureBase64!.isNotEmpty) {
      _currentBase64 = widget.initialSignatureBase64;
      _hasSigned = true;
    }
  }

  String _resolveNom(UserProvider user) {
    if (widget.forceNom != null && widget.forceNom!.isNotEmpty) {
      return widget.forceNom!;
    }
    return user.nomComplet.isNotEmpty ? user.nomComplet : '—';
  }

  String _resolveRole(UserProvider user) => widget.roleLabel;

  void _clear() {
    setState(() {
      _currentBase64 = null;
      _hasSigned = false;
    });
    widget.onSignatureChanged(null);
  }

  void _openDialog(UserProvider user) {
    if (widget.readOnly) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SignatureDialog(
        roleLabel: _resolveRole(user),
        nomUtilisateur: _resolveNom(user),
        onConfirm: (b64) {
          setState(() {
            _currentBase64 = b64;
            _hasSigned = b64 != null && b64.isNotEmpty;
          });
          widget.onSignatureChanged(b64);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nom = _resolveNom(user);
    final role = _resolveRole(user);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Label rôle ──────────────────────────────────────────────────────
        Text(
          role,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.grey[300] : const Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 2),
        // ── Nom de l'utilisateur ────────────────────────────────────────────
        Text(
          nom,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),

        // ── Zone de signature (vignette) ────────────────────────────────────
        GestureDetector(
          onTap: () => _openDialog(user),
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hasSigned
                    ? const Color(0xFF33A1C9)
                    : (isDark ? Colors.grey[600]! : Colors.grey[300]!),
                width: _hasSigned ? 1.5 : 1.0,
              ),
            ),
            child: _hasSigned && _currentBase64 != null
                ? Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.memory(
                  base64Decode(_currentBase64!),
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              if (!widget.readOnly)
                Positioned(
                  top: 3,
                  right: 3,
                  child: GestureDetector(
                    onTap: _clear,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 11, color: Colors.white),
                    ),
                  ),
                ),
            ])
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.readOnly
                      ? Icons.lock_outline
                      : Icons.draw_outlined,
                  size: 20,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.readOnly ? 'Non signé' : 'Appuyer pour signer',
                  style: TextStyle(
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                    color:
                    isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Indicateur "Signé" ──────────────────────────────────────────────
        if (_hasSigned) ...[
          const SizedBox(height: 3),
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

// ─────────────────────────────────────────────────────────────────────────────
// Dialog plein écran de saisie de signature
// ─────────────────────────────────────────────────────────────────────────────
class _SignatureDialog extends StatefulWidget {
  final String roleLabel;
  final String nomUtilisateur;
  final ValueChanged<String?> onConfirm;

  const _SignatureDialog({
    required this.roleLabel,
    required this.nomUtilisateur,
    required this.onConfirm,
  });

  @override
  State<_SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<_SignatureDialog> {
  final List<_SignaturePoint> _points = [];
  final GlobalKey _repaintKey = GlobalKey();
  bool _hasSigned = false;

  Future<String?> _export() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final bytes =
      await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return null;
      return base64Encode(bytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  void _clear() => setState(() {
    _points.clear();
    _hasSigned = false;
  });

  Future<void> _confirm() async {
    if (!_hasSigned) return;
    final b64 = await _export();
    if (mounted) {
      Navigator.pop(context);
      widget.onConfirm(b64);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête ────────────────────────────────────────────────────
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF33A1C9).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.draw_outlined,
                    color: Color(0xFF33A1C9), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.roleLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF33A1C9),
                      ),
                    ),
                    Text(
                      widget.nomUtilisateur,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              'Tracez votre signature ci-dessous',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),

            // ── Zone de dessin ─────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hasSigned
                      ? const Color(0xFF33A1C9)
                      : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              height: 200,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: GestureDetector(
                    onPanUpdate: (d) => setState(() {
                      _points.add(_SignaturePoint(d.localPosition));
                      _hasSigned = true;
                    }),
                    onPanEnd: (_) => setState(
                            () => _points.add(_SignaturePoint(null))),
                    child: Container(
                      color: Colors.white,
                      child: CustomPaint(
                        painter: _SignaturePainter(_points),
                        child: _points.isEmpty
                            ? Center(
                          child: Text(
                            'Signez ici',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Actions ────────────────────────────────────────────────────
            Row(children: [
              OutlinedButton.icon(
                onPressed: _clear,
                icon: const Icon(Icons.refresh, size: 15),
                label: const Text('Effacer',
                    style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[500])),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _hasSigned ? _confirm : null,
                icon: const Icon(Icons.check, size: 15),
                label: const Text('Valider',
                    style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF33A1C9),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[200],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}