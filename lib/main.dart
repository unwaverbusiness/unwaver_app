import 'package:flutter/material.dart';

void main() => runApp(const UnwaverApp());

class UnwaverApp extends StatelessWidget {
  const UnwaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Unwaver'),
          backgroundColor: const Color.fromARGB(255, 29, 140, 160),
        ),
        body: const Center(
          child: Text('Hello buddy'),
        ),
      ),
    );
  }
}