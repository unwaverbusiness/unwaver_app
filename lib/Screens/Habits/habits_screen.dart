import 'package:flutter/material.dart';
import 'package:unwaver/widgets/main_drawer.dart';
import 'package:unwaver/widgets/global_app_bar.dart'; // Make sure this path is correct
import 'habit_creation_screen.dart'; 
import 'habit_instruction_banner.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  // --- TOP BAR STATE ---
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // 1. Banner State
  bool _showBanner = true;
  
  // 2. Dashboard Expansion State
  bool _isDashboardExpanded = true;

  // Dummy data
  final List<Map<String, dynamic>> _habits = [
    {"title": "Morning Meditation", "isCompleted": false, "streak": 12},
    {"title": "Drink 2L Water", "isCompleted": true, "streak": 5},
    {"title": "No Sugar", "isCompleted": false, "streak": 3},
    {"title": "Read 10 Pages", "isCompleted": false, "streak": 20},
    {"title": "Cold Shower", "isCompleted": true, "streak": 8},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleHabit(int index, List<Map<String, dynamic>> activeList) {
    setState(() {
      // Find the actual habit in the master list to update it
      final habitTitle = activeList[index]['title'];
      final masterIndex = _habits.indexWhere((h) => h['title'] == habitTitle);
      
      if (masterIndex != -1) {
        _habits[masterIndex]['isCompleted'] = !_habits[masterIndex]['isCompleted'];
        
        // Simple logic to increment streak visually when checked
        if (_habits[masterIndex]['isCompleted']) {
          _habits[masterIndex]['streak'] += 1;
        } else {
          _habits[masterIndex]['streak'] -= 1;
        }
      }
    });
  }

  void _navToCreation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HabitCreationScreen()),
    );
  }

  // --- TOP BAR ACTION SHEETS ---
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 300,
        child: const Center(child: Text("Filter Habits (Coming Soon)", style: TextStyle(fontWeight: FontWeight.bold))),
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 300,
        child: const Center(child: Text("Sort Habits (Coming Soon)", style: TextStyle(fontWeight: FontWeight.bold))),
      ),
    );
  }

  // --- INFOGRAPHIC LOGIC ---
  Map<String, String> _calculateStats() {
    final totalHabits = _habits.length;
    final completedToday = _habits.where((h) => h['isCompleted'] == true).length;
    
    // 1. Best Streak: The highest streak in the list
    int bestStreak = 0;
    // 2. Total Days: Sum of all streaks (Gamification metric)
    int totalStreakDays = 0;

    if (_habits.isNotEmpty) {
      for (var h in _habits) {
        int s = h['streak'] as int;
        if (s > bestStreak) bestStreak = s;
        totalStreakDays += s;
      }
    }

    final percent = totalHabits == 0 ? 0 : ((completedToday / totalHabits) * 100).toInt();

    return {
      "Best Streak": "$bestStreak",
      "Total Days": "$totalStreakDays",
      "Done": "$completedToday/$totalHabits",
      "Rate": "$percent%",
    };
  }

  // --- INFOGRAPHIC WIDGETS ---
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon Circle
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        // Value
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        // Label
        Text(
          label,
          style: TextStyle(
            fontSize: 10, 
            color: Colors.grey[600], 
            fontWeight: FontWeight.w600
          ),
        ),
      ],
    );
  }

  Widget _buildInfographic() {
    final stats = _calculateStats();

    return Container(
      margin: const EdgeInsets.all(16),
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16), bottom: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bolt, size: 18, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Text(
                        "HABITS DASHBOARD",
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          letterSpacing: 1.2,
                          color: Colors.grey[800]
                        ),
                      ),
                    ],
                  ),
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
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isDashboardExpanded
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 24),
                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem("Best Streak", stats["Best Streak"]!, Icons.local_fire_department, Colors.orange),
                          _buildStatItem("Total Days", stats["Total Days"]!, Icons.history, Colors.purple),
                          _buildStatItem("Done Today", stats["Done"]!, Icons.check_circle, Colors.green),
                          _buildStatItem("Completion", stats["Rate"]!, Icons.pie_chart, Colors.blue),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // --- MAIN BUILD ---
  @override
  Widget build(BuildContext context) {
    // Apply search filter locally
    final filteredHabits = _habits.where((habit) {
      if (_searchController.text.isEmpty) return true;
      return habit['title'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      
      // 1. GLOBAL APP BAR
      appBar: GlobalAppBar(
        isSearching: _isSearching,
        searchController: _searchController,
        onSearchChanged: (val) => setState(() {}),
        onCloseSearch: () => setState(() {
          _isSearching = false;
          _searchController.clear();
        }),
        onSearchTap: () => setState(() => _isSearching = true),
        onFilterTap: _showFilterSheet,
        onSortTap: _showSortSheet,
      ),
      
      drawer: const MainDrawer(currentRoute: '/habits'),

      body: Column(
        children: [
          // 2. INFOGRAPHIC (SUMMARY)
          _buildInfographic(),

          // 3. INSTRUCTION BANNER
          if (_showBanner)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: HabitInstructionBanner(
                onDismiss: () {
                  setState(() {
                    _showBanner = false;
                  });
                },
              ),
            ),

          // 4. HABIT LIST
          Expanded(
            child: filteredHabits.isEmpty
              ? Center(
                  child: Text("No habits found matching '${_searchController.text}'", style: TextStyle(color: Colors.grey[500])),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                  itemCount: filteredHabits.length,
                  itemBuilder: (context, index) {
                    final habit = filteredHabits[index];
                    final bool isCompleted = habit['isCompleted'];

                    return Card(
                      elevation: 0,
                      color: isCompleted
                          ? Colors.green.withValues(alpha:0.1)
                          : Colors.grey[100], 
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isCompleted ? Colors.green.withValues(alpha:0.5) : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCompleted ? Colors.green : Colors.grey.shade300
                            ),
                          ),
                          child: Icon(
                            isCompleted ? Icons.check : Icons.local_fire_department,
                            color: isCompleted ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          habit['title'],
                          style: TextStyle(
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: isCompleted ? Colors.grey[600] : Colors.black87,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            "${habit['streak']} Day Streak",
                            style: TextStyle(
                              color: isCompleted ? Colors.green[700] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              fontSize: 12
                            ),
                          ),
                        ),
                        trailing: IconButton(
                          onPressed: () => _toggleHabit(index, filteredHabits),
                          icon: Icon(
                            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isCompleted ? Colors.green : Colors.grey[400],
                            size: 32,
                          ),
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