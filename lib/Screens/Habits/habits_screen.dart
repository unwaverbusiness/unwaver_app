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
        centerTitle: false,
        automaticallyImplyLeading: false, // Removes back button
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.calendar_month))
        ],
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
                activeThumbColor: Colors.green,
                onChanged: (val) => _toggleHabit(index),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}