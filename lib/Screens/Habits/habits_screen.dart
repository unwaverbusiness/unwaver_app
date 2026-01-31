import 'package:flutter/material.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  // Dummy data - later this will fetch from Firebase
  final List<Map<String, dynamic>> _habits = [
    {"title": "Morning Meditation", "isCompleted": false, "streak": 12},
    {"title": "Drink 2L Water", "isCompleted": true, "streak": 5},
    {"title": "No Sugar", "isCompleted": false, "streak": 3},
    {"title": "Read 10 Pages", "isCompleted": false, "streak": 20},
  ];

  void _toggleHabit(int index) {
    setState(() {
      _habits[index]['isCompleted'] = !_habits[index]['isCompleted'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Habits"),
        centerTitle: true, // Changed to true for better UI balance
        // REMOVED: automaticallyImplyLeading: false (This allows the drawer icon to show)
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.calendar_month))
        ],
      ),

      // 1. ADDED DRAWER
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Unwaver",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Build Discipline",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Coach'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to Coach
              },
            ),
            ListTile(
              leading: const Icon(Icons.track_changes),
              title: const Text('Goals'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to Goals
              },
            ),
            ListTile(
              leading: const Icon(Icons.repeat, color: Colors.teal),
              title: const Text('Habits'),
              selected: true,
              selectedColor: Colors.teal,
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _habits.length,
        itemBuilder: (context, index) {
          final habit = _habits[index];
          return Card(
            elevation: 0,
            color: habit['isCompleted']
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: habit['isCompleted'] ? Colors.green : Colors.transparent,
              ),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Icon(
                  habit['isCompleted'] ? Icons.check : Icons.local_fire_department,
                  color: habit['isCompleted'] ? Colors.green : Colors.orange,
                  size: 20,
                ),
              ),
              title: Text(
                habit['title'],
                style: TextStyle(
                  decoration: habit['isCompleted'] ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.w600,
                  color: habit['isCompleted'] ? Colors.grey : Colors.black87,
                ),
              ),
              subtitle: Text("${habit['streak']} Day Streak"),
              trailing: Switch(
                value: habit['isCompleted'],
                activeColor: Colors.white,
                activeTrackColor: Colors.green,
                onChanged: (val) => _toggleHabit(index),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}