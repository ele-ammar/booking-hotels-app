// lib/screens/login_screen.dart
import 'package:booking/views/screens/user_home_screen.dart';
import 'package:booking/views/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:booking/core/constants/app_colors.dart';
import 'package:provider/provider.dart';

import '../../controllers/hotel_card_controller.dart' show HotelCardController;
import '../../core/constants/app_strings.dart';
import '../../widgets/custom_text_field.dart';
import 'admin/admin_home_screen.dart';
import 'signup_screen.dart';
import '../../controllers/auth_controller.dart'; // We'll instantiate it directly
import '../../models/user.dart'; // Ensure User model has `role` & `isAdmin`

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 🔹 Local state (no provider!)
  bool _isLoading = false;
  String? _authError;

  // 🔹 Instantiate controller directly (singleton or per-screen — both ok for auth)
  final AuthController _authController = AuthController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 🔑 Identical forgot password flow — just use _authController directly
  Future<void> _showForgotPasswordFlow(BuildContext context) async {
    // Étape 1 : Saisir l'email
    final emailController = TextEditingController();
    final emailFormKey = GlobalKey<FormState>();

    String? validateEmail(String? value) {
      if (value == null || value.isEmpty) return 'Email requis';
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!emailRegex.hasMatch(value)) return 'Format email invalide';
      return null;
    }

    bool? emailSubmitted = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Réinitialisation mot de passe'),
              content: Form(
                key: emailFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Entrez votre email pour recevoir un code de réinitialisation.', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: 'Votre email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: validateEmail,
                      onChanged: (_) => setState(() => _authError = null),
                    ),
                    const SizedBox(height: 12),
                    if (_authError != null)
                      Text(_authError!, style: TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Annuler')),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                    if (emailFormKey.currentState!.validate()) {
                      setState(() => _isLoading = true);
                      final success = await _authController.forgotPassword(emailController.text.trim());
                      setState(() => _isLoading = false);
                      if (success) {
                        Navigator.pop(ctx, true);
                      } else {
                        setState(() => _authError = _authController.authError);
                      }
                    }
                  },
                  child: _isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white)),
                  )
                      : Text('Envoyer le code'),
                ),
              ],
            );
          },
        );
      },
    );

    if (emailSubmitted != true) return;

    // Étape 2 : Saisir code + nouveau mot de passe
    final codeController = TextEditingController();
    final passwordController = TextEditingController();
    final passwordConfirmController = TextEditingController();
    final resetFormKey = GlobalKey<FormState>();

    String? validateCode(String? value) =>
        (value == null || value.isEmpty) ? 'Code requis' :
        (value.length != 6 || !RegExp(r'^\d{6}$').hasMatch(value)) ? 'Code à 6 chiffres' : null;

    String? validatePassword(String? value) =>
        (value == null || value.isEmpty) ? 'Mot de passe requis' :
        (value.length < 6) ? 'Au moins 6 caractères' : null;

    String? validatePasswordMatch(String? value) =>
        passwordController.text != passwordConfirmController.text ? 'Les mots de passe ne correspondent pas' : null;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Nouveau mot de passe'),
              content: Form(
                key: resetFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: codeController,
                      decoration: InputDecoration(
                        hintText: 'Code à 6 chiffres',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: validateCode,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => resetFormKey.currentState?.validate(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        hintText: 'Nouveau mot de passe',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      validator: validatePassword,
                      obscureText: true,
                      onChanged: (_) => resetFormKey.currentState?.validate(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordConfirmController,
                      decoration: InputDecoration(
                        hintText: 'Confirmer le mot de passe',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: validatePasswordMatch,
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    if (_authError != null)
                      Text(_authError!, style: TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                    if (resetFormKey.currentState!.validate()) {
                      setState(() => _isLoading = true);
                      final success = await _authController.resetPassword(
                        email: emailController.text.trim(),
                        code: codeController.text.trim(),
                        newPassword: passwordController.text,
                      );
                      setState(() => _isLoading = false);
                      Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Mot de passe mis à jour !' : (_authError ?? 'Échec')),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: _isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white)),
                  )
                      : Text('Réinitialiser'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/img2.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.loginTitle,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 30),
                    CustomTextField(
                      controller: _usernameController,
                      hintText: AppStrings.usernameHint,
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _passwordController,
                      hintText: AppStrings.passwordHint,
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                              final username = _usernameController.text.trim();
                              final password = _passwordController.text;

                              if (username.isEmpty || password.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Veuillez remplir tous les champs")),
                                );
                                return;
                              }

                              // Inside login button onPressed:
                              final authController = Provider.of<AuthController>(context, listen: false);
                              final hotelCardController = Provider.of<HotelCardController>(context, listen: false);

                              setState(() => _isLoading = true);
                              final success = await authController.login(username, password);
                              setState(() => _isLoading = false);

                              if (success) {
                                if (authController.currentUser!.isAdmin) {
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminHomeScreen()));
                                } else {
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => UserHomeScreen(
                                    authController: authController,
                                    hotelCardController: hotelCardController,
                                  )));
                                }

                              }else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_authController.authError ?? "Identifiants invalides"),
                                  ),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.primary),
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.lightBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? CircularProgressIndicator(color: AppColors.primary)
                                : Text(AppStrings.loginButton),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SignupScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: AppColors.black,
                              backgroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(AppStrings.signupButton),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => _showForgotPasswordFlow(context),
                      child: Text(
                        AppStrings.forgotPassword,
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}