import 'package:flutter/material.dart';
import 'package:unwaver/widgets/main_drawer.dart'; 
import 'package:unwaver/widgets/global_app_bar.dart'; // Make sure this path is correct
import 'task_creation_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  // --- TOP BAR STATE ---
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _elementFilterController = TextEditingController();

  // --- SCREEN STATE ---
  bool _isDashboardExpanded = true;
  bool _showDashboardWidget = true;
  
  String _filterStatus = "All"; // "All", "Active", "Done"
  String _selectedTaskType = 'All';

  // Enhanced Data
  final List<Map<String, dynamic>> _tasks = [
    {
      'title': 'Submit Tax Documents',
      'isDone': false,
      'priority': 1, // 1=High
      'category': 'Finance',
      'dueDate': DateTime.now().add(const Duration(days: 1)),
      'type': '1x Tasks',
    },
    {
      'title': 'Call Mom',
      'isDone': false,
      'priority': 2, // 2=Med
      'category': 'Family',
      'dueDate': DateTime.now(),
      'type': '1x Tasks',
    },
    {
      'title': 'Finish Flutter Module',
      'isDone': true,
      'priority': 1, // 1=High
      'category': 'Work',
      'dueDate': DateTime.now().subtract(const Duration(days: 1)),
      'type': '1x Tasks',
    },
    {
      'title': 'Grocery Shopping',
      'isDone': false,
      'priority': 3, // 3=Low
      'category': 'Personal',
      'dueDate': DateTime.now().add(const Duration(days: 2)),
      'type': 'Recurring Tasks',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _elementFilterController.dispose();
    super.dispose();
  }

  // --- LOGIC ---

  void _toggleTask(int originalIndex) {
    setState(() {
      _tasks[originalIndex]['isDone'] = !_tasks[originalIndex]['isDone'];
    });
  }

  void _deleteTask(Map<String, dynamic> task) {
    setState(() {
      _tasks.remove(task);
    });
  }

  void _navToCreation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TaskCreationScreen()),
    );
  }

  // --- TOP BAR ACTION SHEETS ---
  void _showFilterSheet() {
    _elementFilterController.clear();
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: StatefulBuilder(
          builder: (ctx, setDialogState) {
            
            // Filter logic
            final filteredItems = _tasks.where((item) {
              final title = item['title'].toString().toLowerCase();
              final searchTerm = _elementFilterController.text.toLowerCase();
              return title.contains(searchTerm);
            }).toList();

            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.dashboard_customize, color: Colors.blueAccent, size: 24),
                          const SizedBox(width: 12),
                          const Text("Customize Tasks", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Drag to reorder • Tap to show/hide", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _elementFilterController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Search tasks...",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                      suffixIcon: _elementFilterController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey.shade400),
                              onPressed: () {
                                _elementFilterController.clear();
                                setDialogState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 8),

                  // Static Dashboard Toggle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: _showDashboardWidget ? Colors.blueAccent.withValues(alpha: 0.05) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _showDashboardWidget ? Colors.blueAccent.withValues(alpha: 0.3) : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(Icons.drag_indicator, size: 20, color: Colors.transparent), // invisible drag handle
                          ),
                          Icon(Icons.dashboard, size: 20, color: _showDashboardWidget ? Colors.blueAccent : Colors.grey.shade400),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showDashboardWidget = !_showDashboardWidget;
                                });
                                setDialogState(() {});
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Text(
                                "Dashboard Widget",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: _showDashboardWidget ? FontWeight.w600 : FontWeight.normal,
                                  color: _showDashboardWidget ? Colors.black87 : Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showDashboardWidget = !_showDashboardWidget;
                              });
                              setDialogState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              color: Colors.transparent,
                              child: Icon(
                                _showDashboardWidget ? Icons.visibility : Icons.visibility_off,
                                size: 20,
                                color: _showDashboardWidget ? Colors.blueAccent : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Flexible(
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      buildDefaultDragHandles: false,
                      itemCount: filteredItems.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final oldActualIndex = _tasks.indexOf(filteredItems[oldIndex]);
                          final item = _tasks.removeAt(oldActualIndex);
                          
                          final newActualIndex = newIndex == filteredItems.length - 1
                              ? _tasks.length
                              : _tasks.indexOf(filteredItems[newIndex]);
                          _tasks.insert(newActualIndex, item);
                        });
                        setDialogState(() {});
                      },
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final title = item['title'] as String;
                        final isVisible = !(item['isHidden'] == true);
                        
                        return Container(
                          key: ValueKey(title),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isVisible ? Colors.blueAccent.withValues(alpha: 0.05) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isVisible ? Colors.blueAccent.withValues(alpha: 0.3) : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            child: Row(
                              children: [
                                ReorderableDragStartListener(
                                  index: index,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Icon(Icons.drag_indicator, size: 20, color: Colors.grey.shade400),
                                  ),
                                ),
                                Icon(Icons.check_circle_outline, size: 20, color: isVisible ? Colors.blueAccent : Colors.grey.shade400),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        item['isHidden'] = isVisible;
                                      });
                                      setDialogState(() {});
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isVisible ? FontWeight.w600 : FontWeight.normal,
                                        color: isVisible ? Colors.black87 : Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      item['isHidden'] = isVisible;
                                    });
                                    setDialogState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    color: Colors.transparent,
                                    child: Icon(
                                      isVisible ? Icons.visibility : Icons.visibility_off,
                                      size: 20,
                                      color: isVisible ? Colors.blueAccent : Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 300,
        child: const Center(child: Text("Sort Tasks (Coming Soon)", style: TextStyle(fontWeight: FontWeight.bold))),
      ),
    );
  }

  // --- STATS LOGIC ---
  Map<String, String> _calculateStats() {
    final currentTypeTasks = _selectedTaskType == 'All' 
        ? _tasks 
        : _tasks.where((t) => t['type'] == _selectedTaskType).toList();
    final total = currentTypeTasks.length;
    final done = currentTypeTasks.where((t) => t['isDone'] == true).length;
    final pending = total - done;
    final highPriority = currentTypeTasks.where((t) => t['priority'] == 1 && t['isDone'] == false).length;
    final percent = total == 0 ? 0 : ((done / total) * 100).toInt();

    return {
      "Total": "$total",
      "Pending": "$pending",
      "HighPri": "$highPriority",
      "Rate": "$percent%",
    };
  }

  List<Map<String, dynamic>> _getFilteredTasks() {
    return _tasks.where((task) {
      if (task['isHidden'] == true) return false;
      if (_selectedTaskType != 'All' && task['type'] != _selectedTaskType) return false;
      
      final matchesSearch = task['title']
          .toString()
          .toLowerCase()
          .contains(_searchController.text.toLowerCase());
      
      bool matchesStatus = true;
      if (_filterStatus == "Active") matchesStatus = !task['isDone'];
      if (_filterStatus == "Done") matchesStatus = task['isDone'];

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1: return Colors.redAccent;
      case 2: return Colors.amber;
      case 3: return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}";
  }

  // --- WIDGETS ---

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // 1. DASHBOARD WIDGET
  Widget _buildDashboard() {
    final stats = _calculateStats();
    
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
                      const Icon(Icons.analytics_outlined, size: 18, color: Color.fromARGB(255, 187, 142, 19)),
                      const SizedBox(width: 8),
                      Text(
                        "TASKS DASHBOARD",
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
          
          // Content
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem("Total", stats["Total"]!, Icons.list, Colors.blueGrey),
                          _buildStatItem("Pending", stats["Pending"]!, Icons.hourglass_empty, Colors.orange),
                          _buildStatItem("High Pri.", stats["HighPri"]!, Icons.priority_high, Colors.red),
                          _buildStatItem("Rate", stats["Rate"]!, Icons.pie_chart, Colors.green),
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

  // 2. FILTER CHIPS
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: ["All", "Active", "Done"].map((filter) {
          final isSelected = _filterStatus == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _filterStatus = filter);
              },
              selectedColor: Colors.black,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: ['All', '1x Tasks', 'Recurring Tasks'].map((type) {
            final isSelected = _selectedTaskType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTaskType = type),
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
    final filteredList = _getFilteredTasks();

    return Scaffold(
      backgroundColor: Colors.white,
      
      // 1. GLOBAL APP BAR
      appBar: GlobalAppBar(
        isSearching: _isSearching,
        searchController: _searchController,
        onSearchChanged: (val) => setState(() {}),
        onCloseSearch: () => setState(() {
          _isSearching = false;
          _searchController.clear();
        }),
        onSearchTap: () => setState(() => _isSearching = true),
        onFilterTap: _showFilterSheet,
        onSortTap: _showSortSheet,
      ),

      drawer: const MainDrawer(currentRoute: '/tasks'),
      
      floatingActionButton: FloatingActionButton(
        onPressed: _navToCreation,
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTypeToggle(),
          // 2. Expandable Dashboard
          if (_showDashboardWidget) _buildDashboard(),

          // 3. Quick Filters
          const SizedBox(height: 8),
          _buildFilterChips(),
          const SizedBox(height: 8),

          // 5. Task List
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isNotEmpty ? "No matching tasks" : "No tasks found",
                          style: TextStyle(color: Colors.grey[500], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), // extra bottom padding for FAB
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final task = filteredList[index];
                      // Find actual index for toggling/deleting logic
                      final originalIndex = _tasks.indexOf(task);

                      return Dismissible(
                        key: Key(task['title']),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red[500],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        onDismissed: (direction) => _deleteTask(task),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha:0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  // Priority Strip
                                  Container(
                                    width: 4,
                                    color: _getPriorityColor(task['priority']),
                                  ),
                                  // Content
                                  Expanded(
                                    child: CheckboxListTile(
                                      activeColor: const Color.fromARGB(255, 187, 142, 19),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      title: Text(
                                        task['title'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          decoration: task['isDone']
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: task['isDone'] ? Colors.grey : Colors.black87,
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 6.0),
                                        child: Row(
                                          children: [
                                            // Category Tag
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                task['category'] ?? "General",
                                                style: TextStyle(fontSize: 10, color: Colors.grey[800]),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Date
                                            Icon(Icons.calendar_today, size: 10, color: Colors.grey[500]),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatDate(task['dueDate']),
                                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                            ),
                                          ],
                                        ),
                                      ),
                                      value: task['isDone'],
                                      onChanged: (value) => _toggleTask(originalIndex),
                                      controlAffinity: ListTileControlAffinity.leading,
                                    ),
                                  ),
                                ],
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
    );
  }
}