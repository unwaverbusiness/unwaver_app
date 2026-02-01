import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:unwaver/widgets/maindrawer.dart';
import 'package:unwaver/widgets/app_logo.dart';

// --- EVENT MODEL ---
class Event {
  final String id;
  String title;
  String description;
  TimeOfDay time;
  String category;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.category,
  });
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // --- STATE ---
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  late Map<DateTime, List<Event>> _events;
  bool _isSyncing = false; // To show loading state during sync

  // Theme Colors
  final Color _goldColor = const Color(0xFFBB8E13);
  final Color _bgGrey = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _events = {};
  }

  @override
  void dispose() {
    super.dispose();
  }

  // --- LOGIC ---

  List<Event> _getEventsForDay(DateTime day) {
    final events = _events[day] ?? [];
    events.sort((a, b) {
      final aMinutes = a.time.hour * 60 + a.time.minute;
      final bMinutes = b.time.hour * 60 + b.time.minute;
      return aMinutes.compareTo(bMinutes);
    });
    return events;
  }

  void _addEvent(String title, String desc, TimeOfDay time, String cat) {
    if (_selectedDay == null) return;
    
    final newEvent = Event(
      id: DateTime.now().toString(),
      title: title,
      description: desc,
      time: time,
      category: cat,
    );

    setState(() {
      if (_events[_selectedDay!] != null) {
        _events[_selectedDay!]!.add(newEvent);
      } else {
        _events[_selectedDay!] = [newEvent];
      }
    });
  }

  void _deleteEvent(Event event) {
    setState(() {
      _events[_selectedDay!]?.remove(event);
    });
  }

  // --- MOCK SYNC LOGIC ---
  Future<void> _handleSync(String source) async {
    Navigator.pop(context); // Close sheet
    setState(() => _isSyncing = true);

    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Successfully synced with $source"),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // In a real app, you would fetch events from device_calendar here
    }
  }

  // --- DIALOGS & SHEETS ---

  void _showSyncOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, color: Colors.grey[300]),
              const SizedBox(height: 20),
              Text("Sync Calendars", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _goldColor)),
              const SizedBox(height: 8),
              const Text("Import events from your external accounts.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),

              // Google Calendar Option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.g_mobiledata, color: Colors.red.shade700, size: 28),
                ),
                title: const Text("Google Calendar", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Connect your Gmail account"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _handleSync("Google Calendar"),
              ),
              const Divider(),
              
              // Apple Calendar Option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.apple, color: Colors.blue.shade900, size: 28),
                ),
                title: const Text("Apple Calendar", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Connect iCloud calendar"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _handleSync("Apple Calendar"),
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
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, color: Colors.grey[300])),
                  const SizedBox(height: 20),
                  Text("Add to Schedule", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _goldColor)),
                  const SizedBox(height: 20),
                  
                  TextField(
                    decoration: const InputDecoration(labelText: "Title", border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)),
                    onChanged: (val) => title = val,
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    decoration: const InputDecoration(labelText: "Details (Optional)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.description_outlined)),
                    onChanged: (val) => description = val,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(context: context, initialTime: selectedTime);
                            if (picked != null) setSheetState(() => selectedTime = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 20),
                                const SizedBox(width: 8),
                                Text(selectedTime.format(context)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCategory,
                              isExpanded: true,
                              items: categories.map((String c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (val) {
                                if (val != null) setSheetState(() => selectedCategory = val);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                      onPressed: () {
                        if (title.isNotEmpty) {
                          _addEvent(title, description, selectedTime, selectedCategory);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Confirm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  // --- UI BUILDER ---

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
          // SYNC BUTTON IN APP BAR
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: "Sync Calendars",
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
          // 1. CALENDAR WIDGET
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
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
              eventLoader: _getEventsForDay,
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(color: _goldColor, shape: BoxShape.circle),
                todayDecoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                todayTextStyle: const TextStyle(color: Colors.white),
                markerDecoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
              ),
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: true,
                formatButtonTextStyle: TextStyle(color: Colors.black),
                formatButtonDecoration: BoxDecoration(
                  border: Border.fromBorderSide(BorderSide(color: Colors.grey)),
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
                titleTextStyle: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold),
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black),
                rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black),
              ),
            ),
          ),

          // 2. TIMELINE / AGENDA
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- CONNECT CALENDAR CARD ---
                  // Replaces "Daily Focus" with a functional sync card
                  GestureDetector(
                    onTap: _showSyncOptions,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sync, color: _goldColor, size: 28),
                          const SizedBox(width: 16),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Sync External Calendars", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("Connect Google or Apple Calendar", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- TIMELINE HEADER ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader("Timeline"),
                      Text(
                        "${dailyEvents.length} Events",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),

                  // --- EMPTY STATE ---
                  if (dailyEvents.isEmpty)
                     Padding(
                       padding: const EdgeInsets.only(top: 40),
                       child: Center(
                         child: Column(
                           children: [
                             Icon(Icons.event_busy, size: 40, color: Colors.grey.shade300),
                             const SizedBox(height: 8),
                             Text("No schedule set.", style: TextStyle(color: Colors.grey.shade400)),
                           ],
                         ),
                       ),
                     )
                  else
                    // --- EVENT LIST ---
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dailyEvents.length,
                      itemBuilder: (context, index) {
                        return _buildTimelineEvent(dailyEvents[index]);
                      },
                    ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTimelineEvent(Event event) {
    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade100,
        child: Icon(Icons.delete, color: Colors.red.shade900),
      ),
      onDismissed: (_) => _deleteEvent(event),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 60,
              child: Column(
                children: [
                  Text(
                    event.time.format(context),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    event.time.period == DayPeriod.am ? "AM" : "PM",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                  ),
                ],
              ),
            ),
            
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              width: 2,
              height: 60,
              color: Colors.grey.shade300,
            ),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                  ],
                  border: Border(left: BorderSide(
                    width: 3,
                    color: _getCategoryColor(event.category),
                  )),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            event.title, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(event.category).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            event.category,
                            style: TextStyle(
                              fontSize: 10, 
                              fontWeight: FontWeight.bold, 
                              color: _getCategoryColor(event.category)
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.description,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case "Deep Work": return _goldColor;
      case "Meeting": return Colors.blueGrey;
      case "Health": return Colors.green;
      case "Routine": return Colors.grey;
      default: return Colors.black;
    }
  }
}