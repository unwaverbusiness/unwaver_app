import 'package:flutter/material.dart';
import 'package:unwaver/widgets/MainDrawer.dart';

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
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.calendar_month))
        ],
      ),
      // FIX 1: Add the required 'currentRoute' argument
      drawer: MainDrawer(currentRoute: '/habits'),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _habits.length,
        itemBuilder: (context, index) {
          final habit = _habits[index];
          return Card(
            elevation: 0,
            // FIX 2: syntax was likely broken here in your previous file
            color: habit['isCompleted']
                // ignore: deprecated_member_use
                ? Colors.green.withOpacity(0.1)
                // ignore: deprecated_member_use
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
              trailing: IconButton(
                onPressed: () => _toggleHabit(index),
                icon: Icon(
                  habit['isCompleted'] ? Icons.check_circle : Icons.cancel,
                  color: habit['isCompleted'] ? Colors.lightGreen : Colors.red,
                  size: 30,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}