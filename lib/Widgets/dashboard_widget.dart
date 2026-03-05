import 'package:flutter/material.dart';

class DashboardWidget extends StatefulWidget {
  final List<Map<String, dynamic>> goals;
  final String selectedGoalType;

  const DashboardWidget({
    super.key,
    required this.goals,
    required this.selectedGoalType,
  });

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  // The widget manages its own expanded/collapsed state
  bool _isDashboardExpanded = true;

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color ?? Colors.black87)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Basic stats calculation based on passed-in data
    final currentTypeGoals = widget.selectedGoalType == 'All' 
        ? widget.goals 
        : widget.goals.where((g) => g['type'] == widget.selectedGoalType).toList();
        
    final total = currentTypeGoals.length;
    final completed = currentTypeGoals.where((g) => (g['progress'] as double? ?? 0.0) >= 1.0).length;
    final percent = total == 0 ? 0 : ((completed / total) * 100).toInt();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
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
                      Icon(Icons.bar_chart, size: 16, color: Colors.grey[600]), 
                      const SizedBox(width: 8),
                      Text("DASHBOARD", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey[800])),
                    ],
                  ),
                  Icon(_isDashboardExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey[600], size: 20),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isDashboardExpanded 
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      const Divider(height: 1), const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem("Total", "$total"),
                          _buildStatItem("Active", "${total - completed}", color: Colors.orange[700]),
                          _buildStatItem("Completed", "$completed", color: Colors.green[700]),
                          _buildStatItem("Success Rate", "$percent%", color: Colors.blue[700]),
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
}