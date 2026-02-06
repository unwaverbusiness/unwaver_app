import 'package:flutter/material.dart';

class TaskInstructionBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const TaskInstructionBanner({
    super.key,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // Reduced bottom padding to tighten the layout
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4), 
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 155, 151, 151).withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha:0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2.0),
                child: Icon(
                  Icons.check_circle_outline_rounded, // Changed to a checkmark icon
                  color: Color(0xFFD4AF37),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Add one-time tasks or to-do items here. This section is ideal for single-use activities that need to be completed once.",
                  style: TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          // Align the button to the bottom right with minimal spacing
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onDismiss,
              style: TextButton.styleFrom(
                // Removes default large button padding
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                "Dismiss",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}