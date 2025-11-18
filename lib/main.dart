// lib/main.dart

import 'package:booking/views/screens/admin/UserManagementScreen.dart';
import 'package:booking/views/screens/login_screen.dart';
import 'package:booking/views/screens/search_results_screen.dart';
import 'package:booking/views/screens/user_home_screen.dart'; // Your current version
import 'package:booking/views/screens/wishlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Controllers
import 'controllers/PlaceController.dart';
import 'controllers/auth_controller.dart';
import 'controllers/hotel_card_controller.dart';
import 'controllers/signup_controller.dart';
import 'controllers/hotel_controller.dart'; // only if used elsewhere

// Screens
import 'views/screens/admin/admin_home_screen.dart';
import 'views/screens/admin/admin_hotel_edit_screen.dart';
import 'views/screens/admin/admin_hotel_list_screen.dart';
import 'views/screens/hotel_detail_page.dart';
import 'views/screens/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => HotelCardController()),
        ChangeNotifierProvider(create: (_) => SignupController()),
        ChangeNotifierProvider(create: (_) => HotelController()),
        ChangeNotifierProvider(create: (_) => PlaceController()),
      ],
      child: MaterialApp(
        title: 'Booking Hotel',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Poppins',
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const WelcomeScreen(),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginScreen());

            case '/user-home':
            // ✅ Fetch controllers from Provider and pass to constructor
              return MaterialPageRoute(
                builder: (context) {
                  final authController = Provider.of<AuthController>(context, listen: false);
                  final hotelCardController = Provider.of<HotelCardController>(context, listen: false);
                  return UserHomeScreen(
                    authController: authController,
                    hotelCardController: hotelCardController,
                  );
                },
              );

            case '/wishlist':
              return MaterialPageRoute(builder: (_) => const WishlistScreen());

            case '/hotel':
              String? hotelId;

              // ✅ Gère les deux cas : String direct OU Map avec 'id'
              final args = settings.arguments;
              if (args is String) {
                hotelId = args;
              } else if (args is Map<String, dynamic>?) {
                hotelId = args?['id'] as String?;
              }

              if (hotelId == null) {
                return MaterialPageRoute(builder: (_) => const Scaffold(
                  body: Center(child: Text('Hôtel non spécifié')),
                ));
              }

              return MaterialPageRoute(builder: (_) => HotelDetailPage(hotelId: hotelId!));

            case '/management':
              return MaterialPageRoute(builder: (_) => const UserManagementScreen());

            case '/search-results':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => SearchResultsScreen(
                  location: args?['location'] as String?,
                  checkIn: args?['checkIn'] as DateTime?,
                  checkOut: args?['checkOut'] as DateTime?,
                  guests: args?['guests'] as int?,
                ),
              );

            default:
              return MaterialPageRoute(builder: (_) => const WelcomeScreen());
          }
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}