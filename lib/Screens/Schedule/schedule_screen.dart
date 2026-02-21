import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
// Ensure these point to your actual file locations
import 'package:unwaver/widgets/main_drawer.dart';
import 'package:unwaver/widgets/global_app_bar.dart';

// --- ENUMS & MODELS ---
enum ScheduleView { Day, Month, Sync }
enum ItemType { Event, Habit, Task }

class ScheduleItem {
  final String id;
  String title;
  ItemType type;
  DateTime? scheduledDate; 
  TimeOfDay? startTime;
  int durationMinutes;
  Color color;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.type,
    this.scheduledDate,
    this.startTime,
    this.durationMinutes = 60,
    required this.color,
  });

  ScheduleItem copyWith({DateTime? scheduledDate, TimeOfDay? startTime}) {
    return ScheduleItem(
      id: id,
      title: title,
      type: type,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes,
      color: color,
    );
  }
}

// --- MAIN CLASS ---
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with SingleTickerProviderStateMixin {
  // --- STATE ---
  ScheduleView _currentView = ScheduleView.Day;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  
  // App Bar Search State
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Data Pools
  List<ScheduleItem> _unscheduledItems = [];
  final Map<DateTime, List<ScheduleItem>> _scheduledItems = {};

  // Colors
  final Color _goldColor = const Color(0xFFD4AF37);
  final Color _darkBg = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _seedDummyData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _seedDummyData() {
    // Unscheduled items waiting in the "Routine Pool"
    _unscheduledItems = [
      ScheduleItem(id: 'u1', title: 'Morning Meditation', type: ItemType.Habit, color: Colors.purple.shade400, durationMinutes: 30),
      ScheduleItem(id: 'u2', title: 'Read 20 Pages', type: ItemType.Habit, color: Colors.indigo.shade400, durationMinutes: 45),
      ScheduleItem(id: 'u3', title: 'Review Finances', type: ItemType.Task, color: Colors.blueGrey.shade600, durationMinutes: 60),
      ScheduleItem(id: 'u4', title: 'Gym Workout', type: ItemType.Habit, color: Colors.red.shade400, durationMinutes: 90),
    ];

    // Already scheduled items
    final todayMidnight = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    _scheduledItems[todayMidnight] = [
      ScheduleItem(
        id: 's1', 
        title: 'Deep Work Session', 
        type: ItemType.Event, 
        scheduledDate: todayMidnight, 
        startTime: const TimeOfDay(hour: 9, minute: 0), 
        color: _goldColor,
        durationMinutes: 120
      ),
      ScheduleItem(
        id: 's2', 
        title: 'Client Sync', 
        type: ItemType.Event, 
        scheduledDate: todayMidnight, 
        startTime: const TimeOfDay(hour: 13, minute: 0), 
        color: Colors.blue.shade600,
      ),
    ];
  }

  // --- LOGIC ---
  void _onItemDropped(ScheduleItem item, TimeOfDay dropTime) {
    setState(() {
      final normalizedDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
      
      // Remove from old location
      if (item.scheduledDate == null) {
        _unscheduledItems.removeWhere((e) => e.id == item.id);
      } else {
        final oldDate = DateTime(item.scheduledDate!.year, item.scheduledDate!.month, item.scheduledDate!.day);
        _scheduledItems[oldDate]?.removeWhere((e) => e.id == item.id);
      }

      // Add to new location
      final updatedItem = item.copyWith(scheduledDate: normalizedDate, startTime: dropTime);
      if (_scheduledItems[normalizedDate] == null) {
        _scheduledItems[normalizedDate] = [];
      }
      _scheduledItems[normalizedDate]!.add(updatedItem);
      
      // Sort the day's timeline
      _scheduledItems[normalizedDate]!.sort((a, b) => 
        (a.startTime!.hour * 60 + a.startTime!.minute)
        .compareTo(b.startTime!.hour * 60 + b.startTime!.minute)
      );
    });
  }

  void _removeToPool(ScheduleItem item) {
    setState(() {
      final normalizedDate = DateTime(item.scheduledDate!.year, item.scheduledDate!.month, item.scheduledDate!.day);
      _scheduledItems[normalizedDate]?.removeWhere((e) => e.id == item.id);
      _unscheduledItems.add(item.copyWith(scheduledDate: null, startTime: null));
    });
  }

  List<ScheduleItem> _getEventsForDay(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return _scheduledItems[normalized] ?? [];
  }

  // --- BUILDERS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
          // Future: Open filter options
        },
        onSortTap: () {
          // Future: Open sort options
        }, actions: [],
      ),
      drawer: const MainDrawer(currentRoute: '/schedule'),
      body: Column(
        children: [
          _buildTopNavigation(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCurrentView(),
            ),
          ),
        ],
      ),
      floatingActionButton: _currentView == ScheduleView.Day 
          ? FloatingActionButton.extended(
              backgroundColor: Colors.black,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Create", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                // Future: Open 'Create Item' Bottom Sheet
              },
            )
          : null,
    );
  }

  Widget _buildTopNavigation() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // View Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildTabButton("Routine Builder", ScheduleView.Day),
                _buildTabButton("Month", ScheduleView.Month),
                _buildTabButton("Sync", ScheduleView.Sync),
              ],
            ),
          ),
          
          if (_currentView == ScheduleView.Day) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() => _selectedDay = _selectedDay.subtract(const Duration(days: 1))),
                ),
                Column(
                  children: [
                    Text(
                      DateFormat('EEEE').format(_selectedDay), // e.g., "Monday"
                      style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    Text(
                      DateFormat('MMMM d, yyyy').format(_selectedDay),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() => _selectedDay = _selectedDay.add(const Duration(days: 1))),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, ScheduleView view) {
    final isSelected = _currentView == view;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentView = view),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : [],
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.black : Colors.grey[500],
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case ScheduleView.Day:
        return _buildDayBuilderView();
      case ScheduleView.Month:
        return _buildMonthOverview();
      case ScheduleView.Sync:
        return _buildSyncDashboard();
    }
  }

  // --- 1. DAY BUILDER (DRAG & DROP) ---
  Widget _buildDayBuilderView() {
    return Column(
      key: const ValueKey("DayView"),
      children: [
        // The Interactive Timeline
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 20, bottom: 100), // Space for FAB
            itemCount: 24,
            itemBuilder: (context, index) {
              final hour = index;
              final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
              final amPm = hour < 12 ? "AM" : "PM";
              
              // Find item scheduled for this hour
              final dailyItems = _getEventsForDay(_selectedDay);
              final itemsForThisHour = dailyItems.where((i) => i.startTime?.hour == hour).toList();

              return DragTarget<ScheduleItem>(
                onWillAcceptWithDetails: (details) => true,
                onAcceptWithDetails: (details) => _onItemDropped(details.data, TimeOfDay(hour: hour, minute: 0)),
                builder: (context, candidateData, rejectedData) {
                  final isHovered = candidateData.isNotEmpty;
                  
                  return Container(
                    height: 80, // Height of one hour block
                    decoration: BoxDecoration(
                      color: isHovered ? _goldColor.withValues(alpha:0.1) : Colors.transparent,
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time Column
                        SizedBox(
                          width: 60,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8, right: 12),
                            child: Text(
                              "$displayHour $amPm",
                              textAlign: TextAlign.right,
                              style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        // Timeline Divider
                        Container(width: 1, color: Colors.grey[300]),
                        // Content Area
                        Expanded(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              if (isHovered)
                                Center(child: Text("Drop Here", style: TextStyle(color: _goldColor, fontWeight: FontWeight.bold))),
                              
                              for (var item in itemsForThisHour)
                                Positioned(
                                  top: 4,
                                  left: 8,
                                  right: 16,
                                  child: LongPressDraggable<ScheduleItem>(
                                    data: item,
                                    feedback: Material(
                                      color: Colors.transparent,
                                      child: SizedBox(width: MediaQuery.of(context).size.width - 90, child: _buildScheduledBlock(item, isDragging: true)),
                                    ),
                                    childWhenDragging: Opacity(opacity: 0.3, child: _buildScheduledBlock(item)),
                                    child: Dismissible(
                                      key: Key(item.id),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 16),
                                        child: const Icon(Icons.arrow_downward, color: Colors.grey),
                                      ),
                                      onDismissed: (_) => _removeToPool(item),
                                      child: _buildScheduledBlock(item),
                                    ),
                                  ),
                                )
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        
        // The Routine Pool (Draggable source)
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10, offset: const Offset(0, -4))],
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("ROUTINE POOL", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    Text("Drag to assign", style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _unscheduledItems.length,
                  itemBuilder: (context, index) {
                    final item = _unscheduledItems[index];
                    return Draggable<ScheduleItem>(
                      data: item,
                      feedback: Material(
                        color: Colors.transparent,
                        child: _buildPoolCard(item, isDragging: true),
                      ),
                      childWhenDragging: Opacity(opacity: 0.3, child: _buildPoolCard(item)),
                      child: _buildPoolCard(item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduledBlock(ScheduleItem item, {bool isDragging = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: item.color, width: 4)),
        boxShadow: isDragging ? [const BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[900])),
              Icon(_getIconForType(item.type), size: 14, color: item.color),
            ],
          ),
          const SizedBox(height: 4),
          Text("${item.durationMinutes} min", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildPoolCard(ScheduleItem item, {bool isDragging = false}) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.color.withValues(alpha:0.3)),
        boxShadow: [BoxShadow(color: item.color.withValues(alpha:0.1), blurRadius: isDragging ? 12 : 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getIconForType(item.type), color: item.color, size: 20),
          const Spacer(),
          Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text("${item.type.name} • ${item.durationMinutes}m", style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }

  IconData _getIconForType(ItemType type) {
    switch (type) {
      case ItemType.Event: return Icons.event;
      case ItemType.Habit: return Icons.cached;
      case ItemType.Task: return Icons.check_circle_outline;
    }
  }

  // --- 2. MONTH OVERVIEW ---
  Widget _buildMonthOverview() {
    return Container(
      key: const ValueKey("MonthView"),
      color: Colors.white,
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
            _currentView = ScheduleView.Day; // Jump to day view on tap
          });
        },
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(color: _goldColor, shape: BoxShape.circle),
          todayDecoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
        ),
        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
        eventLoader: _getEventsForDay, // Shows dots under days with events
      ),
    );
  }

  // --- 3. SYNC DASHBOARD ---
  Widget _buildSyncDashboard() {
    return SingleChildScrollView(
      key: const ValueKey("SyncView"),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Integrations", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text("Connect external calendars to Unwaver to populate your Routine Builder automatically.", style: TextStyle(color: Colors.grey[600], height: 1.5)),
          const SizedBox(height: 32),
          
          _buildIntegrationCard(
            title: "Google Calendar",
            description: "Sync events from your Google workspace.",
            icon: Icons.g_mobiledata,
            iconColor: Colors.red,
            isConnected: true,
          ),
          const SizedBox(height: 16),
          _buildIntegrationCard(
            title: "Apple Calendar",
            description: "Sync iCloud events and reminders.",
            icon: Icons.apple,
            iconColor: Colors.black,
            isConnected: false,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _goldColor.withValues(alpha:0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: _goldColor.withValues(alpha:0.3))),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: _goldColor),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text("Unwaver never deletes external events. Changes made here sync safely to your providers.", style: TextStyle(fontSize: 12)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildIntegrationCard({required String title, required String description, required IconData icon, required Color iconColor, required bool isConnected}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isConnected ? _goldColor : Colors.grey.shade200, width: isConnected ? 2 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isConnected ? Colors.white : Colors.black,
              foregroundColor: isConnected ? Colors.red : Colors.white,
              elevation: 0,
              side: isConnected ? BorderSide(color: Colors.grey.shade300) : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              // Toggle sync logic here
            },
            child: Text(isConnected ? "Disconnect" : "Connect"),
          )
        ],
      ),
    );
  }
}