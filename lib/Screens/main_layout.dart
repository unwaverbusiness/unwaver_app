import 'package:flutter/material.dart';

import 'Goals/goal_overview_screen.dart';
import 'Habits/habits_screen.dart';
import 'Home/purpose_generator_screen.dart';
import 'Tasks/tasks_screen.dart';
import 'Calendar/calendar_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // --- THE 5 SCREENS ---
  final List<Widget> _screens = [
    const GoalOverviewScreen(),      // Index 0: Goals
    const HabitsScreen(),            // Index 1: Habits
    const PurposeGeneratorScreen(),  // Index 2: Purpose
    const TasksScreen(),             // Index 3: Tasks
    const CalendarScreen(),          // Index 4: Calendar
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps your Goal/Habit data alive when you switch tabs
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        // --- THE 5 NAVIGATION TABS ---
        destinations: const <NavigationDestination>[
          // 1. Goals
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Goals',
          ),
          
          // 2. Habits
          NavigationDestination(
            icon: Icon(Icons.cached), 
            selectedIcon: Icon(Icons.cached),
            label: 'Habits',
          ),
          
          // 3. Purpose
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Purpose',
          ),
          
          // 4. Tasks
          NavigationDestination(
            icon: Icon(Icons.check_box_outlined),
            selectedIcon: Icon(Icons.check_box),
            label: 'Tasks',
          ),
          
          // 5. Calendar
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
        ],
      ),
    );
  }
}