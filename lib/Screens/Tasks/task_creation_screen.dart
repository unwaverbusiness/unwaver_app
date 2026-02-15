import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskCreationScreen extends StatefulWidget {
  const TaskCreationScreen({super.key});

  @override
  State<TaskCreationScreen> createState() => _TaskCreationScreenState();
}

class _TaskCreationScreenState extends State<TaskCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Controllers ---
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  // --- State Variables ---
  String _priority = 'Medium';
  DateTime? _dueDate;
  TimeOfDay? _dueTime;

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Critical'];

  // --- Date & Time Pickers ---
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
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
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
      setState(() => _dueTime = picked);
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      // Create Task Object
      final newTask = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'category': _categoryController.text.isEmpty ? 'General' : _categoryController.text,
        'priority': _priority,
        'dueDate': _dueDate,
        'dueTime': _dueTime,
        'isDone': false,
      };

      debugPrint("Task Created: $newTask"); // Debug print
      Navigator.pop(context); // Return to Tasks Screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("New Task", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _saveTask,
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
            // 1. Task Title
            _buildLabel("Task Title"),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration("e.g. Finish Project Report"),
              validator: (val) => val!.isEmpty ? "Please enter a title" : null,
            ),
            const SizedBox(height: 20),

            // 2. Category
            _buildLabel("Category / Project"),
            TextFormField(
              controller: _categoryController,
              decoration: _inputDecoration("e.g. Work"),
            ),
            const SizedBox(height: 20),

            // 3. Priority
            _buildLabel("Priority"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _priority,
                  isExpanded: true,
                  items: _priorities.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                  onChanged: (val) => setState(() => _priority = val!),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 4. Date & Time Row
            _buildLabel("Due Date & Time"),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            _dueDate == null ? "Select Date" : DateFormat('MMM dd, yyyy').format(_dueDate!),
                            style: TextStyle(color: _dueDate == null ? Colors.grey : Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            _dueTime == null ? "Select Time" : _dueTime!.format(context),
                            style: TextStyle(color: _dueTime == null ? Colors.grey : Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 5. Description
            _buildLabel("Notes"),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: _inputDecoration("Add details..."),
            ),

            const SizedBox(height: 40),

            // 6. Create Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("CREATE TASK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
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
}