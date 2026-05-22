import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unwaver/screens/habits/exercise/exercise_screen.dart';

// --- CLEAN STATE ENUM ---
enum CardStatus { none, completed, skipped, failed }

class ReusableCard extends StatefulWidget {
  // Core Info
  final String habitId;
  final String itemClass;
  final String title;
  final String? description;
  final IconData icon; 
  final Color? color; 

  // Metadata
  final String? priority; 
  final String? urgency;  
  final String? importance; 
  final String? pillar;   
  final String? category;
  final List<String>? tags; 
  final DateTime? deadline;
  final String? type;

  // Initial State
  final CardStatus initialStatus;

  // Primary Action
  final ValueChanged<CardStatus>? onStatusChanged;

  // Secondary Tools
  final VoidCallback? onCalendarTap;
  final VoidCallback? onStatsTap;
  final VoidCallback? onHistoryTap;
  final VoidCallback? onTagsTap;

  // Exercise support
  final bool isExercise;
  final ValueChanged<Map<String, dynamic>>? onWorkoutSaved;
  final bool isNativeSync;

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onShareTap;

  const ReusableCard({
    super.key,
    required this.habitId,
    this.itemClass = 'habit',
    required this.title,
    this.description,
    required this.icon,
    this.color,

    // Metadata
    this.priority,
    this.urgency,         
    this.importance,      
    this.pillar,          
    this.category,
    this.tags,
    this.deadline,
    this.type,

    // Status
    this.initialStatus = CardStatus.none,
    this.onStatusChanged,

    // Tools & Management
    this.onCalendarTap,
    this.onStatsTap,
    this.onHistoryTap,
    this.onTagsTap,
    this.isExercise = false,
    this.onWorkoutSaved,
    this.isNativeSync = false,
    this.onEdit,
    this.onDelete,
    this.onShareTap,
  });

  @override
  State<ReusableCard> createState() => _ReusableCardState();
}

