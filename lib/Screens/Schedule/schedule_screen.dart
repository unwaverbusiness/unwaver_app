// ignore_for_file: constant_identifier_names, unused_field

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
      scheduledDate: scheduledDate, // Allow nullification if it's a template
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
  
  // Calendar View State
  String _calendarMode = 'Month'; // 'Week', 'Month', 'Year'
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // Routine Builder State
  String _routineContext = 'date'; // 'date', 'standard', 'weekday', 'weekend', 'monday', etc.

  // App Bar Search State
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Data Pools
  List<ScheduleItem> _unscheduledItems = [];
  final Map<DateTime, List<ScheduleItem>> _scheduledItems = {};
  
  // Template Pools
  final Map<String, List<ScheduleItem>> _routineTemplates = {
    'standard': [], 'weekday': [], 'weekend': [],
    'monday': [], 'tuesday': [], 'wednesday': [], 
    'thursday': [], 'friday': [], 'saturday': [], 'sunday': []
  };

  // Colors
  final Color _goldColor = const Color(0xFFD4AF37);

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
    _unscheduledItems = [
      ScheduleItem(id: 'u1', title: 'Morning Meditation', type: ItemType.Habit, color: Colors.purple.shade400, durationMinutes: 30),
      ScheduleItem(id: 'u2', title: 'Read 20 Pages', type: ItemType.Habit, color: Colors.indigo.shade400, durationMinutes: 45),
      ScheduleItem(id: 'u3', title: 'Review Finances', type: ItemType.Task, color: Colors.blueGrey.shade600, durationMinutes: 60),
      ScheduleItem(id: 'u4', title: 'Gym Workout', type: ItemType.Habit, color: Colors.red.shade400, durationMinutes: 90),
    ];

    final todayMidnight = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    _scheduledItems[todayMidnight] = [
      ScheduleItem(id: 's1', title: 'Deep Work Session', type: ItemType.Event, scheduledDate: todayMidnight, startTime: const TimeOfDay(hour: 9, minute: 0), color: _goldColor, durationMinutes: 120),
      ScheduleItem(id: 's2', title: 'Client Sync', type: ItemType.Event, scheduledDate: todayMidnight, startTime: const TimeOfDay(hour: 13, minute: 0), color: Colors.blue.shade600),
    ];

    _routineTemplates['standard'] = [
      ScheduleItem(id: 't1', title: 'Standard Morning Prep', type: ItemType.Habit, startTime: const TimeOfDay(hour: 7, minute: 0), color: Colors.green.shade600, durationMinutes: 60),
    ];
  }

  // --- LOGIC ---
  List<ScheduleItem> _getItemsForCurrentContext(int hour) {
    List<ScheduleItem> sourceList;
    if (_routineContext == 'date') {
      final normalized = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
      sourceList = _scheduledItems[normalized] ?? [];
    } else {
      sourceList = _routineTemplates[_routineContext] ?? [];
    }
    return sourceList.where((i) => i.startTime?.hour == hour).toList();
  }

  void _onItemDropped(ScheduleItem item, TimeOfDay dropTime) {
    setState(() {
      // 1. Remove from wherever it currently is
      _unscheduledItems.removeWhere((e) => e.id == item.id);
      for (var list in _scheduledItems.values) { list.removeWhere((e) => e.id == item.id); }
      for (var list in _routineTemplates.values) { list.removeWhere((e) => e.id == item.id); }

      // 2. Add to the currently active context
      if (_routineContext == 'date') {
        final normalizedDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
        final updatedItem = item.copyWith(scheduledDate: normalizedDate, startTime: dropTime);
        if (_scheduledItems[normalizedDate] == null) _scheduledItems[normalizedDate] = [];
        _scheduledItems[normalizedDate]!.add(updatedItem);
        _scheduledItems[normalizedDate]!.sort((a, b) => (a.startTime!.hour * 60 + a.startTime!.minute).compareTo(b.startTime!.hour * 60 + b.startTime!.minute));
      } else {
        // Saving to a Template
        final updatedItem = ScheduleItem(id: item.id, title: item.title, type: item.type, color: item.color, durationMinutes: item.durationMinutes, startTime: dropTime, scheduledDate: null);
        if (_routineTemplates[_routineContext] == null) _routineTemplates[_routineContext] = [];
        _routineTemplates[_routineContext]!.add(updatedItem);
        _routineTemplates[_routineContext]!.sort((a, b) => (a.startTime!.hour * 60 + a.startTime!.minute).compareTo(b.startTime!.hour * 60 + b.startTime!.minute));
      }
    });
  }

  void _removeToPool(ScheduleItem item) {
    setState(() {
      for (var list in _scheduledItems.values) { list.removeWhere((e) => e.id == item.id); }
      for (var list in _routineTemplates.values) { list.removeWhere((e) => e.id == item.id); }
      _unscheduledItems.add(item.copyWith(scheduledDate: null, startTime: null));
    });
  }

  Future<bool?> _showRemoveConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Schedule'),
        content: const Text('Move this item back to the Routine Pool?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: const Text('Remove')),
        ],
      ),
    );
  }

  void _deleteItemPermanently(ScheduleItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Permanently delete "${item.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _unscheduledItems.removeWhere((e) => e.id == item.id);
                for (var list in _scheduledItems.values) { list.removeWhere((e) => e.id == item.id); }
                for (var list in _routineTemplates.values) { list.removeWhere((e) => e.id == item.id); }
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${item.title}" deleted')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addNewItem() {
    final titleController = TextEditingController();
    final durationController = TextEditingController(text: '60');
    ItemType selectedType = ItemType.Task;
    Color selectedColor = Colors.blue.shade600;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()), autofocus: true),
                const SizedBox(height: 16),
                DropdownButtonFormField<ItemType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: ItemType.values.map((type) => DropdownMenuItem(value: type, child: Row(children: [Icon(_getIconForType(type), size: 18), const SizedBox(width: 8), Text(type.name)]))).toList(),
                  onChanged: (value) { if (value != null) setDialogState(() => selectedType = value); },
                ),
                const SizedBox(height: 16),
                TextField(controller: durationController, decoration: const InputDecoration(labelText: 'Duration (minutes)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    Colors.blue.shade600, Colors.purple.shade400, Colors.green.shade600, Colors.red.shade400, Colors.orange.shade600, Colors.indigo.shade400, _goldColor,
                  ].map((color) {
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(width: 36, height: 36, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: selectedColor == color ? Border.all(color: Colors.black, width: 3) : null)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                final newItem = ScheduleItem(
                  id: 'item_${DateTime.now().millisecondsSinceEpoch}', title: titleController.text.trim(), type: selectedType, color: selectedColor, durationMinutes: int.tryParse(durationController.text) ?? 60,
                );
                setState(() => _unscheduledItems.add(newItem));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${newItem.title}" added to Routine Pool')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _editItem(ScheduleItem item) {
    final titleController = TextEditingController(text: item.title);
    final durationController = TextEditingController(text: item.durationMinutes.toString());
    ItemType selectedType = item.type;
    Color selectedColor = item.color;
    TimeOfDay? selectedTime = item.startTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                
                // TIME PICKER
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Start Time", style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Text(selectedTime?.format(context) ?? "Not Set", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: selectedTime ?? TimeOfDay.now());
                    if (t != null) setDialogState(() => selectedTime = t);
                  },
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<ItemType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: ItemType.values.map((type) => DropdownMenuItem(value: type, child: Row(children: [Icon(_getIconForType(type), size: 18), const SizedBox(width: 8), Text(type.name)]))).toList(),
                  onChanged: (value) { if (value != null) setDialogState(() => selectedType = value); },
                ),
                const SizedBox(height: 16),
                TextField(controller: durationController, decoration: const InputDecoration(labelText: 'Duration (minutes)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    Colors.blue.shade600, Colors.purple.shade400, Colors.green.shade600, Colors.red.shade400, Colors.orange.shade600, Colors.indigo.shade400, _goldColor,
                  ].map((color) {
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(width: 36, height: 36, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: selectedColor == color ? Border.all(color: Colors.black, width: 3) : null)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                setState(() {
                  item.title = titleController.text.trim();
                  item.type = selectedType;
                  item.color = selectedColor;
                  item.durationMinutes = int.tryParse(durationController.text) ?? 60;
                  
                  // Move item to new hour slot dynamically if changed
                  if (selectedTime != item.startTime && selectedTime != null) {
                    _onItemDropped(item, selectedTime!); 
                  }
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${item.title}" updated')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // --- BUILDERS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: GlobalAppBar(
        isSearching: _isSearching, searchController: _searchController,
        onSearchChanged: (val) => setState(() {}),
        onCloseSearch: () => setState(() { _isSearching = false; _searchController.clear(); }),
        onSearchTap: () => setState(() => _isSearching = true),
        onFilterTap: () {}, onSortTap: () {},
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
          ? FloatingActionButton.extended(backgroundColor: Colors.black, icon: const Icon(Icons.add, color: Colors.white), label: const Text("Create", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), onPressed: _addNewItem)
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
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                _buildTabButton("Routine Builder", ScheduleView.Day),
                _buildTabButton("Calendar", ScheduleView.Month),
                _buildTabButton("Sync", ScheduleView.Sync),
              ],
            ),
          ),
          
          if (_currentView == ScheduleView.Day) ...[
            const SizedBox(height: 16),
            
            // ROUTINE CONTEXT SELECTOR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _routineContext,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: _goldColor),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 15),
                  items: [
                    DropdownMenuItem(value: 'date', child: Text("Specific Date: ${DateFormat('MMM d, yyyy').format(_selectedDay)}")),
                    const DropdownMenuItem(value: 'standard', child: Text("Template: Standard Routine")),
                    const DropdownMenuItem(value: 'weekday', child: Text("Template: Weekdays (Mon-Fri)")),
                    const DropdownMenuItem(value: 'weekend', child: Text("Template: Weekends")),
                    const DropdownMenuItem(value: 'monday', child: Text("Template: Every Monday")),
                    const DropdownMenuItem(value: 'tuesday', child: Text("Template: Every Tuesday")),
                    const DropdownMenuItem(value: 'wednesday', child: Text("Template: Every Wednesday")),
                    const DropdownMenuItem(value: 'thursday', child: Text("Template: Every Thursday")),
                    const DropdownMenuItem(value: 'friday', child: Text("Template: Every Friday")),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _routineContext = val);
                  },
                ),
              ),
            ),
            
            if (_routineContext == 'date') ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _selectedDay = _selectedDay.subtract(const Duration(days: 1)))),
                  Text(DateFormat('EEEE').format(_selectedDay), style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _selectedDay = _selectedDay.add(const Duration(days: 1)))),
                ],
              )
            ]
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
          decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(16), boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : []),
          child: Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? Colors.black : Colors.grey[500], fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case ScheduleView.Day: return _buildDayBuilderView();
      case ScheduleView.Month: return _buildCalendarView();
      case ScheduleView.Sync: return _buildSyncDashboard();
    }
  }

  // --- 1. DAY BUILDER ---
  Widget _buildDayBuilderView() {
    return Column(
      key: const ValueKey("DayView"),
      children: [
        // Timeline
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 20, bottom: 20),
            itemCount: 24,
            itemBuilder: (context, index) {
              final hour = index;
              final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
              final amPm = hour < 12 ? "AM" : "PM";
              
              final itemsForThisHour = _getItemsForCurrentContext(hour);

              return DragTarget<ScheduleItem>(
                onWillAcceptWithDetails: (_) => true,
                onAcceptWithDetails: (details) => _onItemDropped(details.data, TimeOfDay(hour: hour, minute: 0)),
                builder: (context, candidateData, rejectedData) {
                  final isHovered = candidateData.isNotEmpty;
                  
                  return Container(
                    constraints: const BoxConstraints(minHeight: 80),
                    decoration: BoxDecoration(color: isHovered ? _goldColor.withValues(alpha:0.1) : Colors.transparent, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 60, child: Padding(padding: const EdgeInsets.only(top: 8, right: 12), child: Text("$displayHour $amPm", textAlign: TextAlign.right, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold)))),
                        Container(width: 1, color: Colors.grey[300]),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (isHovered) Padding(padding: const EdgeInsets.all(8.0), child: Center(child: Text("Drop Here", style: TextStyle(color: _goldColor, fontWeight: FontWeight.bold)))),
                              for (var item in itemsForThisHour)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6, left: 8, right: 16, bottom: 6),
                                  child: Dismissible(
                                    key: Key(item.id),
                                    direction: DismissDirection.endToStart,
                                    confirmDismiss: (_) async => await _showRemoveConfirmation(context),
                                    background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.remove_circle_outline, color: Colors.orange)),
                                    onDismissed: (_) => _removeToPool(item),
                                    child: GestureDetector(
                                      onTap: () => _editItem(item),
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
        
        // Routine Pool
        Container(
          height: 160, 
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10, offset: const Offset(0, -4))], border: Border(top: BorderSide(color: Colors.grey.shade200))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("ROUTINE POOL", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    Text("Drag to assign • Tap to edit", style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: _unscheduledItems.length,
                  itemBuilder: (context, index) {
                    final item = _unscheduledItems[index];
                    return Draggable<ScheduleItem>(
                      data: item,
                      feedback: Material(color: Colors.transparent, child: SizedBox(width: 140, height: 100, child: _buildPoolCard(item, isDragging: true))),
                      childWhenDragging: Opacity(opacity: 0.3, child: _buildPoolCard(item)),
                      child: GestureDetector(onTap: () => _editItem(item), onDoubleTap: () => _deleteItemPermanently(item), child: _buildPoolCard(item)),
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

  // FIXED THE INFINITE RECURSION BUG HERE
  Widget _buildScheduledBlock(ScheduleItem item, {bool isDragging = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: item.color, width: 4)),
        boxShadow: isDragging ? [const BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))] : [],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // IMPORTANT: Only render the Draggable wrapper if it's NOT already a drag preview! 
          // If we wrap the drag preview in another Draggable, it triggers an infinite loop stack overflow.
          if (!isDragging)
            Draggable<ScheduleItem>(
              data: item,
              feedback: Material(color: Colors.transparent, child: SizedBox(width: MediaQuery.of(context).size.width - 90, child: _buildScheduledBlock(item, isDragging: true))),
              childWhenDragging: Opacity(opacity: 0.0, child: Icon(Icons.drag_indicator, color: Colors.grey.shade400, size: 24)),
              child: Icon(Icons.drag_indicator, color: Colors.grey.shade500, size: 24), // Instant grab area!
            )
          else 
            Icon(Icons.drag_indicator, color: Colors.transparent, size: 24), // Keep spacing consistent
            
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(item.title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[900]), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Icon(_getIconForType(item.type), size: 14, color: item.color),
                  ],
                ),
                const SizedBox(height: 4),
                Text("${item.durationMinutes} min", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoolCard(ScheduleItem item, {bool isDragging = false}) {
    return Container(
      width: 140, margin: EdgeInsets.symmetric(horizontal: 4, vertical: isDragging ? 0 : 4), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: item.color.withValues(alpha:0.3)), boxShadow: [BoxShadow(color: item.color.withValues(alpha:0.1), blurRadius: isDragging ? 12 : 4, offset: isDragging ? const Offset(0, 4) : Offset.zero)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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

  // --- 2. CALENDAR OVERVIEW (WITH FORMAT SWITCHER) ---
  Widget _buildCalendarView() {
    return Column(
      key: const ValueKey("CalendarView"),
      children: [
        // Mode Switcher (Week / Month / Year)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['Week', 'Month', 'Year'].map((mode) {
              final isSelected = _calendarMode == mode;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(mode, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                  selected: isSelected,
                  selectedColor: Colors.black,
                  backgroundColor: Colors.grey.shade200,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _calendarMode = mode;
                        if (mode == 'Week') _calendarFormat = CalendarFormat.week;
                        if (mode == 'Month') _calendarFormat = CalendarFormat.month;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.white,
            child: _calendarMode == 'Year' 
              ? _buildYearGrid() 
              : TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                      _routineContext = 'date'; 
                      _currentView = ScheduleView.Day; 
                    });
                  },
                  calendarStyle: CalendarStyle(selectedDecoration: BoxDecoration(color: _goldColor, shape: BoxShape.circle), todayDecoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)),
                  headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                  eventLoader: (day) => _scheduledItems[DateTime(day.year, day.month, day.day)] ?? [], 
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildYearGrid() {
    final currentYear = _focusedDay.year;
    final months = List.generate(12, (index) => DateTime(currentYear, index + 1, 1));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _focusedDay = DateTime(currentYear - 1))),
              Text("$currentYear", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _focusedDay = DateTime(currentYear + 1))),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.8),
            itemCount: 12,
            itemBuilder: (context, index) {
              final monthDate = months[index];
              final isCurrentMonth = monthDate.month == DateTime.now().month && monthDate.year == DateTime.now().year;
              return InkWell(
                onTap: () {
                  setState(() {
                    _focusedDay = monthDate;
                    _calendarMode = 'Month';
                    _calendarFormat = CalendarFormat.month;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(color: isCurrentMonth ? _goldColor.withValues(alpha:0.1) : Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: isCurrentMonth ? Border.all(color: _goldColor) : Border.all(color: Colors.grey.shade200)),
                  child: Center(
                    child: Text(DateFormat('MMM').format(monthDate), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isCurrentMonth ? _goldColor : Colors.black)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
          _buildIntegrationCard(title: "Google Calendar", description: "Sync events from your Google workspace.", icon: Icons.g_mobiledata, iconColor: Colors.red, isConnected: true),
          const SizedBox(height: 16),
          _buildIntegrationCard(title: "Apple Calendar", description: "Sync iCloud events and reminders.", icon: Icons.apple, iconColor: Colors.black, isConnected: false),
        ],
      ),
    );
  }

  Widget _buildIntegrationCard({required String title, required String description, required IconData icon, required Color iconColor, required bool isConnected}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isConnected ? _goldColor : Colors.grey.shade200, width: isConnected ? 2 : 1), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 10)]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle), child: Icon(icon, size: 32, color: iconColor)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 4), Text(description, style: TextStyle(color: Colors.grey[500], fontSize: 12))])),
          const SizedBox(width: 16),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: isConnected ? Colors.white : Colors.black, foregroundColor: isConnected ? Colors.red : Colors.white, elevation: 0, side: isConnected ? BorderSide(color: Colors.grey.shade300) : null, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () {}, child: Text(isConnected ? "Disconnect" : "Connect"))
        ],
      ),
    );
  }
}