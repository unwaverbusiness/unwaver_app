import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:intl/intl.dart'; 

class GoalCreationScreen extends StatefulWidget {
  const GoalCreationScreen({super.key});

  @override
  State<GoalCreationScreen> createState() => _GoalCreationScreenState();
}

class _GoalCreationScreenState extends State<GoalCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Controllers & State ---
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _metricController = TextEditingController(); // e.g. "Run 5km" or "$10k Saved"
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedPillar = 'Health';
  String _priority = 'Medium';
  
  DateTime _deadline = DateTime.now().add(const Duration(days: 30)); // Default to 30 days out

  // --- Dropdown Options ---
  final List<String> _pillars = [
    'Faith',
    'Health',
    'Relationships',
    'Optimization',
    'Education',
    'Work',
    'Creativity'
  ];

  final List<String> _levels = ['Low', 'Medium', 'High', 'Critical'];

  // --- Date Picker Helper ---
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black, 
              onPrimary: Colors.white, 
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      // Process Data Here
      final newGoal = {
        'title': _titleController.text,
        'metric': _metricController.text,
        'pillar': _selectedPillar,
        'priority': _priority,
        'description': _descriptionController.text,
        'deadline': _deadline,
        'progress': 0.0, // Start at 0%
      };

      if (kDebugMode) {
        // ignore: avoid_print
        print("Goal Created: $newGoal");
      } // Debug print
      Navigator.pop(context); // Go back to previous screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("New Goal", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _saveGoal,
            child: const Text(
              "SAVE",
              style: TextStyle(color: Color.fromARGB(255, 187, 142, 19), fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 1. Goal Title
            _buildLabel("Goal Title"),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration("e.g. Run a Marathon"),
              validator: (val) => val!.isEmpty ? "Please enter a title" : null,
            ),
            const SizedBox(height: 20),

            // 2. Success Metric
            _buildLabel("Success Metric (Measurable Result)"),
            TextFormField(
              controller: _metricController,
              decoration: _inputDecoration("e.g. 42km in under 4 hours"),
            ),
            const SizedBox(height: 20),

            // 3. Pillar (Dropdown)
            _buildLabel("Life Pillar"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPillar,
                  isExpanded: true,
                  items: _pillars.map((String pillar) {
                    return DropdownMenuItem<String>(
                      value: pillar,
                      child: Text(pillar),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedPillar = val!),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 4. Priority 
            _buildLabel("Priority"),
            _buildDropdown(_levels, _priority, (val) => setState(() => _priority = val!)),
            const SizedBox(height: 20),

            // 5. Deadline
            _buildLabel("Target Deadline"),
            InkWell(
              onTap: () => _pickDate(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM dd, yyyy').format(_deadline),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.calendar_today, color: Colors.black),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 6. Description / Strategy
            _buildLabel("Strategy / Description"),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: _inputDecoration("How will you achieve this?"),
            ),
            
            const SizedBox(height: 40),
            
            // 7. Create Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("CREATE GOAL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade400)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade400)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black)),
    );
  }

  Widget _buildDropdown(List<String> items, String currentValue, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          items: items.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}