import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Variables to track the current date state
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black, // Changed to Black
        elevation: 0,
      ),

      // 1. DRAWER (Updated to Black Theme)
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black), // Header background
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
                    "Plan Your Success",
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
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Tasks'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to Tasks
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: Colors.black), // Icon Color
              title: const Text('Calendar'),
              selected: true,
              selectedColor: Colors.black, // Text Color
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,

            // Logic to highlight the selected day
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: _onDaySelected,

            // Update the view when the month is swiped
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },

            // Styling matched to Black Theme
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: Colors.black, // Selected day is solid Black
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.grey[800], // Today is Dark Grey
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(color: Colors.white),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false, 
              titleCentered: true,
              // Month Title Color
              titleTextStyle: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black),
            ),
          ),

          const SizedBox(height: 20),

          // Display the selected date below
          Text(
            _selectedDay != null
                ? "Selected: ${_selectedDay.toString().split(' ')[0]}"
                : "No date selected",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}