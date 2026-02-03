import 'package:flutter/material.dart';
import 'package:unwaver/widgets/maindrawer.dart';
import 'package:unwaver/widgets/app_logo.dart';
import 'goal_creation_screen.dart';
// IMPORT FIX: Assuming 'Goals' is a sibling folder to 'Goals'
import '../Goals/Goal_instruction_banner.dart'; 

class GoalOverviewScreen extends StatefulWidget {
  const GoalOverviewScreen({super.key});

  @override
  State<GoalOverviewScreen> createState() => _GoalOverviewScreenState();
}

class _GoalOverviewScreenState extends State<GoalOverviewScreen> {
  // --- STATE LOGIC ---
  
  // 1. Add the visibility toggle for the banner
  bool _showBanner = true;

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
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.calendar_month)),
        ],
      ),
      
      drawer: const MainDrawer(currentRoute: '/goals'),

      body: Column(
        children: [
          // 1. The Dismissible Banner (Replaces the Summary Card)
          if (_showBanner)
            GoalInstructionBanner(
              onDismiss: () {
                setState(() {
                  _showBanner = false;
                });
              },
            ),

          // 2. Goal List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
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
                      // ignore: deprecated_member_use
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