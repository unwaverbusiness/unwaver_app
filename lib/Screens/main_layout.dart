import 'package:flutter/material.dart';
// REMOVED: import 'package:widgets/purpose_nav_icon.dart'; (Not needed since class is below)
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
      
      // Wrap NavigationBar in a Container to apply the gradient
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C2C2C), // Dark Grey (Top)
              Color(0xFF000000), // Pure Black (Bottom)
            ],
          ),
        ),
        child: NavigationBarTheme(
          // Theme wrapper to force icon colors
          data: NavigationBarThemeData(
            iconTheme: WidgetStateProperty.resolveWith((states) {
              // If selected, icon is white (useful for standard icons)
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: Colors.white);
              }
              // If unselected, icon is white
              return const IconThemeData(color: Colors.white);
            }),
            labelTextStyle: WidgetStateProperty.all(
              const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          child: NavigationBar(
            // Make background transparent so gradient shows through
            backgroundColor: Colors.transparent,
            
            // Gold Selection Indicator
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
              
              // --- UPDATED PURPOSE BUTTON ---
              NavigationDestination(
                icon: PurposeNavIcon(size: 60), // Unselected State
                selectedIcon: PurposeNavIcon(size: 60), // Selected State (Slightly larger)
                label: 'Purpose',
              ),
              // ------------------------------

              NavigationDestination(
                icon: Icon(Icons.check_box_outlined),
                selectedIcon: Icon(Icons.check_box),
                label: 'Tasks',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: 'Calendar',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- CUSTOM WIDGET DEFINITION ---
// Because this class is here, you do not need to import it at the top.
class PurposeNavIcon extends StatelessWidget {
  final double size;

  const PurposeNavIcon({
    super.key, 
    this.size = 24.0, 
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: Image.asset(
        'assets/PurposeButton.png',
        fit: BoxFit.contain,
        // Note: No color is applied here, so it uses the original image colors.
      ),
    );
  }
}