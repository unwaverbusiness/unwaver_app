import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double height;
  
  const AppLogo({super.key, this.height = 40});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/Unwaver_App_Icon.png', // UPDATED: Changed '.' to '_'
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.track_changes, 
          color: Colors.white, 
          size: height,
        );
      },
    );
  }
}