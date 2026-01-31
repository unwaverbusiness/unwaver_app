import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:unwaver/widgets/maindrawer.dart'; // Import your custom drawer

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
        // Removed manual colors to use the Global Black Theme from main.dart
      ),

      // 1. REPLACED HARDCODED DRAWER WITH MAIN DRAWER
      drawer: const MainDrawer(currentRoute: '/calendar'),

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