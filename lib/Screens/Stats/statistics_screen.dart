import 'package:flutter/material.dart';
import 'package:unwaver/widgets/global_app_bar.dart'; 
// MainDrawer is intentionally omitted from the widget tree to allow the Back button 
// to naturally appear and return the user to the previous screen where the drawer was.

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // --- TOP BAR STATE ---
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- MOCK BREAKDOWN DATA ---
  final Map<String, dynamic> _dataBreakdown = {
    'Goals': {'Total': 12, 'Achieved': 3, 'In Progress': 9},
    'Habits': {'To Build': 7, 'To Break': 3, 'Active Streaks': 5},
    'Tasks': {'Total': 24, 'Done': 15, 'Pending': 9},
    'Events': {'Scheduled': 18, 'Completed': 10},
    'Purpose Elements': {
      'Core Values': 4,
      'Priorities': 3,
      'Identity Statements': 2,
      'Strengths': 5,
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Match theme of goal/habit screens
      
      appBar: GlobalAppBar(
        isSearching: _isSearching,
        searchController: _searchController,
        onSearchChanged: (val) => setState(() {}),
        onCloseSearch: () => setState(() {
          _isSearching = false;
          _searchController.clear();
        }),
        onSearchTap: () => setState(() => _isSearching = true),
        onFilterTap: () {
          // Placeholder for filter
        },
        onSortTap: () {
          // Placeholder for sort
        },
      ),
      // Drawer is purposely ignored so GlobalAppBar shows a back button

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            const Text(
              "Intelligence & Insights",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Your performance across all dimensions.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // --- MAIN SCORECARD ---
            _buildMainScoreCard(),
            const SizedBox(height: 30),

            // --- CATEGORY BREAKDOWN ---
            const Text(
              "Total Breakdown",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Goals Breakdown
            _buildBreakdownSection(
              title: "Goals Overview",
              icon: Icons.flag_rounded,
              color: Colors.blue,
              stats: _dataBreakdown['Goals'],
            ),
            const SizedBox(height: 15),
            
            // Habits Breakdown
            _buildBreakdownSection(
              title: "Habits Overview",
              icon: Icons.loop_rounded,
              color: Colors.green,
              stats: _dataBreakdown['Habits'],
            ),
            const SizedBox(height: 15),
            
            // Tasks Breakdown
            _buildBreakdownSection(
              title: "Tasks Overview",
              icon: Icons.check_circle_outline,
              color: Colors.redAccent,
              stats: _dataBreakdown['Tasks'],
            ),
            const SizedBox(height: 15),

            // Events Breakdown
            _buildBreakdownSection(
              title: "Events Overview",
              icon: Icons.calendar_month_rounded,
              color: Colors.orange,
              stats: _dataBreakdown['Events'],
            ),
            const SizedBox(height: 15),

            // Purpose Generator Breakdown
            _buildBreakdownSection(
              title: "Purpose & Identity Elements",
              icon: Icons.stars_rounded,
              color: const Color(0xFFBB8E13), // Gold
              stats: _dataBreakdown['Purpose Elements'],
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildMainScoreCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Discipline Score",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 5),
              Text(
                "87%",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                "Top 10% of users",
                style: TextStyle(color: Colors.greenAccent, fontSize: 12),
              ),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: 0.87,
                  strokeWidth: 8,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const Icon(Icons.trending_up, color: Colors.white, size: 30),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection({
    required String title,
    required IconData icon,
    required Color color,
    required Map<String, dynamic> stats,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats Row
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: stats.entries.map((entry) {
              return _buildStatChip(entry.key, entry.value.toString(), color);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}