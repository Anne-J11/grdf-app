// lib/auth/component/photo_selection_widget.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Formats acceptés affichés à l'utilisateur.
const List<String> _formatsAcceptes = ['.jpg', '.jpeg', '.png', '.webp', '.heic'];

// Taille maximale : 10 Mo (en octets).
const int _tailleMaxOctets = 10 * 1024 * 1024;

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
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _photosBase64 = List.from(widget.initialPhotosBase64);
  }

  // ── Validation ───────────────────────────────────────────────────────────
  //
  // On utilise exclusivement xfile.readAsBytes() et xfile.openRead() —
  // jamais dart:io File.open() — car les chemins temporaires produits par
  // image_picker sur Android/iOS fonctionnent toujours avec l'API XFile,
  // alors que RandomAccessFile peut lever une exception sur ces chemins.
  //
  // image_picker avec imageQuality < 100 re-encode toujours le résultat en
  // JPEG dans un fichier cache. Sans imageQuality, il copie le fichier natif
  // (HEIC sur iPhone, JPEG/PNG sur Android). Dans les deux cas l'API XFile
  // fonctionne. On vérifie les magic bytes uniquement pour détecter les cas
  // aberrants (script injecté), pas pour filtrer des images normales.

  /// Retourne null si le fichier est accepté, ou un message d'erreur sinon.
  Future<String?> _verifierFichier(XFile xfile) async {
    // 1. Taille
    final taille = await xfile.length();
    if (taille > _tailleMaxOctets) {
      final mo = (taille / (1024 * 1024)).toStringAsFixed(1);
      return 'Fichier trop volumineux : $mo Mo (max 10 Mo).';
    }

    // 2. Lecture des 16 premiers octets via openRead (fonctionne sur XFile)
    List<int> header;
    try {
      final chunks = await xfile.openRead(0, 16).toList();
      header = chunks.expand((c) => c).toList();
    } catch (e) {
      // Si on ne peut même pas lire le header, on rejette avec message précis.
      return 'Impossible de lire le fichier : $e';
    }

    if (header.length < 3) {
      return 'Fichier vide ou corrompu (${header.length} octet(s) lus).';
    }

    // 3. Vérification des magic bytes des formats acceptés

    // JPEG : FF D8 FF
    if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF) {
      return null;
    }

    // PNG : 89 50 4E 47
    if (header.length >= 4 &&
        header[0] == 0x89 && header[1] == 0x50 &&
        header[2] == 0x4E && header[3] == 0x47) {
      return null;
    }

    // WebP : RIFF????WEBP
    if (header.length >= 12 &&
        header[0] == 0x52 && header[1] == 0x49 &&
        header[2] == 0x46 && header[3] == 0x46 &&
        header[8] == 0x57 && header[9] == 0x45 &&
        header[10] == 0x42 && header[11] == 0x50) {
      return null;
    }

    // HEIC/HEIF : ????ftyp<brand>
    if (header.length >= 12 &&
        header[4] == 0x66 && header[5] == 0x74 &&
        header[6] == 0x79 && header[7] == 0x70) {
      final brand = String.fromCharCodes(header.sublist(8, 12)).toLowerCase();
      const heicBrands = {
        'heic', 'heif', 'mif1', 'msf1', 'hevc',
        'heix', 'hevx', 'heim', 'heis', 'hevm', 'hevs',
      };
      if (heicBrands.contains(brand)) return null;
      return 'Format conteneur non supporté (type : $brand).\n'
          'Formats acceptés : ${_formatsAcceptes.join(", ")}';
    }

    // GIF : GIF8
    if (header.length >= 4 &&
        header[0] == 0x47 && header[1] == 0x49 &&
        header[2] == 0x46 && header[3] == 0x38) {
      return null;
    }

    // BMP : BM
    if (header[0] == 0x42 && header[1] == 0x4D) {
      return null;
    }

    // 4. Fallback extension : image_picker peut retourner un chemin cache
    //    sans extension reconnue (ex. "/data/.../image_picker_123456").
    //    Dans ce cas on fait confiance à image_picker.
    final pathLower = xfile.path.toLowerCase();
    const extensionsOk = {
      '.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif',
      '.bmp', '.gif', '.tif', '.tiff',
    };
    for (final ext in extensionsOk) {
      if (pathLower.endsWith(ext)) return null;
    }

    // 5. Dernier filet de sécurité : détecter les scripts uniquement.
    //    Les octets ASCII imprimables du header ne doivent pas former
    //    des mots-clés de scripts connus. On n'utilise PAS ce test pour
    //    rejeter des images inconnues — uniquement pour des scripts évidents.
    if (header.length >= 5) {
      final texte = String.fromCharCodes(
        header.where((b) => b >= 0x20 && b < 0x80),
      ).toLowerCase();
      const scripts = ['<?php', '<script', 'javascript:', 'eval(', 'exec('];
      for (final s in scripts) {
        if (texte.contains(s)) {
          return 'Fichier refusé : contenu suspect détecté.';
        }
      }
    }

    // Magic bytes non reconnus mais pas un script.
    // image_picker ne produit jamais de fichier non-image → on accepte.
    return null;
  }

  // ── Ajout d'une photo ────────────────────────────────────────────────────

  Future<void> _ajouterPhoto(ImageSource source) async {
    XFile? xfile;
    try {
      xfile = await _picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 800,
      );
    } catch (e) {
      if (mounted) _snackErreur('Erreur caméra/galerie : $e');
      return;
    }

    if (xfile == null) return; // annulé

    final erreur = await _verifierFichier(xfile);
    if (erreur != null) {
      if (mounted) _snackErreur(erreur);
      return;
    }

    try {
      final bytes = await xfile.readAsBytes();
      final b64 = base64Encode(bytes);
      if (mounted) {
        setState(() => _photosBase64.add(b64));
        widget.onPhotosChanged(_photosBase64);
      }
    } catch (e) {
      if (mounted) _snackErreur('Erreur de lecture du fichier : $e');
    }
  }

  void _snackErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 5),
    ));
  }

  void _supprimerPhoto(int index) {
    setState(() => _photosBase64.removeAt(index));
    widget.onPhotosChanged(_photosBase64);
  }

  void _afficherChoixSource() {
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
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 16, right: 16),
                child: Text(
                  'Formats : ${_formatsAcceptes.join("  ·  ")}',
                  style: TextStyle(
                    fontSize: 11, fontStyle: FontStyle.italic,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined,
                    color: Color(0xFF33A1C9)),
                title: Text('Prendre une photo',
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  Navigator.pop(ctx);
                  _ajouterPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: Color(0xFF33A1C9)),
                title: Text('Choisir depuis la galerie',
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87)),
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

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
    isDark ? const Color(0xFF4DB8D9) : const Color(0xFF33A1C9);
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(Icons.photo_library_outlined, size: 16, color: primaryColor),
              const SizedBox(width: 6),
              Text(
                '${widget.label}'
                    '${_photosBase64.isNotEmpty ? " (${_photosBase64.length})" : ""}',
                style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13,
                  color: isDark ? Colors.grey[300] : Colors.black87,
                ),
              ),
            ]),
            if (!widget.readOnly)
              TextButton.icon(
                onPressed: _afficherChoixSource,
                icon: Icon(Icons.add_a_photo_outlined,
                    size: 16, color: primaryColor),
                label: Text('Ajouter',
                    style: TextStyle(fontSize: 12, color: primaryColor)),
                style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Zone photos
        if (_photosBase64.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
            ),
            child: Column(children: [
              Icon(Icons.add_photo_alternate_outlined,
                  size: 32,
                  color: isDark ? Colors.grey[700] : Colors.grey[400]),
              const SizedBox(height: 6),
              Text('Aucune photo ajoutée',
                  style: TextStyle(fontSize: 12, color: subtitleColor)),
              const SizedBox(height: 4),
              Text(
                _formatsAcceptes.join('  ·  '),
                style: TextStyle(
                    fontSize: 10, fontStyle: FontStyle.italic,
                    color: isDark ? Colors.grey[700] : Colors.grey[400]),
              ),
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
                    onTap: _afficherChoixSource,
                    child: Container(
                      width: 90,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: isDark
                                ? Colors.grey[800]!
                                : Colors.grey[300]!),
                      ),
                      child: Icon(Icons.add_a_photo_outlined,
                          color: isDark
                              ? Colors.grey[700]
                              : Colors.grey[400],
                          size: 28),
                    ),
                  );
                }
                return _buildThumbnail(i, isDark);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildThumbnail(int index, bool isDark) {
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
              errorBuilder: (_, __, ___) => Container(
                color: isDark ? Colors.grey[900] : Colors.grey[200],
                child: Icon(Icons.broken_image_outlined,
                    color: Colors.grey[400], size: 24),
              ),
            ),
          ),
          if (!widget.readOnly)
            Positioned(
              top: 4, right: 4,
              child: GestureDetector(
                onTap: () => _supprimerPhoto(index),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}