import 'package:flutter/material.dart';

class PurposeNavIcon extends StatelessWidget {
  final double size;
  final Color? color; 

  const PurposeNavIcon({
    super.key, 
    this.size = 24.0, 
    this.color, 
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: Image.asset(
        'assets/PurposeButton.png',
        fit: BoxFit.contain,
        // If color is null, the image uses its original colors.
        // If color is provided (e.g., Colors.white), it tints the image.
        color: color, 
      ),
    );
  }
}