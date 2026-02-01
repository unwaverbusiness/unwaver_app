import 'package:flutter/material.dart';
import 'package:unwaver/widgets/maindrawer.dart'; 
import 'package:unwaver/widgets/app_logo.dart';   
// IMPORT FIX: Ensure this file exists in the same folder!
import 'goal_creation_screen.dart'; 

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
      // FIX: Explicitly tell Flutter this is a double
      total += (goal['progress'] as double);
    }
    return total / _goals.length;
  }

  int get _completedCount {
    // FIX: Explicitly cast to double before comparing
    return _goals.where((g) => (g['progress'] as double) >= 1.0).length;
  }

  void _updateProgress(int index) {
    setState(() {
      // FIX: Explicitly cast to double
      double current = (_goals[index]['progress'] as double);
      if (current >= 1.0) {
        _goals[index]['progress'] = 0.0;
      } else {
        _goals[index]['progress'] = (current + 0.25).clamp(0.0, 1.0);
      }
    });
  }

  void _navToCreation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GoalCreationScreen()),
    );
  }

  // --- UI BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
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
                      color: Colors.black, 
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
                
                // FIX: Cast variables for safety
                final Color goalColor = goal['color'] as Color;
                final IconData goalIcon = goal['icon'] as IconData;
                final double goalProgress = goal['progress'] as double;
                final String goalTitle = goal['title'] as String;
                final String goalSubtitle = goal['subtitle'] as String;

                return ListTile(
                  leading: GestureDetector(
                    onTap: () => _updateProgress(index),
                    child: CircleAvatar(
                      backgroundColor: goalColor.withOpacity(0.2),
                      child: Icon(goalIcon, color: goalColor),
                    ),
                  ),
                  title: Text(goalTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goalSubtitle),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: goalProgress,
                        backgroundColor: Colors.grey[200],
                        color: goalColor,
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

      floatingActionButton: FloatingActionButton(
        onPressed: _navToCreation,
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}