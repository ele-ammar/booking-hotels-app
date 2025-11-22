// lib/main.dart

import 'package:booking/views/screens/HotelRoomsScreen.dart';
import 'package:booking/views/screens/PaymentScreen.dart';
import 'package:booking/views/screens/admin/UserManagementScreen.dart';
import 'package:booking/views/screens/booking_summary_screen.dart';
import 'package:booking/views/screens/login_screen.dart';
import 'package:booking/views/screens/search_results_screen.dart';
import 'package:booking/views/screens/user_home_screen.dart'; // Your current version
import 'package:booking/views/screens/wishlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Controllers
import 'controllers/PlaceController.dart';
import 'controllers/RoomController.dart';
import 'controllers/auth_controller.dart';
import 'controllers/booking_controller.dart';
import 'controllers/hotel_card_controller.dart';
import 'controllers/signup_controller.dart';
import 'controllers/hotel_controller.dart'; // only if used elsewhere

// Screens
import 'models/hotel.dart';
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
        ChangeNotifierProvider(create: (_) => RoomController()),
        ChangeNotifierProvider(create: (_) => BookingController()),
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
              final args = settings.arguments;

              String? hotelId;
              DateTime? checkIn;
              DateTime? checkOut;
              int guests = 2;

              // 🔹 Gère les deux formats d'arguments :
              //   1. String directe (ancien comportement)
              //   2. Map (nouveau comportement avec filtres)
              if (args is String) {
                hotelId = args;
              } else if (args is Map<String, dynamic>?) {
                hotelId = args?['hotelId'] as String?;
                checkIn = args?['checkIn'] as DateTime?;
                checkOut = args?['checkOut'] as DateTime?;
                guests = (args?['guests'] as int?) ?? 2;
              }

              if (hotelId == null || hotelId.isEmpty) {
                return MaterialPageRoute(builder: (_) => Scaffold(
                  appBar: AppBar(title: Text('Erreur')),
                  body: Center(child: Text('ID d’hôtel manquant')),
                ));
              }

              return MaterialPageRoute(builder: (_) => HotelDetailPage(
                hotelId: hotelId!,
                checkIn: checkIn,
                checkOut: checkOut,
                guests: guests,
              ));
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


            case '/hotel-rooms':
              final args = settings.arguments as Map<String, dynamic>?;
              final hotelData = args?['hotel'];
              final Hotel hotel = hotelData is Map
                  ? Hotel.fromJson(hotelData)
                  : hotelData as Hotel;
              return MaterialPageRoute(builder: (_) => HotelRoomsScreen(
                hotel: hotel,
                checkIn: args?['checkIn'],
                checkOut: args?['checkOut'],
                guests: (args?['guests'] as int?) ?? 2,
              ));

            case '/booking-summary':
              final args = settings.arguments as Map<String, dynamic>?;
              final hotel = args?['hotel'] is Map
                  ? Hotel.fromJson(args!['hotel'] as Map<String, dynamic>)
                  : args?['hotel'] as Hotel;
              return MaterialPageRoute(builder: (_) => BookingSummaryScreen(
                hotel: hotel,
                roomType: args?['roomType'] ?? 'Standard',
                price: (args?['price'] as num?)?.toDouble() ?? 0.0,
                checkIn: args?['checkIn'],
                checkOut: args?['checkOut'],
                guests: (args?['guests'] as int?) ?? 1,
              ));

            case '/payment':
              return MaterialPageRoute(builder: (_) => PaymentScreen());





            default:
              return MaterialPageRoute(builder: (_) => const WelcomeScreen());
          }
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}