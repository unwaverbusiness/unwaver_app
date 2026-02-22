// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // Add to pubspec.yaml
import 'package:unwaver/widgets/main_drawer.dart';
import 'package:unwaver/widgets/global_app_bar.dart'; 
import '../Habits/habit_instruction_banner.dart';

// --- MASSIVE ICON LIBRARY ---
final List<IconData> _availableIcons = [
  Icons.star, Icons.flag, Icons.rocket_launch, Icons.favorite, 
  Icons.directions_run, Icons.fitness_center, Icons.monitor_weight, Icons.sports_tennis, 
  Icons.pool, Icons.menu_book, Icons.school, Icons.language, 
  Icons.work, Icons.attach_money, Icons.trending_up, Icons.home, 
  Icons.directions_car, Icons.flight_takeoff, Icons.public, Icons.landscape, 
  Icons.restaurant, Icons.local_cafe, Icons.local_drink, Icons.cake, 
  Icons.celebration, Icons.music_note, Icons.palette, Icons.brush, 
  Icons.camera_alt, Icons.videocam, Icons.gamepad, Icons.sports_esports, 
  Icons.computer, Icons.phone_iphone, Icons.watch, Icons.health_and_safety, 
  Icons.spa, Icons.self_improvement, Icons.volunteer_activism, Icons.water_drop, 
  Icons.wb_sunny, Icons.nights_stay, Icons.cloud, Icons.ac_unit, 
  Icons.pets, Icons.emoji_nature, Icons.forest, Icons.auto_awesome, 
  Icons.lightbulb, Icons.check_circle, Icons.done_all, Icons.build, Icons.handyman
];

class GoalOverviewScreen extends StatefulWidget {
  const GoalOverviewScreen({super.key});

  @override
  State<GoalOverviewScreen> createState() => _GoalOverviewScreenState();
}

