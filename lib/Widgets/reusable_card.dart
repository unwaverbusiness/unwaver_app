import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReusableCard extends StatefulWidget {
  // Core Info
  final String title;
  final String? description;
  final IconData icon; // Stays static, never overwritten
  final Color color;

  // Metadata
  final String? pillar; // Single word
  final List<String>? tags; // Multiple words, no icons
  final String? urgency;
  final String? importance;
  final DateTime? deadline;

  // Initial Toggle States from Database
  final bool initialCompleted;
  final bool initialSkipped;
  final bool initialFailed;

  // Primary Actions (Triggered after local state updates)
  final VoidCallback? onComplete; 
  final VoidCallback? onSkip;     
  final VoidCallback? onFail;     

  // Secondary Tools
  final VoidCallback? onCalendarTap;
  final VoidCallback? onStatsTap;
  final VoidCallback? onHistoryTap;
  final VoidCallback? onTagsTap;

  // Management
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReusableCard({
    super.key,
    required this.title,
    this.description,
    required this.icon,
    this.color = Colors.blueAccent,

    // Metadata
    this.pillar,
    this.tags,
    this.urgency,
    this.importance,
    this.deadline,

    // Initial States
    this.initialCompleted = false,
    this.initialSkipped = false,
    this.initialFailed = false,

    // Actions
    this.onComplete,
    this.onSkip,
    this.onFail,
    this.onCalendarTap,
    this.onStatsTap,
    this.onHistoryTap,
    this.onTagsTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<ReusableCard> createState() => _ReusableCardState();
}

class _ReusableCardState extends State<ReusableCard> {
  // Local state for blazing fast UI updates independent of parent
  late bool _isCompleted;
  late bool _isSkipped;
  late bool _isFailed;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.initialCompleted;
    _isSkipped = widget.initialSkipped;
    _isFailed = widget.initialFailed;
  }

  // Sync local state if parent rebuilds with new data from Firebase
  @override
  void didUpdateWidget(covariant ReusableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCompleted != oldWidget.initialCompleted) _isCompleted = widget.initialCompleted;
    if (widget.initialSkipped != oldWidget.initialSkipped) _isSkipped = widget.initialSkipped;
    if (widget.initialFailed != oldWidget.initialFailed) _isFailed = widget.initialFailed;
  }

  // --- LOCAL TOGGLE LOGIC ---
  void _toggleComplete() {
    setState(() {
      _isCompleted = !_isCompleted;
      if (_isCompleted) {
        _isSkipped = false;
        _isFailed = false;
      }
    });
    if (widget.onComplete != null) widget.onComplete!();
  }

  void _toggleSkip() {
    setState(() {
      _isSkipped = !_isSkipped;
      if (_isSkipped) {
        _isCompleted = false;
        _isFailed = false;
      }
    });
    if (widget.onSkip != null) widget.onSkip!();
  }

  void _toggleFail() {
    setState(() {
      _isFailed = !_isFailed;
      if (_isFailed) {
        _isCompleted = false;
        _isSkipped = false;
      }
    });
    if (widget.onFail != null) widget.onFail!();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA), // Slightly grey to pop off white backgrounds
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- TOP ROW: INDICATORS & WORD TAGS ---
          if (widget.pillar != null || (widget.tags != null && widget.tags!.isNotEmpty) || widget.urgency != null || widget.importance != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Pillar (Word only)
                  if (widget.pillar != null && widget.pillar!.isNotEmpty) 
                    _buildWordBadge(widget.pillar!, Colors.blueGrey),
                  
                  // Tags (Words only)
                  if (widget.tags != null)
                    ...widget.tags!.map((tag) => _buildWordBadge(tag, Colors.deepPurple)),
                  
                  // Indicators (Small colored dots)
                  if (widget.urgency != null && widget.urgency!.isNotEmpty) 
                    _buildIndicator('Urgency: ${widget.urgency}', _getUrgencyColor(widget.urgency!)),
                  if (widget.importance != null && widget.importance!.isNotEmpty) 
                    _buildIndicator('Importance: ${widget.importance}', _getImportanceColor(widget.importance!)),
                ],
              ),
            ),

          // --- MIDDLE ROW: CORE INFO & TOGGLE ACTIONS ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Static Icon Avatar (Never Overwritten)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 28),
                ),
                const SizedBox(width: 16),

                // Text Data
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isCompleted || _isSkipped || _isFailed ? Colors.grey.shade600 : Colors.black87,
                          decoration: _isCompleted || _isSkipped || _isFailed ? TextDecoration.lineThrough : null,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (widget.description != null && widget.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.description!,
                          style: TextStyle(
                            fontSize: 13, 
                            color: Colors.grey.shade600, 
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
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade600),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Segmented Toggle Group (Check, Skip, X)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildToggleBtn(Icons.check, Colors.green, _isCompleted, _toggleComplete),
                      Divider(height: 1, color: Colors.grey.shade200),
                      _buildToggleBtn(Icons.fast_forward, Colors.orange, _isSkipped, _toggleSkip),
                      Divider(height: 1, color: Colors.grey.shade200),
                      _buildToggleBtn(Icons.close, Colors.red, _isFailed, _toggleFail),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- BOTTOM ROW: SECONDARY TOOLS ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Utility Icons
                Row(
                  children: [
                    _buildIconButton(Icons.calendar_month, 'Calendar', widget.onCalendarTap),
                    _buildIconButton(Icons.bar_chart, 'Statistics', widget.onStatsTap),
                    _buildIconButton(Icons.history, 'History', widget.onHistoryTap),
                    _buildIconButton(Icons.label_outline, 'Tags', widget.onTagsTap),
                  ],
                ),
                // Management Icons
                Row(
                  children: [
                    _buildIconButton(Icons.edit_outlined, 'Edit', widget.onEdit, color: Colors.blue),
                    _buildIconButton(Icons.delete_outline, 'Delete', widget.onDelete, color: Colors.red),
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

  // Word only, strictly NO icons
  Widget _buildWordBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text.toUpperCase(), 
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5),
      ),
    );
  }

  // Indicator with a small colored status dot
  Widget _buildIndicator(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }

  // Unified Toggle Button Logic
  Widget _buildToggleBtn(IconData icon, Color activeColor, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon, 
          color: isActive ? activeColor : Colors.grey.shade400, 
          size: 22
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String tooltip, VoidCallback? onTap, {Color color = Colors.black54}) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: color,
      onPressed: onTap,
      tooltip: tooltip,
      constraints: const BoxConstraints(), 
      padding: const EdgeInsets.all(8),
    );
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical': return Colors.deepPurple.shade700;
      case 'high': return Colors.purple.shade600;
      case 'medium': return Colors.teal.shade700;
      default: return Colors.grey.shade600;
    }
  }

  Color _getImportanceColor(String importance) {
    switch (importance.toLowerCase()) {
      case 'critical': return Colors.red.shade700;
      case 'high': return Colors.orange.shade700;
      case 'medium': return Colors.amber.shade700;
      default: return Colors.grey.shade600;
    }
  }
}