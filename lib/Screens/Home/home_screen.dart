import 'package:flutter/material.dart';
import 'purpose_generator_screen.dart'; // Ensure this file exists

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Set default index to 2 so "Purpose" (the middle tab) is the Home
  int _selectedIndex = 2;

  // --- THE 5 TABS ---
  static const List<Widget> _widgetOptions = <Widget>[
    GoalsView(),      // Index 0
    HabitsView(),     // Index 1
    PurposeGeneratorScreen(), // Index 2 (HOME)
    TasksView(),      // Index 3
    CalendarView(),   // Index 4
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- UNIFIED APP BAR WITH LOGO ---
      appBar: AppBar(
        // This puts your logo in the center of the bar
        title: Image.asset(
          'assets/Unwaver App Icon.png',
          height: 40,        // Adjusts the size
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        
        // White background to make the logo pop
        backgroundColor: Colors.white,
        elevation: 0, 
        
        // This ensures the "Hamburger" menu icon stays visible (Teal)
        iconTheme: const IconThemeData(color: Colors.teal),
      ),
      
      // --- MAIN DRAWER (SIDE MENU) ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              accountName: Text("Nick"),
              accountEmail: Text("unwaver.business@gmail.com"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text("N", style: TextStyle(fontSize: 24, color: Colors.teal)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Account'),
              onTap: () {
                Navigator.pop(context); // Closes the drawer
                // TODO: Navigate to Profile
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
             const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                // TODO: Add Logout Logic
              },
            ),
          ],
        ),
      ),

      // --- BODY CONTENT ---
      body: _widgetOptions.elementAt(_selectedIndex),

      // --- 5-TAB BOTTOM NAVIGATION ---
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.flag_outlined), label: 'Goals'),
          BottomNavigationBarItem(icon: Icon(Icons.repeat), label: 'Habits'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'Purpose'),
          BottomNavigationBarItem(icon: Icon(Icons.check_box_outlined), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed, // CRITICAL for 4+ items
        onTap: _onItemTapped,
      ),
    );
  }
}

// --- PLACEHOLDER WIDGETS FOR NEW TABS ---
class GoalsView extends StatelessWidget {
  const GoalsView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Goals Tracker Coming Soon"));
  }
}

class HabitsView extends StatelessWidget {
  const HabitsView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Habits Tracker Coming Soon"));
  }
}

class TasksView extends StatelessWidget {
  const TasksView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Tasks Manager Coming Soon"));
  }
}

class CalendarView extends StatelessWidget {
  const CalendarView({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Calendar Coming Soon"));
  }
}