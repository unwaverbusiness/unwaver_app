import 'package:flutter/material.dart';

// --- Data Models ---

enum WeightUnit { kg, lbs }

class ExerciseSet {
  String id;
  int reps;
  double weight;
  WeightUnit unit;

  ExerciseSet({
    required this.id,
    required this.reps,
    required this.weight,
    required this.unit,
  });
}

class Exercise {
  String id;
  String name;
  List<ExerciseSet> sets;

  Exercise({
    required this.id,
    required this.name,
    required this.sets,
  });
}

// --- Main Screen ---

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  // Temporary local state list. In a full app, this would come from a database.
  List<Exercise> exercises = [];

  void _addExercise(String name) {
    setState(() {
      exercises.add(Exercise(
        id: DateTime.now().toString(),
        name: name,
        sets: [],
      ));
    });
  }

  void _deleteExercise(String id) {
    setState(() {
      exercises.removeWhere((ex) => ex.id == id);
    });
  }

  void _updateExerciseName(String id, String newName) {
    setState(() {
      final index = exercises.indexWhere((ex) => ex.id == id);
      if (index != -1) {
        exercises[index].name = newName;
      }
    });
  }

  // Dialog to add a new exercise
  void _showAddExerciseDialog() {
    String newName = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Exercise'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g., Bench Press'),
          onChanged: (val) => newName = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newName.isNotEmpty) {
                _addExercise(newName);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Tracker'),
        centerTitle: true,
      ),
      body: exercises.isEmpty
          ? const Center(
              child: Text(
                'No exercises added yet.\nTap + to start.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                return ExerciseCard(
                  exercise: exercises[index],
                  onDelete: () => _deleteExercise(exercises[index].id),
                  onUpdateName: (newName) =>
                      _updateExerciseName(exercises[index].id, newName),
                  onSetChanged: () => setState(() {}), // Refresh UI on set changes
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExerciseDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- Exercise Card Widget ---

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onDelete;
  final Function(String) onUpdateName;
  final VoidCallback onSetChanged;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onDelete,
    required this.onUpdateName,
    required this.onSetChanged,
  });

  void _addSet(BuildContext context) {
    // Default values for new set
    exercise.sets.add(ExerciseSet(
      id: DateTime.now().toString(),
      reps: 0,
      weight: 0.0,
      unit: WeightUnit.lbs, // Default to lbs, user can toggle
    ));
    onSetChanged();
  }

  void _removeSet(int index) {
    exercise.sets.removeAt(index);
    onSetChanged();
  }

  void _editExerciseName(BuildContext context) {
    String tempName = exercise.name;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextFormField(
          initialValue: tempName,
          onChanged: (val) => tempName = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (tempName.isNotEmpty) {
                onUpdateName(tempName);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    exercise.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                  onPressed: () => _editExerciseName(context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                  onPressed: onDelete,
                ),
              ],
            ),
            const Divider(),
            
            // Sets Header
            if (exercise.sets.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(flex: 1, child: Center(child: Text("Set", style: TextStyle(fontWeight: FontWeight.bold)))),
                    Expanded(flex: 2, child: Center(child: Text("Reps", style: TextStyle(fontWeight: FontWeight.bold)))),
                    Expanded(flex: 3, child: Center(child: Text("Weight", style: TextStyle(fontWeight: FontWeight.bold)))),
                    Expanded(flex: 1, child: SizedBox()), // Delete button spacer
                  ],
                ),
              ),

            // Sets List
            ...exercise.sets.asMap().entries.map((entry) {
              int idx = entry.key;
              ExerciseSet set = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    // Set Number
                    Expanded(
                      flex: 1,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.grey[200],
                        child: Text(
                          "${idx + 1}",
                          style: const TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ),
                    ),
                    
                    // Reps Input
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextFormField(
                          initialValue: set.reps == 0 ? '' : set.reps.toString(),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.all(8),
                            border: OutlineInputBorder(),
                            hintText: '0',
                          ),
                          onChanged: (val) {
                            set.reps = int.tryParse(val) ?? 0;
                          },
                        ),
                      ),
                    ),

                    // Weight Input & Unit Toggle
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: set.weight == 0 ? '' : set.weight.toString(),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.all(8),
                                border: OutlineInputBorder(),
                                hintText: '0.0',
                              ),
                              onChanged: (val) {
                                set.weight = double.tryParse(val) ?? 0.0;
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              // Toggle Unit
                              set.unit = set.unit == WeightUnit.kg
                                  ? WeightUnit.lbs
                                  : WeightUnit.kg;
                              onSetChanged();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blueAccent),
                              ),
                              child: Text(
                                set.unit.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Delete Set Button
                    Expanded(
                      flex: 1,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                        onPressed: () => _removeSet(idx),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),
            
            // Add Set Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _addSet(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Set'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}