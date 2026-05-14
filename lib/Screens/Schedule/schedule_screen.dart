import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:device_calendar/device_calendar.dart' as dev_cal;
import 'package:unwaver/widgets/main_drawer.dart';
import 'package:unwaver/widgets/global_app_bar.dart';
import 'event_creation_screen.dart';

// --- ENUMS & MODELS ---
enum ScheduleView { routine, daily, weekly, monthly }
enum ItemType { event, habit, task }

class ScheduleItem {
  final String id;
  String title;
  ItemType type;
  DateTime? scheduledDate;
  TimeOfDay? startTime;
  int durationMinutes;
  Color color;
  bool isAllDay;
  bool isNativeSync; // True if from Google/Apple Calendar

  ScheduleItem({
    required this.id,
    required this.title,
    required this.type,
    this.scheduledDate,
    this.startTime,
    this.durationMinutes = 60,
    required this.color,
    this.isAllDay = false,
    this.isNativeSync = false,
  });

  ScheduleItem copyWith({DateTime? scheduledDate, TimeOfDay? startTime}) {
    return ScheduleItem(
      id: id,
      title: title,
      type: type,
      scheduledDate: scheduledDate, 
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes,
      color: color,
      isAllDay: isAllDay,
      isNativeSync: isNativeSync,
    );
  }
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // --- STATE ---
  ScheduleView _currentView = ScheduleView.daily;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  // App Bar Search State
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Calendar Sync State
  final dev_cal.DeviceCalendarPlugin _deviceCalendarPlugin = dev_cal.DeviceCalendarPlugin();
  List<dev_cal.Calendar> _calendars = [];
  bool _isLoading = true;

  // Data Pools
  final Map<DateTime, List<ScheduleItem>> _scheduledItems = {};
  final List<ScheduleItem> _unscheduledItems = [];

  // Colors
  final Color _goldColor = const Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _seedDummyUnscheduledData();
    _retrieveCalendarsAndEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _seedDummyUnscheduledData() {
    _unscheduledItems.addAll([
      ScheduleItem(id: 'u1', title: 'Morning Meditation', type: ItemType.habit, color: Colors.purple.shade400, durationMinutes: 30),
      ScheduleItem(id: 'u2', title: 'Read 20 Pages', type: ItemType.habit, color: Colors.indigo.shade400, durationMinutes: 45),
      ScheduleItem(id: 'u3', title: 'Review Finances', type: ItemType.task, color: Colors.blueGrey.shade600, durationMinutes: 60),
      ScheduleItem(id: 'u4', title: 'Gym Workout', type: ItemType.habit, color: Colors.red.shade400, durationMinutes: 90),
    ]);
  }

