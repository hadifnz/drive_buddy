// lib/screens/login_screen.dart

import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers to manage the text in TextFields
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Using a Scaffold to provide a standard app layout
    return Scaffold(
      // Setting a dark background color as per your design
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. App Title [cite: 595]
                const Text(
                  'DRIVE BUDDY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 30),

                // 2. Car Image (Using a placeholder for now)
                // You can replace 'assets/car.png' with your actual image path
                // Image.asset('assets/car.png', height: 150),
                const Icon(Icons.directions_car, color: Colors.white, size: 120),
                const SizedBox(height: 50),

                // 3. Username TextField [cite: 588]
                _buildTextField(
                    controller: _usernameController,
                    labelText: 'Username',
                ),
                const SizedBox(height: 20),

                // 4. Password TextField [cite: 589]
                _buildTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    isObscure: true, // Hides the password text
                ),
                const SizedBox(height: 40),

                // 5. Log In Button [cite: 596]
                _buildButton(text: 'Log In', isPrimary: true, onPressed: () {
                    // Navigate using the named route
                    Navigator.of(context).pushReplacementNamed('/dashboard');
                }),
                const SizedBox(height: 15),

                // 6. Sign Up Button [cite: 597]
                _buildButton(text: 'Sign Up', isPrimary: false, onPressed: () {
                  // TODO: Navigate to registration screen
                }),
                const SizedBox(height: 20),

                // 7. Forgot Password Link [cite: 598]
                Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for TextFields to avoid code repetition
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    bool isObscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.grey.shade900,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
  
  // Helper widget for Buttons
  Widget _buildButton({
    required String text,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.white : Colors.grey.shade800,
          foregroundColor: isPrimary ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}