import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grdf_app/auth/screens/registration_screen.dart';
import 'package:grdf_app/home/screens/home_screen.dart';
import 'package:grdf_app/auth/services/auth_service.dart';
import 'package:grdf_app/auth/providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    try {
      final userModel = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        // Stocker l'utilisateur dans le Provider global
        context.read<UserProvider>().setUser(userModel);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Bienvenue', style: TextStyle(color: Colors.white)),
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
                'Veuillez vous connecter',
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
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFF33A1C9).withOpacity(0.5), width: 1),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/img/logo.png',
                      height: 50,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 50),
                    ),
                    const SizedBox(height: 35),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Email', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: "name@exemple.com",
                        isDense: true,
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Mot de passe', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: "••••••••",
                        isDense: true,
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                      ),
                    ),
                    const SizedBox(height: 40),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF33A1C9),
                              minimumSize: const Size(180, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Se connecter',
                              style: TextStyle(color: Colors.white, fontSize: 20),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('pas encore de compte? ', style: TextStyle(fontSize: 12)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                      );
                    },
                    child: const Text(
                      'Créer un compte',
                      style: TextStyle(
                        color: Color(0xFF33A1C9),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
