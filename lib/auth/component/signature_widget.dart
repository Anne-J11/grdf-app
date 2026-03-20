// lib/auth/component/signature_widget.dart

import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

/// Widget de signature numérique (Pad de dessin avec agrandissement plein écran)
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
  bool _hasDrawing = false;
  String? _signedName;

  @override
  void initState() {
    super.initState();
    if (widget.initialSignatureBase64 != null) {
      _hasDrawing = true;
      _signedName = widget.initialSignatureBase64;
    }
  }

  void _clear() {
    setState(() {
      _hasDrawing = false;
      _signedName = null;
    });
    widget.onSignatureChanged(null);
  }

  Future<void> _openSignatureDialog() async {
    if (widget.readOnly) return;

    final result = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _FullscreenSignatureDialog(
          roleLabel: widget.roleLabel,
          forceNom: widget.forceNom,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _hasDrawing = true;
        _signedName = result;
      });
      widget.onSignatureChanged(result);
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
                child: const Text('Effacer', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: widget.readOnly ? null : _openSignatureDialog,
          borderRadius: BorderRadius.circular(12),
          child: Container(
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
            child: Center(
              child: _hasDrawing
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_outlined, color: Colors.green, size: 30),
                        const SizedBox(height: 4),
                        Text(
                          _signedName ?? '',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!widget.readOnly)
                          const Text(
                            '(Appuyer pour modifier)',
                            style: TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.draw_outlined, color: Colors.grey[400], size: 24),
                        const SizedBox(height: 4),
                        Text(
                          'Appuyer pour signer',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FullscreenSignatureDialog extends StatefulWidget {
  final String roleLabel;
  final String? forceNom;

  const _FullscreenSignatureDialog({
    required this.roleLabel,
    this.forceNom,
  });

  @override
  State<_FullscreenSignatureDialog> createState() => _FullscreenSignatureDialogState();
}

class _FullscreenSignatureDialogState extends State<_FullscreenSignatureDialog> {
  final List<Offset?> _points = [];

  void _clear() {
    setState(() {
      _points.clear();
    });
  }

  void _confirm() {
    if (_points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez signer avant de valider')),
      );
      return;
    }
    final user = context.read<UserProvider>();
    final nom = widget.forceNom ?? user.nomComplet;
    Navigator.of(context).pop(nom);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final padColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF33A1C9),
        title: Text('Signature ${widget.roleLabel}', style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _clear,
            tooltip: 'Effacer',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Veuillez signer ci-dessous',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: padColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        RenderBox renderBox = context.findRenderObject() as RenderBox;
                        _points.add(renderBox.globalToLocal(details.globalPosition));
                      });
                    },
                    onPanEnd: (_) => _points.add(null),
                    child: CustomPaint(
                      painter: SignaturePainter(
                        points: _points,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  onPressed: _confirm,
                  child: const Text(
                    'Valider la signature',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
      ..strokeWidth = 4.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => oldDelegate.points != points;
}
