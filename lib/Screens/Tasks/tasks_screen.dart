import 'package:flutter/material.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  // This list holds your tasks
  final List<Map<String, dynamic>> _tasks = [
    {'title': 'Buy groceries', 'isDone': false},
    {'title': 'Call mom', 'isDone': false},
    {'title': 'Finish Flutter app', 'isDone': true},
  ];

  // Function to add a new task
  void _addTask(String taskTitle) {
    setState(() {
      _tasks.add({'title': taskTitle, 'isDone': false});
    });
  }

  // Function to toggle checkbox
  void _toggleTask(int index) {
    setState(() {
      _tasks[index]['isDone'] = !_tasks[index]['isDone'];
    });
  }

  // Function to delete task
  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  // Pop-up dialog to type new task
  void _showAddTaskDialog() {
    String newTask = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Task'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter task name'),
          onChanged: (value) => newTask = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newTask.isNotEmpty) {
                _addTask(newTask);
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
        title: const Text('My Tasks'),
        centerTitle: true,
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
                    "Get Things Done",
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
              leading: const Icon(Icons.repeat),
              title: const Text('Habits'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to Habits
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Colors.teal),
              title: const Text('Tasks'),
              selected: true, // Highlights this item
              selectedColor: Colors.teal,
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),

      // Floating + Button
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          return Dismissible(
            // Key is needed for swiping to delete
            key: Key(_tasks[index]['title']),
            background: Container(color: Colors.red),
            onDismissed: (direction) => _deleteTask(index),
            child: CheckboxListTile(
              activeColor: Colors.teal,
              title: Text(
                _tasks[index]['title'],
                style: TextStyle(
                  decoration: _tasks[index]['isDone']
                      ? TextDecoration.lineThrough
                      : null,
                  color: _tasks[index]['isDone'] ? Colors.grey : Colors.black,
                ),
              ),
              value: _tasks[index]['isDone'],
              onChanged: (value) => _toggleTask(index),
            ),
          );
        },
      ),
    );
  }
}