import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive
import 'models/car_model.dart';
import 'package:drive_buddy/screens/add_new_car_screen.dart';
import 'package:drive_buddy/screens/logbook_screen.dart';
import 'package:drive_buddy/screens/chatbot_screen.dart';
import 'package:drive_buddy/screens/driving_session_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Hive
  await Hive.initFlutter();
  // Register the Car adapter
  Hive.registerAdapter(CarAdapter());
  // Open a Hive box for storing cars
  await Hive.openBox<Car>('cars');

  runApp(const DriveBuddyApp());
}

class DriveBuddyApp extends StatelessWidget {
  const DriveBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drive Buddy',
      theme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.blue),
      // Set up named routes
      initialRoute: '/login', // The app will start at the login screen

      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/dashboard':
            return MaterialPageRoute(builder: (_) => const DashboardScreen());
          case '/add_car':
            return MaterialPageRoute(builder: (_) => const AddNewCarScreen());

          // *** ADD THIS NEW CASE FOR THE LOGBOOK ***
          case '/logbook':
            // 1. Extract the 'car' object from the navigation arguments
            final car = settings.arguments as Car;
            // 2. Pass the 'car' object to the LogbookScreen
            return MaterialPageRoute(builder: (_) => LogbookScreen(car: car));

          case '/chatbot':
            return MaterialPageRoute(builder: (_) => const ChatbotScreen());

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
