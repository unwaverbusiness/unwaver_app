import 'package:flutter/material.dart';
import 'Goals/goal_overview_screen.dart';
import 'Habits/habits_screen.dart';
import 'home/purpose_generator_screen.dart';
import 'Tasks/tasks_screen.dart';
import 'Schedule/schedule_screen.dart';

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
    const CalendarScreen(),
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C2C2C),
              Color(0xFF000000),
            ],
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            iconTheme: WidgetStateProperty.resolveWith((states) {
              return const IconThemeData(color: Colors.white);
            }),
            labelTextStyle: WidgetStateProperty.all(
              const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            indicatorColor: const Color.fromARGB(255, 187, 142, 19),
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
              
              // --- FIX APPLIED HERE ---
              NavigationDestination(
                // Unselected: Shows original PNG colors
                icon: PurposeNavIcon(size: 60, color: null), 
                // Selected: Tints the image white
                selectedIcon: PurposeNavIcon(size: 60, color: Colors.white), 
                label: 'Purpose',
              ),
              // -----------------------

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
        ),
      ),
    );
  }
}

class PurposeNavIcon extends StatelessWidget {
  final double size;
  final Color? color; 

  const PurposeNavIcon({
    super.key, 
    this.size = 24.0, 
    this.color, 
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: Image.asset(
        'assets/PurposeButton.png',
        fit: BoxFit.contain,
        color: color, 
      ),
    );
  }
}