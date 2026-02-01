// ignore_for_file: file_names

import 'package:flutter/material.dart';
// 1. IMPORT THE SCREENS
import 'package:unwaver/Screens/Stats/Statistics.dart'; 
import 'package:unwaver/Screens/Settings/settings_screen.dart'; // Add this import

class MainDrawer extends StatelessWidget {
  final String currentRoute;

  const MainDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column( // Changed ListView to Column to use Spacer()
        children: [
          Expanded(
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

                // STATISTICS ITEM
                _buildDrawerItem(context, 
                  icon: Icons.bar_chart, 
                  text: 'Statistics', 
                  route: '/statistics', 
                  onTapOverride: () {
                    Navigator.pop(context); 
                    Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(builder: (context) => const StatisticsScreen())
                    );
                  }
                ),
              ],
            ),
          ),

          // --- DIVIDER & SETTINGS (At Bottom) ---
          const Divider(),
          _buildDrawerItem(context,
            icon: Icons.settings,
            text: 'Settings',
            route: '/settings',
            onTapOverride: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(height: 16), // Padding at bottom
        ],
      ),
    );
  }

  // Helper function 
  Widget _buildDrawerItem(BuildContext context, {
    required IconData icon, 
    required String text, 
    required String route,
    VoidCallback? onTapOverride, 
  }) {
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
      selectedTileColor: Colors.grey[200], 
      onTap: onTapOverride ?? () {
        if (isSelected) {
          Navigator.pop(context);
        } else {
          Navigator.pop(context); 
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}