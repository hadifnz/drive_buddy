import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'package:drive_buddy/screens/add_new_car_screen.dart';

void main() {
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
      ),
      // Set up named routes
      initialRoute: '/login', // The app will start at the login screen
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/add_car': (context) => const AddNewCarScreen(), // Add this new route
      },
      debugShowCheckedModeBanner: false,
    );
  }
}