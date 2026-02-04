import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // Added for date formatting
import 'package:unwaver/widgets/maindrawer.dart';
import 'package:unwaver/widgets/app_logo.dart';

// --- MODELS ---
class Event {
  final String id;
  String title;
  String description;
  TimeOfDay time;
  String category;
  // Added duration for dashboard calculation
  final int durationMinutes; 

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.category,
    this.durationMinutes = 60,
  });
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // --- STATE ---
  CalendarFormat _calendarFormat = CalendarFormat.week; // Default to week for "Schedule" feel
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _showBanner = true; // For Instruction Banner

  // Toggles for "Layers"
  bool _showEvents = true;
  bool _showHabits = false;
  bool _showTasks = false;

  late Map<DateTime, List<Event>> _events;
  bool _isSyncing = false;

  // Theme Colors
  final Color _goldColor = const Color(0xFFD4AF37); // Fixed Gold Color
  final Color _bgGrey = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _events = {};
    // Add some dummy data for demonstration
    _addDummyData();
  }

  void _addDummyData() {
    final now = DateTime.now();
    _events[DateTime(now.year, now.month, now.day)] = [
      Event(id: '1', title: 'Deep Work Session', description: 'Coding the new module', time: const TimeOfDay(hour: 9, minute: 0), category: 'Deep Work', durationMinutes: 120),
      Event(id: '2', title: 'Team Sync', description: 'Weekly standup', time: const TimeOfDay(hour: 13, minute: 0), category: 'Meeting', durationMinutes: 30),
      Event(id: '3', title: 'Gym', description: 'Leg day', time: const TimeOfDay(hour: 17, minute: 30), category: 'Health', durationMinutes: 60),
    ];
  }

  // --- LOGIC ---

  List<Event> _getEventsForDay(DateTime day) {
    // Normalizing date to ignore time for map lookup
    final normalizedDate = DateTime(day.year, day.month, day.day);
    final events = _events[normalizedDate] ?? [];
    events.sort((a, b) {
      final aMinutes = a.time.hour * 60 + a.time.minute;
      final bMinutes = b.time.hour * 60 + b.time.minute;
      return aMinutes.compareTo(bMinutes);
    });
    return events;
  }

  void _addEvent(String title, String desc, TimeOfDay time, String cat) {
    if (_selectedDay == null) return;
    final normalizedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    
    final newEvent = Event(
      id: DateTime.now().toString(),
      title: title,
      description: desc,
      time: time,
      category: cat,
    );

    setState(() {
      if (_events[normalizedDate] != null) {
        _events[normalizedDate]!.add(newEvent);
      } else {
        _events[normalizedDate] = [newEvent];
      }
    });
  }

  void _deleteEvent(Event event) {
    if (_selectedDay == null) return;
    final normalizedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    setState(() {
      _events[normalizedDate]?.remove(event);
    });
  }

  Future<void> _handleSync(String source) async {
    Navigator.pop(context);
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Synced with $source"), backgroundColor: Colors.black),
      );
    }
  }

  // --- DASHBOARD STATS CALCULATION ---
  Map<String, String> _calculateDailyStats() {
    final events = _getEventsForDay(_selectedDay ?? DateTime.now());
    
    int totalMinutes = events.fold(0, (sum, item) => sum + item.durationMinutes);
    int hours = totalMinutes ~/ 60;
    
    // Mocking Habit/Task counts for now since they aren't fully linked
    int habitCount = _showHabits ? 3 : 0; 
    int taskCount = _showTasks ? 5 : 0;

    return {
      "Events": "${events.length}",
      "Hours": "$hours",
      "Habits": "$habitCount",
      "Tasks": "$taskCount",
    };
  }

  // --- BOTTOM SHEETS ---

  void _showSyncOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, color: Colors.grey[300]),
              const SizedBox(height: 20),
              Text("Sync Calendars", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _goldColor)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.g_mobiledata, size: 32, color: Colors.red),
                title: const Text("Google Calendar", style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.check_circle, color: Colors.green), // Mock connected state
                onTap: () => _handleSync("Google"),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.apple, size: 32),
                title: const Text("Apple Calendar", style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _handleSync("Apple"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showAddEventSheet() {
    String title = "";
    String description = "";
    TimeOfDay selectedTime = TimeOfDay.now();
    String selectedCategory = "Deep Work";
    final List<String> categories = ["Deep Work", "Meeting", "Health", "Routine", "Other"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, color: Colors.grey[300]),
              const SizedBox(height: 20),
              Text("Add Event", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _goldColor)),
              const SizedBox(height: 20),
              TextField(
                decoration: const InputDecoration(hintText: "Title", prefixIcon: Icon(Icons.edit)),
                onChanged: (val) => title = val,
                autofocus: true,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(hintText: "Description", prefixIcon: Icon(Icons.subject)),
                onChanged: (val) => description = val,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    if (title.isNotEmpty) {
                      _addEvent(title, description, selectedTime, selectedCategory);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Add to Schedule", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- WIDGETS ---

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _goldColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _goldColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: _goldColor),
          const SizedBox(width: 12),
          Expanded(
            child: const Text(
              "Organize your day. Sync calendars and overlay your Habits and Tasks to see your complete schedule at a glance.",
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _showBanner = false),
            child: const Icon(Icons.close, size: 20, color: Colors.grey),
          )
        ],
      ),
    );
  }

  Widget _buildEventsDashboard() {
    final stats = _calculateDailyStats();
    final dateStr = DateFormat('EEEE, MMM d').format(_selectedDay ?? DateTime.now());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("DAILY BRIEFING", style: TextStyle(color: _goldColor, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(dateStr, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDashStat("Events", stats["Events"]!),
              Container(width: 1, height: 30, color: Colors.grey.shade800),
              _buildDashStat("Busy Hrs", stats["Hours"]!),
              Container(width: 1, height: 30, color: Colors.grey.shade800),
              _buildDashStat("Habits", stats["Habits"]!, isActive: _showHabits),
              Container(width: 1, height: 30, color: Colors.grey.shade800),
              _buildDashStat("Tasks", stats["Tasks"]!, isActive: _showTasks),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashStat(String label, String value, {bool isActive = true}) {
    return Column(
      children: [
        Text(
          value, 
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade700, 
            fontSize: 18, 
            fontWeight: FontWeight.bold
          )
        ),
        Text(
          label, 
          style: TextStyle(
            color: isActive ? Colors.grey.shade400 : Colors.grey.shade800, 
            fontSize: 10
          )
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip("Events", _showEvents, (val) => setState(() => _showEvents = val)),
          const SizedBox(width: 8),
          _buildFilterChip("Habits", _showHabits, (val) => setState(() => _showHabits = val)),
          const SizedBox(width: 8),
          _buildFilterChip("Tasks", _showTasks, (val) => setState(() => _showTasks = val)),
          const SizedBox(width: 8),
          // Goal is purely visual for this demo
          _buildFilterChip("Goals", false, (val) {}), 
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, Function(bool) onSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: Colors.white,
      selectedColor: _goldColor,
      checkmarkColor: Colors.black,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.grey[600],
        fontWeight: FontWeight.bold,
        fontSize: 12
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
      ),
    );
  }

  // --- MAIN BUILD ---

  @override
  Widget build(BuildContext context) {
    final dailyEvents = _getEventsForDay(_selectedDay ?? DateTime.now());

    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        title: const AppLogo(),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isSyncing ? Icons.hourglass_top : Icons.sync, color: Colors.white),
            onPressed: _showSyncOptions,
          ),
        ],
      ),
      drawer: const MainDrawer(currentRoute: '/calendar'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: _showAddEventSheet,
        child: Icon(Icons.add, color: _goldColor),
      ),
      body: Column(
        children: [
          // 1. CALENDAR (Collapsible/Adjustable)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 8),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
                CalendarFormat.twoWeeks: '2 Weeks',
                CalendarFormat.week: 'Week',
              },
              onFormatChanged: (format) => setState(() => _calendarFormat = format),
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
              onPageChanged: (focusedDay) => _focusedDay = focusedDay,
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(color: _goldColor, shape: BoxShape.circle),
                todayDecoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                todayTextStyle: const TextStyle(color: Colors.white),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // 2. SCROLLABLE CONTENT
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_showBanner) _buildBanner(),
                  _buildEventsDashboard(),
                  _buildFilterBar(),

                  const SizedBox(height: 16),

                  // 3. SCHEDULE LIST
                  if (dailyEvents.isEmpty && !_showHabits && !_showTasks)
                     Center(
                       child: Padding(
                         padding: const EdgeInsets.all(40.0),
                         child: Text("Schedule Clear", style: TextStyle(color: Colors.grey[400])),
                       ),
                     )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // A. EVENTS SECTION
                          if (_showEvents && dailyEvents.isNotEmpty) ...[
                            Text("TIMELINE", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            ...dailyEvents.map((e) => _buildTimelineEvent(e)),
                          ],

                          // B. HABITS SECTION (Mock Data)
                          if (_showHabits) ...[
                            const SizedBox(height: 16),
                            Text("DAILY HABITS", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            _buildMockItem("Morning Meditation", Icons.self_improvement, Colors.purple),
                            _buildMockItem("Drink 2L Water", Icons.local_drink, Colors.blue),
                          ],

                          // C. TASKS SECTION (Mock Data)
                          if (_showTasks) ...[
                            const SizedBox(height: 16),
                            Text("PENDING TASKS", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            _buildMockItem("Submit Tax Report", Icons.check_circle_outline, Colors.orange),
                            _buildMockItem("Call Mom", Icons.check_circle_outline, Colors.green),
                            _buildMockItem("Buy Groceries", Icons.check_circle_outline, Colors.grey),
                          ],
                          
                          const SizedBox(height: 80), // Space for FAB
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineEvent(Event event) {
    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteEvent(event),
      background: Container(
        color: Colors.red[100], 
        alignment: Alignment.centerRight, 
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.red[900]),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: _getCategoryColor(event.category), width: 4)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Column(
              children: [
                Text(event.time.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("${event.durationMinutes} min", style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              ],
            ),
            Container(width: 1, height: 30, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  if (event.description.isNotEmpty)
                    Text(event.description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Text(event.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMockItem(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Icon(Icons.more_horiz, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case "Deep Work": return _goldColor;
      case "Meeting": return Colors.blueGrey;
      case "Health": return Colors.green;
      default: return Colors.black;
    }
  }
}