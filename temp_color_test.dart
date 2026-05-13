import 'package:flutter/material.dart';
void main() {
  const c = Color(0xFF000000);
  final c2 = c.withValues(alpha: 0.5);
  debugPrint(c2.toString());
}
