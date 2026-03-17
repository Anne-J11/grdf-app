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

  // Liste blanche des extensions autorisées pour prévenir l'upload de scripts
  final List<String> _allowedExtensions = ['.jpg', '.jpeg', '.png', '.heic', '.webp'];

  Future<void> _ajouterPhoto(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 800,
      );

      if (image != null) {
        // VÉRIFICATION DE SÉCURITÉ : Extension du fichier
        final extension = p.extension(image.path).toLowerCase();
        if (!_allowedExtensions.contains(extension)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Format de fichier non autorisé (Scripts interdits)'), backgroundColor: Colors.red),
            );
          }
          return;
        }

        final bytes = await File(image.path).readAsBytes();
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
