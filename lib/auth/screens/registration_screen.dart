// lib/auth/screens/registration_screen.dart

import 'package:flutter/material.dart';
import 'package:grdf_app/auth/screens/login_screen.dart';
import 'package:grdf_app/home/screens/home_screen.dart';
import 'package:grdf_app/auth/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:grdf_app/auth/providers/user_provider.dart';
import 'package:grdf_app/firestore_service.dart';
import 'package:grdf_app/auth/models/agence_model.dart';
import 'package:grdf_app/auth/models/site_model.dart';
import '../component/custom_button.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  // Services
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // Controllers
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Sélections
  String? selectedRole;
  String? selectedAgenceId;
  String? selectedSiteId;

  // Listes
  final List<String> roles = ['referent', 'technicien', 'manager'];
  List<AgenceModel> agences = [];
  List<SiteModel> sites = [];

  // États de chargement
  bool isLoading = false;
  bool isLoadingAgences = true;

  @override
  void initState() {
    super.initState();
    _loadAgences();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Charger les agences
  Future<void> _loadAgences() async {
    try {
      final loadedAgences = await _firestoreService.getAgences();
      setState(() {
        agences = loadedAgences;
        isLoadingAgences = false;
      });
    } catch (e) {
      _showError('Erreur lors du chargement des agences');
      setState(() {
        isLoadingAgences = false;
      });
    }
  }

  // Charger les sites d'une agence
  Future<void> _loadSites(String agenceId) async {
    try {
      final loadedSites = await _firestoreService.getSitesByAgence(agenceId);
      setState(() {
        sites = loadedSites;
        selectedSiteId = null;
      });
    } catch (e) {
      _showError('Erreur lors du chargement des sites');
    }
  }

  // Fonction d'inscription
  Future<void> _register() async {
    // Validation
    if (_nomController.text.trim().isEmpty ||
        _prenomController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        selectedRole == null ||
        selectedAgenceId == null ||
        selectedSiteId == null) {
      _showError('Veuillez remplir tous les champs');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Les mots de passe ne correspondent pas');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('Le mot de passe doit contenir au moins 6 caractères');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final registeredUser = await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        role: selectedRole!,
        agenceId: selectedAgenceId!,
        siteId: selectedSiteId!,
      );

      if (mounted) {
        // Stocker l'utilisateur dans le Provider global
        context.read<UserProvider>().setUser(registeredUser);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription réussie ! ✅'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Inscription', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF33A1C9),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Veuillez vous inscrire',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF33A1C9),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 2),
                height: 4,
                width: 70,
                color: Colors.orange,
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: const Color(0xFF33A1C9).withOpacity(0.5),
                      width: 1),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/img/logo.png',
                      height: 50,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image, size: 50),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Nom *'),
                    _buildTextField(
                      controller: _nomController,
                      hintText: 'Entrez votre nom',
                    ),
                    const SizedBox(height: 15),

                    _buildLabel('Prénom *'),
                    _buildTextField(
                      controller: _prenomController,
                      hintText: 'Entrez votre prénom',
                    ),
                    const SizedBox(height: 15),

                    _buildLabel('Email *'),
                    _buildTextField(
                      controller: _emailController,
                      hintText: 'exemple@mail.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 15),

                    _buildLabel('Rôle *'),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      hint: const Text('Sélectionnez un rôle'),
                      decoration: _dropdownDecoration(),
                      items: roles.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role == 'referent' ? 'Référent' : role == 'manager' ? 'Manager' : 'Technicien'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value;
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    _buildLabel('Agence *'),
                    isLoadingAgences
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                      value: selectedAgenceId,
                      hint: const Text('Sélectionnez une agence'),
                      decoration: _dropdownDecoration(),
                      items: agences.map((agence) {
                        return DropdownMenuItem(
                          value: agence.id,
                          child: Text(agence.nom),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedAgenceId = value;
                          if (value != null) {
                            _loadSites(value);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    _buildLabel('Site *'),
                    DropdownButtonFormField<String>(
                      value: selectedSiteId,
                      hint: Text(
                        selectedAgenceId == null
                            ? 'Choisir d\'abord une agence'
                            : 'Sélectionnez un site',
                      ),
                      decoration: _dropdownDecoration(),
                      items: sites.map((site) {
                        return DropdownMenuItem(
                          value: site.id,
                          child: Text(site.nom),
                        );
                      }).toList(),
                      onChanged: selectedAgenceId == null
                          ? null
                          : (value) {
                        setState(() {
                          selectedSiteId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    _buildLabel('Mot de passe *'),
                    _buildTextField(
                      controller: _passwordController,
                      obscureText: true,
                      hintText: 'Minimum 6 caractères',
                    ),
                    const SizedBox(height: 15),

                    _buildLabel('Confirmer le mot de passe *'),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      hintText: 'Retapez votre mot de passe',
                    ),
                    const SizedBox(height: 30),

                    if (isLoading)
                      const CircularProgressIndicator()
                    else
                      CustomButton(
                        elevatedButtonText: 'S\'inscrire',
                        textButtonText: 'Déjà un compte? Se connecter',
                        elevatedButtonClicked: _register,
                        textButtonClicked: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(text,
            style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ),
    );
  }

  Widget _buildTextField({
    bool obscureText = false,
    String? hintText,
    TextInputType? keyboardType,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        isDense: true,
        border: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black)),
        enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black)),
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return const InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
      enabledBorder:
      OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
    );
  }
}