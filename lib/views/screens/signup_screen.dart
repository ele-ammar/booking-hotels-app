// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:booking/core/constants/app_colors.dart';
import 'package:booking/core/constants/app_strings.dart';
import '../../widgets/custom_text_field.dart';
import '../../controllers/signup_controller.dart';
import 'login_screen.dart'; // Pour revenir au login

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signupController = Provider.of<SignupController>(context);

    return Scaffold(
      body: Stack(
        children: [
          // 🖼️ Image de fond (même que login)
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/img11 (6).jpg'), // 👈 même image que login
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 📱 Overlay (identique à login_screen)
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.5, // ✅ même hauteur que login
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.7), // ✅ même transparence
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.all(32.0), // ✅ même padding
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Créer un compte", // 👈 ou utilise AppStrings.signupTitle
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 30),
                    CustomTextField(
                      controller: _usernameController,
                      hintText: "Nom d'utilisateur",
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _emailController,
                      hintText: "Email",
                      prefixIcon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _passwordController,
                      hintText: "Mot de passe",
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        // 🔷 Bouton "S'inscrire" (comme "Login" dans login_screen)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: signupController.isLoading
                                ? null
                                : () async {
                              final username = _usernameController.text.trim();
                              final email = _emailController.text.trim();
                              final password = _passwordController.text;

                              if (username.isEmpty || email.isEmpty || password.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Veuillez remplir tous les champs")),
                                );
                                return;
                              }

                              final success = await signupController.signup(
                                username: username,
                                email: email,
                                password: password,
                              );

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Compte créé avec succès !")),
                                );
                                // Revenir automatiquement à l'écran de login
                                Future.delayed(const Duration(seconds: 1), () {
                                  Navigator.pop(context);
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Échec de l'inscription")),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.lightBlue, // ✅ même bleu que login
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: signupController.isLoading
                                ? CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            )
                                : Text("SignUp"),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // 🔶 Bouton "Login" (comme "S'inscrire" dans login_screen)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context); // Retour au login
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.primary),
                              foregroundColor: AppColors.black,
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text("Login"),
                          ),
                        ),
                      ],
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