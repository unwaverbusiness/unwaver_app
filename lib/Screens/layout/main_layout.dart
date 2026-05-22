import 'package:flutter/material.dart';
import '../today/today_screen.dart';
import '../Habits/habits_screen.dart';
import '../purpose/purpose_generator_screen.dart';
import '../Schedule/schedule_screen.dart';
import 'package:provider/provider.dart';
import '../../services/app_data_service.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;

  const MainLayout({
    super.key, 
    this.initialIndex = 2 
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppDataService>(context, listen: false).loadFromFirebase();
    });
  }

  final List<Widget> _screens = [
    const TodayScreen(),
    const HabitsScreen(),
    const PurposeGeneratorScreen(),
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
            icon: TodayNavIcon(isSelected: false),
            selectedIcon: TodayNavIcon(isSelected: true),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Planner',
          ),
          NavigationDestination(
            icon: PurposeNavIcon(), 
            label: 'Purpose',
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
  final double visualSize;
  final double layoutSize;

  const PurposeNavIcon({
    super.key, 
    this.visualSize = 50.0, 
    this.layoutSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the icon color based on the current nav bar color (White or Black)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.black : Colors.white;

    return SizedBox(
      height: layoutSize,
      width: layoutSize,
      child: OverflowBox(
        maxHeight: visualSize,
        maxWidth: visualSize,
        child: Image.asset(
          'assets/PurposeButton.png',
          fit: BoxFit.contain,
          color: iconColor, 
        ),
      ),
    );
  }
}

class TodayNavIcon extends StatelessWidget {
  final bool isSelected;
  
  const TodayNavIcon({
    super.key, 
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final dayString = DateTime.now().day.toString();
    final iconColor = IconTheme.of(context).color;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          isSelected ? Icons.calendar_today : Icons.calendar_today_outlined,
          size: 24,
        ),
        Positioned(
          top: 9, // Centered in the blank space of the calendar_today icon
          child: Text(
            dayString,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: iconColor,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}