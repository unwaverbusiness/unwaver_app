import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:unwaver/services/api_key_manager.dart';
import 'package:unwaver/widgets/maindrawer.dart'; 
import 'package:unwaver/widgets/app_logo.dart';

class PurposeGeneratorScreen extends StatefulWidget {
  const PurposeGeneratorScreen({super.key});

  @override
  State<PurposeGeneratorScreen> createState() => _PurposeGeneratorScreenState();
}

class _PurposeGeneratorScreenState extends State<PurposeGeneratorScreen> {
  // --- AI LOGIC ---
  late final GenerativeModel _model;
  ChatSession? _chat; 
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Mock User Context for the AI
  final String _userGoals = "1. Run a marathon. 2. Build a million-dollar business. 3. Read 20 books this year.";
  final String _userHabits = "Morning meditation, Coding for 2 hours daily, No sugar diet.";

  // --- LIFE SYSTEM STATE ---
  final TextEditingController _purposeController = TextEditingController(text: "I build systems that empower others to find freedom.");
  
  // OPTIMIZED FIX: Defined as nullable list to allow for the safety check below
  final List<String>? _coreValues = ["Discipline", "Clarity", "Impact", "Growth"];

  @override
  void initState() {
    super.initState();
    _setupAI();
  }

  void _setupAI() {
    try {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash', 
        apiKey: ApiKeyManager.geminiKey,
        systemInstruction: Content.system(_buildSystemPrompt()),
      );
      _chat = _model.startChat();
    } catch (e) {
      debugPrint("--- CRITICAL ERROR in _setupAI: $e ---");
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

  Future<void> _sendMessage(StateSetter updateModalState) async {
    final message = _textController.text.trim();
    if (message.isEmpty) return;
    if (_chat == null) return;

    updateModalState(() {
      _messages.add(ChatMessage(text: message, isUser: true));
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final response = await _chat!.sendMessage(Content.text(message));
      final text = response.text;

      if (text != null && mounted) {
        updateModalState(() {
          _messages.add(ChatMessage(text: text, isUser: false));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      updateModalState(() {
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

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFBB8E13);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const AppLogo(), 
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const MainDrawer(currentRoute: '/Coach'),
      
      // --- FLOATING AI BUTTON ---
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        icon: const Icon(Icons.psychology, color: goldColor),
        label: const Text("Consult Coach", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showAIChatModal(context),
      ),

      // --- LIFE SYSTEM DASHBOARD ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Life System",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1),
            ),
            const SizedBox(height: 5),
            Text(
              "Define your north star.",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // 1. PRIME PURPOSE WIDGET
            _buildFloatingCard(
              title: "Prime Purpose",
              icon: Icons.star,
              goldAccent: true,
              child: TextField(
                controller: _purposeController,
                maxLines: 3,
                style: const TextStyle(fontSize: 18, height: 1.5, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "What is your ultimate mission?",
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 2. CORE VALUES WIDGET
            _buildFloatingCard(
              title: "Core Values",
              icon: Icons.diamond,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: (_coreValues ?? []).map((value) => Chip( // <--- THE FIX: Added safety check (?? [])
                  label: Text(value),
                  backgroundColor: Colors.black,
                  labelStyle: const TextStyle(color: Colors.white),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                )).toList(),
              ),
            ),

            const SizedBox(height: 20),

                        // 2. PILLARS OF LIFE WIDGET
            _buildFloatingCard(
              title: "Define the 7 Pillars of Life",
              icon: Icons.account_balance,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: (_coreValues ?? []).map((value) => Chip( // <--- THE FIX: Added safety check (?? [])
                  label: Text(value),
                  backgroundColor: Colors.black,
                  labelStyle: const TextStyle(color: Colors.white),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                )).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // 3. IDENTITY STATEMENTS
            _buildFloatingCard(
              title: "Identity Statements",
              icon: Icons.fingerprint,
              child: Column(
                children: [
                  _buildIdentityRow("I am", "a relentless problem solver."),
                  const Divider(),
                  _buildIdentityRow("I create", "value for those around me."),
                  const Divider(),
                  _buildIdentityRow("I never", "compromise on my standards."),
                ],
              ),
            ),
            
            // Padding for FAB
            const SizedBox(height: 80),

            
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildFloatingCard({
    required String title, 
    required IconData icon, 
    required Widget child,
    bool goldAccent = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: goldAccent 
          ? Border.all(color: const Color(0xFFBB8E13).withOpacity(0.5), width: 1.5)
          : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: goldAccent ? const Color(0xFFBB8E13) : Colors.grey.shade400),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: goldAccent ? const Color(0xFFBB8E13) : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildIdentityRow(String prefix, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$prefix ",
            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // --- CHAT MODAL ---

  void _showAIChatModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A), 
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.psychology, color: Color(0xFFBB8E13)),
                        SizedBox(width: 8),
                        Text(
                          "AI Life Coach",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.grey),

                  Expanded(
                    child: _messages.isEmpty 
                      ? const Center(child: Text("Ask me anything about your purpose...", style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
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
                                  color: msg.isUser ? const Color(0xFFBB8E13) : Colors.grey.shade800,
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
                            );
                          },
                        ),
                  ),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(color: Color(0xFFBB8E13)),
                    ),

                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16, 
                      left: 16, 
                      right: 16, 
                      top: 8
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.grey.shade700),
                            ),
                            child: TextField(
                              controller: _textController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: "Type a message...",
                                hintStyle: TextStyle(color: Colors.grey),
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _sendMessage(setModalState),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(
                          backgroundColor: const Color(0xFFBB8E13),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_upward, color: Colors.white),
                            onPressed: () => _sendMessage(setModalState),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}