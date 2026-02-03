import 'package:flutter/material.dart';

class HabitInstructionBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const HabitInstructionBanner({
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
        color: const Color.fromARGB(255, 155, 151, 151).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.3),
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
                  Icons.info_outline_rounded,
                  color: Color(0xFFD4AF37),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Add recurring habits you intend to build or break here. This section is ideal for activities that repeat and do not have a set end date.",
                  style: const TextStyle(
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