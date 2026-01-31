import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:unwaver/services/api_key_manager.dart';
<<<<<<< HEAD
// FIXED: Added quotes, removed '/lib/', and added semicolon
import 'package:unwaver/widgets/main_drawer.dart'; 
=======
>>>>>>> 9adc0af4c64c5a0d42b958c3c4a68527308ef64f

class PurposeGeneratorScreen extends StatefulWidget {
  const PurposeGeneratorScreen({super.key});

  @override
  State<PurposeGeneratorScreen> createState() => _PurposeGeneratorScreenState();
}

class _PurposeGeneratorScreenState extends State<PurposeGeneratorScreen> {
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // --- MOCK DATA ---
  final String _userGoals = "1. Run a marathon. 2. Build a million-dollar business. 3. Read 20 books this year.";
  final String _userHabits = "Morning meditation, Coding for 2 hours daily, No sugar diet.";

  @override
  void initState() {
    super.initState();
    _setupAI();
  }

  void _setupAI() {
    try {
      debugPrint("--- Configuring Gemini Model ---");
      _model = GenerativeModel(
<<<<<<< HEAD
        model: 'gemini-2.5-flash',
=======
        model: 'gemini-1.5-flash', // Note: gemini-1.5-flash is currently the standard stable identifier
>>>>>>> 9adc0af4c64c5a0d42b958c3c4a68527308ef64f
        apiKey: ApiKeyManager.geminiKey,
        systemInstruction: Content.system(_buildSystemPrompt()),
      );
      _chat = _model.startChat();
      debugPrint("--- AI is ready! ---");
    } catch (e) {
      debugPrint("--- CRITICAL ERROR in _setupAI: $e ---");
      setState(() {
        _messages.add(ChatMessage(text: "System Error: Check API Key configuration.", isUser: false));
      });
    }
  }

  String _buildSystemPrompt() {
    return """
    You are an expert Purpose & Alignment Coach. 
    CURRENT GOALS: $_userGoals
    CURRENT HABITS: $_userHabits
    Your Job: Answer questions about motivation and discipline. Always align answers with the user's goals.
    """;
  }

  Future<void> _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true));
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(message));
      final text = response.text;

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
        title: const Text("Purpose Coach"),
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
        elevation: 1,
      ),
      
      // THE DRAWER (Top Left Menu)
<<<<<<< HEAD
      drawer: const MainDrawer(currentRoute: '/coach'),

      body: Column(
        children: [
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
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: msg.isUser ? const Color.fromARGB(255, 0, 0, 0) : Colors.grey.shade800,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(msg.isUser ? 16 : 0),
                        bottomRight: Radius.circular(msg.isUser ? 0 : 16),
                      ),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: Text(
                      msg.text,
                      style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.white),
                    ),
                  ),
=======
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color.fromARGB(255, 0, 0, 0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Unwaver",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Stay Disciplined",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: Color.fromARGB(255, 0, 0, 0)),
              title: const Text('Coach'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.track_changes, color: Color.fromARGB(255, 0, 0, 0)),
              title: const Text('Goals'),
              onTap: () {
                Navigator.pop(context);
                // Future: Navigate to Goals page
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.grey),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                // Future: Add logout logic
              },
            ),
          ],
        ),
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
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: msg.isUser ? const Color.fromARGB(255, 0, 0, 0) : Colors.grey.shade200,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(msg.isUser ? 16 : 0),
                        bottomRight: Radius.circular(msg.isUser ? 0 : 16),
                      ),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: Text(
                      msg.text,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                    ),
                  ),
>>>>>>> 9adc0af4c64c5a0d42b958c3c4a68527308ef64f
                );
              },
            ),
          ),
<<<<<<< HEAD
=======

          // LOADING INDICATOR
>>>>>>> 9adc0af4c64c5a0d42b958c3c4a68527308ef64f
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color.fromARGB(255, 0, 0, 0)),
              ),
            ),
<<<<<<< HEAD
=======

          // INPUT AREA
>>>>>>> 9adc0af4c64c5a0d42b958c3c4a68527308ef64f
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
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
                        hintText: "Message your coach...",
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: Color.fromARGB(255, 0, 0, 0)),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}