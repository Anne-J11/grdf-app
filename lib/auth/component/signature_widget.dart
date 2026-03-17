// lib/auth/component/signature_widget.dart

import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

/// Widget de signature numérique (Pad de dessin)
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
    this.width = double.infinity,
    this.height = 120,
  });

  @override
  State<SignatureWidget> createState() => _SignatureWidgetState();
}

class _SignatureWidgetState extends State<SignatureWidget> {
  List<Offset?> _points = [];
  bool _hasDrawing = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSignatureBase64 != null) {
      _hasDrawing = true;
    }
  }

  void _clear() {
    setState(() {
      _points.clear();
      _hasDrawing = false;
    });
    widget.onSignatureChanged(null);
  }

  // Note: Pour une application réelle, on convertirait les points en Image/Base64 ici.
  // Pour cet exercice, nous allons simuler la capture de la signature par le nom du signataire
  // tout en offrant l'expérience visuelle d'un pad de dessin, comme demandé.
  void _onStrokeEnd() {
    if (_points.isNotEmpty) {
      _hasDrawing = true;
      final user = context.read<UserProvider>();
      final nom = widget.forceNom ?? user.nomComplet;
      widget.onSignatureChanged(nom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF4DB8D9) : const Color(0xFF33A1C9);
    final bgColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey[50]!;
    final textColor = isDark ? Colors.grey[300] : const Color(0xFF2C3E50);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.roleLabel,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
            ),
            if (!widget.readOnly && _hasDrawing)
              GestureDetector(
                onTap: _clear,
                child: Text('Effacer', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hasDrawing ? primaryColor : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
              width: _hasDrawing ? 1.5 : 1,
            ),
          ),
          child: widget.readOnly
              ? Center(
                  child: widget.initialSignatureBase64 != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_outlined, color: Colors.green, size: 30),
                            Text(widget.initialSignatureBase64!,
                                style: TextStyle(fontStyle: FontStyle.italic, color: isDark ? Colors.white70 : Colors.black54)),
                          ],
                        )
                      : Text('Non signé', style: TextStyle(color: Colors.grey)),
                )
              : Stack(
                  children: [
                    GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          RenderBox renderBox = context.findRenderObject() as RenderBox;
                          _points.add(renderBox.globalToLocal(details.globalPosition));
                        });
                      },
                      onPanEnd: (_) => _onStrokeEnd(),
                      child: CustomPaint(
                        painter: SignaturePainter(points: _points, color: isDark ? Colors.white : Colors.black),
                        size: Size.infinite,
                      ),
                    ),
                    if (!_hasDrawing)
                      Center(
                        child: Text(
                          'Signez ici',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;

  SignaturePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => oldDelegate.points != points;
}
