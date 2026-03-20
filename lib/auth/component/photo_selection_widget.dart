// lib/auth/component/photo_selection_widget.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class PhotoSelectionWidget extends StatefulWidget {
  final List<String> initialPhotosBase64;
  final Function(List<String>) onPhotosChanged;
  final bool readOnly;
  final String label;

  const PhotoSelectionWidget({
    super.key,
    required this.initialPhotosBase64,
    required this.onPhotosChanged,
    this.label = 'Photos',
    this.readOnly = false,
  });

  @override
  State<PhotoSelectionWidget> createState() => _PhotoSelectionWidgetState();
}

class _PhotoSelectionWidgetState extends State<PhotoSelectionWidget> {
  late List<String> _photosBase64;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _photosBase64 = List.from(widget.initialPhotosBase64);
  }

  /// Vérifie si le fichier est un script malveillant.
  /// Analyse les Magic Numbers pour les formats d'image.
  /// Ne scanne les patterns de script QUE si le fichier ne ressemble pas à une image.
  Future<bool> _isActuallyScript(File file) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length < 12) return true; // Trop petit pour être une image ou un script utile

      // 1. Détection des Magic Numbers (Signatures binaires)
      bool isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8;
      bool isPng = bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47;
      bool isGif = bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46;
      bool isWebp = bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46; // RIFF
      
      // Signature HEIC/HEIF (Apple/Android moderne)
      String header12 = String.fromCharCodes(bytes.take(12));
      bool isHeic = header12.contains('ftypheic') || 
                    header12.contains('ftypheif') || 
                    header12.contains('ftypmif1') ||
                    header12.contains('ftyphevc');

      // SI C'EST UNE IMAGE CONNUE : On valide immédiatement (évite les faux positifs binaires)
      if (isJpeg || isPng || isGif || isWebp || isHeic) {
        return false;
      }

      // 2. SI CE N'EST PAS UNE IMAGE CONNUE : On cherche des traces de script
      final content = String.fromCharCodes(bytes.take(2048)).toLowerCase();
      final suspiciousPatterns = [
        '<?php', '<script', 'javascript:', 'eval(', 'exec(', 'system(', 
        'chmod ', 'chown ', 'base64_decode'
      ];

      for (var pattern in suspiciousPatterns) {
        if (content.contains(pattern)) {
          return true; // Script détecté
        }
      }

      // Par sécurité, si ce n'est ni une image connue ni un script identifié,
      // on vérifie l'extension. Si c'est une extension image, on accepte.
      final ext = p.extension(file.path).toLowerCase();
      if (['.jpg', '.jpeg', '.png', '.heic', '.webp'].contains(ext)) {
        return false;
      }

      return true; // Fichier inconnu ou suspect
    } catch (e) {
      return true; // Erreur = Sécurité max (blocage)
    }
  }

  Future<void> _ajouterPhoto(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 800,
      );

      if (image != null) {
        final file = File(image.path);
        
        // VÉRIFICATION DE SÉCURITÉ AMÉLIORÉE
        bool isScript = await _isActuallyScript(file);
        
        if (isScript) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fichier refusé : Format non reconnu ou contenu suspect.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        setState(() {
          _photosBase64.add(base64String);
        });
        widget.onPhotosChanged(_photosBase64);
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout de la photo : $e');
    }
  }

  void _supprimerPhoto(int index) {
    setState(() {
      _photosBase64.removeAt(index);
    });
    widget.onPhotosChanged(_photosBase64);
  }

  void _afficherChoixPhoto() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: Color(0xFF33A1C9)),
                title: Text('Prendre une photo', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  Navigator.pop(ctx);
                  _ajouterPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF33A1C9)),
                title: Text('Choisir depuis la galerie', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  Navigator.pop(ctx);
                  _ajouterPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF4DB8D9) : const Color(0xFF33A1C9);
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(Icons.photo_library_outlined, size: 16, color: primaryColor),
              const SizedBox(width: 6),
              Text(
                '${widget.label}${_photosBase64.isNotEmpty ? ' (${_photosBase64.length})' : ''}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.grey[300] : Colors.black87,
                ),
              ),
            ]),
            if (!widget.readOnly)
              TextButton.icon(
                onPressed: _afficherChoixPhoto,
                icon: Icon(Icons.add_a_photo_outlined, size: 16, color: primaryColor),
                label: Text('Ajouter', style: TextStyle(fontSize: 12, color: primaryColor)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_photosBase64.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
            ),
            child: Column(children: [
              Icon(Icons.add_photo_alternate_outlined, size: 32, color: isDark ? Colors.grey[700] : Colors.grey[400]),
              const SizedBox(height: 6),
              Text('Aucune photo ajoutée', style: TextStyle(fontSize: 12, color: subtitleColor)),
            ]),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photosBase64.length + (widget.readOnly ? 0 : 1),
              itemBuilder: (ctx, i) {
                if (!widget.readOnly && i == _photosBase64.length) {
                  return GestureDetector(
                    onTap: _afficherChoixPhoto,
                    child: Container(
                      width: 90,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                      ),
                      child: Icon(Icons.add_a_photo_outlined, color: isDark ? Colors.grey[700] : Colors.grey[400], size: 28),
                    ),
                  );
                }
                return _buildPhotoThumbnail(i, isDark);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoThumbnail(int index, bool isDark) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              base64Decode(_photosBase64[index]),
              fit: BoxFit.cover,
            ),
          ),
          if (!widget.readOnly)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _supprimerPhoto(index),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
