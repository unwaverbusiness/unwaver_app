// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:unwaver/screens/settings/settings_screen.dart';
import 'package:unwaver/screens/stats/statistics_screen.dart';
import 'package:unwaver/screens/life_resume/life_resume_screen.dart';

class MainDrawer extends StatelessWidget {
  final String currentRoute;

  const MainDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    // In Light Mode, Drawer is Black, so text must be White.
    // In Dark Mode, Drawer is White, so text must be Black.
    final isDarkAppMode = Theme.of(context).brightness == Brightness.dark;
    final drawerTextColor = isDarkAppMode ? Colors.black : Colors.white;

    return Drawer(
      width: 338,
      child: Column(
        children: [
          // --- HEADER ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 60, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Image.asset(
                      'assets/Unwaver_App_Icon.png',
                      height: 92,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Text(
                  "Unwaver",
                  style: TextStyle(
                    color: drawerTextColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Declare your purpose.",
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .primary, // Uses Accent Color
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
                _buildDrawerItem(context,
                    icon: Icons.psychology, text: 'AI Coach', route: '/coach'),
                _buildDrawerItem(
                  context,
                  icon: Icons.insights_rounded,
                  text: 'Statistics',
                  route: '/statistics',
                  onTapOverride: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => StatisticsScreen()));
                  },
                ),
                _buildDrawerItem(context,
                    icon: Icons.label_outline_rounded,
                    text: 'Tags',
                    route: '/tags'),
                _buildDrawerItem(
                  context,
                  icon: Icons.badge_outlined,
                  text: 'Life Resume',
                  route: '/life_resume',
                  onTapOverride: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LifeResumeScreen()));
                  },
                ),
                _buildDrawerItem(context,
                    icon: Icons.notifications_none_rounded,
                    text: 'Reminders',
                    route: '/reminders'),
                _buildDrawerItem(context,
                    icon: Icons.handshake_outlined,
                    text: 'Accountability Partners',
                    route: '/accountability'),
                _buildDrawerItem(context,
                    icon: Icons.workspaces_outline,
                    text: 'Teams',
                    route: '/teams'),
              ],
            ),
          ),

          // --- BOTTOM SETTINGS ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: drawerTextColor.withValues(alpha: 0.1))),
            ),
            child: SafeArea(
              top: false,
              child: _buildDrawerItem(
                context,
                icon: Icons.settings_outlined,
                text: 'Settings',
                route: '/settings',
                onTapOverride: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsScreen()));
                },
              ),
            ),
          ),
        ],
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
    final isDarkAppMode = Theme.of(context).brightness == Brightness.dark;

    // Default text/icon color contrasts with the drawer background
    final defaultColor = isDarkAppMode ? Colors.black87 : Colors.white70;
    // Highlighted text/icon uses the global Accent Color
    final activeColor = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(
          icon,
          color: isSelected ? activeColor : defaultColor,
          size: 24,
        ),
        title: Text(
          text,
          style: TextStyle(
            color: isSelected ? activeColor : defaultColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 15,
          ),
        ),
        selected: isSelected,
        selectedTileColor: activeColor.withValues(alpha: 0.1),
        tileColor: Colors.transparent,
        onTap: onTapOverride ??
            () {
              Navigator.pop(context);
              if (isSelected) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$text coming soon!'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: activeColor,
                ),
              );
            },
      ),
    );
  }
}
