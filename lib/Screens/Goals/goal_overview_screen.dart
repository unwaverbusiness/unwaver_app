import 'package:flutter/material.dart';

class GoalOverviewScreen extends StatefulWidget {
  const GoalOverviewScreen({super.key});

  @override
  State<GoalOverviewScreen> createState() => _GoalOverviewScreenState();
}

class _GoalOverviewScreenState extends State<GoalOverviewScreen> {
  // This is dummy data. Later we will pull this from your "Logic" folder or Firebase.
  final List<Map<String, dynamic>> _goals = [
    {
      "title": "Drink 2L Water",
      "subtitle": "Health • 5 Day Streak",
      "progress": 0.5, // 50%
      "icon": Icons.local_drink,
      "color": Colors.blue,
    },
    {
      "title": "Read 10 Pages",
      "subtitle": "Growth • 12 Day Streak",
      "progress": 0.8, // 80%
      "icon": Icons.book,
      "color": Colors.purple,
    },
    {
      "title": "Gym Workout",
      "subtitle": "Health • 3 Day Streak",
      "progress": 0.0, // 0%
      "icon": Icons.fitness_center,
      "color": Colors.orange,
    },
    {
      "title": "Code Unwaver App",
      "subtitle": "Career • 20 Day Streak",
      "progress": 0.3, // 30%
      "icon": Icons.computer,
      "color": Colors.teal,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Goals'),
        centerTitle: false,
        automaticallyImplyLeading: false, // Removes back button since it's a main tab
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Create Goal Feature Coming Soon!")),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircularProgressIndicator(
                  value: 0.65, // Example total progress
                  backgroundColor: Colors.grey[300],
                  color: Theme.of(context).primaryColor,
                  strokeWidth: 8,
                ),
                const SizedBox(width: 20),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily Progress",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text("You have completed 3/5 goals"),
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
                  leading: CircleAvatar(
                    backgroundColor: goal['color'].withOpacity(0.2),
                    child: Icon(goal['icon'], color: goal['color']),
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
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  isThreeLine: true,
                  onTap: () {
                    // Navigate to details later
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}