import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:unwaver/services/api_key_manager.dart';

class AiActivityCreatorScreen extends StatefulWidget {
  const AiActivityCreatorScreen({super.key});

  @override
  State<AiActivityCreatorScreen> createState() => _AiActivityCreatorScreenState();
}

class _AiActivityCreatorScreenState extends State<AiActivityCreatorScreen> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;

  final Map<String, IconData> _aiIconMap = {
    'fitness_center': Icons.fitness_center,
    'directions_run': Icons.directions_run,
    'menu_book': Icons.menu_book,
    'local_atm': Icons.local_atm,
    'self_improvement': Icons.self_improvement,
    'favorite': Icons.favorite,
    'work': Icons.work,
    'school': Icons.school,
    'restaurant': Icons.restaurant,
    'flight': Icons.flight,
    'music_note': Icons.music_note,
    'brush': Icons.brush,
    'check_circle': Icons.check_circle,
    'star': Icons.star,
    'bolt': Icons.bolt,
    'spa': Icons.spa,
    'eco': Icons.eco,
    'sports_esports': Icons.sports_esports,
    'lightbulb': Icons.lightbulb,
    'water_drop': Icons.water_drop,
    'bed': Icons.bed,
    'directions_bike': Icons.directions_bike,
    'pool': Icons.pool,
    'people': Icons.people,
    'monitor_heart': Icons.monitor_heart,
  };

  Future<void> _generateActivity() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
    });
    FocusScope.of(context).unfocus();

    try {
      final apiKey = ApiKeyManager.geminiKey;
      if (apiKey.isEmpty) {
        throw Exception("API Key is missing.");
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final systemInstruction = '''
You are an intelligent assistant in a productivity app. The user will describe an activity they want to track.
Your job is to analyze their prompt and output a perfectly formatted JSON object that maps to our app's data model.

Respond ONLY with valid JSON. Do not include markdown formatting like ```json or any conversational text.

JSON schema:
{
  "itemClass": "habit" | "goal" | "task" | "event",
  "type": "Habits to Build" | "Habits to Break" | "Short-Term" | "Long-Term" | "Bucket List" | "One-Time" | "Recurring",
  "title": "String (Short, actionable title)",
  "description": "String (A thoughtful, encouraging description of why they should do this or what it entails, 1-2 sentences)",
  "pillar": "Health" | "Wealth" | "Mind" | "Soul" | "Relationships",
  "category": "String (e.g. Fitness, Saving, Reading, Meditation, Family)",
  "tags": ["String", "String"],
  "iconName": "String (Must be one of the allowed icons below)"
}

Allowed iconName values:
fitness_center, directions_run, menu_book, local_atm, self_improvement, favorite, work, school, restaurant, flight, music_note, brush, check_circle, star, bolt, spa, eco, sports_esports, lightbulb, water_drop, bed, directions_bike, pool, people, monitor_heart.

Rules:
- If itemClass is "habit", type must be "Habits to Build" or "Habits to Break".
- If itemClass is "goal", type must be "Short-Term", "Long-Term", or "Bucket List".
- If itemClass is "task" or "event", type must be "One-Time" or "Recurring".
- Choose the most appropriate pillar from the provided list.
- Generate a highly relevant category (1-2 words).
- Generate 1-3 relevant tags.
''';

      final response = await model.generateContent([
        Content.text('$systemInstruction\n\nUser Request: $prompt'),
      ]);

      var responseText = response.text ?? '';
      
      // Clean up potential markdown formatting from the AI response
      responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();

      final data = jsonDecode(responseText) as Map<String, dynamic>;

      // Map the string icon name back to an actual Flutter IconData
      final String iconName = data['iconName'] ?? 'star';
      final IconData chosenIcon = _aiIconMap[iconName] ?? Icons.star;

      data['iconCodePoint'] = chosenIcon.codePoint;
      data['iconFontFamily'] = chosenIcon.fontFamily;

      if (!mounted) return;
      Navigator.pop(context, data); // Return the JSON data back to the previous screen

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate activity: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Create with AI", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.auto_awesome, size: 64, color: Colors.blueAccent),
            const SizedBox(height: 24),
            const Text(
              "Describe the activity you want to track, and our AI will instantly configure the perfect dashboard card for you.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _promptController,
              decoration: InputDecoration(
                hintText: "e.g., I want to run a 5k next month...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.all(20),
              ),
              maxLines: 4,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isLoading ? null : _generateActivity,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "Generate Magic",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
