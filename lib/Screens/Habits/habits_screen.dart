import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unwaver/widgets/main_drawer.dart';
import 'package:unwaver/widgets/global_app_bar.dart';
import 'package:unwaver/widgets/reusable_card.dart';
import 'habit_creation_screen.dart';

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

  final CollectionReference _habitsCollection = FirebaseFirestore.instance.collection('habits');
  late Stream<QuerySnapshot> _habitsStream;

  @override
  void initState() {
    super.initState();
    _habitsStream = _habitsCollection.orderBy('createdAt', descending: true).snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- FIREBASE OPERATIONS ---

  // Unified state update for the 3-way toggle (Complete, Skip, Fail)
  Future<void> _updateHabitState(DocumentSnapshot doc, String stateType) async {
    HapticFeedback.lightImpact(); 
    final data = doc.data() as Map<String, dynamic>;
    final int currentStreak = data['streak'] ?? 0;

    bool isCompleted = false;
    bool isSkipped = false;
    bool isFailed = false;
    int newStreak = currentStreak;

    // Logic to ensure only one toggle is active at a time and streak is handled safely
    if (stateType == 'complete') {
      isCompleted = !(data['isCompleted'] ?? false);
      newStreak = isCompleted ? currentStreak + 1 : (currentStreak > 0 ? currentStreak - 1 : 0);
    } else if (stateType == 'skip') {
      isSkipped = !(data['isSkipped'] ?? false);
    } else if (stateType == 'fail') {
      isFailed = !(data['isFailed'] ?? false);
      newStreak = isFailed ? 0 : currentStreak; // Failing resets the streak to 0
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
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

  // --- NAVIGATION ROUTING ---
  
  // Routes to a specific detail screen based on which icon on the card was clicked
  void _navToHabitDetail(String title, String specificView) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('$title - $specificView', style: const TextStyle(color: Colors.black)),
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
        : docs.where((doc) => (doc.data() as Map<String, dynamic>)['type'] == _selectedHabitType).toList();

    final totalHabits = currentTypeHabits.length;
    final completedToday = currentTypeHabits.where((doc) => (doc.data() as Map<String, dynamic>)['isCompleted'] == true).length;

    int bestStreak = 0;
    int totalStreakDays = 0;

    for (var doc in currentTypeHabits) {
      final data = doc.data() as Map<String, dynamic>;
      int s = data['streak'] ?? 0;
      if (s > bestStreak) bestStreak = s;
      totalStreakDays += s;
    }

    final percent = totalHabits == 0 ? 0 : ((completedToday / totalHabits) * 100).toInt();

    return {
      "Best Streak": "$bestStreak",
      "Total Days": "$totalStreakDays",
      "Done": "$completedToday/$totalHabits",
      "Rate": "$percent%",
    };
  }

  // --- UI BUILDERS ---
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600)),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isDashboardExpanded = !_isDashboardExpanded);
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
                      Text("HABITS DASHBOARD", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey[800])),
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
                        const Divider(height: 1),
                        const SizedBox(height: 24),
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
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
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
            return const Center(child: Text('Error loading habits. Check your database rules.'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          final allDocs = snapshot.data!.docs;

          final filteredDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['isHidden'] == true) return false;
            if (_selectedHabitType != 'All' && data['type'] != _selectedHabitType) return false;

            final searchTerm = _searchController.text.toLowerCase();
            if (searchTerm.isNotEmpty && !data['title'].toString().toLowerCase().contains(searchTerm)) {
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
                    ? Center(child: Text("No habits found.", style: TextStyle(color: Colors.grey[500])))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 100), 
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final data = doc.data() as Map<String, dynamic>;

                          // Core
                          final String title = data['title'] ?? 'Untitled';
                          final int streak = data['streak'] ?? 0;
                          
                          // Toggle States
                          final bool isCompleted = data['isCompleted'] ?? false;
                          final bool isSkipped = data['isSkipped'] ?? false;
                          final bool isFailed = data['isFailed'] ?? false;

                          // Parse Deadline securely
                          DateTime? parsedDeadline;
                          if (data['deadline'] != null) {
                            parsedDeadline = (data['deadline'] as Timestamp).toDate();
                          }

                          return GestureDetector(
                            // Tapping the card body opens the main detail view
                            onTap: () => _navToHabitDetail(title, 'Main Dashboard'),
                            child: ReusableCard(
                              title: title,
                              description: "$streak Day Streak",
                              icon: Icons.local_fire_department, // Static Icon (Never overwritten)
                              color: Colors.black87,
                              
                              // Pass Metadata dynamically
                              pillar: data['pillar'],
                              tags: data['category'] != null ? [data['category']] : null, 
                              urgency: data['urgency'],
                              importance: data['priority'], // Mapping your creation screen 'priority' to 'importance'
                              deadline: parsedDeadline,

                              // Pass Toggle States to trigger visuals
                              initialCompleted: isCompleted,
                              initialSkipped: isSkipped,
                              initialFailed: isFailed,

                              // Connect the Segmented Toggle Actions to Firestore
                              onComplete: () => _updateHabitState(doc, 'complete'),
                              onSkip: () => _updateHabitState(doc, 'skip'),
                              onFail: () => _updateHabitState(doc, 'fail'),

                              // Connect the Secondary Tools to Navigation
                              onCalendarTap: () => _navToHabitDetail(title, 'Calendar'),
                              onStatsTap: () => _navToHabitDetail(title, 'Statistics'),
                              onHistoryTap: () => _navToHabitDetail(title, 'History'),
                              onTagsTap: () => _navToHabitDetail(title, 'Tags'),
                              
                              // Management Actions
                              onEdit: () => _navToHabitDetail(title, 'Edit'),
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
        onPressed: _navToCreation,
        backgroundColor: Colors.black,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}