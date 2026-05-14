import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unwaver/widgets/main_drawer.dart';
import 'package:unwaver/widgets/global_app_bar.dart';
import 'package:unwaver/widgets/reusable_card.dart';
import 'habit_creation_screen.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'habit_constants.dart';
import 'package:share_plus/share_plus.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isDashboardExpanded = true;
  final bool _showDashboardWidget = true;
  String _selectedHabitType = 'All';

  final CollectionReference _habitsCollection =
      FirebaseFirestore.instance.collection('habits');
  late Stream<QuerySnapshot> _habitsStream;

  @override
  void initState() {
    super.initState();
    _habitsStream =
        _habitsCollection.orderBy('createdAt', descending: true).snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- FIREBASE OPERATIONS ---

  // Helper method to map Firebase booleans to the unified CardStatus enum
  CardStatus _determineStatus(Map<String, dynamic> data) {
    if (data['isCompleted'] == true) return CardStatus.completed;
    if (data['isSkipped'] == true) return CardStatus.skipped;
    if (data['isFailed'] == true) return CardStatus.failed;
    return CardStatus.none;
  }

  // Unified state update connected directly to the ReusableCard's onStatusChanged
  Future<void> _updateHabitState(DocumentSnapshot doc, CardStatus newStatus) async {
    HapticFeedback.lightImpact();
    final data = doc.data() as Map<String, dynamic>;
    final int currentStreak = data['streak'] ?? 0;
    final bool wasCompleted = data['isCompleted'] ?? false;

    // Map the incoming enum back to booleans for the database
    bool isCompleted = newStatus == CardStatus.completed;
    bool isSkipped = newStatus == CardStatus.skipped;
    bool isFailed = newStatus == CardStatus.failed;

    int newStreak = currentStreak;

    // Streak handling logic
    if (isCompleted && !wasCompleted) {
      newStreak = currentStreak + 1; // Increment if newly completed
    } else if (!isCompleted && wasCompleted) {
      newStreak = currentStreak > 0 ? currentStreak - 1 : 0; // Decrement if completion is undone
    }

    if (isFailed) {
      newStreak = 0; // Failing immediately resets the streak to 0
    }

    await _habitsCollection.doc(doc.id).update({
      'isCompleted': isCompleted,
      'isSkipped': isSkipped,
      'isFailed': isFailed,
      'streak': newStreak,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteHabit(String docId) async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit?'),
        content: const Text('This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _habitsCollection.doc(docId).delete();
    }
  }

  void _navToCreation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HabitCreationScreen()),
    );
  }

  Future<void> _showEditHabitDialog(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _EditHabitScreen(
          doc: doc,
          data: data,
          habitsCollection: _habitsCollection,
          formatPriority: _formatPriority,
          formatUrgency: _formatUrgency,
        ),
      ),
    );
  }

  // --- NAVIGATION ROUTING ---

  // Routes to a specific detail screen based on which icon on the card was clicked
  void _navToHabitDetail(String title, String specificView) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('$title - $specificView',
                style: const TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black),
            elevation: 0,
          ),
          body: Center(
            child: Text(
              'Detailed $specificView view for $title coming soon.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  // --- INFOGRAPHIC LOGIC ---
  Map<String, String> _calculateStats(List<QueryDocumentSnapshot> docs) {
    final currentTypeHabits = _selectedHabitType == 'All'
        ? docs
        : docs
            .where((doc) =>
                (doc.data() as Map<String, dynamic>)['type'] ==
                _selectedHabitType)
            .toList();

    final totalHabits = currentTypeHabits.length;
    final completedToday = currentTypeHabits
        .where((doc) =>
            (doc.data() as Map<String, dynamic>)['isCompleted'] == true)
        .length;

    int bestStreak = 0;
    int totalStreakDays = 0;

    for (var doc in currentTypeHabits) {
      final data = doc.data() as Map<String, dynamic>;
      int s = data['streak'] ?? 0;
      if (s > bestStreak) bestStreak = s;
      totalStreakDays += s;
    }

    final percent =
        totalHabits == 0 ? 0 : ((completedToday / totalHabits) * 100).toInt();

    return {
      "Best Streak": "$bestStreak",
      "Total Days": "$totalStreakDays",
      "Done": "$completedToday/$totalHabits",
      "Rate": "$percent%",
    };
  }

  // --- UI BUILDERS ---
  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildInfographic(List<QueryDocumentSnapshot> docs) {
    final stats = _calculateStats(docs);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isDashboardExpanded = !_isDashboardExpanded);
            },
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16), bottom: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bolt, size: 18, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Text("HABITS DASHBOARD",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.grey[800])),
                    ],
                  ),
                  Icon(
                      _isDashboardExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                      size: 20),
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
                        const Divider(height: 1),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatItem("Best Streak", stats["Best Streak"]!,
                                Icons.local_fire_department, Colors.orange),
                            _buildStatItem("Total Days", stats["Total Days"]!,
                                Icons.history, Colors.purple),
                            _buildStatItem("Done Today", stats["Done"]!,
                                Icons.check_circle, Colors.green),
                            _buildStatItem("Completion", stats["Rate"]!,
                                Icons.pie_chart, Colors.blue),
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
            color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: ['All', 'Habits to Build', 'Habits to Break'].map((type) {
            final isSelected = _selectedHabitType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedHabitType = type);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [
                            const BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2))
                          ]
                        : [],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.grey[500],
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: GlobalAppBar(
        isSearching: _isSearching,
        searchController: _searchController,
        onSearchChanged: (val) => setState(() {}),
        onCloseSearch: () => setState(() {
          _isSearching = false;
          _searchController.clear();
        }),
        onSearchTap: () => setState(() => _isSearching = true),
        onFilterTap: () {},
        onSortTap: () {},
      ),
      drawer: const MainDrawer(currentRoute: '/habits'),
      body: StreamBuilder<QuerySnapshot>(
        stream: _habitsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child:
                    Text('Error loading habits. Check your database rules.'));
          }

          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.black));
          }

          final allDocs = snapshot.data!.docs;

          final filteredDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['isHidden'] == true) return false;
            if (_selectedHabitType != 'All' &&
                data['type'] != _selectedHabitType) {
              return false;
            }

            final searchTerm = _searchController.text.toLowerCase();
            if (searchTerm.isNotEmpty &&
                !data['title'].toString().toLowerCase().contains(searchTerm)) {
              return false;
            }
            return true;
          }).toList();

          return Column(
            children: [
              _buildTypeToggle(),
              if (_showDashboardWidget) _buildInfographic(allDocs),
              Expanded(
                child: filteredDocs.isEmpty
                    ? Center(
                        child: Text("No habits found.",
                            style: TextStyle(color: Colors.grey[500])))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          // Core
                          final String title = data['title'] ?? 'Untitled';
                          final int streak = data['streak'] ?? 0;

                          // Parse Deadline securely
                          DateTime? parsedDeadline;
                          if (data['deadline'] != null) {
                            parsedDeadline =
                                (data['deadline'] as Timestamp).toDate();
                          }

                          final bool isExercise = data['isExercise'] == true ||
                              data['category']?.toString().toLowerCase() == 'exercise';
                          final List<String> tags = [];
                          if (data['category'] != null && data['category'].toString().isNotEmpty) {
                            tags.add(data['category'].toString());
                          }
                          if (data['tags'] is List) {
                            for (var rawTag in data['tags'] as List) {
                              final tag = rawTag.toString().trim();
                              if (tag.isNotEmpty && !tags.contains(tag)) {
                                tags.add(tag);
                              }
                            }
                          }

                          final int? iconCode = data['iconCodePoint'];
                          final String? iconFamily = data['iconFontFamily'];
                          final int? colorValue = data['colorValue'];

                          final IconData habitIcon = iconCode != null
                              ? IconData(iconCode, fontFamily: iconFamily)
                              : Icons.fitness_center;
                          final Color habitColor = colorValue != null
                              ? Color(colorValue)
                              : Colors.black87;

                          return GestureDetector(
                            // Tapping the card body opens the edit dialog
                            onTap: () => _showEditHabitDialog(doc),
                            child: ReusableCard(
                              habitId: doc.id,
                              title: title,
                              description: "$streak Day Streak",
                              icon: habitIcon,
                              color: habitColor,
                              isExercise: isExercise,
                              onWorkoutSaved: isExercise
                                  ? (workoutData) async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      await _habitsCollection.doc(doc.id).update({
                                        'exerciseLogs': FieldValue.arrayUnion([workoutData]),
                                        'lastWorkout': workoutData,
                                      });
                                      if (!mounted) return;
                                      messenger.showSnackBar(const SnackBar(
                                          content: Text('Workout logged successfully.')));
                                    }
                                  : null,

                              // Pass Metadata dynamically
                              type: data['type'],
                              pillar: data['pillar'],
                              tags: tags.isNotEmpty ? tags : null,
                              urgency: data['urgency'],
                              priority: data['priority'], 
                              deadline: parsedDeadline,

                              // Pass unified initial state
                              initialStatus: _determineStatus(data),

                              // Connect the single Status Callback to Firestore
                              onStatusChanged: (newStatus) => 
                                  _updateHabitState(doc, newStatus),

                              // Connect the Secondary Tools to Navigation
                              onCalendarTap: () =>
                                  _navToHabitDetail(title, 'Calendar'),
                              onStatsTap: () =>
                                  _navToHabitDetail(title, 'Statistics'),
                              onHistoryTap: () =>
                                  _navToHabitDetail(title, 'History'),
                              onTagsTap: () => _navToHabitDetail(title, 'Tags'),

                              // Management Actions
                              onShareTap: () {
                                Share.share('Join me on Unwaver and let\'s collaborate on my habit: $title! 🚀');
                              },
                              onEdit: () => _showEditHabitDialog(doc),
                              onDelete: () => _deleteHabit(doc.id),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: _navToCreation,
        backgroundColor: Colors.black,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // --- FORMATTER HELPERS ---

  String _formatPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'low': return 'P1';
      case 'medium': return 'P2';
      case 'high': return 'P3';
      case 'critical': return 'P4';
      default: return priority;
    }
  }

  String _formatUrgency(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'low': return '!';
      case 'medium': return '!!';
      case 'high': return '!!!';
      case 'critical': return '!!!!';
      default: return urgency;
    }
  }
}

