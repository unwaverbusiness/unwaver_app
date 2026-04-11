import 'package:flutter/material.dart';
import '../Goals/goal_overview_screen.dart';
import '../Habits/habits_screen.dart';
import '../purpose/purpose_generator_screen.dart';
import '../Tasks/tasks_screen.dart';
import '../Schedule/schedule_screen.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;

  const MainLayout({
    super.key, 
    this.initialIndex = 0 
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    const GoalOverviewScreen(),
    const HabitsScreen(),
    const PurposeGeneratorScreen(),
    const TasksScreen(),
    const ScheduleScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      // Automatically uses Black/White styling from main.dart
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.track_changes_outlined),
            selectedIcon: Icon(Icons.track_changes),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.cached),
            selectedIcon: Icon(Icons.cached),
            label: 'Habits',
          ),
          NavigationDestination(
            icon: PurposeNavIcon(size: 60), 
            label: 'Purpose',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_box_outlined),
            selectedIcon: Icon(Icons.check_box),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
        ],
      ),
    );
  }
}

class PurposeNavIcon extends StatelessWidget {
  final double size;

  const PurposeNavIcon({
    super.key, 
    this.size = 24.0, 
  });

  @override
  Widget build(BuildContext context) {
    // Determine the icon color based on the current nav bar color (White or Black)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.black : Colors.white;

    return SizedBox(
      height: size,
      width: size,
      child: Image.asset(
        'assets/PurposeButton.png',
        fit: BoxFit.contain,
        color: iconColor, 
      ),
    );
  }
}