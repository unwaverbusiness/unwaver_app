// ignore_for_file: file_names

import 'package:flutter/material.dart';

class MainDrawer extends StatelessWidget {
  // We pass in the current route name to know which tab to highlight
  final String currentRoute;

  const MainDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // --- HEADER ---
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.black),
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
                  "Discipline & Focus",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),

          // --- NAVIGATION TABS ---
          _buildDrawerItem(context, 
            icon: Icons.psychology, 
            text: 'Coach', 
            route: '/coach'
          ),
          _buildDrawerItem(context, 
            icon: Icons.flag, 
            text: 'Goals', 
            route: '/goals'
          ),
          _buildDrawerItem(context, 
            icon: Icons.repeat, 
            text: 'Habits', 
            route: '/habits'
          ),
          _buildDrawerItem(context, 
            icon: Icons.check_circle_outline, 
            text: 'Tasks', 
            route: '/tasks'
          ),
          _buildDrawerItem(context, 
            icon: Icons.calendar_month, 
            text: 'Calendar', 
            route: '/calendar'
          ),
          _buildDrawerItem(context, 
            icon: Icons.bar_chart, // Choose an icon
           text: 'Statistics',    // The label
           route: '/statistics'   // The route name you registered in main.dart
          ),
        ],
      ),
    );
  }

  // Helper function to build items and handle highlighting
  Widget _buildDrawerItem(BuildContext context, {required IconData icon, required String text, required String route}) {
    final bool isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.black : Colors.grey[700]),
      title: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.grey[200], // Subtle highlight background
      onTap: () {
        // If we are already on this page, just close the drawer
        if (isSelected) {
          Navigator.pop(context);
        } else {
          // Navigate to the new page and remove the back history (so you don't get stuck in a loop)
          Navigator.pop(context); // Close drawer first
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}