// --- EDIT HABIT SCREEN (FULL-SCREEN) ---

class _EditHabitScreen extends StatefulWidget {
  final DocumentSnapshot doc;
  final Map<String, dynamic> data;
  final CollectionReference habitsCollection;
  final Function(String) formatPriority;
  final Function(String) formatUrgency;

  const _EditHabitScreen({
    required this.doc,
    required this.data,
    required this.habitsCollection,
    required this.formatPriority,
    required this.formatUrgency,
  });

  @override
  State<_EditHabitScreen> createState() => _EditHabitScreenState();
}

class _EditHabitScreenState extends State<_EditHabitScreen> {
  late TextEditingController titleCtrl;
  late TextEditingController categoryCtrl;
  late TextEditingController tagsCtrl;
  late TextEditingController descriptionCtrl;
  
  late String habitType;
  late String selectedPillar;
  late String priority;
  late String urgency;
  late bool isExercise;
  bool _isSaving = false;
  late IconData _selectedIcon;
  late Color _selectedColor;

  final List<String> _habitTypes = ['Habits to Build', 'Habits to Break'];
  final List<String> _pillars = ['Faith', 'Health', 'Relationships', 'Optimization', 'Education', 'Work', 'Creativity'];
  final List<String> _levels = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void initState() {
    super.initState();
    final tags = (widget.data['tags'] as List<dynamic>?)
            ?.map((tag) => tag.toString())
            .toList() ??
        [];
    
    titleCtrl = TextEditingController(text: widget.data['title'] ?? '');
    categoryCtrl = TextEditingController(text: widget.data['category'] ?? '');
    tagsCtrl = TextEditingController(text: tags.join(', '));
    descriptionCtrl = TextEditingController(text: widget.data['description'] ?? '');
    
    habitType = widget.data['type'] ?? 'Habits to Build';
    selectedPillar = widget.data['pillar'] ?? 'Health';
    priority = widget.data['priority'] ?? 'Medium';
    urgency = widget.data['urgency'] ?? 'Medium';
    isExercise = widget.data['isExercise'] == true;

    final int? iconCode = widget.data['iconCodePoint'];
    final String? iconFamily = widget.data['iconFontFamily'];
    final int? colorValue = widget.data['colorValue'];

    _selectedIcon = iconCode != null ? IconData(iconCode, fontFamily: iconFamily) : Icons.fitness_center;
    _selectedColor = colorValue != null ? Color(colorValue) : Colors.black87;
  }