class _GoalOverviewScreenState extends State<GoalOverviewScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  bool _showBanner = true;
  bool _isDashboardExpanded = true; 
  String _selectedGoalType = 'Short-Term';

  // --- MOCK DATA (Expanded for advanced features) ---
  final List<Map<String, dynamic>> _goals = [
    {
      "id": "1",
      "title": "Drink 2L Water",
      "subtitle": "Health • 5 Day Streak",
      "progress": 0.5,
      "icon": Icons.local_drink,
      "color": Colors.blue,
      "targetDate": DateTime.now(),
      "type": "Short-Term",
      "priority": "Medium",
      "notes": "Use the big hydro-flask to track easily.",
      "milestones": [
        {"title": "Buy a 2L bottle", "isCompleted": true},
        {"title": "Hit 7 day streak", "isCompleted": false},
      ]
    },
    {
      "id": "2",
      "title": "Visit Japan",
      "subtitle": "Travel • Dream",
      "progress": 0.0,
      "icon": Icons.flight,
      "color": Colors.pink,
      "targetDate": DateTime.now().add(const Duration(days: 365 * 2)),
      "type": "Bucket List",
      "priority": "High",
      "notes": "Plan for cherry blossom season.",
      "milestones": []
    },
  ];

  final Color _goldColor = const Color(0xFFBB8E13);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateProgress(String id) {
    setState(() {
      final index = _goals.indexWhere((g) => g['id'] == id);
      if (index != -1) {
        double current = (_goals[index]['progress'] as double?) ?? 0.0;
        if (current >= 1.0) {
          _goals[index]['progress'] = 0.0;
        } else {
          _goals[index]['progress'] = (current + 0.1).clamp(0.0, 1.0);
        }
      }
    });
  }

  void _deleteGoal(String id) {
    setState(() => _goals.removeWhere((g) => g['id'] == id));
  }

  // --- NEW: FLOATING ADD GOAL DIALOG ---
  void _showAddGoalDialog() {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    String selectedType = _selectedGoalType;
    Color selectedColor = Colors.blue;
    IconData selectedIcon = Icons.star;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Declare Goal", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: InputDecoration(labelText: "Goal Title", filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: subtitleController,
                    decoration: InputDecoration(labelText: "Category / Subtitle", filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 16),

                  // Goal Type Selector
                  const Text("Timeline", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedType,
                        isExpanded: true,
                        items: ['Short-Term', 'Long-Term', 'Bucket List'].map((type) => DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                        onChanged: (val) { if (val != null) setDialogState(() => selectedType = val); },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Appearance (Icon & Custom Color Picker)
                  const Text("Appearance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Selected Icon Preview
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: selectedColor.withValues(alpha:0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: selectedColor.withValues(alpha:0.5))),
                        child: Icon(selectedIcon, color: selectedColor),
                      ),
                      const SizedBox(width: 12),
                      
                      // Color Wheel Button
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Pick a color'),
                                  content: SingleChildScrollView(
                                    child: ColorPicker(
                                      pickerColor: selectedColor,
                                      onColorChanged: (c) => setDialogState(() => selectedColor = c),
                                      pickerAreaHeightPercent: 0.8,
                                      enableAlpha: false, // Solid colors only for goals
                                    ),
                                  ),
                                  actions: <Widget>[
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                                      child: const Text('Done'),
                                      onPressed: () => Navigator.of(context).pop(),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.color_lens, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text("Custom Color", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Icon Grid
                  Container(
                    height: 120,
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, crossAxisSpacing: 8, mainAxisSpacing: 8),
                      itemCount: _availableIcons.length,
                      itemBuilder: (context, index) {
                        final icon = _availableIcons[index];
                        final isSelected = selectedIcon == icon;
                        return InkWell(
                          onTap: () => setDialogState(() => selectedIcon = icon),
                          child: Container(
                            decoration: BoxDecoration(color: isSelected ? selectedColor : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                            child: Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade600, size: 20),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        if (titleController.text.trim().isEmpty) return;
                        setState(() {
                          _goals.add({
                            "id": DateTime.now().millisecondsSinceEpoch.toString(),
                            "title": titleController.text.trim(),
                            "subtitle": subtitleController.text.trim(),
                            "type": selectedType,
                            "color": selectedColor,
                            "icon": selectedIcon,
                            "targetDate": selectedDate,
                            "progress": 0.0,
                            "priority": "Medium",
                            "notes": "",
                            "milestones": [],
                          });
                          _selectedGoalType = selectedType;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text("Create Goal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  // --- NAVIGATE TO ADVANCED DETAIL SCREEN ---
  void _openGoalDetails(Map<String, dynamic> goal) async {
    final updatedGoal = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GoalDetailScreen(goal: goal)),
    );

    if (updatedGoal != null) {
      setState(() {
        final index = _goals.indexWhere((g) => g['id'] == updatedGoal['id']);
        if (index != -1) _goals[index] = updatedGoal;
      });
    }
  }

  // --- UI BUILDERS ---

  Widget _buildTypeToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: ['Short-Term', 'Long-Term', 'Bucket List'].map((type) {
            final isSelected = _selectedGoalType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedGoalType = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : [],
                  ),
                  alignment: Alignment.center,
                  child: Text(type, style: TextStyle(color: isSelected ? Colors.black : Colors.grey[500], fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 13)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    // Basic stats calculation
    final currentTypeGoals = _goals.where((g) => g['type'] == _selectedGoalType).toList();
    final total = currentTypeGoals.length;
    final completed = currentTypeGoals.where((g) => (g['progress'] as double? ?? 0.0) >= 1.0).length;
    final percent = total == 0 ? 0 : ((completed / total) * 100).toInt();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isDashboardExpanded = !_isDashboardExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16), bottom: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart, size: 16, color: Colors.grey[600]), const SizedBox(width: 8),
                      Text("GOALS DASHBOARD", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey[800])),
                    ],
                  ),
                  Icon(_isDashboardExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey[600], size: 20),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isDashboardExpanded 
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      const Divider(height: 1), const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem("Total", "$total"),
                          _buildStatItem("Active", "${total - completed}", color: Colors.orange[700]),
                          _buildStatItem("Completed", "$completed", color: Colors.green[700]),
                          _buildStatItem("Success Rate", "$percent%", color: Colors.blue[700]),
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

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color ?? Colors.black87)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredGoals = _goals.where((goal) {
      if (goal['type'] != _selectedGoalType) return false;
      if (_searchController.text.isEmpty) return true;
      return (goal['title'] as String).toLowerCase().contains(_searchController.text.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: GlobalAppBar(
        isSearching: _isSearching, searchController: _searchController,
        onSearchChanged: (val) => setState(() {}),
        onCloseSearch: () => setState(() { _isSearching = false; _searchController.clear(); }),
        onSearchTap: () => setState(() => _isSearching = true),
        onFilterTap: () {}, onSortTap: () {},
      ),
      drawer: const MainDrawer(currentRoute: '/goals'),
      body: Column(
        children: [
          _buildTypeToggle(),
          _buildDashboard(),
          if (_showBanner) Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: HabitInstructionBanner(onDismiss: () => setState(() => _showBanner = false))),

          Expanded(
            child: filteredGoals.isEmpty
              ? Center(child: Text("No goals found matching '${_searchController.text}'", style: TextStyle(color: Colors.grey[500])))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), 
                  itemCount: filteredGoals.length,
                  itemBuilder: (context, index) {
                    final goal = filteredGoals[index];
                    final Color goalColor = (goal['color'] as Color?) ?? Colors.grey;
                    final double goalProgress = (goal['progress'] as double?) ?? 0.0;

                    return Dismissible(
                      key: Key(goal['id']),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.only(right: 20), alignment: Alignment.centerRight,
                        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.delete_outline, color: Colors.red.shade700),
                      ),
                      onDismissed: (_) => _deleteGoal(goal['id']),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.02), spreadRadius: 1, blurRadius: 6, offset: const Offset(0, 3))],
                        ),
                        child: InkWell(
                          onTap: () => _openGoalDetails(goal), // OPENS ADVANCED SCREEN
                          borderRadius: BorderRadius.circular(12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(backgroundColor: goalColor.withValues(alpha:0.15), child: Icon(goal['icon'], color: goalColor)),
                            title: Text(goal['title'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(goal['subtitle'], style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(child: LinearProgressIndicator(value: goalProgress, backgroundColor: Colors.grey.shade200, color: goalColor, minHeight: 6, borderRadius: BorderRadius.circular(4))),
                                    const SizedBox(width: 8),
                                    Text("${(goalProgress * 100).toInt()}%", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle),
                              color: goalProgress >= 1.0 ? Colors.green : Colors.grey[400], iconSize: 28,
                              onPressed: () => _updateProgress(goal['id']),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGoalDialog,
        backgroundColor: Colors.black, elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white), label: const Text("New Goal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ============================================================================
// NEW: ADVANCED GOAL DETAIL SCREEN
// ============================================================================

class GoalDetailScreen extends StatefulWidget {
  final Map<String, dynamic> goal;
  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _subtitleCtrl;
  late TextEditingController _notesCtrl;
  
  late String _type;
  late String _priority;
  late Color _color;
  late IconData _icon;
  late DateTime _targetDate;
  late double _progress;
  late List<Map<String, dynamic>> _milestones;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.goal['title']);
    _subtitleCtrl = TextEditingController(text: widget.goal['subtitle']);
    _notesCtrl = TextEditingController(text: widget.goal['notes'] ?? "");
    
    _type = widget.goal['type'];
    _priority = widget.goal['priority'] ?? 'Medium';
    _color = widget.goal['color'];
    _icon = widget.goal['icon'];
    _targetDate = widget.goal['targetDate'];
    _progress = widget.goal['progress'];
    
    // Safely cast existing milestones or initialize empty
    _milestones = List<Map<String, dynamic>>.from(widget.goal['milestones'] ?? []);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _saveAndPop() {
    final updatedGoal = {
      "id": widget.goal['id'],
      "title": _titleCtrl.text,
      "subtitle": _subtitleCtrl.text,
      "type": _type,
      "color": _color,
      "icon": _icon,
      "targetDate": _targetDate,
      "progress": _progress,
      "priority": _priority,
      "notes": _notesCtrl.text,
      "milestones": _milestones,
    };
    Navigator.pop(context, updatedGoal);
  }

  void _addMilestone() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("New Milestone", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(controller: ctrl, autofocus: true, decoration: InputDecoration(hintText: "E.g., Save first \$1000")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _color, foregroundColor: Colors.white),
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                setState(() => _milestones.add({"title": ctrl.text, "isCompleted": false}));
                Navigator.pop(ctx);
              }
            },
            child: const Text("Add"),
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
        backgroundColor: _color,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Goal Details", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveAndPop),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HERO HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              decoration: BoxDecoration(
                color: _color,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  CircleAvatar(radius: 40, backgroundColor: Colors.white24, child: Icon(_icon, size: 40, color: Colors.white)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleCtrl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: "Goal Title", hintStyle: TextStyle(color: Colors.white54)),
                  ),
                  TextField(
                    controller: _subtitleCtrl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: "Category", hintStyle: TextStyle(color: Colors.white54), isDense: true, contentPadding: EdgeInsets.zero),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- PROGRESS SLIDER ---
                  const Text("Overall Progress", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _progress,
                          onChanged: (val) => setState(() => _progress = val),
                          activeColor: _color, inactiveColor: Colors.grey.shade200,
                        ),
                      ),
                      Text("${(_progress * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, color: _color, fontSize: 16)),
                    ],
                  ),
                  const Divider(height: 40),

                  // --- METADATA ---
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Priority", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            DropdownButton<String>(
                              value: _priority, isExpanded: true, underline: const SizedBox(),
                              items: ['Low', 'Medium', 'High'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                              onChanged: (val) { if (val != null) setState(() => _priority = val); },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Timeline Type", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            DropdownButton<String>(
                              value: _type, isExpanded: true, underline: const SizedBox(),
                              items: ['Short-Term', 'Long-Term', 'Bucket List'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                              onChanged: (val) { if (val != null) setState(() => _type = val); },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // TARGET DATE
                  InkWell(
                    onTap: () async {
                      final d = await showDatePicker(context: context, initialDate: _targetDate, firstDate: DateTime.now(), lastDate: DateTime(2050));
                      if (d != null) setState(() => _targetDate = d);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [Icon(Icons.calendar_month, color: _color), const SizedBox(width: 12), const Text("Target Date", style: TextStyle(fontWeight: FontWeight.bold))]),
                          Text(DateFormat('MMMM d, yyyy').format(_targetDate), style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 40),

                  // --- MILESTONES ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Milestones", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton.icon(onPressed: _addMilestone, icon: Icon(Icons.add, size: 16, color: _color), label: Text("Add", style: TextStyle(color: _color))),
                    ],
                  ),
                  if (_milestones.isEmpty)
                    Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text("Break this goal down into smaller actionable steps.", style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
                  
                  ..._milestones.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var milestone = entry.value;
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: _color,
                      title: Text(milestone['title'], style: TextStyle(decoration: milestone['isCompleted'] ? TextDecoration.lineThrough : null, color: milestone['isCompleted'] ? Colors.grey : Colors.black)),
                      value: milestone['isCompleted'],
                      onChanged: (val) => setState(() => _milestones[idx]['isCompleted'] = val),
                      secondary: IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.grey), onPressed: () => setState(() => _milestones.removeAt(idx))),
                    );
                  }),
                  
                  const Divider(height: 40),

                  // --- NOTES ---
                  const Text("Journal & Notes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "Why is this important? What are the blockers?",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true, fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}