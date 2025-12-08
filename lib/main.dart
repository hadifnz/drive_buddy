// lib/main.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv

// --- MODELS ---
import 'models/car_model.dart';
import 'models/trip_session_model.dart';
import 'models/user_model.dart'; // Import User model

// --- SCREENS ---
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_new_car_screen.dart';
import 'screens/logbook_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/driving_session_screen.dart';
import 'screens/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Hive
  await Hive.initFlutter();
  
  // 2. Register Adapters
  // (Run 'flutter packages pub run build_runner build' if you get errors here)
  Hive.registerAdapter(CarAdapter());
  Hive.registerAdapter(TripSessionAdapter());
  Hive.registerAdapter(UserAdapter()); // NEW: Register User adapter
  
  // 3. Open Database Boxes
  await Hive.openBox<Car>('cars');
  await Hive.openBox<TripSession>('trip_sessions');
  await Hive.openBox<User>('users');       // NEW: Store user accounts
  await Hive.openBox('session_data');      // NEW: Store login state

  // 4. Load Environment Variables (API Keys)
  await dotenv.load(fileName: ".env");

  runApp(const DriveBuddyApp());
}

class DriveBuddyApp extends StatelessWidget {
  const DriveBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if user is already logged in
    final sessionBox = Hive.box('session_data');
    final bool isLoggedIn = sessionBox.containsKey('currentUserKey');

    return MaterialApp(
      title: 'Drive Buddy',
      theme: ThemeData(
        brightness: Brightness.dark, 
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
      ),
      
      // Auto-Login Logic: If key exists, go to Dashboard, else Login
      initialRoute: isLoggedIn ? '/dashboard' : '/login',

      onGenerateRoute: (settings) {
        switch (settings.name) {
          // --- AUTH ROUTES ---
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterScreen());
            
          // --- MAIN APP ROUTES ---
          case '/dashboard':
            return MaterialPageRoute(builder: (_) => const DashboardScreen());
          case '/add_car':
            return MaterialPageRoute(builder: (_) => const AddNewCarScreen());
          case '/profile':
             return MaterialPageRoute(builder: (_) => const ProfileScreen());

          // --- ROUTES WITH ARGUMENTS ---
          
          case '/logbook':
            // Expects a 'Car' object passed as argument
            final car = settings.arguments as Car;
            return MaterialPageRoute(builder: (_) => LogbookScreen(car: car));

          case '/chatbot':
            // Expects a 'Car' object for context
            final car = settings.arguments as Car;
            return MaterialPageRoute(builder: (_) => ChatbotScreen(car: car));

          case '/driving_session':
            // Expects a 'Car' object to track miles
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