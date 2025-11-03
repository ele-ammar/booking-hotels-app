// lib/main.dart
import 'package:booking/views/screens/user_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; //

import 'controllers/signup_controller.dart';
import 'views/screens/admin/admin_home_screen.dart';
import 'views/screens/admin/admin_hotel_edit_screen.dart';
import 'views/screens/admin/admin_hotel_list_screen.dart';
import 'views/screens/hotel_detail_page.dart';
import 'views/screens/welcome_screen.dart';
// ✅ Importe ton contrôleur
import 'controllers/hotel_controller.dart';
import 'controllers/auth_controller.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HotelController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => SignupController()),
        ChangeNotifierProvider(create: (_) => CarouselController()),

      ],
      child: MaterialApp(
        title: 'Booking Hotel',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Poppins',
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home:UserHomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}