class _ReusableCardState extends State<ReusableCard> {
  late CardStatus _status;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
  }

  @override
  void didUpdateWidget(covariant ReusableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatus != oldWidget.initialStatus) {
      _status = widget.initialStatus;
    }
  }

  // --- SINGLE TOGGLE LOGIC ---
  void _cycleStatus() {
    setState(() {
      switch (_status) {
        case CardStatus.none:
          _status = CardStatus.completed;
          break;
        case CardStatus.completed:
          _status = CardStatus.skipped;
          break;
        case CardStatus.skipped:
          _status = CardStatus.failed;
          break;
        case CardStatus.failed:
          _status = CardStatus.none;
          break;
      }
    });
    
    if (widget.onStatusChanged != null) {
      widget.onStatusChanged!(_status);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isResolved = _status != CardStatus.none;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Dynamic Theme Variables
    final activeAccentColor = widget.color ?? theme.colorScheme.primary;
    final cardBgColor = isDark ? Colors.grey.shade800 : Colors.white;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: widget.color?.withValues(alpha: 0.1) ?? Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // --- ADDED COLUMN WRAPPER TO FIX LAYOUT CRASH ---
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- TOP ROW: CORE INFO & THE CYCLER BUTTON ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Static Icon Avatar
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: activeAccentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: activeAccentColor, size: 28),
                ),
                const SizedBox(width: 16),
                
                // Text Data & Badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          decoration: isResolved ? TextDecoration.lineThrough : null,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (widget.description != null && widget.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.description!,
                          style: TextStyle(
                            fontSize: 13, 
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, 
                            height: 1.4
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // --- METADATA WRAP ---
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Deadline / Due Date
                          _buildMetaChip(
                            icon: Icons.event,
                            label: widget.deadline != null 
                                ? DateFormat('MMM dd, yyyy').format(widget.deadline!)
                                : 'No Deadline',
                            color: widget.deadline != null ? Colors.red.shade400 : Colors.grey.shade500,
                            isDark: isDark,
                            isBold: widget.deadline != null,
                          ),
                          // Pillar & Category (Sub-pillar)
                          if (widget.pillar != null && widget.pillar!.isNotEmpty)
                            _buildMetaChip(
                              icon: Icons.account_balance,
                              label: widget.category != null && widget.category!.isNotEmpty 
                                  ? '${widget.pillar} > ${widget.category}'
                                  : widget.pillar!,
                              color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                              isDark: isDark,
                            ),
                          // Priority
                          if (widget.priority != null && widget.priority!.isNotEmpty)
                            _buildWordBadge(
                              _formatPriority(widget.priority!), 
                              _getPriorityColor(widget.priority!),
                              isDark,
                            ),
                          // Urgency
                          if (widget.urgency != null && widget.urgency!.isNotEmpty)
                            _buildWordBadge(
                              _formatUrgency(widget.urgency!), 
                              isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                              isDark,
                            ),
                          // Tags
                          if (widget.tags != null && widget.tags!.isNotEmpty)
                            _buildMetaChip(
                              icon: Icons.local_offer,
                              label: '${widget.tags!.length}',
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              isDark: isDark,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Exercise Button (Only visible if marked as exercise)
                if (widget.isExercise) ...[
                  _buildExerciseButton(isDark),
                  const SizedBox(width: 8),
                ],

                // THE SINGLE CYCLE BUTTON
                _buildCycleButton(isDark),
              ],
            ),
          ),

          // --- BOTTOM ROW: SECONDARY TOOLS ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _TypeScroller(
                    docId: widget.habitId,
                    currentClass: widget.itemClass,
                    currentType: widget.type,
                    isDark: isDark,
                    isNativeSync: widget.isNativeSync,
                  ),
                ),
                Row(
                  children: [
                    _buildIconButton(Icons.history, 'Archive', widget.onHistoryTap, color: isDark ? Colors.orange.shade300 : Colors.orange),
                    _buildIconButton(Icons.share_outlined, 'Share', widget.onShareTap, color: isDark ? Colors.purple.shade300 : Colors.purple),
                    _buildIconButton(Icons.edit_outlined, 'Edit', widget.onEdit, color: isDark ? Colors.blue.shade300 : Colors.blue),
                    _buildIconButton(Icons.delete_outline, 'Delete', widget.onDelete, color: isDark ? Colors.red.shade300 : Colors.red),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Methods ---
  // Formatter removed as it is now handled by _TypeScroller

  Widget _buildCycleButton(bool isDark) {
    IconData icon;
    Color bgColor;
    Color iconColor;
    Color btnBorderColor;

    switch (_status) {
      case CardStatus.completed:
        icon = Icons.check;
        bgColor = Colors.green;
        iconColor = Colors.white;
        btnBorderColor = Colors.green;
        break;
      case CardStatus.skipped:
        icon = Icons.fast_forward;
        bgColor = Colors.orange;
        iconColor = Colors.white;
        btnBorderColor = Colors.orange;
        break;
      case CardStatus.failed:
        icon = Icons.close;
        bgColor = Colors.red;
        iconColor = Colors.white;
        btnBorderColor = Colors.red;
        break;
      case CardStatus.none:
        icon = Icons.radio_button_unchecked;
        bgColor = Colors.transparent;
        iconColor = isDark ? Colors.grey.shade500 : Colors.grey.shade400;
        btnBorderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
        break;
    }

    return GestureDetector(
      onTap: _cycleStatus,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: btnBorderColor, width: 2),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }

  Widget _buildWordBadge(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.5 : 0.2)),
      ),
      child: Text(
        text.toUpperCase(), 
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildExerciseButton(bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseScreen(
              habitId: widget.habitId,
              habitName: widget.title, 
            ),
          ),
        );  
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black12,
          shape: BoxShape.circle,
          border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.fitness_center,
          color: widget.color ?? Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String tooltip, VoidCallback? onTap, {required Color color}) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: color,
      onPressed: onTap,
      tooltip: tooltip,
      constraints: const BoxConstraints(), 
      padding: const EdgeInsets.all(8),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical': return Colors.red.shade500;
      case 'high': return Colors.orange.shade500;
      case 'medium': return Colors.teal.shade500;
      case 'low': return Colors.blue.shade500;
      default: return Colors.grey.shade500;
    }
  }

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

  Widget _buildMetaChip({required IconData icon, required String label, required Color color, required bool isDark, bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeScroller extends StatefulWidget {
  final String docId;
  final String currentClass;
  final String? currentType;
  final bool isDark;
  final bool isNativeSync;

  const _TypeScroller({
    required this.docId,
    required this.currentClass,
    this.currentType,
    required this.isDark,
    required this.isNativeSync,
  });

  @override
  State<_TypeScroller> createState() => _TypeScrollerState();
}

class _TypeScrollerState extends State<_TypeScroller> {
  late String _selectedClass;
  late String _selectedType;
  
  final Map<String, List<String>> _typesMap = {
    'habit': ['Habits to Build', 'Habits to Break'],
    'goal': ['Short-Term', 'Long-Term', 'Bucket List'],
    'task': ['One-Time', 'Recurring'],
    'event': ['One-Time', 'Recurring'],
  };

  final List<String> _classes = ['habit', 'goal', 'task', 'event'];

  late FixedExtentScrollController _classController;
  late FixedExtentScrollController _typeController;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.currentClass;
    if (!_classes.contains(_selectedClass)) {
      _selectedClass = 'habit';
    }
    
    _selectedType = widget.currentType ?? (_typesMap[_selectedClass]!.first);
    if (!_typesMap[_selectedClass]!.contains(_selectedType)) {
      _selectedType = _typesMap[_selectedClass]!.first;
    }
    
    _classController = FixedExtentScrollController(initialItem: _classes.indexOf(_selectedClass));
    _typeController = FixedExtentScrollController(initialItem: _typesMap[_selectedClass]!.indexOf(_selectedType).clamp(0, 99));
  }
  
  @override
  void didUpdateWidget(covariant _TypeScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentClass != widget.currentClass || oldWidget.currentType != widget.currentType) {
       _selectedClass = widget.currentClass;
       if (!_classes.contains(_selectedClass)) _selectedClass = 'habit';
       
       _selectedType = widget.currentType ?? (_typesMap[_selectedClass]!.first);
       if (!_typesMap[_selectedClass]!.contains(_selectedType)) _selectedType = _typesMap[_selectedClass]!.first;
       
       if (_classController.hasClients) {
          _classController.jumpToItem(_classes.indexOf(_selectedClass));
       }
       if (_typeController.hasClients) {
          _typeController.jumpToItem(_typesMap[_selectedClass]!.indexOf(_selectedType).clamp(0, 99));
       }
    }
  }

  @override
  void dispose() {
    _classController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  String _formatUI(String raw, bool isClass) {
     if (isClass) return raw.toUpperCase();
     if (raw == 'Habits to Build') return 'BUILD';
     if (raw == 'Habits to Break') return 'BREAK';
     return raw.toUpperCase();
  }

  void _updateFirestore() {
     if (widget.isNativeSync) return;
     FirebaseFirestore.instance.collection('habits').doc(widget.docId).update({
        'itemClass': _selectedClass,
        'type': _selectedType,
     });
  }

  @override
  Widget build(BuildContext context) {
     final textStyle = TextStyle(
       fontWeight: FontWeight.bold,
       fontSize: 12,
       color: widget.isDark ? Colors.grey.shade400 : Colors.grey.shade700,
       letterSpacing: 0.5,
     );

     // Only render if docId exists or it's a native event
     if (widget.docId.isEmpty || widget.isNativeSync) {
        return Text(
          "${_formatUI(_selectedClass, true)} • ${_formatUI(_selectedType, false)}",
          style: textStyle,
        );
     }

     return SizedBox(
       height: 40, // Reduced height for tighter padding
       child: ScrollConfiguration(
         behavior: ScrollConfiguration.of(context).copyWith(
           dragDevices: {
             PointerDeviceKind.touch,
             PointerDeviceKind.mouse,
             PointerDeviceKind.trackpad,
           },
         ),
         child: NotificationListener<ScrollNotification>(
           onNotification: (notification) {
             if (notification is ScrollStartNotification || notification is ScrollUpdateNotification) {
               if (!_isScrolling) setState(() => _isScrolling = true);
             } else if (notification is ScrollEndNotification) {
               if (_isScrolling) setState(() => _isScrolling = false);
             }
             return false;
           },
           child: Row(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.center,
             children: [
                SizedBox(
                  width: 60, 
                  child: ListWheelScrollView.useDelegate(
                     controller: _classController,
                     itemExtent: 20,
                     physics: const FixedExtentScrollPhysics(),
                     overAndUnderCenterOpacity: _isScrolling ? 0.3 : 0.0,
                     onSelectedItemChanged: (idx) {
                      setState(() {
                         _selectedClass = _classes[idx];
                         _selectedType = _typesMap[_selectedClass]!.first;
                         if (_typeController.hasClients) {
                            _typeController.jumpToItem(0);
                         }
                      });
                      _updateFirestore();
                   },
                   childDelegate: ListWheelChildBuilderDelegate(
                      childCount: _classes.length,
                      builder: (context, idx) {
                         return Align(
                           alignment: Alignment.centerRight,
                           child: Text(_formatUI(_classes[idx], true), style: textStyle, maxLines: 1)
                         );
                      }
                   ),
                ),
              ),
              Text('   •   ', style: textStyle),
              SizedBox(
                width: 100,
                child: ListWheelScrollView.useDelegate(
                   controller: _typeController,
                   itemExtent: 20,
                   physics: const FixedExtentScrollPhysics(),
                   overAndUnderCenterOpacity: _isScrolling ? 0.3 : 0.0,
                   onSelectedItemChanged: (idx) {
                      setState(() {
                         _selectedType = _typesMap[_selectedClass]![idx];
                      });
                      _updateFirestore();
                   },
                   childDelegate: ListWheelChildBuilderDelegate(
                      childCount: _typesMap[_selectedClass]!.length,
                      builder: (context, idx) {
                         return Align(
                           alignment: Alignment.centerLeft,
                           child: Text(_formatUI(_typesMap[_selectedClass]![idx], false), style: textStyle, maxLines: 1, overflow: TextOverflow.ellipsis)
                         );
                      }
                   ),
                ),
              ),
           ],
         ),
       ),
     ),
   );
  }
}