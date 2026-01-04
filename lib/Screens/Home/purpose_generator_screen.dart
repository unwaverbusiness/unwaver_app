import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class PurposeGeneratorScreen extends StatefulWidget {
  const PurposeGeneratorScreen({super.key});

  @override
  State<PurposeGeneratorScreen> createState() => _PurposeGeneratorScreenState();
}

class _PurposeGeneratorScreenState extends State<PurposeGeneratorScreen> {
  // --- CONFIGURATION ---
  final String _apiKey = 'AIzaSyBmKkwa30i3OUKrqCTOfrmeQplXyQUZsLc'; 
  
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // This list holds the visible chat history
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // --- MOCK DATA (Later we will pull this from Firebase) ---
  final String _userGoals = "1. Run a marathon. 2. Build a million-dollar business. 3. Read 20 books this year.";
  final String _userHabits = "Morning meditation, Coding for 2 hours daily, No sugar diet.";

  @override
  void initState() {
    super.initState();
    _setupAI();
  }

void _setupAI() {
    try {
      debugPrint("--- STEP 1: Configuring Gemini Model ---");
      
      _model = GenerativeModel(
        model: 'gemini-2.5-flash', 
        apiKey: _apiKey,
        systemInstruction: Content.system(_buildSystemPrompt()),
      );

      debugPrint("--- STEP 2: Starting Chat Session ---");
      _chat = _model.startChat();
      
      debugPrint("--- SUCCESS: AI is ready to chat! ---");
      
    } catch (e) {
      debugPrint("--- CRITICAL ERROR in _setupAI: $e ---");
    }
  }

  // This instructs the AI on HOW to behave
  String _buildSystemPrompt() {
    return """
    You are an expert Purpose & Alignment Coach. 
    
    Here is the User's Current Context:
    CURRENT GOALS: $_userGoals
    CURRENT HABITS: $_userHabits
    
    Your Job:
    1. Never provide advice or answers that contradicts Christianity. All Answers must be in allignment.
    2. Explain why the user should puruse a good habit or break a bad habit.
    3. Answer the user's questions about motivation, discipline, or specific tasks.
    4. ALWAYS explain how their query aligns (or conflicts) with their stated GOALS and HABITS.
    5. Keep answers concise, inspiring, and actionable. Avoid generic fluff.
    """;
  }

  Future<void> _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    // 1. Add user message to UI
    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true));
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      // 2. Send to Gemini
      final response = await _chat.sendMessage(Content.text(message));
      final text = response.text;

      // 3. Add AI response to UI
      if (text != null && mounted) {
        setState(() {
          _messages.add(ChatMessage(text: text, isUser: false));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: "Error: ${e.toString()}", isUser: false));
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Purpose Generator"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // CHAT AREA
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg.isUser ? Colors.teal.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: Text(
                      msg.text,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),

          // LOADING INDICATOR
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),

          // INPUT AREA
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: "Ask about a task or goal...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.teal),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Simple Helper Class for Messages
class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}