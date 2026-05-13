import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unwaver/screens/habits/exercise/exercise_screen.dart';

// Import your workout tracking screen here
// import 'workout_tracking_screen.dart'; 

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
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _habitType = 'Habits to Build';
  String _selectedPillar = 'Health';
  String _priority = 'Medium';
  String _urgency = 'Medium';
  bool _isExercise = false;
  bool _isSaving = false;
  
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  DateTime? _deadline;

  // --- Icon & Color State ---
  IconData _selectedIcon = Icons.star_rounded;
  Color _selectedColor = Colors.teal; 

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

  final List<Color> _brandColors = [
    Colors.teal,
    Colors.black,
    const Color.fromARGB(255, 187, 142, 19), // Signature Gold
    Colors.blueAccent,
    Colors.deepPurple,
    Colors.redAccent,
    Colors.orange,
    Colors.green,
  ];

  final List<IconData> _habitIcons = [
    Icons.star_rounded, Icons.favorite_rounded, Icons.fitness_center_rounded,
    Icons.directions_run_rounded, Icons.book_rounded, Icons.self_improvement_rounded,
    Icons.water_drop_rounded, Icons.attach_money_rounded, Icons.bolt_rounded,
    Icons.bed_rounded, Icons.edit_note_rounded, Icons.palette_rounded,
    Icons.computer_rounded, Icons.spa_rounded, Icons.monitor_heart_rounded,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- Pickers ---
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

  void _showIconPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select an Icon', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _habitIcons.length,
            itemBuilder: (context, index) {
              return IconButton(
                icon: Icon(_habitIcons[index], size: 30, color: Colors.black87),
                onPressed: () {
                  setState(() => _selectedIcon = _habitIcons[index]);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select a Color', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _brandColors.map((color) {
            return GestureDetector(
              onTap: () {
                setState(() => _selectedColor = color);
                Navigator.pop(context);
              },
              child: CircleAvatar(
                backgroundColor: color,
                radius: 20,
                child: _selectedColor == color 
                    ? const Icon(Icons.check, color: Colors.white, size: 20) 
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- SMART SAVE LOGIC (Handles Both Flows) ---
  Future<void> _saveHabit({bool recordWorkoutNext = false}) async {
    if (_formKey.currentState!.validate() && !_isSaving) {
      setState(() => _isSaving = true);
      FocusScope.of(context).unfocus(); // Dismiss keyboard

      final newHabit = {
        'title': _nameController.text.trim(),
        'type': _habitType,
        'category': _categoryController.text.trim(),
        'tags': _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(),
        'pillar': _selectedPillar,
        'priority': _priority,
        'urgency': _urgency,
        'isExercise': _isExercise,
        'description': _descriptionController.text.trim(),
        'startDate': _startDate,
        'endDate': _endDate,
        'deadline': _deadline,
        
        'iconCodePoint': _selectedIcon.codePoint,
        'iconFontFamily': _selectedIcon.fontFamily,
        'colorValue': _selectedColor.toARGB32(),
        
        'isCompleted': false,
        'streak': 0,
        'isHidden': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      try {
        // Await the creation so we can get the document ID for the workout subcollection
        final docRef = await FirebaseFirestore.instance.collection('habits').add(newHabit);

        if (kDebugMode) {
          print("Habit Created: ${docRef.id}");
        }
        
        if (!mounted) return;

        if (recordWorkoutNext) {
          // PushReplacement ensures that clicking "Back" from the workout screen 
          // takes you to the dashboard, NOT back to an empty creation screen.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ExerciseScreen(
                habitId: docRef.id,
                habitName: _nameController.text.trim(),
              ),
            ),
          );
        } else {
          Navigator.pop(context); // Standard save, go back to dashboard
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
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
          // THE TRIGGER: Appears instantly if marked as an exercise
          if (_isExercise)
            IconButton(
              icon: const Icon(Icons.fitness_center_rounded, color: Colors.teal),
              tooltip: "Save & Record Workout",
              onPressed: _isSaving ? null : () => _saveHabit(recordWorkoutNext: true),
            ),
          TextButton(
            onPressed: _isSaving ? null : () => _saveHabit(recordWorkoutNext: false),
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
            // --- Visual Identity ---
            Row(
              children: [
                GestureDetector(
                  onTap: _showIconPicker,
                  child: Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: _selectedColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _selectedColor),
                    ),
                    child: Icon(_selectedIcon, color: _selectedColor, size: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Visual Identity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _showColorPicker,
                            icon: const Icon(Icons.palette, size: 16, color: Colors.black87),
                            label: const Text("Set Color", style: TextStyle(color: Colors.black87)),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),

            _buildLabel("Habit Name"),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration("e.g. Morning Run"),
              validator: (val) => val!.isEmpty ? "Please enter a name" : null,
            ),
            const SizedBox(height: 20),

            _buildLabel("Classification"),
            _buildDropdown(_habitTypes, _habitType, (val) => setState(() => _habitType = val!)),
            const SizedBox(height: 20),

            _buildLabel("Life Pillar"),
            _buildDropdown(_pillars, _selectedPillar, (val) => setState(() => _selectedPillar = val!)),
            const SizedBox(height: 20),

            _buildLabel("Category (Sub-pillar)"),
            TextFormField(
              controller: _categoryController,
              decoration: _inputDecoration("e.g. Cardio"),
            ),
            const SizedBox(height: 16),
            _buildLabel("Tags"),
            TextFormField(
              controller: _tagsController,
              decoration: _inputDecoration("Comma-separated tags, e.g. Exercise, Strength"),
            ),
            const SizedBox(height: 16),

            // Exercise Toggle
            if (_selectedPillar == 'Health')
              Row(
                children: [
                  const Expanded(
                    child: Text("Mark as Exercise Habit",
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                  ),
                  Switch(
                    value: _isExercise,
                    activeThumbColor: Colors.black,
                    onChanged: (value) {
                      setState(() {
                        _isExercise = value;
                        // UX Polish: Automatically set the dumbbell icon if they toggle this on
                        if (value) {
                          _selectedIcon = Icons.fitness_center_rounded;
                        }
                      });
                    },
                  ),
                ],
              ),
            if (_selectedPillar == 'Health')
              const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Priority"),
                      _buildFormattedDropdown(_levels, _priority, (val) => setState(() => _priority = val!), _formatPriority),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Urgency"),
                      _buildFormattedDropdown(_levels, _urgency, (val) => setState(() => _urgency = val!), _formatUrgency),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

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

            _buildLabel("Description / Why?"),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: _inputDecoration("Describe the habit and why it matters..."),
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () => _saveHabit(recordWorkoutNext: false),
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

  Widget _buildFormattedDropdown(List<String> items, String currentValue, ValueChanged<String?> onChanged, Function(String) formatter) {
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
          items: items.map((val) => DropdownMenuItem(value: val, child: Text('$val (${formatter(val)})'))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  String _formatPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'low': return 'P1';
      case 'medium': return 'P2';
      case 'high': return 'P3';
      case 'critical': return 'P4';
      default: return priority;
    }
  }

  String _formatUrgency(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'low': return '!';
      case 'medium': return '!!';
      case 'high': return '!!!';
      case 'critical': return '!!!!';
      default: return urgency;
    }
  }
}