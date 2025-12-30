// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import Screens
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_new_car_screen.dart';
import 'screens/logbook_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/driving_session_screen.dart';
import 'screens/profile_screen.dart';

import 'models/car_model.dart'; // Needed for arguments

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  await Firebase.initializeApp();

  // 2. Load Environment Variables (API Keys)
  await dotenv.load(fileName: ".env");

  runApp(const DriveBuddyApp());
}

class DriveBuddyApp extends StatelessWidget {
  const DriveBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drive Buddy',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
      ),

      // Check if user is logged in
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const DashboardScreen();
          }
          return const LoginScreen();
        },
      ),

      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterScreen());
          case '/dashboard':
            return MaterialPageRoute(builder: (_) => const DashboardScreen());
          case '/add_car':
            return MaterialPageRoute(builder: (_) => const AddNewCarScreen());
          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfileScreen());

          // --- ROUTES WITH ARGUMENTS ---
          case '/logbook':
            final car = settings.arguments as Car;
            return MaterialPageRoute(builder: (_) => LogbookScreen(car: car));

          case '/chatbot':
            final car = settings.arguments as Car;
            return MaterialPageRoute(builder: (_) => ChatbotScreen(car: car));

          case '/driving_session':
            final car = settings.arguments as Car;
            return MaterialPageRoute(
              builder: (_) => DrivingSessionScreen(car: car),
            );

          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
