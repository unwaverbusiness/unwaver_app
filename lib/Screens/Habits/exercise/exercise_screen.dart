import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Data Models for Dynamic State ---
class SetEntry {
  TextEditingController repsCtrl = TextEditingController();
  TextEditingController weightCtrl = TextEditingController();

  void dispose() {
    repsCtrl.dispose();
    weightCtrl.dispose();
  }
}

class ExerciseEntry {
  TextEditingController nameCtrl = TextEditingController();
  List<SetEntry> sets = [SetEntry()]; // Start with 1 set by default

  void dispose() {
    nameCtrl.dispose();
    for (var set in sets) {
      set.dispose();
    }
  }
}

// --- Main Screen ---
class ExerciseScreen extends StatefulWidget {
  final String habitId;
  final String habitName;

  const ExerciseScreen({
    super.key,
    required this.habitId,
    required this.habitName,
  });

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  String _selectedCategory = 'Push';
  final List<String> _categories = [
    'Push', 'Pull', 'Legs', 'Cardio', 'Arms', 'Core', 'Full Body'
  ];

  // The dynamic list holding all exercises for this specific session
  final List<ExerciseEntry> _exercises = [ExerciseEntry()];
  
  // Local history for immediate UI updates if needed
  final List<Map<String, dynamic>> _workoutHistory = [];

  @override
  void dispose() {
    // CRITICAL: Prevent memory leaks from dynamically generated controllers
    for (var exercise in _exercises) {
      exercise.dispose();
    }
    super.dispose();
  }

  // --- Dynamic Form Actions ---
  void _addExercise() {
    setState(() {
      _exercises.add(ExerciseEntry());
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises[index].dispose(); // Clean up memory first
      _exercises.removeAt(index);
    });
  }

  void _addSet(int exerciseIndex) {
    setState(() {
      _exercises[exerciseIndex].sets.add(SetEntry());
    });
  }

  void _removeSet(int exerciseIndex, int setIndex) {
    setState(() {
      _exercises[exerciseIndex].sets[setIndex].dispose(); // Clean up memory
      _exercises[exerciseIndex].sets.removeAt(setIndex);
    });
  }

  // --- Save Workout with Timestamp ---
  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one exercise.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    FocusScope.of(context).unfocus();

    try {
      final now = DateTime.now();
      final workoutData = {
        'category': _selectedCategory,
        'exercises': _exercises.map((ex) => {
          'name': ex.nameCtrl.text.trim(),
          'sets': ex.sets.map((set) => {
            'reps': int.tryParse(set.repsCtrl.text.trim()) ?? 0,
            'weight': double.tryParse(set.weightCtrl.text.trim()) ?? 0.0,
          }).toList(),
        }).toList(),
        'timestamp': now,
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('habits')
          .doc(widget.habitId)
          .collection('workouts')
          .add(workoutData);

      // Add to local history
      setState(() => _workoutHistory.add(workoutData));

      if (!mounted) return;
      Navigator.pop(context); // Pop back to Habits screen
      
      // SUCCESS MESSAGE
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout Logged!'), 
          backgroundColor: Colors.teal,
        ),
      );
      
    } catch (e) {
      if (!mounted) return;
      
      // ERROR MESSAGE
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving workout: $e'), 
          backgroundColor: Colors.red,
        ),
      );
      
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Record Workout", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(widget.habitName, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveWorkout,
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
          padding: const EdgeInsets.all(16),
          children: [
            // --- Category Selection (Chips) ---
            const Text("Muscle Group", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: Colors.black,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = category);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Divider(),

            // --- Dynamic Exercises List ---
            ..._exercises.asMap().entries.map((entry) {
              int exIndex = entry.key;
              ExerciseEntry exercise = entry.value;

              return Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Exercise Header
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: exercise.nameCtrl,
                              decoration: const InputDecoration(
                                hintText: "Exercise Name (e.g. Bench Press)",
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              validator: (val) => val!.isEmpty ? "Required" : null,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.redAccent),
                            onPressed: () => _removeExercise(exIndex),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Headers for Sets
                      const Row(
                        children: [
                          SizedBox(width: 30, child: Text("Set", style: TextStyle(color: Colors.grey, fontSize: 12))),
                          Expanded(child: Text("lbs/kg", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))),
                          Expanded(child: Text("Reps", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))),
                          SizedBox(width: 48), // Spacing for delete icon
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Sets List
                      ...exercise.sets.asMap().entries.map((setEntry) {
                        int setIndex = setEntry.key;
                        SetEntry set = setEntry.value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 30, 
                                child: Text("${setIndex + 1}", style: const TextStyle(fontWeight: FontWeight.bold))
                              ),
                              Expanded(
                                child: _buildNumberInput(set.weightCtrl, "Weight"),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildNumberInput(set.repsCtrl, "Reps"),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                                onPressed: () => _removeSet(exIndex, setIndex),
                              )
                            ],
                          ),
                        );
                      }), 

                      const SizedBox(height: 8),
                      // Add Set Button
                      TextButton.icon(
                        onPressed: () => _addSet(exIndex),
                        icon: const Icon(Icons.add, size: 16, color: Colors.teal),
                        label: const Text("Add Set", style: TextStyle(color: Colors.teal)),
                      )
                    ],
                  ),
                ),
              );
            }), 

            // --- Add Exercise Button ---
            OutlinedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text("ADD EXERCISE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: const BorderSide(color: Colors.black, width: 1.5),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- UI Helper for sleek inputs ---
  Widget _buildNumberInput(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        validator: (val) => val!.isEmpty ? "!" : null,
      ),
    );
  }
}