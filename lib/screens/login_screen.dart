import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // --- THE FIX: MANUALLY NAVIGATE TO DASHBOARD ---
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
      // -----------------------------------------------
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Login Failed")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          // Added scroll to prevent keyboard overflow
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. TITLE
              const Text(
                "DRIVE\nBUDDY",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  height: 1.0,
                ),
              ),

              const SizedBox(height: 30),

              // 2. CAR IMAGE (Placeholder)
              // Put your image file in 'assets/car_login.png' and uncomment the line below.
              // For now, we use a placeholder icon.
              SizedBox(
                height: 120,
                child: Image.asset(
                  'assets/car_login.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback if image is missing
                    return const Icon(
                      Icons.directions_car_filled,
                      color: Colors.white,
                      size: 100,
                    );
                  },
                ),
              ),

              const SizedBox(height: 50),

              // 3. INPUT FIELDS (Label : Input Style)
              _buildRowInput(
                "Username :",
                _emailController,
                false,
              ), // Label says Username, but uses Email logic
              const SizedBox(height: 20),
              _buildRowInput("Password :", _passwordController, true),

              const SizedBox(height: 40),

              // 4. LOGIN BUTTON
              if (_isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Log In",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // 5. SIGN UP BUTTON (Dark Style)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                "Forgot Password?",
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to create the "Label : Input" layout
  Widget _buildRowInput(
    String label,
    TextEditingController controller,
    bool isObscure,
  ) {
    return Row(
      children: [
        // Label
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Input Box
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9), // Light grey like your design
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              controller: controller,
              obscureText: isObscure,
              style: const TextStyle(color: Colors.black),
              textAlign: TextAlign.center, // Center text inside the oval
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ), // Center text vertically
              ),
            ),
          ),
        ),
      ],
    );
  }
}
