import 'package:flutter/material.dart';
import 'package:unwaver/widgets/maindrawer.dart';
import 'package:unwaver/widgets/app_logo.dart';
import 'goal_creation_screen.dart';
import '../Habits/habit_instruction_banner.dart';

class GoalOverviewScreen extends StatefulWidget {
  const GoalOverviewScreen({super.key});

  @override
  State<GoalOverviewScreen> createState() => _GoalOverviewScreenState();
}

class _GoalOverviewScreenState extends State<GoalOverviewScreen> {
  bool _showBanner = true;
  
  // 1. ADDED: State to track if dashboard is open or closed
  bool _isDashboardExpanded = true; 

  final List<Map<String, dynamic>> _goals = [
    {
      "title": "Drink 2L Water",
      "subtitle": "Health • 5 Day Streak",
      "progress": 0.5,
      "icon": Icons.local_drink,
      "color": Colors.blue,
      "targetDate": DateTime.now(),
    },
    {
      "title": "Read 10 Pages",
      "subtitle": "Growth • 12 Day Streak",
      "progress": 0.8,
      "icon": Icons.book,
      "color": Colors.purple,
      "targetDate": DateTime.now().add(const Duration(days: 400)),
    },
    {
      "title": "Gym Workout",
      "subtitle": "Health • 3 Day Streak",
      "progress": 0.0,
      "icon": Icons.fitness_center,
      "color": const Color.fromARGB(255, 0, 255, 213),
      "targetDate": DateTime.now().add(const Duration(days: 365 * 4)),
    },
    {
      "title": "Buy a House",
      "subtitle": "Life • Saving",
      "progress": 0.1,
      "icon": Icons.house,
      "color": Colors.orange,
      "targetDate": DateTime.now().add(const Duration(days: 365 * 9)),
    },
  ];

  void _updateProgress(int index) {
    setState(() {
      double current = (_goals[index]['progress'] as double?) ?? 0.0;
      if (current >= 1.0) {
        _goals[index]['progress'] = 0.0;
      } else {
        _goals[index]['progress'] = (current + 0.25).clamp(0.0, 1.0);
      }
    });
  }

  void _navToCreation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GoalCreationScreen()),
    );
  }

  Map<String, String> _calculateStats() {
    final now = DateTime.now();
    final total = _goals.length;
    final completed = _goals.where((g) => (g['progress'] as double? ?? 0.0) >= 1.0).length;

    final currentYear = _goals.where((g) {
      final date = g['targetDate'] as DateTime?;
      return date != null && date.year == now.year;
    }).length;

    final nextYear = _goals.where((g) {
      final date = g['targetDate'] as DateTime?;
      return date != null && date.year == now.year + 1;
    }).length;

    final within5 = _goals.where((g) {
      final date = g['targetDate'] as DateTime?;
      return date != null && date.year <= now.year + 5;
    }).length;

    final within10 = _goals.where((g) {
      final date = g['targetDate'] as DateTime?;
      return date != null && date.year <= now.year + 10;
    }).length;

    final notCompleted = total - completed;
    final percent = total == 0 ? 0 : ((completed / total) * 100).toInt();

    return {
      "Total": "$total",
      "This Year": "$currentYear",
      "Next Year": "$nextYear",
      "5 Years": "$within5",
      "10 Years": "$within10",
      "Done": "$completed",
      "Pending": "$notCompleted",
      "Rate": "$percent%",
    };
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color ?? Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // 2. UPDATED: Dashboard Builder
  Widget _buildDashboard() {
    final stats = _calculateStats();
    
    return Container(
      margin: const EdgeInsets.all(16),
      // Removed padding here to allow InkWell to hit edges, applied internal padding instead
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // --- CLICKABLE HEADER ---
          InkWell(
            onTap: () {
              setState(() {
                _isDashboardExpanded = !_isDashboardExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16), bottom: Radius.circular(16)), // Smooth touch area
            child: Padding(
              padding: const EdgeInsets.all(16.0), // Padding moved inside
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        "GOALS DASHBOARD",
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          letterSpacing: 1.2,
                          color: Colors.grey[800]
                        ),
                      ),
                    ],
                  ),
                  // Arrow Icon changes based on state
                  Icon(
                    _isDashboardExpanded 
                        ? Icons.keyboard_arrow_up 
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          
          // --- EXPANDABLE CONTENT ---
          // Using AnimatedSize for a smooth transition effect
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isDashboardExpanded 
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      // Row 1: Timeline
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem("Total", stats["Total"]!),
                          _buildStatItem("This Year", stats["This Year"]!),
                          _buildStatItem("Next Year", stats["Next Year"]!),
                          _buildStatItem("< 5 Yrs", stats["5 Years"]!),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Row 2: Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem("< 10 Yrs", stats["10 Years"]!),
                          _buildStatItem("Done", stats["Done"]!, color: Colors.green[700]),
                          _buildStatItem("Active", stats["Pending"]!, color: Colors.orange[700]),
                          _buildStatItem("Rate", stats["Rate"]!, color: Colors.blue[700]),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(), // Hides content when collapsed
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const AppLogo(),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.calendar_month)),
        ],
      ),
      drawer: const MainDrawer(currentRoute: '/goals'),
      body: Column(
        children: [
          _buildDashboard(),

          if (_showBanner)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: HabitInstructionBanner(
                onDismiss: () => setState(() => _showBanner = false),
              ),
            ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                final Color goalColor = (goal['color'] as Color?) ?? Colors.grey;
                final IconData goalIcon = (goal['icon'] as IconData?) ?? Icons.error;
                final double goalProgress = (goal['progress'] as double?) ?? 0.0;
                final String goalTitle = (goal['title'] as String?) ?? "Untitled";
                final String goalSubtitle = (goal['subtitle'] as String?) ?? "";

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha:0.4),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 3), 
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: GestureDetector(
                      onTap: () => _updateProgress(index),
                      child: CircleAvatar(
                        backgroundColor: goalColor.withValues(alpha:0.15),
                        child: Icon(goalIcon, color: goalColor),
                      ),
                    ),
                    title: Text(
                      goalTitle, 
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          goalSubtitle, 
                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: goalProgress,
                          backgroundColor: Colors.white,
                          color: goalColor,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: Colors.grey[600],
                      onPressed: () => _updateProgress(index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navToCreation,
        backgroundColor: Colors.black,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}