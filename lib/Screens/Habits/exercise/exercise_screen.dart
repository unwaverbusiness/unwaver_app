import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/services.dart';

enum TrackingType { weightAndReps, timeAndDistance }

// --- Data Models for Dynamic State ---
class SetEntry {
  TextEditingController repsCtrl = TextEditingController();
  TextEditingController weightCtrl = TextEditingController();
  TextEditingController timeCtrl = TextEditingController();
  TextEditingController distanceCtrl = TextEditingController();
  
  int? previousReps;
  double? previousWeight;
  int? previousTime;
  double? previousDistance;

  void dispose() {
    repsCtrl.dispose();
    weightCtrl.dispose();
    timeCtrl.dispose();
    distanceCtrl.dispose();
  }
}

class ExerciseEntry {
  TextEditingController nameCtrl = TextEditingController();
  TextEditingController noteCtrl = TextEditingController();
  
  String category = 'Push';
  TrackingType trackingType = TrackingType.weightAndReps;
  bool isNoteVisible = false;
  
  List<SetEntry> sets = [SetEntry()];

  Timer? debounceTimer;

  void dispose() {
    nameCtrl.dispose();
    noteCtrl.dispose();
    debounceTimer?.cancel();
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

  final List<String> _categories = [
    'Push', 'Pull', 'Legs', 'Cardio', 'Arms', 'Core', 'Full Body'
  ];

  // The dynamic list holding all exercises for this specific session
  final List<ExerciseEntry> _exercises = [ExerciseEntry()];
  
  // Local history for immediate UI updates if needed
  final List<Map<String, dynamic>> _workoutHistory = [];

  // --- General Workout Note ---
  final TextEditingController _workoutNoteCtrl = TextEditingController();

  // --- Routine Toggle ---
  bool _saveAsRoutine = false;

  // --- Stopwatch ---
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _stopwatchTimer;
  String _stopwatchText = "00:00:00";

  // --- Countdown Timer ---
  Timer? _countdownTimer;
  int _countdownSeconds = 0;

  @override
  void dispose() {
    _workoutNoteCtrl.dispose();
    _stopwatchTimer?.cancel();
    _countdownTimer?.cancel();
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

  // --- Timer & Stopwatch Methods ---
  void _toggleStopwatch() {
    setState(() {
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        _stopwatchTimer?.cancel();
      } else {
        _stopwatch.start();
        _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) return;
          setState(() {
            final duration = _stopwatch.elapsed;
            final hours = duration.inHours.toString().padLeft(2, '0');
            final mins = (duration.inMinutes % 60).toString().padLeft(2, '0');
            final secs = (duration.inSeconds % 60).toString().padLeft(2, '0');
            _stopwatchText = "$hours:$mins:$secs";
          });
        });
      }
    });
  }

  void _resetStopwatch() {
    setState(() {
      _stopwatch.stop();
      _stopwatch.reset();
      _stopwatchTimer?.cancel();
      _stopwatchText = "00:00:00";
    });
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    setState(() {
      _countdownSeconds = seconds;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
        } else {
          timer.cancel();
          HapticFeedback.vibrate();
        }
      });
    });
  }

  // --- Historical Data Fetching ---
  void _onExerciseNameChanged(ExerciseEntry exercise) {
    exercise.debounceTimer?.cancel();
    exercise.debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchPreviousMetrics(exercise);
    });
  }

  Future<void> _fetchPreviousMetrics(ExerciseEntry exercise) async {
    final name = exercise.nameCtrl.text.trim();
    if (name.isEmpty) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('habits')
          .doc(widget.habitId)
          .collection('workouts')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final exercises = data['exercises'] as List<dynamic>?;
        if (exercises == null) continue;

        for (var ex in exercises) {
          if (ex['name']?.toString().toLowerCase() == name.toLowerCase()) {
            final sets = ex['sets'] as List<dynamic>?;
            if (sets != null && sets.isNotEmpty) {
              // Populate previous data for existing sets in UI
              for (int i = 0; i < exercise.sets.length; i++) {
                if (i < sets.length) {
                  final prevSet = sets[i];
                  setState(() {
                    exercise.sets[i].previousReps = prevSet['reps'] as int?;
                    exercise.sets[i].previousWeight = (prevSet['weight'] as num?)?.toDouble();
                    exercise.sets[i].previousTime = prevSet['time'] as int?;
                    exercise.sets[i].previousDistance = (prevSet['distance'] as num?)?.toDouble();
                  });
                }
              }
            }
            return; // Found the most recent match, stop searching
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching previous metrics: $e");
    }
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
        'note': _workoutNoteCtrl.text.trim(),
        'exercises': _exercises.map((ex) => {
          'name': ex.nameCtrl.text.trim(),
          'category': ex.category,
          'note': ex.noteCtrl.text.trim(),
          'trackingType': ex.trackingType.toString(),
          'sets': ex.sets.map((set) => {
            'reps': int.tryParse(set.repsCtrl.text.trim()),
            'weight': double.tryParse(set.weightCtrl.text.trim()),
            'time': int.tryParse(set.timeCtrl.text.trim()),
            'distance': double.tryParse(set.distanceCtrl.text.trim()),
          }).toList(),
        }).toList(),
        'timestamp': now,
        'duration': _stopwatchText,
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('habits')
          .doc(widget.habitId)
          .collection('workouts')
          .add(workoutData);

      // Save as Routine if toggled
      if (_saveAsRoutine) {
        await FirebaseFirestore.instance
            .collection('habits')
            .doc(widget.habitId)
            .collection('routines')
            .add({
          'name': 'Routine ${now.month}/${now.day}/${now.year}', // Prompt for name in a real app, auto-gen for now
          'exercises': workoutData['exercises'],
          'timestamp': now,
        });
      }

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

  Future<void> _loadRoutine() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('habits')
        .doc(widget.habitId)
        .collection('routines')
        .get();

    if (snapshot.docs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No routines found.')),
      );
      return;
    }

    if (!mounted) return;
    final selectedRoutine = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select Routine'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: snapshot.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.docs[index];
                final data = doc.data();
                return ListTile(
                  title: Text(data['name'] ?? 'Routine'),
                  onTap: () => Navigator.pop(context, data),
                );
              },
            ),
          ),
        );
      }
    );

    if (selectedRoutine != null) {
      final exercisesData = selectedRoutine['exercises'] as List<dynamic>?;
      if (exercisesData != null) {
        setState(() {
          for (var ex in _exercises) {
            ex.dispose();
          }
          _exercises.clear();
          
          for (var exData in exercisesData) {
            final ex = ExerciseEntry();
            ex.nameCtrl.text = exData['name'] ?? '';
            ex.category = exData['category'] ?? 'Push';
            ex.noteCtrl.text = exData['note'] ?? '';
            ex.trackingType = exData['trackingType'] == TrackingType.timeAndDistance.toString() 
                ? TrackingType.timeAndDistance 
                : TrackingType.weightAndReps;
            
            ex.sets.clear();
            final setsData = exData['sets'] as List<dynamic>?;
            if (setsData != null && setsData.isNotEmpty) {
              for (var setData in setsData) {
                final setEntry = SetEntry();
                setEntry.repsCtrl.text = setData['reps']?.toString() ?? '';
                setEntry.weightCtrl.text = setData['weight']?.toString() ?? '';
                setEntry.timeCtrl.text = setData['time']?.toString() ?? '';
                setEntry.distanceCtrl.text = setData['distance']?.toString() ?? '';
                ex.sets.add(setEntry);
              }
            } else {
               ex.sets.add(SetEntry());
            }
            _exercises.add(ex);
          }
          if (_exercises.isEmpty) _exercises.add(ExerciseEntry());
        });
      }
    }
  }

  void _showTimerBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Timers", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  // Stopwatch UI
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        const Text("Stopwatch", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(_stopwatchText, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFeatures: [FontFeature.tabularFigures()])),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                _toggleStopwatch();
                                setModalState(() {});
                                setState(() {});
                              },
                              child: Text(_stopwatch.isRunning ? "Pause" : "Start"),
                            ),
                            const SizedBox(width: 16),
                            TextButton(
                              onPressed: () {
                                _resetStopwatch();
                                setModalState(() {});
                                setState(() {});
                              },
                              child: const Text("Reset"),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Countdown UI
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        const Text("Rest Timer", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("${(_countdownSeconds ~/ 60).toString().padLeft(2, '0')}:${(_countdownSeconds % 60).toString().padLeft(2, '0')}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFeatures: [FontFeature.tabularFigures()])),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                _startCountdown(30);
                                setModalState(() {});
                                setState(() {});
                              },
                              child: const Text("+30s"),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                _startCountdown(60);
                                setModalState(() {});
                                setState(() {});
                              },
                              child: const Text("+60s"),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                _startCountdown(90);
                                setModalState(() {});
                                setState(() {});
                              },
                              child: const Text("+90s"),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                             _countdownTimer?.cancel();
                             _countdownSeconds = 0;
                             setModalState(() {});
                             setState(() {});
                          },
                          child: const Text("Stop"),
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      }
    );
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showTimerBottomSheet,
        backgroundColor: Colors.black,
        child: const Icon(Icons.timer, color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Header Controls ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: _loadRoutine,
                  icon: const Icon(Icons.file_download, size: 18),
                  label: const Text("Load Routine"),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _saveAsRoutine,
                      onChanged: (val) => setState(() => _saveAsRoutine = val ?? false),
                    ),
                    const Text("Save as Routine", style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // --- Workout Notes ---
            TextFormField(
              controller: _workoutNoteCtrl,
              decoration: InputDecoration(
                hintText: "Workout Notes (e.g., Felt great today!)",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

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
                              onChanged: (val) => _onExerciseNameChanged(exercise),
                              decoration: const InputDecoration(
                                hintText: "Exercise Name",
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              validator: (val) => val!.isEmpty ? "Required" : null,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.note_add, color: exercise.isNoteVisible ? Colors.teal : Colors.grey),
                            onPressed: () => setState(() => exercise.isNoteVisible = !exercise.isNoteVisible),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.redAccent),
                            onPressed: () => _removeExercise(exIndex),
                          )
                        ],
                      ),
                      
                      // Custom Options (Category & Type)
                      Row(
                        children: [
                          DropdownButton<String>(
                            value: exercise.category,
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                            underline: const SizedBox(),
                            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) => setState(() => exercise.category = val!),
                          ),
                          const SizedBox(width: 16),
                          DropdownButton<TrackingType>(
                            value: exercise.trackingType,
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: TrackingType.weightAndReps, child: Text("Weight & Reps")),
                              DropdownMenuItem(value: TrackingType.timeAndDistance, child: Text("Time & Distance")),
                            ],
                            onChanged: (val) => setState(() => exercise.trackingType = val!),
                          ),
                        ],
                      ),
                      
                      // Notes specific to exercise
                      if (exercise.isNoteVisible) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: exercise.noteCtrl,
                          decoration: InputDecoration(
                            hintText: "Exercise Notes",
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 16),
                      
                      // Headers for Sets
                      Row(
                        children: [
                          const SizedBox(width: 30, child: Text("Set", style: TextStyle(color: Colors.grey, fontSize: 12))),
                          if (exercise.trackingType == TrackingType.weightAndReps) ...[
                            const Expanded(child: Text("lbs/kg", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))),
                            const Expanded(child: Text("Reps", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))),
                          ] else ...[
                            const Expanded(child: Text("Seconds", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))),
                            const Expanded(child: Text("Miles/Km", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))),
                          ],
                          const SizedBox(width: 48), // Spacing for delete icon
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Sets List
                      ...exercise.sets.asMap().entries.map((setEntry) {
                        int setIndex = setEntry.key;
                        SetEntry set = setEntry.value;

                        String? previousText;
                        if (exercise.trackingType == TrackingType.weightAndReps) {
                           if (set.previousWeight != null && set.previousReps != null) {
                             previousText = "Prev: ${set.previousWeight}x${set.previousReps}";
                           }
                        } else {
                           if (set.previousTime != null && set.previousDistance != null) {
                             previousText = "Prev: ${set.previousTime}s ${set.previousDistance}m";
                           }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (previousText != null) 
                                Padding(
                                  padding: const EdgeInsets.only(left: 30, bottom: 4),
                                  child: GestureDetector(
                                    onTap: () {
                                      // Auto-fill
                                      setState(() {
                                        if (exercise.trackingType == TrackingType.weightAndReps) {
                                          set.weightCtrl.text = set.previousWeight?.toString() ?? '';
                                          set.repsCtrl.text = set.previousReps?.toString() ?? '';
                                        } else {
                                          set.timeCtrl.text = set.previousTime?.toString() ?? '';
                                          set.distanceCtrl.text = set.previousDistance?.toString() ?? '';
                                        }
                                      });
                                    },
                                    child: Text(previousText, style: TextStyle(fontSize: 10, color: Colors.blue.shade300, fontStyle: FontStyle.italic)),
                                  ),
                                ),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 30, 
                                    child: Text("${setIndex + 1}", style: const TextStyle(fontWeight: FontWeight.bold))
                                  ),
                                  if (exercise.trackingType == TrackingType.weightAndReps) ...[
                                    Expanded(child: _buildNumberInput(set.weightCtrl, "Weight")),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildNumberInput(set.repsCtrl, "Reps")),
                                  ] else ...[
                                    Expanded(child: _buildNumberInput(set.timeCtrl, "Time")),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildNumberInput(set.distanceCtrl, "Dist")),
                                  ],
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                                    onPressed: () => _removeSet(exIndex, setIndex),
                                  )
                                ],
                              ),
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
            const SizedBox(height: 100), // extra padding for FAB
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
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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