import 'package:flutter/material.dart';
import 'package:unwaver/widgets/main_drawer.dart';
import 'package:unwaver/widgets/global_app_bar.dart'; // Make sure this path is correct
import 'habit_creation_screen.dart'; 

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  // --- TOP BAR STATE ---
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _elementFilterController = TextEditingController();
  
  // 2. Dashboard Expansion State
  bool _isDashboardExpanded = true;
  bool _showDashboardWidget = true;

  String _selectedHabitType = 'All';

  // Dummy data
  final List<Map<String, dynamic>> _habits = [
    {"title": "Morning Meditation", "isCompleted": false, "streak": 12, "type": "Habits to Build"},
    {"title": "Drink 2L Water", "isCompleted": true, "streak": 5, "type": "Habits to Build"},
    {"title": "No Sugar", "isCompleted": false, "streak": 3, "type": "Habits to Break"},
    {"title": "Read 10 Pages", "isCompleted": false, "streak": 20, "type": "Habits to Build"},
    {"title": "Cold Shower", "isCompleted": true, "streak": 8, "type": "Habits to Build"},
    {"title": "Stop Biting Nails", "isCompleted": false, "streak": 1, "type": "Habits to Break"},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _elementFilterController.dispose();
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
    _elementFilterController.clear();
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: StatefulBuilder(
          builder: (ctx, setDialogState) {
            
            // Filter logic
            final filteredItems = _habits.where((item) {
              final title = item['title'].toString().toLowerCase();
              final searchTerm = _elementFilterController.text.toLowerCase();
              return title.contains(searchTerm);
            }).toList();

            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.dashboard_customize, color: Colors.blue, size: 24),
                          const SizedBox(width: 12),
                          const Text("Customize Habits", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Drag to reorder • Tap to show/hide", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _elementFilterController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Search habits...",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search, color: Colors.blue),
                      suffixIcon: _elementFilterController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey.shade400),
                              onPressed: () {
                                _elementFilterController.clear();
                                setDialogState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 8),

                  // Static Dashboard Toggle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: _showDashboardWidget ? Colors.blue.withValues(alpha: 0.05) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _showDashboardWidget ? Colors.blue.withValues(alpha: 0.3) : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(Icons.drag_indicator, size: 20, color: Colors.transparent), // invisible drag handle
                          ),
                          Icon(Icons.dashboard, size: 20, color: _showDashboardWidget ? Colors.blue : Colors.grey.shade400),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showDashboardWidget = !_showDashboardWidget;
                                });
                                setDialogState(() {});
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Text(
                                "Dashboard Widget",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: _showDashboardWidget ? FontWeight.w600 : FontWeight.normal,
                                  color: _showDashboardWidget ? Colors.black87 : Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showDashboardWidget = !_showDashboardWidget;
                              });
                              setDialogState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              color: Colors.transparent,
                              child: Icon(
                                _showDashboardWidget ? Icons.visibility : Icons.visibility_off,
                                size: 20,
                                color: _showDashboardWidget ? Colors.blue : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  Flexible(
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      buildDefaultDragHandles: false,
                      itemCount: filteredItems.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final oldActualIndex = _habits.indexOf(filteredItems[oldIndex]);
                          final item = _habits.removeAt(oldActualIndex);
                          
                          final newActualIndex = newIndex == filteredItems.length - 1
                              ? _habits.length
                              : _habits.indexOf(filteredItems[newIndex]);
                          _habits.insert(newActualIndex, item);
                        });
                        setDialogState(() {});
                      },
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final title = item['title'] as String;
                        final isVisible = !(item['isHidden'] == true);
                        
                        return Container(
                          key: ValueKey(title),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isVisible ? Colors.blue.withValues(alpha: 0.05) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isVisible ? Colors.blue.withValues(alpha: 0.3) : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            child: Row(
                              children: [
                                ReorderableDragStartListener(
                                  index: index,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Icon(Icons.drag_indicator, size: 20, color: Colors.grey.shade400),
                                  ),
                                ),
                                Icon(Icons.cached, size: 20, color: isVisible ? Colors.blue : Colors.grey.shade400),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        item['isHidden'] = isVisible;
                                      });
                                      setDialogState(() {});
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isVisible ? FontWeight.w600 : FontWeight.normal,
                                        color: isVisible ? Colors.black87 : Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      item['isHidden'] = isVisible;
                                    });
                                    setDialogState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    color: Colors.transparent,
                                    child: Icon(
                                      isVisible ? Icons.visibility : Icons.visibility_off,
                                      size: 20,
                                      color: isVisible ? Colors.blue : Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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
    final currentTypeHabits = _selectedHabitType == 'All' 
        ? _habits 
        : _habits.where((h) => h['type'] == _selectedHabitType).toList();
    final totalHabits = currentTypeHabits.length;
    final completedToday = currentTypeHabits.where((h) => h['isCompleted'] == true).length;
    
    // 1. Best Streak: The highest streak in the list
    int bestStreak = 0;
    // 2. Total Days: Sum of all streaks (Gamification metric)
    int totalStreakDays = 0;

    if (currentTypeHabits.isNotEmpty) {
      for (var h in currentTypeHabits) {
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

  Widget _buildTypeToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: ['All', 'Habits to Build', 'Habits to Break'].map((type) {
            final isSelected = _selectedHabitType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedHabitType = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : [],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.grey[500],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- MAIN BUILD ---
  @override
  Widget build(BuildContext context) {
    // Apply search filter locally
    final filteredHabits = _habits.where((habit) {
      if (habit['isHidden'] == true) return false;
      if (_selectedHabitType != 'All' && habit['type'] != _selectedHabitType) return false;
      if (_searchController.text.isNotEmpty && !habit['title'].toString().toLowerCase().contains(_searchController.text.toLowerCase())) return false;
      return true;
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
          _buildTypeToggle(),
          // 2. INFOGRAPHIC (SUMMARY)
          if (_showDashboardWidget) _buildInfographic(),

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