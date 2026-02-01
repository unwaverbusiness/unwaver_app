import 'package:flutter/material.dart';

class PurposeNavIcon extends StatelessWidget {
  final double size;

  const PurposeNavIcon({
    super.key, 
    this.size = 24.0, 
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: Image.asset(
        'assets/PurposeButton.png',
        fit: BoxFit.contain,
      ),
    );
  }
}