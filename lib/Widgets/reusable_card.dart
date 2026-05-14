import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unwaver/screens/habits/exercise/exercise_screen.dart';

// --- CLEAN STATE ENUM ---
enum CardStatus { none, completed, skipped, failed }

class ReusableCard extends StatefulWidget {
  // Core Info
  final String habitId;
  final String title;
  final String? description;
  final IconData icon; 
  final Color? color; 

  // Metadata
  final String? priority; 
  final String? urgency;  
  final String? importance; 
  final String? pillar;   
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

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onShareTap;

  const ReusableCard({
    super.key,
    required this.habitId, 
    required this.title,
    this.description,
    required this.icon,
    this.color,

    // Metadata
    this.priority,
    this.urgency,         
    this.importance,      
    this.pillar,          
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
                      if (widget.deadline != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.event_busy, size: 14, color: Colors.red.shade400),
                            const SizedBox(width: 4),
                            Text(
                              'Due: ${DateFormat('MMM dd, yyyy').format(widget.deadline!)}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade400),
                            ),
                          ],
                        ),
                      ],
                      // Priority & Urgency Badges
                      if ((widget.priority != null && widget.priority!.isNotEmpty) || 
                          (widget.urgency != null && widget.urgency!.isNotEmpty))
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              if (widget.priority != null && widget.priority!.isNotEmpty)
                                _buildWordBadge(
                                  _formatPriority(widget.priority!), 
                                  _getPriorityColor(widget.priority!),
                                  isDark, // Passed missing isDark parameter
                                ),
                              if (widget.priority != null && widget.priority!.isNotEmpty && 
                                  widget.urgency != null && widget.urgency!.isNotEmpty)
                                const SizedBox(width: 8),
                              if (widget.urgency != null && widget.urgency!.isNotEmpty)
                                _buildWordBadge(
                                  _formatUrgency(widget.urgency!), 
                                  isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                                  isDark, // Passed missing isDark parameter
                                ),
                              if (widget.type != null && widget.type!.isNotEmpty) ...[
                                if ((widget.priority != null && widget.priority!.isNotEmpty) || 
                                    (widget.urgency != null && widget.urgency!.isNotEmpty))
                                  const SizedBox(width: 8),
                                _buildWordBadge(
                                  widget.type!.contains('Build') ? 'BUILD' : 'BREAK',
                                  widget.type!.contains('Build') ? Colors.green.shade600 : Colors.red.shade600,
                                  isDark,
                                ),
                              ],
                            ],
                          ),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                Row(
                  children: [
                    _buildIconButton(Icons.calendar_month, 'Calendar', widget.onCalendarTap, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                    _buildIconButton(Icons.bar_chart, 'Statistics', widget.onStatsTap, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                    _buildIconButton(Icons.history, 'History', widget.onHistoryTap, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                    _buildIconButton(Icons.label_outline, 'Tags', widget.onTagsTap, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                  ],
                ),
                Row(
                  children: [
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
}