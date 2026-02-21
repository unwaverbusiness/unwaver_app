// ignore_for_file: file_names

import 'package:flutter/material.dart';
// Make sure this import matches your actual file structure
import 'package:unwaver/Screens/settings/settings_screen.dart'; 

class MainDrawer extends StatelessWidget {
  final String currentRoute;

  const MainDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF8F9FA), // Slightly off-white for contrast against white tiles
      width: 260,
      child: Column(
        children: [
          // --- HEADER ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 60, 18, 18),
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: 80,
                  width: 80,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                    image: const DecorationImage(
                      image: AssetImage('assets/Unwaver_App_Icon.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const Text(
                  "Unwaver",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Declare your purpose.",
                  style: TextStyle(
                    color: Color(0xFFBB8E13), // Unwaver Gold
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // --- MENU ITEMS ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                _buildSectionHeader("Intelligence & Insights"),
                _buildDrawerItem(
                  context,
                  icon: Icons.psychology,
                  text: 'AI Coach',
                  route: '/coach',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.insights_rounded,
                  text: 'Statistics',
                  route: '/statistics',
                ),

                const SizedBox(height: 16),
                _buildSectionHeader("Organization"),
                _buildDrawerItem(
                  context,
                  icon: Icons.label_outline_rounded,
                  text: 'Tags',
                  route: '/tags',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.fact_check_outlined,
                  text: 'Completion Log',
                  route: '/completion_log',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.notifications_none_rounded,
                  text: 'Reminders',
                  route: '/reminders',
                ),

                const SizedBox(height: 16),
                _buildSectionHeader("Social & Collaboration"),
                _buildDrawerItem(
                  context,
                  icon: Icons.handshake_outlined,
                  text: 'Accountability Partners',
                  route: '/accountability',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.workspaces_outline,
                  text: 'Teams',
                  route: '/teams',
                ),
              ],
            ),
          ),

          // --- BOTTOM SETTINGS ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              top: false,
              child: _buildDrawerItem(
                context,
                icon: Icons.settings_outlined,
                text: 'Settings',
                route: '/settings',
                // --- OVERRIDE FOR ACTUAL NAVIGATION ---
                onTapOverride: () {
                  Navigator.pop(context); // Close the drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required String route,
    VoidCallback? onTapOverride,
  }) {
    final bool isSelected = currentRoute == route;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(
          icon, 
          color: isSelected ? Colors.black : Colors.grey.shade700,
          size: 24,
        ),
        title: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 15,
          ),
        ),
        selected: isSelected,
        selectedTileColor: Colors.white, 
        // Subtle hover/tap background for non-selected items
        tileColor: isSelected ? Colors.white : Colors.transparent,
        onTap: onTapOverride ?? () {
          // Close the drawer immediately
          Navigator.pop(context);

          // If it's already the active screen, do nothing
          if (isSelected) return;

          // Placeholder logic: Show snackbar instead of navigating
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$text coming soon!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.black87,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      ),
    );
  }
}