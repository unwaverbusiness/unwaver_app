import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
// Ensure these imports point to your actual file locations
import 'package:unwaver/widgets/maindrawer.dart';
import 'package:unwaver/widgets/app_logo.dart';

// --- MODELS ---
class Event {
  final String id;
  String title;
  String description;
  final DateTime date;
  TimeOfDay time;
  String category;
  final int durationMinutes; 

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.category,
    this.durationMinutes = 60,
  });
}

// --- MAIN CLASS ---
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with TickerProviderStateMixin {
  // --- STATE ---
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _showBanner = true; 
  
  // Dashboard State
  bool _isDashboardExpanded = true;

  // Search State
  bool _isSearching = false;
  late TextEditingController _searchController;

  // Filter State
  bool _showEvents = true;
  bool _showHabits = true;
  bool _showTasks = true;
  String _selectedCategoryFilter = "All"; 

  late Map<DateTime, List<Event>> _events;
  bool _isSyncing = false;

  // Colors
  final Color _goldColor = const Color(0xFFD4AF37); 
  
  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _searchController = TextEditingController();
    _events = {};
    _addDummyData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addDummyData() {
    final now = DateTime.now();
    
    // Helper to safely add events
    void add(DateTime d, String title, String cat) {
      // Normalize key to midnight (removes time info for the Map key)
      final key = DateTime(d.year, d.month, d.day);
      
      final ev = Event(
        id: DateTime.now().microsecondsSinceEpoch.toString() + title,
        title: title, 
        description: "", 
        date: d, 
        time: TimeOfDay(hour: d.hour, minute: d.minute), 
        category: cat
      );

      if (_events[key] == null) _events[key] = [];
      _events[key]!.add(ev);
    }

    add(now, 'Deep Work', 'Deep Work');
    add(now.add(const Duration(hours: 3)), 'Team Sync', 'Meeting');
    add(now.add(const Duration(days: 2)), 'Client Call', 'Meeting');
    add(now.add(const Duration(days: 3)), 'Project Review', 'Deep Work');
    add(now.add(const Duration(days: 9)), 'Dentist', 'Health');
    add(now.add(const Duration(days: 20)), 'Monthly Report', 'Deep Work');
    add(now.add(const Duration(days: 90)), 'Quarterly Review', 'Meeting');
    add(now.add(const Duration(days: 150)), 'Product Launch', 'Deep Work');
    add(now.add(const Duration(days: 300)), 'Year End Party', 'Other');
  }

  // --- LOGIC ---

  List<Event> _getEventsForDay(DateTime day) {
    // Normalize lookup date to midnight
    final normalizedDate = DateTime(day.year, day.month, day.day);
    var events = _events[normalizedDate] ?? [];
    
    // 1. Filter by Search Query
    if (_searchController.text.isNotEmpty) {
      events = events.where((e) => 
        e.title.toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    }

    // 2. Filter by Category (if not "All")
    if (_selectedCategoryFilter != "All") {
      events = events.where((e) => e.category == _selectedCategoryFilter).toList();
    }

    // Sort by time
    events.sort((a, b) {
      final aMinutes = a.time.hour * 60 + a.time.minute;
      final bMinutes = b.time.hour * 60 + b.time.minute;
      return aMinutes.compareTo(bMinutes);
    });
    return events;
  }

  void _addEvent(String title, String desc, TimeOfDay time, String cat) {
    if (_selectedDay == null) return;
    final d = _selectedDay!;
    final normalizedDate = DateTime(d.year, d.month, d.day);
    final fullDate = DateTime(d.year, d.month, d.day, time.hour, time.minute);

    final newEvent = Event(
      id: DateTime.now().toString(),
      title: title,
      description: desc,
      date: fullDate,
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

  Map<String, String> _calculateDetailedStats() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final nextWeek = todayStart.add(const Duration(days: 7));
    final next2Weeks = todayStart.add(const Duration(days: 14));
    final nextMonth = todayStart.add(const Duration(days: 30));
    final next6Months = todayStart.add(const Duration(days: 180));
    final nextYear = todayStart.add(const Duration(days: 365));

    int cToday = 0;
    int cWeek = 0;
    int c2Weeks = 0;
    int cMonth = 0;
    int c6Months = 0;
    int cYear = 0;

    _events.forEach((key, list) {
      for (var e in list) {
        // Respect Category Filter in Stats? 
        // Uncomment next line if stats should ONLY show filtered category
        // if (_selectedCategoryFilter != "All" && e.category != _selectedCategoryFilter) continue;

        if (e.date.isBefore(todayStart)) continue;
        
        if (e.date.isBefore(todayStart.add(const Duration(days: 1)))) cToday++;
        if (e.date.isBefore(nextWeek)) cWeek++;
        if (e.date.isBefore(next2Weeks)) c2Weeks++;
        if (e.date.isBefore(nextMonth)) cMonth++;
        if (e.date.isBefore(next6Months)) c6Months++;
        if (e.date.isBefore(nextYear)) cYear++;
      }
    });

    return {
      "Today": "$cToday",
      "Week": "$cWeek",
      "2 Wks": "$c2Weeks",
      "Month": "$cMonth",
      "6 Mths": "$c6Months",
      "Year": "$cYear",
    };
  }

  // --- BOTTOM SHEETS ---

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        // StatefulBuilder allows the switches inside the modal to update visually
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, color: Colors.grey[300])),
                  const SizedBox(height: 20),
                  Text("Filter Options", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _goldColor)),
                  const SizedBox(height: 20),
                  
                  // Toggle Switches
                  SwitchListTile(
                    title: const Text("Show Events"),
                    activeThumbColor: _goldColor,
                    value: _showEvents, 
                    onChanged: (val) {
                      setModalState(() => _showEvents = val);
                      setState(() {}); // Update parent screen
                    }
                  ),
                  SwitchListTile(
                    title: const Text("Show Habits"),
                    activeThumbColor: _goldColor,
                    value: _showHabits, 
                    onChanged: (val) {
                      setModalState(() => _showHabits = val);
                      setState(() {}); // Update parent screen
                    }
                  ),
                  SwitchListTile(
                    title: const Text("Show Tasks"),
                    activeThumbColor: _goldColor,
                    value: _showTasks, 
                    onChanged: (val) {
                      setModalState(() => _showTasks = val);
                      setState(() {}); // Update parent screen
                    }
                  ),
                  
                  const Divider(height: 30),
                  const Text("Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  
                  Wrap(
                    spacing: 8,
                    children: ["All", "Deep Work", "Meeting", "Health", "Other"].map((cat) {
                      final isSelected = _selectedCategoryFilter == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: _goldColor,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() => _selectedCategoryFilter = cat);
                            setState(() {}); // Update parent screen
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      },
    );
  }

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
                trailing: const Icon(Icons.check_circle, color: Colors.green),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _goldColor.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _goldColor.withValues(alpha:0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: _goldColor),
          const SizedBox(width: 12),
          Expanded(
            child: const Text(
              "Organize your day. Sync calendars and overlay your Habits and Tasks.",
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
    final stats = _calculateDetailedStats();

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
          // Header
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
                      Icon(Icons.dashboard_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        "EVENTS FORECAST",
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
                    _isDashboardExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Stats
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isDashboardExpanded
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      // Row 1: Short Term
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDashStat("Today", stats["Today"]!, color: Colors.green[700]),
                          _buildDashStat("This Week", stats["Week"]!),
                          _buildDashStat("2 Weeks", stats["2 Wks"]!),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Row 2: Long Term
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDashStat("Month", stats["Month"]!),
                          _buildDashStat("6 Months", stats["6 Mths"]!),
                          _buildDashStat("Year", stats["Year"]!),
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

  Widget _buildDashStat(String label, String value, {Color? color}) {
    return SizedBox(
      width: 80, 
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color ?? Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- MAIN BUILD ---

  @override
  Widget build(BuildContext context) {
    final dailyEvents = _getEventsForDay(_selectedDay ?? DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // EXPANDABLE SEARCH BAR
        title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              cursorColor: _goldColor,
              decoration: const InputDecoration(
                hintText: "Search events...",
                hintStyle: TextStyle(color: Colors.white60),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero
              ),
              onChanged: (val) => setState(() {}),
            )
          // Removed 'const' to prevent errors if your AppLogo isn't const
          : AppLogo(),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: _isSearching
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
              },
            )
          : null, // Shows Drawer automatically
        actions: [
          if (!_isSearching) ...[
            // 1. SEARCH ICON
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() => _isSearching = true);
              },
            ),
            // 2. FILTER ICON
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterSheet,
            ),
            // 3. SYNC ICON
            IconButton(
              icon: Icon(_isSyncing ? Icons.hourglass_top : Icons.sync, color: Colors.white),
              onPressed: _showSyncOptions,
            ),
          ]
        ],
      ),
      // Removed 'const' here as well just in case
      drawer: MainDrawer(currentRoute: '/calendar'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: _showAddEventSheet,
        child: Icon(Icons.add, color: _goldColor),
      ),
      
      body: Column(
        children: [
          // 1. DASHBOARD (Fixed / Frozen)
          _buildEventsDashboard(),

          // 2. SCROLLABLE AREA (Calendar + List)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // A. CALENDAR
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.only(bottom: 16),
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

                  // B. BANNER & ACTIVE FILTER INFO
                  if (_showBanner) _buildBanner(),
                  
                  if (_selectedCategoryFilter != "All" || _searchController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.filter_alt, size: 14, color: _goldColor),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              "Filtering: ${_selectedCategoryFilter == 'All' ? '' : '$_selectedCategoryFilter '}${_searchController.text.isNotEmpty ? '"${_searchController.text}"' : ''}",
                              style: TextStyle(color: _goldColor, fontSize: 12, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // C. EVENTS LIST
                  if (dailyEvents.isEmpty && !_showHabits && !_showTasks)
                     Center(
                       child: Padding(
                         padding: const EdgeInsets.all(40.0),
                         child: Column(
                           children: [
                             Icon(Icons.search_off, size: 40, color: Colors.grey[300]),
                             const SizedBox(height: 10),
                             Text("No events found", style: TextStyle(color: Colors.grey[400])),
                           ],
                         ),
                       ),
                     )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_showEvents && dailyEvents.isNotEmpty) ...[
                            Text("TIMELINE", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            ...dailyEvents.map((e) => _buildTimelineEvent(e)),
                          ],
                          if (_showHabits) ...[
                            const SizedBox(height: 16),
                            Text("DAILY HABITS", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            _buildMockItem("Morning Meditation", Icons.self_improvement, Colors.purple),
                          ],
                          if (_showTasks) ...[
                            const SizedBox(height: 16),
                            Text("PENDING TASKS", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            _buildMockItem("Submit Tax Report", Icons.check_circle_outline, Colors.orange),
                          ],
                          const SizedBox(height: 80),
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