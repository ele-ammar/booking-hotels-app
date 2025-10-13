// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:booking/core/constants/app_colors.dart';
import 'package:booking/core/constants/app_strings.dart';
import '../widgets/custom_text_field.dart';
import 'login_screen.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Image de fond : occupe tout l'écran
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/img7.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Overlay blanc semi-transparent sur la moitié inférieure
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.85),
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
                      AppStrings.signupTitle,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      hintText: AppStrings.usernameHint,
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      hintText: AppStrings.emailHint,
                      prefixIcon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      hintText: AppStrings.passwordHint,
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Signup clicked")),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.lightBlue ,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: Size(0, 40),
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Text(AppStrings.signupButton),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.primary),
                              backgroundColor: AppColors.white,
                              foregroundColor: AppColors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: Size(0, 40),
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Text(AppStrings.loginButton),
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