  @override
  void dispose() {
    titleCtrl.dispose(); // <-- Added missing controller
    categoryCtrl.dispose();
    tagsCtrl.dispose();
    descriptionCtrl.dispose();
    super.dispose();
  }

  void _saveHabit() async {
      if (titleCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a habit name'))
        );
        return;
      }

      // Dismiss keyboard for a smoother UX while saving
      FocusScope.of(context).unfocus(); 

      setState(() => _isSaving = true);
    
    // ... rest of your try/catch block
    
    try {
      final updatedTags = tagsCtrl.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      // Fire and forget update
      widget.habitsCollection.doc(widget.doc.id).update({
        'title': titleCtrl.text.trim(),
        'category': categoryCtrl.text.trim(),
        'tags': updatedTags,
        'isExercise': isExercise,
        'type': habitType,
        'pillar': selectedPillar,
        'priority': priority,
        'urgency': urgency,
        'description': descriptionCtrl.text.trim(),
        'iconCodePoint': _selectedIcon.codePoint,
        'iconFontFamily': _selectedIcon.fontFamily,
        'colorValue': _selectedColor.toARGB32(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Habit updated successfully')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showIconPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select an Icon', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: kHabitIcons.length,
            itemBuilder: (context, index) {
              return IconButton(
                icon: Icon(kHabitIcons[index], size: 30, color: Colors.black87),
                onPressed: () {
                  setState(() => _selectedIcon = kHabitIcons[index]);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showColorPicker() {
    Color tempColor = _selectedColor;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select a Color', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: HueRingPicker(
            pickerColor: tempColor,
            onColorChanged: (color) {
              tempColor = color;
            },
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text('Select'),
            onPressed: () {
              setState(() => _selectedColor = tempColor);
              Navigator.of(context).pop();
            },
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
        title: const Text("Edit Habit", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveHabit,
            child: const Text(
              "SAVE",
              style: TextStyle(color: Color.fromARGB(255, 187, 142, 19), fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Visual Identity
          Row(
            children: [
              GestureDetector(
                onTap: _showIconPicker,
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: _selectedColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _selectedColor),
                  ),
                  child: Icon(_selectedIcon, color: _selectedColor, size: 32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Visual Identity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _showColorPicker,
                          icon: const Icon(Icons.palette, size: 16, color: Colors.black87),
                          label: const Text("Set Color", style: TextStyle(color: Colors.black87)),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),

          // 1. Name
          _buildLabel("Habit Name"),
          TextField(
            controller: titleCtrl,
            decoration: _inputDecoration("e.g. Morning Run"),
          ),
          const SizedBox(height: 20),

          // 2. Classification (Build vs Break)
          _buildLabel("Classification"),
          _buildDropdown(_habitTypes, habitType, (val) => setState(() => habitType = val!)),
          const SizedBox(height: 20),

          // 3. Pillar (Dropdown)
          _buildLabel("Life Pillar"),
          _buildDropdown(_pillars, selectedPillar, (val) => setState(() => selectedPillar = val!)),
          const SizedBox(height: 20),

          // 4. Category
          _buildLabel("Category (Sub-pillar)"),
          TextField(
            controller: categoryCtrl,
            decoration: _inputDecoration("e.g. Cardio"),
          ),
          const SizedBox(height: 16),
          _buildLabel("Tags"),
          TextField(
            controller: tagsCtrl,
            decoration: _inputDecoration("Comma-separated tags, e.g. Exercise, Strength"),
          ),
          const SizedBox(height: 16),
          if (selectedPillar == 'Health')
            Row(
              children: [
                Expanded(
                  child: Text("Track Workouts",
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                ),
                Switch(
                  value: isExercise,
                  activeThumbColor: Colors.black,
                  onChanged: (value) => setState(() => isExercise = value),
                ),
              ],
            ),
          if (selectedPillar == 'Health')
            const SizedBox(height: 20),

          // 5. Priority & Urgency Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Priority"),
                    _buildFormattedDropdown(_levels, priority, (val) => setState(() => priority = val!), widget.formatPriority),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Urgency"),
                    _buildFormattedDropdown(_levels, urgency, (val) => setState(() => urgency = val!), widget.formatUrgency),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 6. Description
          _buildLabel("Description / Why?"),
          TextField(
            controller: descriptionCtrl,
            maxLines: 4,
            decoration: _inputDecoration("Describe the habit and why it matters..."),
          ),
          
          const SizedBox(height: 40),
          
          // 7. Save Button (Main)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveHabit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSaving 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("UPDATE HABIT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildDropdown(List<String> items, String currentValue, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          items: items.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildFormattedDropdown(List<String> items, String currentValue, ValueChanged<String?> onChanged, Function(String) formatter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          items: items.map((val) => DropdownMenuItem(value: val, child: Text('$val (${formatter(val)})'))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}