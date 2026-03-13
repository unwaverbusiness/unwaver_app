import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Firestore

class HabitCreationScreen extends StatefulWidget {
  const HabitCreationScreen({super.key});

  @override
  State<HabitCreationScreen> createState() => _HabitCreationScreenState();
}

class _HabitCreationScreenState extends State<HabitCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Controllers & State ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _habitType = 'Habits to Build'; // Added Type State
  String _selectedPillar = 'Health';
  String _priority = 'Medium';
  String _urgency = 'Medium';
  bool _isSaving = false; // Prevent double taps
  
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  DateTime? _deadline;

  // --- Dropdown Options ---
  final List<String> _habitTypes = ['Habits to Build', 'Habits to Break'];
  
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
  Future<void> _pickDate(BuildContext context, {required bool isStart, bool isDeadline = false}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
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
        if (isDeadline) {
          _deadline = picked;
        } else if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // --- BLAZING FAST SAVE LOGIC ---
  void _saveHabit() {
    if (_formKey.currentState!.validate() && !_isSaving) {
      setState(() => _isSaving = true);

      // Structure data perfectly for the HabitsScreen stream
      final newHabit = {
        'title': _nameController.text.trim(), // Mapped to 'title' for the dashboard
        'type': _habitType, // Build or Break
        'category': _categoryController.text.trim(),
        'pillar': _selectedPillar,
        'priority': _priority,
        'urgency': _urgency,
        'description': _descriptionController.text.trim(),
        'startDate': _startDate,
        'endDate': _endDate,
        'deadline': _deadline,
        
        // Required functional fields
        'isCompleted': false,
        'streak': 0,
        'isHidden': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Push to Firestore (Handles offline caching automatically for instant speed)
      FirebaseFirestore.instance.collection('habits').add(newHabit);

      if (kDebugMode) {
        print("Habit Created & Pushed to Firestore: ${_nameController.text}");
      }
      
      // Pop instantly. The StreamBuilder on HabitsScreen will catch it immediately.
      Navigator.pop(context); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("New Habit", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveHabit,
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
            // 1. Name
            _buildLabel("Habit Name"),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration("e.g. Morning Run"),
              validator: (val) => val!.isEmpty ? "Please enter a name" : null,
            ),
            const SizedBox(height: 20),

            // 2. Classification (Build vs Break) - ADDED HERE
            _buildLabel("Classification"),
            _buildDropdown(_habitTypes, _habitType, (val) => setState(() => _habitType = val!)),
            const SizedBox(height: 20),

            // 3. Pillar (Dropdown)
            _buildLabel("Life Pillar"),
            _buildDropdown(_pillars, _selectedPillar, (val) => setState(() => _selectedPillar = val!)),
            const SizedBox(height: 20),

            // 4. Category
            _buildLabel("Category (Sub-pillar)"),
            TextFormField(
              controller: _categoryController,
              decoration: _inputDecoration("e.g. Cardio"),
            ),
            const SizedBox(height: 20),

            // 5. Priority & Urgency Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Priority"),
                      _buildDropdown(_levels, _priority, (val) => setState(() => _priority = val!)),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Urgency"),
                      _buildDropdown(_levels, _urgency, (val) => setState(() => _urgency = val!)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 6. Dates Section
            _buildLabel("Timeline"),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildDateRow("Start Date", _startDate, () => _pickDate(context, isStart: true)),
                  const Divider(),
                  _buildDateRow("End Date", _endDate, () => _pickDate(context, isStart: false)),
                  const Divider(),
                  _buildDateRow("Deadline", _deadline, () => _pickDate(context, isStart: false, isDeadline: true), isAlert: true),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 7. Description
            _buildLabel("Description / Why?"),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: _inputDecoration("Describe the habit and why it matters..."),
            ),
            
            const SizedBox(height: 40),
            
            // 8. Create Button (Main)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveHabit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSaving 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("CREATE HABIT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildDateRow(String label, DateTime? date, VoidCallback onTap, {bool isAlert = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: isAlert ? Colors.red : Colors.black87, fontWeight: isAlert ? FontWeight.bold : FontWeight.normal)),
            Row(
              children: [
                Text(
                  date == null ? "Select" : DateFormat('MMM dd, yyyy').format(date),
                  style: TextStyle(
                    color: date == null ? Colors.grey : (isAlert ? Colors.red : Colors.black),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.calendar_today, size: 16, color: isAlert ? Colors.red : Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}