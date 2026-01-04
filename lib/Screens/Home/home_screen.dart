import 'package:flutter/material.dart';
import 'purpose_generator_screen.dart'; // <--- 1. IMPORT THE NEW SCREEN

// Note: If you are pasting this into 'home_screen.dart', you might not need 'main()' here.
// But I left it in case you are running this file standalone.
void main() {
  runApp(const GoalTrackerApp());
}

// 1. The Main App Application Widget
class GoalTrackerApp extends StatelessWidget {
  const GoalTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define specific shades of blue for consistency
    const Color primaryBlue = Color(0xFF1976D2); // A solid darker blue

    return MaterialApp(
      title: 'Basic Goal Tracker',
      debugShowCheckedModeBanner: false,
      // ---- THEME SETUP (Blue & White) ----
      theme: ThemeData(
        useMaterial3: true,
        // Ensure the main background is pure white
        scaffoldBackgroundColor: Colors.white,
        // Define the color scheme based on blue
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          brightness: Brightness.light, // Ensures light mode (white background)
          primary: primaryBlue,
          onPrimary: Colors.white, // Text on top of blue buttons/appbar should be white
        ),
        // Specific styling for the App Bar
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white, // Title text color
          elevation: 4,
          centerTitle: true,
        ),
        // Specific styling for the Floating Action Button
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
        ),
        // Styling for Checkboxes to match the theme
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryBlue;
            }
            return Colors.grey; // Unselected outline color
          }),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// 2. The Home Screen Layout
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Dummy data to visualize the layout
  final List<Map<String, dynamic>> dummyGoals = const [
    {"title": "Drink 8 glasses of water", "isDone": false},
    {"title": "Read 20 pages", "isDone": true},
    {"title": "Walk 10,000 steps", "isDone": false},
    {"title": "Meditate for 10 mins", "isDone": true},
    {"title": "Write code for 1 hour", "isDone": false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top App Bar
      appBar: AppBar(
        title: const Text('My Today Goals'),
        
        // <--- 2. ADDED THE AI BUTTON HERE ---
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome), // The "Sparkle" icon represents AI
            tooltip: 'Purpose Coach',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PurposeGeneratorScreen()),
              );
            },
          ),
        ],
        // ------------------------------------
        
      ),
      // Main Body: A list view of goals
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: dummyGoals.length,
        itemBuilder: (context, index) {
          return GoalTile(
            title: dummyGoals[index]['title'],
            isCompleted: dummyGoals[index]['isDone'],
          );
        },
      ),
      // The "Add" button at the bottom right
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Placeholder action
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add Goal Tapped (Functionality needed)'))
          );
        },
        tooltip: 'Add Goal',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// 3. A separate widget for an individual Goal item
class GoalTile extends StatelessWidget {
  final String title;
  final bool isCompleted;

  const GoalTile({
    super.key,
    required this.title,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    // We use a Card to give each item slight separation from the white background
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white, // Ensure card itself is white
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        // The Checkbox leading the tile
        leading: Transform.scale(
          scale: 1.2, // Make checkbox slightly larger
          child: Checkbox(
            value: isCompleted,
            // Shape it slightly rounded
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (bool? newValue) {
              // NOTE: Since this is a StatelessWidget, tapping this won't change
              // the UI visually yet. You would need a StatefulWidget for that.
            },
          ),
        ),
        // The Goal Title text
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            // If completed, strike-through and grey out the text
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? Colors.grey.shade400 : Colors.black87,
          ),
        ),
      ),
    );
  }
}