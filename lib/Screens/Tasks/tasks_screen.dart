import 'package:flutter/material.dart';
import 'package:unwaver/widgets/maindrawer.dart'; 
import 'package:unwaver/widgets/app_logo.dart';
// IMPORT FIX: Ensure this file exists in the same folder!
import 'task_creation_screen.dart';   

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

  // REPLACED: _showAddTaskDialog is gone.
  // NEW: Navigation helper function
  void _navToCreation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TaskCreationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),

      drawer: const MainDrawer(currentRoute: '/tasks'),

      // UPDATED: Floating Action Button now navigates
      floatingActionButton: FloatingActionButton(
        onPressed: _navToCreation,
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          return Dismissible(
            key: Key(_tasks[index]['title']),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) => _deleteTask(index),
            child: Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: CheckboxListTile(
                activeColor: const Color.fromARGB(255, 187, 142, 19),
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
                controlAffinity: ListTileControlAffinity.leading, 
              ),
            ),
          );
        },
      ),
    );
  }
}