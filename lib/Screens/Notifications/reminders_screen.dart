import 'package:flutter/material.dart';

// --- 1. The Data Model ---

enum ReminderType { habit, goal, schedule }

class ReminderItem {
  final String id;
  final String title;
  final String subtitle;
  final ReminderType type;
  final double? progress; // 0.0 to 1.0 (For Goals)
  final String? time;     // (For Schedule)
  final int? streak;      // (For Habits)
  bool isEnabled;         // The "Toggle Settings" state

  ReminderItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.isEnabled = true,
    this.progress,
    this.time,
    this.streak,
  });
}

// --- 2. The Main Screen ---

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock Data
  final List<ReminderItem> _items = [
    // Habits
    ReminderItem(id: '1', title: 'Morning Jog', subtitle: 'Daily at 6:00 AM', type: ReminderType.habit, streak: 12),
    ReminderItem(id: '2', title: 'Drink Water', subtitle: 'Every 2 hours', type: ReminderType.habit, streak: 5, isEnabled: false),
    ReminderItem(id: '3', title: 'Read 10 Pages', subtitle: 'Before bed', type: ReminderType.habit, streak: 30),
    
    // Goals
    ReminderItem(id: '4', title: 'Save \$5000', subtitle: '\$3,200 / \$5,000 saved', type: ReminderType.goal, progress: 0.64),
    ReminderItem(id: '5', title: 'Learn Flutter', subtitle: 'Module 4 of 10', type: ReminderType.goal, progress: 0.4, isEnabled: false),
    
    // Schedule
    ReminderItem(id: '6', title: 'Team Standup', subtitle: 'Zoom Link • 15 mins', type: ReminderType.schedule, time: '10:00 AM'),
    ReminderItem(id: '7', title: 'Dentist Appt', subtitle: 'Dr. Smith', type: ReminderType.schedule, time: '2:30 PM'),
    ReminderItem(id: '8', title: 'Client Call', subtitle: 'Project Review', type: ReminderType.schedule, time: '4:00 PM'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _toggleItem(String id) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        _items[index].isEnabled = !_items[index].isEnabled;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Soft grey background
      appBar: AppBar(
        title: const Text('My Day', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blueAccent,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'SCHEDULE'),
            Tab(text: 'HABITS'),
            Tab(text: 'GOALS'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              // Placeholder for a global settings modal
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Open Global Notification Settings')),
              );
            },
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(ReminderType.schedule),
          _buildList(ReminderType.habit),
          _buildList(ReminderType.goal),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('New Reminder'),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  Widget _buildList(ReminderType type) {
    final filteredItems = _items.where((i) => i.type == type).toList();

    if (filteredItems.isEmpty) {
      return const Center(child: Text("No reminders found."));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _ReminderTile(
          item: filteredItems[index],
          onToggle: () => _toggleItem(filteredItems[index].id),
        );
      },
    );
  }
}

// --- 3. The Smart Tile Widget ---

class _ReminderTile extends StatelessWidget {
  final ReminderItem item;
  final VoidCallback onToggle;

  const _ReminderTile({required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isEnabled = item.isEnabled;
    final mutedColor = Colors.grey.shade400;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6, // Visual feedback for disabled state
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  _buildLeadingIcon(item, isEnabled),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isEnabled ? Colors.black87 : mutedColor,
                            decoration: isEnabled ? null : TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: isEnabled ? Colors.grey[600] : mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: isEnabled,
                      onChanged: (_) => onToggle(),
                      activeThumbColor: _getColor(item.type),
                    ),
                  ),
                ],
              ),
              // Conditional rendering for extra data (Goals progress bar)
              if (item.type == ReminderType.goal && item.progress != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.progress,
                    backgroundColor: Colors.grey[100],
                    valueColor: AlwaysStoppedAnimation<Color>(
                       isEnabled ? Colors.orangeAccent : mutedColor
                    ),
                    minHeight: 6,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(ReminderItem item, bool isEnabled) {
    IconData icon;
    Color color;

    switch (item.type) {
      case ReminderType.habit:
        icon = Icons.repeat;
        color = Colors.green;
        break;
      case ReminderType.goal:
        icon = Icons.emoji_events_outlined;
        color = Colors.orange;
        break;
      case ReminderType.schedule:
        icon = Icons.access_time;
        color = Colors.blue;
        break;
    }

    if (!isEnabled) color = Colors.grey;

    // Special layout for Schedule (shows time big)
    if (item.type == ReminderType.schedule && item.time != null) {
       return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          item.time!.split(' ')[0], // Just the time
          style: TextStyle(
            color: color, 
            fontWeight: FontWeight.bold,
            fontSize: 14
          ),
        ),
      );
    }

    // Default icon layout
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Color _getColor(ReminderType type) {
    switch (type) {
      case ReminderType.habit: return Colors.green;
      case ReminderType.goal: return Colors.orange;
      case ReminderType.schedule: return Colors.blue;
    }
  }
}