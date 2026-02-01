import 'package:flutter/material.dart';
import 'package:unwaver/widgets/maindrawer.dart'; // <--- Added
import 'package:unwaver/widgets/app_logo.dart';   // <--- Added

class GoalOverviewScreen extends StatefulWidget {
  const GoalOverviewScreen({super.key});

  @override
  State<GoalOverviewScreen> createState() => _GoalOverviewScreenState();
}

class _GoalOverviewScreenState extends State<GoalOverviewScreen> {
  // --- STATE LOGIC ---
  final List<Map<String, dynamic>> _goals = [
    {
      "title": "Drink 2L Water",
      "subtitle": "Health • 5 Day Streak",
      "progress": 0.5,
      "icon": Icons.local_drink,
      "color": Colors.blue,
    },
    {
      "title": "Read 10 Pages",
      "subtitle": "Growth • 12 Day Streak",
      "progress": 0.8,
      "icon": Icons.book,
      "color": Colors.purple,
    },
    {
      "title": "Gym Workout",
      "subtitle": "Health • 3 Day Streak",
      "progress": 0.0,
      "icon": Icons.fitness_center,
      "color": const Color.fromARGB(255, 0, 255, 213),
    },
  ];

  double get _overallProgress {
    if (_goals.isEmpty) return 0.0;
    double total = 0.0;
    for (var goal in _goals) {
      total += goal['progress'];
    }
    return total / _goals.length;
  }

  int get _completedCount {
    return _goals.where((g) => g['progress'] >= 1.0).length;
  }

  void _addNewGoal(String title, String category) {
    setState(() {
      _goals.add({
        "title": title,
        "subtitle": "$category • 0 Day Streak",
        "progress": 0.0,
        "icon": Icons.star,
        "color": Colors.indigo,
      });
    });
  }

  void _updateProgress(int index) {
    setState(() {
      double current = _goals[index]['progress'];
      if (current >= 1.0) {
        _goals[index]['progress'] = 0.0;
      } else {
        _goals[index]['progress'] = (current + 0.25).clamp(0.0, 1.0);
      }
    });
  }

  void _showAddGoalDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // Use AppLogo here for consistency if desired, or keep generic text
        title: const AppLogo(), 
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Goal Title',
                hintText: 'e.g. Meditate',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'e.g. Health',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black, // Match your theme
            ),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                _addNewGoal(
                  titleController.text,
                  categoryController.text.isEmpty ? "General" : categoryController.text,
                );
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black, // Match your theme
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // --- UI BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // FIXED: Replaced Text title with AppLogo
        title: const AppLogo(),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddGoalDialog,
          ),
        ],
      ),
      
      // FIXED: Used MainDrawer instead of hardcoded Drawer
      drawer: const MainDrawer(currentRoute: '/goals'),

      body: Column(
        children: [
          // 1. Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _overallProgress,
                      backgroundColor: Colors.grey[300],
                      color: Colors.black, // Updated to match theme
                      strokeWidth: 8,
                    ),
                    Text(
                      "${(_overallProgress * 100).toInt()}%",
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Daily Progress",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "You have completed $_completedCount/${_goals.length} goals",
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Goal List
          Expanded(
            child: ListView.builder(
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                return ListTile(
                  leading: GestureDetector(
                    onTap: () => _updateProgress(index),
                    child: CircleAvatar(
                      backgroundColor: goal['color'].withOpacity(0.2),
                      child: Icon(goal['icon'], color: goal['color']),
                    ),
                  ),
                  title: Text(goal['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal['subtitle']),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: goal['progress'],
                        backgroundColor: Colors.grey[200],
                        color: goal['color'],
                        minHeight: 5,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: Colors.grey,
                    onPressed: () => _updateProgress(index),
                  ),
                  isThreeLine: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}