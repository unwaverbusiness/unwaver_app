import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:unwaver/widgets/maindrawer.dart';
import 'package:unwaver/widgets/app_logo.dart';

// Import your other screens for navigation
import '../Goals/goal_overview_screen.dart';
import '../Habits/habits_screen.dart';
import '../Tasks/tasks_screen.dart';
import '../Calendar/calendar_screen.dart';

// --- ADD THIS IMPORT ---
// Update this path to wherever your MainLayout file is located (e.g., '../main_layout.dart')
import '../main_layout.dart'; 

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // --- MOCK DATA FOR STATISTICS ---
  final int _totalGoals = 3;
  final double _avgGoalCompletion = 0.65; // 65%
  final int _activeHabits = 4;
  final int _currentStreak = 12; // Days
  final int _tasksToday = 8;
  final int _tasksDone = 5;

  // Navigation Helper
  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate Task Percentage for the Chart
    final double taskPercent = _tasksToday == 0 ? 0 : (_tasksDone / _tasksToday) * 100;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // --- FIX: LEADING BACK BUTTON ---
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // FIX: Navigate to MainLayout, specifically the Purpose Tab (Index 2)
            // pushAndRemoveUntil clears the back stack so you don't return to Stats
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const MainLayout(initialIndex: 2),
              ),
              (route) => false, 
            );
          },
        ),
        title: const AppLogo(),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      drawer: const MainDrawer(currentRoute: '/stats'),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Overview",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              "Your performance at a glance",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            // --- ROW 1: TASKS & STREAKS ---
            Row(
              children: [
                // 1. Task Completion (Pie Chart)
                Expanded(
                  child: _buildStatCard(
                    title: "Today's Focus",
                    onTap: () => _navigateTo(const TasksScreen()),
                    child: SizedBox(
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 0,
                              centerSpaceRadius: 30,
                              sections: [
                                PieChartSectionData(
                                  value: _tasksDone.toDouble(),
                                  color: Colors.black,
                                  radius: 15,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  value: (_tasksToday - _tasksDone).toDouble(),
                                  color: Colors.grey.shade200,
                                  radius: 15,
                                  showTitle: false,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${taskPercent.toInt()}%",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const Text("Done", style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // 2. Habit Streaks
                Expanded(
                  child: _buildStatCard(
                    title: "Top Streak",
                    onTap: () => _navigateTo(const HabitsScreen()),
                    child: SizedBox(
                      height: 120,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orange, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            "$_currentStreak Days",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "$_activeHabits Active Habits",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- ROW 2: GOAL PROGRESS ---
            _buildStatCard(
              title: "Goal Progress",
              onTap: () => _navigateTo(const GoalOverviewScreen()),
              child: SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            switch (value.toInt()) {
                              case 0: return const Text('G1', style: TextStyle(fontSize: 10));
                              case 1: return const Text('G2', style: TextStyle(fontSize: 10));
                              case 2: return const Text('G3', style: TextStyle(fontSize: 10));
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      _makeBarData(0, 5, Colors.blue),
                      _makeBarData(1, 8, Colors.purple),
                      _makeBarData(2, 2, const Color.fromARGB(255, 0, 255, 213)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- ROW 3: CALENDAR SUMMARY ---
            _buildStatCard(
              title: "Upcoming",
              onTap: () => _navigateTo(const CalendarScreen()),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_today, color: Colors.black),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "3 Events Today",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        "Next: Deep Work @ 2:00 PM",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  BarChartGroupData _makeBarData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 10,
            color: Colors.grey.shade100,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Icon(Icons.arrow_outward, size: 16, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}