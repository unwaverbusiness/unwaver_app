import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:unwaver/services/app_data_service.dart';
import 'package:unwaver/screens/habits/exercise/exercise_screen.dart';

import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'habit_constants.dart';
import 'package:unwaver/screens/habits/ai_activity_creator_screen.dart';
// import 'workout_tracking_screen.dart'; 

class ActivityCreationScreen extends StatefulWidget {
  const ActivityCreationScreen({super.key});

  @override
  State<ActivityCreationScreen> createState() => _ActivityCreationScreenState();
}

class _ActivityCreationScreenState extends State<ActivityCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Controllers & State ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _itemClass = 'habit'; // 'habit', 'goal', 'task'
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
  List<String> get _currentTypes {
    if (_itemClass == 'goal') return ['Short-Term', 'Long-Term', 'Bucket List'];
    if (_itemClass == 'task') return ['One-Time', 'Recurring'];
    if (_itemClass == 'event') return ['One-Time', 'Recurring'];
    return ['Habits to Build', 'Habits to Break'];
  }
  
  final List<Tag> _selectedTags = [];

  final List<String> _levels = ['Low', 'Medium', 'High', 'Critical'];

  // Expanded icon and color library removed, using habit_constants instead

  Future<void> _openAiCreator() async {
    final data = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AiActivityCreatorScreen()),
    );

    if (data != null && data is Map<String, dynamic>) {
      setState(() {
        if (data.containsKey('itemClass')) {
          _itemClass = data['itemClass'];
          if (!_currentTypes.contains(_habitType)) {
             _habitType = _currentTypes.first; 
          }
        }
        if (data.containsKey('type') && _currentTypes.contains(data['type'])) {
          _habitType = data['type'];
        }
        if (data.containsKey('title')) {
          _nameController.text = data['title'];
        }
        if (data.containsKey('description')) {
          _descriptionController.text = data['description'];
        }
        if (data.containsKey('pillar') && ['Health', 'Wealth', 'Mind', 'Soul', 'Relationships'].contains(data['pillar'])) {
          _selectedPillar = data['pillar'];
        }
        if (data.containsKey('category')) {
          _categoryController.text = data['category'];
        }
        if (data.containsKey('tags') && data['tags'] is List) {
          _selectedTags.clear();
          for (var tag in data['tags']) {
            _selectedTags.add(Tag(
              id: DateTime.now().millisecondsSinceEpoch.toString() + tag.toString(),
              name: tag.toString(),
              color: Colors.blueAccent,
            ));
          }
        }
        if (data.containsKey('iconCodePoint') && data.containsKey('iconFontFamily')) {
          _selectedIcon = IconData(data['iconCodePoint'], fontFamily: data['iconFontFamily']);
        }
      });
    }
  }

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
            itemCount: kHabitIcons.length,
            itemBuilder: (context, index) {
              return IconButton(
                icon: Icon(kHabitIcons[index], size: 30, color: Colors.black87),
                onPressed: () {
                  setState(() => _selectedIcon = kHabitIcons[index]);
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
    Color tempColor = _selectedColor;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Select a Color', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: HueRingPicker(
                      pickerColor: tempColor,
                      onColorChanged: (color) {
                        setDialogState(() {
                          tempColor = color;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Presets', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kPresetColors.map((color) => GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          tempColor = color;
                        });
                      },
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: tempColor == color ? Colors.black : Colors.grey.shade300, width: tempColor == color ? 3 : 1),
                        ),
                      ),
                    )).toList(),
                  ),
                  if (kRecentColors.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Recent', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kRecentColors.map((color) => GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            tempColor = color;
                          });
                        },
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: tempColor == color ? Colors.black : Colors.grey.shade300, width: tempColor == color ? 3 : 1),
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                child: const Text('Select'),
                onPressed: () {
                  setState(() => _selectedColor = tempColor);
                  if (!kRecentColors.contains(tempColor)) {
                    kRecentColors.insert(0, tempColor);
                    if (kRecentColors.length > 10) kRecentColors.removeLast();
                  } else {
                    kRecentColors.remove(tempColor);
                    kRecentColors.insert(0, tempColor);
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateTagDialog(BuildContext context, StateSetter setModalState) {
    final nameController = TextEditingController();
    Color selectedColor = Colors.blue;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New Tag'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tag Name'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Color:'),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Pick a color'),
                            content: SingleChildScrollView(
                              child: BlockPicker(
                                pickerColor: selectedColor,
                                onColorChanged: (c) => selectedColor = c,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  setDialogState(() {});
                                  Navigator.pop(context);
                                },
                                child: const Text('Select'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(color: selectedColor, shape: BoxShape.circle),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                
                final service = context.read<AppDataService>();
                final existingTag = service.tags.firstWhere(
                  (t) => t.name.toLowerCase() == name.toLowerCase(),
                  orElse: () {
                    final newTag = Tag(
                      id: 't_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      color: selectedColor,
                    );
                    service.addTag(newTag);
                    return newTag;
                  },
                );

                setState(() {
                  if (!_selectedTags.any((t) => t.id == existingTag.id)) {
                    _selectedTags.add(existingTag);
                  }
                });
                
                setModalState(() {});
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTagPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeTags = context.read<AppDataService>().activeTags;
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Select Tags", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("New Tag"),
                        onPressed: () => _showCreateTagDialog(context, setModalState),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (activeTags.isEmpty)
                    const Text("No tags available. Create some in the Tags menu!")
                  else
                    Wrap(
                      spacing: 8,
                      children: activeTags.map((tag) {
                        final isSelected = _selectedTags.any((t) => t.id == tag.id);
                        return FilterChip(
                          label: Text(tag.name),
                          selected: isSelected,
                          selectedColor: tag.color.withValues(alpha: 0.3),
                          checkmarkColor: tag.color,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedTags.add(tag);
                              } else {
                                _selectedTags.removeWhere((t) => t.id == tag.id);
                              }
                            });
                            setModalState(() {});
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                      child: const Text("Done"),
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  void _showNewPillarDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Life Pillar'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Pillar Name',
            hintText: 'e.g. Health, Career, etc.',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final service = context.read<AppDataService>();
                final exists = service.pillars.any((p) => p.name.toLowerCase() == name.toLowerCase());
                if (!exists) {
                  final newPillar = Pillar(
                    id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                  );
                  service.addPillar(newPillar);
                  setState(() {
                    _selectedPillar = name;
                    _categoryController.text = '';
                  });
                } else {
                  final existing = service.pillars.firstWhere((p) => p.name.toLowerCase() == name.toLowerCase());
                  setState(() {
                    _selectedPillar = existing.name;
                    _categoryController.text = '';
                  });
                }
              }
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showNewSubPillarDialog(BuildContext context, Pillar currentPillar) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Sub-Pillar for ${currentPillar.name}'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Sub-Pillar Name',
            hintText: 'e.g. Yoga, Diet, etc.',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final service = context.read<AppDataService>();
                final exists = currentPillar.subPillars.any((sub) => sub.toLowerCase() == name.toLowerCase());
                if (!exists) {
                  final updatedSubs = List<String>.from(currentPillar.subPillars)..add(name);
                  service.updatePillar(currentPillar.copyWith(subPillars: updatedSubs));
                  setState(() {
                    _categoryController.text = name;
                  });
                } else {
                  final existingName = currentPillar.subPillars.firstWhere((sub) => sub.toLowerCase() == name.toLowerCase());
                  setState(() {
                    _categoryController.text = existingName;
                  });
                }
              }
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // --- SMART SAVE LOGIC (Handles Both Flows) ---
  Future<void> _saveHabit({bool recordWorkoutNext = false}) async {
    if (_formKey.currentState!.validate() && !_isSaving) {
      setState(() => _isSaving = true);
      FocusScope.of(context).unfocus(); // Dismiss keyboard

      final newHabit = {
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'itemClass': _itemClass,
        'title': _nameController.text.trim(),
        'type': _habitType,
        'category': _categoryController.text.trim(),
        'tags': _selectedTags.map((t) => t.name).toList(), // Saving names for backward compat in Firestore
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
        if (recordWorkoutNext) {
          final docRef = await FirebaseFirestore.instance.collection('habits').add(newHabit);
          if (!mounted) return;
          
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
          final String activityName = _nameController.text.trim().isEmpty ? "Activity" : _nameController.text.trim();
          final String activityType = _formatUI(_itemClass, true); // formats 'habit' to 'Habit'
          
          // Save in background (optimistic update)
          Future.microtask(() async {
            try {
              await FirebaseFirestore.instance.collection('habits').add(newHabit);
            } catch (e) {
              debugPrint("Error saving: $e");
            }
          });
          
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$activityName $activityType Created!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
          
          Navigator.pop(context); // Standard save, go back to dashboard
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving habit: $e')),
        );
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  String _formatUI(String val, bool toUpper) {
    if (val.isEmpty) return '';
    if (toUpper) return val.toUpperCase();
    return val[0].toUpperCase() + val.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("New Activity", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.blueAccent),
            tooltip: "Create with AI",
            onPressed: _openAiCreator,
          ),
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
            // --- Item Class Toggle ---
            _buildItemClassToggle(),
            const SizedBox(height: 24),

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
              validator: (val) => val == null || val.trim().isEmpty ? "Please enter a name" : null,
            ),
            const SizedBox(height: 20),

            _buildLabel("Classification"),
            _buildDropdown(_currentTypes, _habitType, (val) => setState(() => _habitType = val!)),
            const SizedBox(height: 20),

            _buildLabel("Life Pillar"),
            Consumer<AppDataService>(
              builder: (context, dataService, _) {
                final pillars = dataService.pillars.map((p) => p.name).toList();
                if (pillars.isEmpty) return const Text("No pillars available.");
                if (!pillars.contains(_selectedPillar)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() => _selectedPillar = pillars.first);
                  });
                }
                final dropdownItems = [...pillars, '+ Add New Pillar...'];
                return _buildDropdown(
                  dropdownItems,
                  _selectedPillar,
                  (val) {
                    if (val == '+ Add New Pillar...') {
                      _showNewPillarDialog(context);
                    } else {
                      setState(() => _selectedPillar = val!);
                    }
                  },
                );
              }
            ),
            const SizedBox(height: 20),

            _buildLabel("Category (Sub-pillar)"),
            Consumer<AppDataService>(
              builder: (context, dataService, _) {
                final currentPillar = dataService.pillars.where((p) => p.name == _selectedPillar).firstOrNull;
                final subs = currentPillar?.subPillars ?? [];
                
                if (subs.isEmpty) {
                  return TextFormField(
                    controller: _categoryController,
                    decoration: _inputDecoration("e.g. Cardio"),
                  );
                } else {
                  if (_categoryController.text.isEmpty || !subs.contains(_categoryController.text)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() => _categoryController.text = subs.first);
                    });
                  }
                  final dropdownItems = [...subs, '+ Add New Sub-Pillar...'];
                  return _buildDropdown(
                    dropdownItems,
                    _categoryController.text,
                    (val) {
                      if (val == '+ Add New Sub-Pillar...') {
                        _showNewSubPillarDialog(context, currentPillar!);
                      } else {
                        setState(() => _categoryController.text = val!);
                      }
                    },
                  );
                }
              }
            ),
            const SizedBox(height: 16),
            _buildLabel("Tags"),
            InkWell(
              onTap: _showTagPicker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 8,
                  children: _selectedTags.isEmpty
                      ? [Text("Select tags...", style: TextStyle(color: Colors.grey.shade400))]
                      : _selectedTags.map((tag) => Chip(
                            label: Text(tag.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                            backgroundColor: tag.color,
                            onDeleted: () => setState(() => _selectedTags.removeWhere((t) => t.id == tag.id)),
                          )).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Exercise Toggle
            if (_selectedPillar == 'Health')
              Row(
                children: [
                  const Expanded(
                    child: Text("Track Workouts",
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
              decoration: _inputDecoration("Describe the item and why it matters..."),
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
                    : Text("CREATE ${_itemClass.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemClassToggle() {
    final Map<String, String> classes = {
      'habit': 'Habit',
      'goal': 'Goal',
      'task': 'Task',
      'event': 'Event',
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: classes.entries.map((entry) {
        final isSelected = _itemClass == entry.key;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _itemClass = entry.key;
                if (entry.key == 'habit') _habitType = 'Habits to Build';
                if (entry.key == 'goal') _habitType = 'Short-Term';
                if (entry.key == 'task') _habitType = 'One-Time';
                if (entry.key == 'event') _habitType = 'One-Time';
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                entry.value,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
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