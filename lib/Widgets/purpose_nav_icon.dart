import 'package:flutter/material.dart';

class PurposeNavIcon extends StatelessWidget {
  final double size;

  const PurposeNavIcon({
    super.key, 
    this.size = 60, 
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: Image.asset(
        'assets/PurposeButton.png', // Ensure this image exists in your assets folder
        fit: BoxFit.contain,
      ),
    );
  }
}