  // --- DEVICE CALENDAR LOGIC ---
  Future<void> _retrieveCalendarsAndEvents() async {
    setState(() => _isLoading = true);

    // Bypass native sync if on Web to avoid MissingPluginException
    if (kIsWeb) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && !(permissionsGranted.data ?? false)) {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess || !(permissionsGranted.data ?? false)) {
          setState(() => _isLoading = false);
          return; // Permission denied
        }
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess && calendarsResult.data != null) {
        _calendars = calendarsResult.data!;
      }

      await _fetchEventsForCurrentRange();

    } catch (e) {
      debugPrint("Error fetching calendars: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchEventsForCurrentRange() async {
    if (_calendars.isEmpty) return;

    final startDate = DateTime.now().subtract(const Duration(days: 365));
    final endDate = DateTime.now().add(const Duration(days: 365));

    // Clear previous native items to prevent duplicates on manual sync
    for (var list in _scheduledItems.values) {
      list.removeWhere((item) => item.isNativeSync);
    }

    for (var calendar in _calendars) {
      final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
        calendar.id,
        dev_cal.RetrieveEventsParams(startDate: startDate, endDate: endDate),
      );

      if (eventsResult.isSuccess && eventsResult.data != null) {
        for (var event in eventsResult.data!) {
          if (event.start == null) continue;
          
          final startLocal = event.start!.toLocal();
          final endLocal = event.end?.toLocal() ?? startLocal.add(const Duration(hours: 1));
          
          final normalizedDate = DateTime(startLocal.year, startLocal.month, startLocal.day);
          
          final item = ScheduleItem(
            id: 'sync_${event.eventId ?? UniqueKey().toString()}',
            title: event.title ?? 'Busy',
            type: ItemType.event,
            scheduledDate: normalizedDate,
            startTime: TimeOfDay.fromDateTime(startLocal),
            durationMinutes: endLocal.difference(startLocal).inMinutes.abs(),
            color: calendar.color == null ? Colors.blue : Color(calendar.color!).withAlpha(255),
            isAllDay: event.allDay ?? false,
            isNativeSync: true,
          );

          _scheduledItems.putIfAbsent(normalizedDate, () => []).add(item);
        }
      }
    }

    _sortScheduledItems();
    if (mounted) setState(() {});
  }

  void _manualSync() {
    _retrieveCalendarsAndEvents();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing Calendar...')));
  }

  // --- ROUTINE BUILDER LOGIC ---
  void _sortScheduledItems() {
    for (var key in _scheduledItems.keys) {
      _scheduledItems[key]!.sort((a, b) {
        if (a.isAllDay && !b.isAllDay) return -1;
        if (!a.isAllDay && b.isAllDay) return 1;
        if (a.startTime == null || b.startTime == null) return 0;
        return (a.startTime!.hour * 60 + a.startTime!.minute)
            .compareTo(b.startTime!.hour * 60 + b.startTime!.minute);
      });
    }
  }

  void _onItemDropped(ScheduleItem item, TimeOfDay dropTime) {
    if (item.isNativeSync) return; // Cannot alter synced items via drag and drop

    setState(() {
      // 1. Remove from wherever it currently is
      _unscheduledItems.removeWhere((e) => e.id == item.id);
      for (var list in _scheduledItems.values) {
        list.removeWhere((e) => e.id == item.id);
      }

      // 2. Add to the active day
      final normalizedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
      final updatedItem = item.copyWith(scheduledDate: normalizedDate, startTime: dropTime);
      
      _scheduledItems.putIfAbsent(normalizedDate, () => []).add(updatedItem);
      _sortScheduledItems();
    });
  }

  void _removeToPool(ScheduleItem item) {
    if (item.isNativeSync) return;

    setState(() {
      for (var list in _scheduledItems.values) {
        list.removeWhere((e) => e.id == item.id);
      }
      _unscheduledItems.add(item.copyWith(scheduledDate: null, startTime: null));
    });
  }

  Future<bool?> _showRemoveConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Timeline'),
        content: const Text('Move this item back to the Unscheduled Pool?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Remove')),
        ],
      ),
    );
  }

  IconData _getIconForType(ItemType type) {
    switch (type) {
      case ItemType.event: return Icons.event;
      case ItemType.habit: return Icons.cached;
      case ItemType.task: return Icons.check_box_outlined;
    }
  }

  // --- BUILDERS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF121212) : Colors.grey[50],
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
      drawer: const MainDrawer(currentRoute: '/schedule'),
      body: Column(
        children: [
          _buildTopNavigation(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildCurrentView(),
                  ),
          ),
          _buildDockedCreateButton(),
        ],
      ),
    );
  }

  Widget _buildTopNavigation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: isDark ? Colors.grey[900] : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Schedule",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: _goldColor),
                tooltip: "Sync with Google/Apple Calendar",
                onPressed: _manualSync,
              ),
            ],
          ),
          const SizedBox(height: 12),
              Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.grey[200],
                borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                _buildTabButton("Routine", ScheduleView.routine, isDark),
                _buildTabButton("Daily", ScheduleView.daily, isDark),
                _buildTabButton("Weekly", ScheduleView.weekly, isDark),
                _buildTabButton("Monthly", ScheduleView.monthly, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, ScheduleView view, bool isDark) {
    final isSelected = _currentView == view;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentView = view),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
              color: isSelected ? (isDark ? Colors.grey[800] : Colors.white) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected && !isDark ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : []),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.grey[500],
                fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildDockedCreateButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, -4), blurRadius: 10)
        ],
      ),
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: () async {
            final newItem = await Navigator.push<ScheduleItem>(
              context,
              MaterialPageRoute(builder: (context) => const EventCreationScreen()),
            );
            if (newItem != null) {
              setState(() {
                final normalizedDate = DateTime(newItem.scheduledDate!.year, newItem.scheduledDate!.month, newItem.scheduledDate!.day);
                _scheduledItems.putIfAbsent(normalizedDate, () => []).add(newItem);
                _sortScheduledItems();
              });
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event created successfully!')));
              if (_currentView != ScheduleView.daily) {
                setState(() => _currentView = ScheduleView.daily);
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text("CREATE EVENT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case ScheduleView.routine:
        return _buildRoutineBuilderView();
      case ScheduleView.daily:
        return _buildDailyAgendaView();
      case ScheduleView.weekly:
        return _buildTableCalendar(CalendarFormat.week);
      case ScheduleView.monthly:
        return _buildTableCalendar(CalendarFormat.month);
    }
  }

  // --- DAILY ROUTINE BUILDER ---
  Widget _buildRoutineBuilderView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      key: const ValueKey("Daily"),
      children: [
        // Date Selector Bar
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: isDark ? Colors.grey[850] : Colors.grey[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() {
                  _selectedDay = _selectedDay?.subtract(const Duration(days: 1));
                  _focusedDay = _selectedDay!;
                }),
              ),
              Column(
                children: [
                  Text(DateFormat('EEEE').format(_selectedDay ?? DateTime.now()), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey)),
                  Text(DateFormat('MMMM d, yyyy').format(_selectedDay ?? DateTime.now()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() {
                  _selectedDay = _selectedDay?.add(const Duration(days: 1));
                  _focusedDay = _selectedDay!;
                }),
              ),
            ],
          ),
        ),

        // Unscheduled Items Pool (Draggable)
        if (_unscheduledItems.isNotEmpty)
          Container(
            height: 125,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!)),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _unscheduledItems.length,
              itemBuilder: (context, index) {
                final item = _unscheduledItems[index];
                return Draggable<ScheduleItem>(
                  data: item,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Opacity(opacity: 0.8, child: _buildPoolCard(item)),
                  ),
                  childWhenDragging: Opacity(opacity: 0.3, child: _buildPoolCard(item)),
                  child: _buildPoolCard(item),
                );
              },
            ),
          ),

        // 24-Hour Timeline
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 10, bottom: 20),
            itemCount: 24,
            itemBuilder: (context, index) {
              final hour = index;
              final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
              final amPm = hour < 12 ? "AM" : "PM";

              final normalizedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
              final itemsForThisHour = (_scheduledItems[normalizedDate] ?? [])
                  .where((i) => i.startTime?.hour == hour || (i.isAllDay && hour == 9)) // Show all day at 9am
                  .toList();

              return DragTarget<ScheduleItem>(
                onWillAcceptWithDetails: (_) => true,
                onAcceptWithDetails: (details) => _onItemDropped(details.data, TimeOfDay(hour: hour, minute: 0)),
                builder: (context, candidateData, rejectedData) {
                  final isHovered = candidateData.isNotEmpty;

                  return Container(
                    constraints: const BoxConstraints(minHeight: 80),
                    decoration: BoxDecoration(
                      color: isHovered ? _goldColor.withValues(alpha: 0.1) : Colors.transparent,
                      border: Border(bottom: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 60,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8, right: 12),
                            child: Text("$displayHour $amPm", textAlign: TextAlign.right, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Container(width: 1, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (isHovered)
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(child: Text("Drop Here", style: TextStyle(color: _goldColor, fontWeight: FontWeight.bold))),
                                ),
                              for (var item in itemsForThisHour)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6, left: 8, right: 16, bottom: 6),
                                  child: item.isNativeSync 
                                      ? _buildScheduledBlock(item) // Native sync items cannot be dragged away
                                      : Dismissible(
                                          key: Key(item.id),
                                          direction: DismissDirection.endToStart,
                                          confirmDismiss: (_) async => await _showRemoveConfirmation(context),
                                          background: Container(
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(right: 16),
                                            decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                                            child: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                                          ),
                                          onDismissed: (_) => _removeToPool(item),
                                          child: _buildScheduledBlock(item),
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
      ],
    );
  }

  Widget _buildPoolCard(ScheduleItem item) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.1),
        border: Border.all(color: item.color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getIconForType(item.type), color: item.color, size: 24),
          const SizedBox(height: 8),
          Text(
            item.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: item.color),
          ),
        ],
      ),
    );
  }

  // --- CALENDAR ENGINES ---
  Widget _buildDailyAgendaView() {
    return Column(
      key: const ValueKey("DailyAgenda"),
      children: [
        _buildDateSelectorBar(),
        const Divider(),
        Expanded(child: _buildAgendaList()),
      ],
    );
  }

  Widget _buildTableCalendar(CalendarFormat format) {
    return Column(
      key: ValueKey(format),
      children: [
        TableCalendar<ScheduleItem>(
          firstDay: DateTime.utc(2020, 10, 16),
          lastDay: DateTime.utc(2030, 3, 14),
          focusedDay: _focusedDay,
          calendarFormat: format,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Month',
            CalendarFormat.week: 'Week',
          },
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
              _currentView = ScheduleView.daily; // Switch to daily view to see details
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          eventLoader: (day) {
            final normalized = DateTime(day.year, day.month, day.day);
            return _scheduledItems[normalized] ?? [];
          },
          calendarStyle: CalendarStyle(
            markerDecoration: BoxDecoration(color: _goldColor, shape: BoxShape.circle),
            selectedDecoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
            todayDecoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
          ),
        ),
        const Divider(),
        Expanded(child: _buildAgendaList()),
      ],
    );
  }

  Widget _buildAgendaList() {
    final normalizedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final items = _scheduledItems[normalizedDate] ?? [];

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text("No events scheduled", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildScheduledBlock(items[index]);
      },
    );
  }

  Widget _buildDateSelectorBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: isDark ? Colors.grey[850] : Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() {
              _selectedDay = _selectedDay?.subtract(const Duration(days: 1));
              _focusedDay = _selectedDay!;
            }),
          ),
          Column(
            children: [
              Text(DateFormat('EEEE').format(_selectedDay ?? DateTime.now()), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey)),
              Text(DateFormat('MMMM d, yyyy').format(_selectedDay ?? DateTime.now()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() {
              _selectedDay = _selectedDay?.add(const Duration(days: 1));
              _focusedDay = _selectedDay!;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledBlock(ScheduleItem item) {
    final timeStr = item.isAllDay 
        ? "All Day" 
        : item.startTime != null 
            ? item.startTime!.format(context) 
            : "";
            
    return Container(
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: item.color, width: 6)),
      ),
      child: ListTile(
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: timeStr.isNotEmpty ? Text(timeStr, style: TextStyle(color: Colors.grey[700])) : null,
        trailing: item.isNativeSync 
            ? const Icon(Icons.sync, color: Colors.grey, size: 16) 
            : Icon(_getIconForType(item.type), color: item.color.withValues(alpha: 0.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
