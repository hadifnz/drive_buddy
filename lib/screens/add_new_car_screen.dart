import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:drive_buddy/models/car_model.dart';
import 'package:intl/intl.dart'; // For Date Formatting

class AddNewCarScreen extends StatefulWidget {
  const AddNewCarScreen({super.key});

  @override
  State<AddNewCarScreen> createState() => _AddNewCarScreenState();
}

class _AddNewCarScreenState extends State<AddNewCarScreen> {
  final _plateController = TextEditingController();
  final _modelController = TextEditingController();
  final _makeController = TextEditingController();
  final _odometerController = TextEditingController();
  final _tireSizeController = TextEditingController();
  final _engineController = TextEditingController();
  final _lastServiceController = TextEditingController();
  final _capacityController = TextEditingController();

  // Dropdown Selections
  String? _selectedOilType;
  final List<String> _oilTypes = [
    'Mineral (5,000 km)',
    'Semi-Synthetic (7,000 km)',
    'Fully-Synthetic (10,000 km)',
  ];

  String? _selectedTransmission;
  final List<String> _transmissionTypes = ['Auto (AT)', 'Manual (MT)', 'CVT'];

  @override
  void dispose() {
    _plateController.dispose();
    _modelController.dispose();
    _makeController.dispose();
    _odometerController.dispose();
    _tireSizeController.dispose();
    _engineController.dispose();
    _lastServiceController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  // Date Picker Logic
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _lastServiceController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _saveCar() {
    // 1. Determine Oil Life
    double initialOilLife = 10000.0;
    if (_selectedOilType != null) {
      if (_selectedOilType!.contains('Mineral')) initialOilLife = 5000.0;
      if (_selectedOilType!.contains('Semi')) initialOilLife = 7000.0;
      if (_selectedOilType!.contains('Fully')) initialOilLife = 10000.0;
    }

    // 2. Create Car
    final newCar = Car(
      plateNumber: _plateController.text,
      model: _modelController.text,
      brand: _makeController.text,
      currentMileage: double.tryParse(_odometerController.text) ?? 0.0,
      tireSize: _tireSizeController.text,
      engine: _engineController.text,
      lastService: _lastServiceController.text,
      oilType: _selectedOilType,
      oilLifeRemaining: initialOilLife,
      engineCapacity: _capacityController.text,
      transmissionType: _selectedTransmission,
    );

    final box = Hive.box<Car>('cars');
    box.add(newCar);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'ADD NEW CAR',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildTextField(controller: _plateController, label: 'Plate No.'),
            _buildTextField(controller: _modelController, label: 'Model'),
            _buildTextField(controller: _makeController, label: 'Make'),

            // Odometer (Number Pad)
            _buildTextField(
              controller: _odometerController,
              label: 'Odometer',
              keyboardType: TextInputType.number,
            ),

            // Oil Type Dropdown
            _buildDropdown(
              label: 'Oil Type',
              value: _selectedOilType,
              items: _oilTypes,
              onChanged: (val) => setState(() => _selectedOilType = val),
            ),

            // Capacity (Decimal Pad)
            _buildTextField(
              controller: _capacityController,
              label: 'Capacity (L)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),

            // Transmission Dropdown
            _buildDropdown(
              label: 'Trans.',
              value: _selectedTransmission,
              items: _transmissionTypes,
              onChanged: (val) => setState(() => _selectedTransmission = val),
            ),

            _buildTextField(
              controller: _tireSizeController,
              label: 'Tire Size',
            ),
            _buildTextField(
              controller: _engineController,
              label: 'Engine Code',
            ),

            // Last Service (Date Picker)
            _buildDatePickerField(
              controller: _lastServiceController,
              label: 'Last Service',
              context: context,
            ),

            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: _buildButton(
                    text: 'Cancel',
                    isPrimary: false,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildButton(
                    text: 'Confirm',
                    isPrimary: true,
                    onPressed: _saveCar,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets ---
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
            width: 100,
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField({
    required TextEditingController controller,
    required String label,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label :',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: true,
              onTap: () => _selectDate(context),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: const Icon(
                  Icons.calendar_today,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label :',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  dropdownColor: Colors.grey.shade800,
                  hint: const Text(
                    "Select",
                    style: TextStyle(color: Colors.white54),
                  ),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  onChanged: onChanged,
                  items: items
                      .map<DropdownMenuItem<String>>(
                        (val) => DropdownMenuItem(value: val, child: Text(val)),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
