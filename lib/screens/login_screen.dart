// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:booking/core/constants/app_colors.dart';
import 'package:booking/core/constants/app_strings.dart';
import '../widgets/custom_text_field.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ✅ Add controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    // ✅ Clean up controllers
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Image de fond : occupe tout l'écran
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/img2.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Overlay blanc semi-transparent sur la moitié inférieure
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.5, // Moitié inférieure
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.7),
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
                      controller: _usernameController, // ✅ Added
                      hintText: AppStrings.usernameHint,
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _passwordController, // ✅ Added
                      hintText: AppStrings.passwordHint,
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // ✅ Now you can read input values
                              final username = _usernameController.text;
                              final password = _passwordController.text;

                              if (username.isEmpty || password.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Please fill all fields")),
                                );
                                return;
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Login clicked: $username")),
                              );

                              // TODO: Call your login API here
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.primary),
                              foregroundColor: AppColors.black,
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(AppStrings.loginButton),
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
                              foregroundColor: AppColors.white,
                              backgroundColor: AppColors.lightBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: Size(double.infinity, 40),
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Text(AppStrings.signupButton),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 🔗 Forgot Password
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Forgot password?")),
                        );
                      },
                      child: Text(
                        AppStrings.forgotPassword,
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 15,
                          fontWeight: FontWeight.w300,
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