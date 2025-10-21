// lib/screens/add_new_car_screen.dart

import 'package:flutter/material.dart';

class AddNewCarScreen extends StatefulWidget {
  const AddNewCarScreen({super.key});

  @override
  State<AddNewCarScreen> createState() => _AddNewCarScreenState();
}

class _AddNewCarScreenState extends State<AddNewCarScreen> {
  // A controller for each text field to manage its value
  final _plateController = TextEditingController();
  final _modelController = TextEditingController();
  final _makeController = TextEditingController();
  final _odometerController = TextEditingController();
  final _tireSizeController = TextEditingController();
  final _engineController = TextEditingController();
  final _lastServiceController = TextEditingController();

  @override
  void dispose() {
    // Clean up controllers when the widget is removed from the widget tree
    _plateController.dispose();
    _modelController.dispose();
    _makeController.dispose();
    _odometerController.dispose();
    _tireSizeController.dispose();
    _engineController.dispose();
    _lastServiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        // AppBar title "ADD NEW CAR"
        title: const Text(
          'ADD NEW CAR',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Form fields matching your UI design
            _buildTextField(controller: _plateController, label: 'Plate No.'),
            _buildTextField(controller: _modelController, label: 'Model'),
            _buildTextField(controller: _makeController, label: 'Make'),
            _buildTextField(controller: _odometerController, label: 'Odometer', keyboardType: TextInputType.number),
            _buildTextField(controller: _tireSizeController, label: 'Tire Size'),
            _buildTextField(controller: _engineController, label: 'Engine'),
            _buildTextField(controller: _lastServiceController, label: 'Last Service'),
            const SizedBox(height: 40),
            
            // Action buttons: "Cancel" and "Confirm"
            Row(
              children: [
                Expanded(
                  child: _buildButton(
                    text: 'Cancel',
                    isPrimary: false,
                    onPressed: () {
                      // Pop the screen to go back to the dashboard
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildButton(
                    text: 'Confirm',
                    isPrimary: true,
                    onPressed: () {
                      // TODO: Add logic to save the car data to the database (Hive/Firebase)
                      // After saving, pop the screen
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for a single form field row
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 100, // Fixed width for labels
            child: Text(
              '$label :',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for the action buttons
  Widget _buildButton({
    required String text,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? Colors.white : Colors.grey.shade800,
        foregroundColor: isPrimary ? Colors.black : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}