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

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? selectedRole;
  String? selectedAgenceId;
  String? selectedSiteId;

  final List<String> roles = ['referent', 'technicien', 'manager'];
  List<AgenceModel> agences = [];
  List<SiteModel> sites = [];

  bool isLoading = false;
  bool isLoadingAgences = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

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

  Future<void> _loadAgences() async {
    try {
      final loadedAgences = await _firestoreService.getAgences();
      setState(() {
        agences = loadedAgences;
        isLoadingAgences = false;
      });
    } catch (e) {
      _showError('Erreur lors du chargement des agences');
      setState(() => isLoadingAgences = false);
    }
  }

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

  Future<void> _register() async {
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

    setState(() => isLoading = true);
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
        context.read<UserProvider>().setUser(registeredUser);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Inscription réussie !'),
              backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryColor = isDark ? const Color(0xFF4DB8D9) : const Color(0xFF33A1C9);
    final labelColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final borderColor = isDark ? Colors.grey[600]! : Colors.grey[400]!;
    final inputFillColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final dropdownTextColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Inscription', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF33A1C9),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Veuillez vous inscrire',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor),
              ),
              Container(
                  margin: const EdgeInsets.only(top: 2),
                  height: 4,
                  width: 70,
                  color: Colors.orange),
              const SizedBox(height: 30),

              // ── Carte formulaire ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: primaryColor.withOpacity(0.5), width: 1),
                  boxShadow: isDark
                      ? []
                      : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  children: [
                    Image.asset('assets/img/logo.png',
                        height: 50,
                        errorBuilder: (_, __, ___) => Icon(Icons.image,
                            size: 50, color: Colors.grey[400])),
                    const SizedBox(height: 20),

                    _buildLabel('Nom *', labelColor),
                    _buildTextField(
                        controller: _nomController,
                        hint: 'Entrez votre nom',
                        fillColor: inputFillColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        primaryColor: primaryColor),
                    const SizedBox(height: 15),

                    _buildLabel('Prénom *', labelColor),
                    _buildTextField(
                        controller: _prenomController,
                        hint: 'Entrez votre prénom',
                        fillColor: inputFillColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        primaryColor: primaryColor),
                    const SizedBox(height: 15),

                    _buildLabel('Email *', labelColor),
                    _buildTextField(
                        controller: _emailController,
                        hint: 'exemple@mail.com',
                        keyboardType: TextInputType.emailAddress,
                        fillColor: inputFillColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        primaryColor: primaryColor),
                    const SizedBox(height: 15),

                    // Rôle
                    _buildLabel('Rôle *', labelColor),
                    _buildDropdown<String>(
                      value: selectedRole,
                      hint: 'Sélectionnez un rôle',
                      items: roles
                          .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(
                          r == 'referent'
                              ? 'Référent'
                              : r == 'manager'
                              ? 'Manager'
                              : 'Technicien',
                          style: TextStyle(color: dropdownTextColor),
                        ),
                      ))
                          .toList(),
                      onChanged: (val) => setState(() => selectedRole = val),
                      fillColor: inputFillColor,
                      borderColor: borderColor,
                      textColor: dropdownTextColor,
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 15),

                    // Agence
                    _buildLabel('Agence *', labelColor),
                    isLoadingAgences
                        ? Center(
                        child: CircularProgressIndicator(
                            color: primaryColor))
                        : _buildDropdown<String>(
                      value: selectedAgenceId,
                      hint: 'Sélectionnez une agence',
                      items: agences
                          .map((a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(a.nom,
                            style: TextStyle(
                                color: dropdownTextColor)),
                      ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedAgenceId = val;
                          sites = [];
                          selectedSiteId = null;
                        });
                        if (val != null) _loadSites(val);
                      },
                      fillColor: inputFillColor,
                      borderColor: borderColor,
                      textColor: dropdownTextColor,
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 15),

                    // Site
                    _buildLabel('Site *', labelColor),
                    _buildDropdown<String>(
                      value: selectedSiteId,
                      hint: selectedAgenceId == null
                          ? 'Choisir d\'abord une agence'
                          : sites.isEmpty
                          ? 'Chargement...'
                          : 'Sélectionnez un site',
                      items: sites
                          .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.nom,
                            style:
                            TextStyle(color: dropdownTextColor)),
                      ))
                          .toList(),
                      onChanged: selectedAgenceId == null
                          ? null
                          : (val) => setState(() => selectedSiteId = val),
                      fillColor: inputFillColor,
                      borderColor: borderColor,
                      textColor: dropdownTextColor,
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 15),

                    // Mot de passe
                    _buildLabel('Mot de passe *', labelColor),
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Minimum 6 caractères',
                      obscureText: _obscurePassword,
                      fillColor: inputFillColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      primaryColor: primaryColor,
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: labelColor,
                            size: 20),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Confirmer mot de passe
                    _buildLabel('Confirmer le mot de passe *', labelColor),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hint: 'Retapez votre mot de passe',
                      obscureText: _obscureConfirm,
                      fillColor: inputFillColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      primaryColor: primaryColor,
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: labelColor,
                            size: 20),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Boutons
                    isLoading
                        ? CircularProgressIndicator(color: primaryColor)
                        : Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text("S'inscrire",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                          ),
                          child: Text('Déjà un compte ? Se connecter',
                              style: TextStyle(
                                  color: primaryColor, fontSize: 13)),
                        ),
                      ],
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

  Widget _buildLabel(String text, Color color) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 14, fontWeight: FontWeight.w500)),
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required Color fillColor,
    required Color borderColor,
    required Color textColor,
    required Color primaryColor,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: textColor.withOpacity(0.4), fontSize: 13),
        isDense: true,
        filled: true,
        fillColor: fillColor,
        suffixIcon: suffixIcon,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primaryColor, width: 1.5)),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    required Color fillColor,
    required Color borderColor,
    required Color textColor,
    required Color primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint,
              style: TextStyle(
                  color: textColor.withOpacity(0.4), fontSize: 13)),
          isExpanded: true,
          isDense: true,
          dropdownColor: fillColor,
          style: TextStyle(color: textColor, fontSize: 14),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}