// lib/screens/register_screen.dart

import 'package:drive_buddy/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _register() {
    final box = Hive.box<User>('users');
    final username = _usernameController.text.trim();

    // 1. Check if user already exists
    final userExists = box.values.any((user) => user.username == username);
    if (userExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username already taken!")),
      );
      return;
    }

    if (username.isEmpty || _passwordController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    // 2. Create User
    final newUser = User(
      username: username,
      password: _passwordController.text,
      fullName: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
    );

    // 3. Save to Hive
    box.add(newUser);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Account created! Please log in.")),
    );

    Navigator.of(context).pop(); // Go back to Login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Sign Up"), backgroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.person_add, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            
            // --- UPDATED CALLS TO USE NAMED PARAMETERS ---
            _buildTextField(label: "Full Name", controller: _nameController),
            _buildTextField(label: "Username", controller: _usernameController),
            _buildTextField(label: "Email", controller: _emailController, type: TextInputType.emailAddress),
            _buildTextField(label: "Phone", controller: _phoneController, type: TextInputType.phone),
            
            // This is the line that was causing the error. 
            // Now it works because we updated the definition below.
            _buildTextField(
              label: "Password", 
              controller: _passwordController, 
              isObscure: true
            ),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Create Account", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- FIX IS HERE: Changed [...] to {...} ---
  Widget _buildTextField({
    required String label, 
    required TextEditingController controller, 
    TextInputType type = TextInputType.text, 
    bool isObscure = false, // Now a named parameter
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: type,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade900,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}