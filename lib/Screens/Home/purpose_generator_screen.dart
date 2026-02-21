import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:unwaver/services/api_key_manager.dart';
import 'package:unwaver/widgets/main_drawer.dart'; 
import 'package:unwaver/widgets/global_app_bar.dart';

class PurposeGeneratorScreen extends StatefulWidget {
  const PurposeGeneratorScreen({super.key});

  @override
  State<PurposeGeneratorScreen> createState() => _PurposeGeneratorScreenState();
}

class _PurposeGeneratorScreenState extends State<PurposeGeneratorScreen> {
  // --- TOP BAR STATE ---
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // --- GLOBAL AI LOGIC (Main Coach) ---
  late final GenerativeModel _model;
  ChatSession? _chat; 
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Mock User Context
  final String _userGoals = "1. Run a marathon. 2. Build a million-dollar business. 3. Read 20 books this year.";
  final String _userHabits = "Morning meditation, Coding for 2 hours daily, No sugar diet.";

  // --- LIFE SYSTEM STATE ---
  final TextEditingController _purposeController = TextEditingController(text: "I build systems that empower others to find freedom.");
  
  final Map<String, TextEditingController> _identityControllers = {};

  // Dynamic Lists for the Dashboard
  List<String> _coreValues = ["Discipline", "Clarity", "Impact", "Growth"];
  List<String> _priorities = ["Health & Fitness", "Building Unwaver", "Family Time"];
  List<String> _strengths = ["Strategic Vision", "Resilience", "Fast Learner"];
  List<String> _weaknesses = ["Impatience", "Overworking", "Delegation"];
  List<String> _vices = ["Doomscrolling", "Sugar", "Procrastination"];
  List<String> _gratitudes = ["Healthy Body", "Clean Water", "Opportunity to Build"];
  List<String> _innerCircle = ["Mom", "Dad", "Best Friend", "Mentor"];

  final Color _goldColor = const Color(0xFFBB8E13);

  @override
  void initState() {
    super.initState();
    _setupAI();
    
    // Initialize editable identity controllers
    _identityControllers['I am'] = TextEditingController(text: "a relentless problem solver.");
    _identityControllers['I create'] = TextEditingController(text: "value for those around me.");
    _identityControllers['I never'] = TextEditingController(text: "compromise on my standards.");
  }

  @override
  void dispose() {
    _searchController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _purposeController.dispose();
    for (var ctrl in _identityControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
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

  // --- BRAINSTORM & EDIT MODAL ---
  
  void _showBrainstormModal({
    required String categoryTitle,
    required String aiContext,
    required Function(String) onAdd,
    String? prefillAdd,
  }) {
    final TextEditingController addCtrl = TextEditingController(text: prefillAdd);
    final TextEditingController localChatCtrl = TextEditingController();
    final ScrollController localScrollCtrl = ScrollController();
    List<ChatMessage> localChatHistory = [];
    bool isLocalTyping = false;

    // Initialize a temporary chat specifically for this trait
    late final ChatSession localChatSession;
    try {
      localChatSession = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: ApiKeyManager.geminiKey,
        systemInstruction: Content.system("You are helping the user define their '$categoryTitle'. Their Prime Purpose is: '${_purposeController.text}'. $aiContext Keep responses brief, conversational, and direct."),
      ).startChat();
      
      localChatHistory.add(ChatMessage(text: "Hi! Need ideas for your $categoryTitle? Tell me what's on your mind, or ask me for suggestions based on your Purpose.", isUser: false));
    } catch(e) {
      localChatHistory.add(ChatMessage(text: "AI is currently offline.", isUser: false));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          
          Future<void> sendLocalMessage() async {
            final msg = localChatCtrl.text.trim();
            if (msg.isEmpty) return;

            setModalState(() {
              localChatHistory.add(ChatMessage(text: msg, isUser: true));
              isLocalTyping = true;
            });
            localChatCtrl.clear();
            WidgetsBinding.instance.addPostFrameCallback((_) => localScrollCtrl.jumpTo(localScrollCtrl.position.maxScrollExtent));

            try {
              final response = await localChatSession.sendMessage(Content.text(msg));
              if (response.text != null) {
                setModalState(() {
                  localChatHistory.add(ChatMessage(text: response.text!, isUser: false));
                  isLocalTyping = false;
                });
                WidgetsBinding.instance.addPostFrameCallback((_) => localScrollCtrl.jumpTo(localScrollCtrl.position.maxScrollExtent));
              }
            } catch (e) {
              setModalState(() {
                localChatHistory.add(ChatMessage(text: "Error: $e", isUser: false));
                isLocalTyping = false;
              });
            }
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A), 
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Header Line
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8), height: 4, width: 40,
                  decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2)),
                ),
                
                // --- ADD ITEM SECTION (Pinned to top) ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade800)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: addCtrl,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: prefillAdd != null ? "Edit statement..." : "Type to add to $categoryTitle...",
                            hintStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.normal),
                            filled: true,
                            fillColor: Colors.grey.shade900,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _goldColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        onPressed: () {
                          if (addCtrl.text.trim().isNotEmpty) {
                            onAdd(addCtrl.text.trim());
                            Navigator.pop(ctx);
                          }
                        },
                        child: Text(prefillAdd != null ? "Save" : "Add", style: const TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),

                // --- AI BRAINSTORM CHAT ---
                Expanded(
                  child: ListView.builder(
                    controller: localScrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: localChatHistory.length,
                    itemBuilder: (context, index) {
                      final msg = localChatHistory[index];
                      return Align(
                        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: msg.isUser ? _goldColor.withValues(alpha:0.2) : Colors.grey.shade800,
                            border: msg.isUser ? Border.all(color: _goldColor.withValues(alpha:0.5)) : null,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(msg.isUser ? 16 : 0), bottomRight: Radius.circular(msg.isUser ? 0 : 16),
                            ),
                          ),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                          child: Text(msg.text, style: TextStyle(fontSize: 14, height: 1.4, color: msg.isUser ? _goldColor : Colors.white)),
                        ),
                      );
                    },
                  ),
                ),
                
                if (isLocalTyping)
                  Padding(padding: const EdgeInsets.all(8.0), child: CircularProgressIndicator(color: _goldColor)),

                // --- CHAT INPUT ---
                Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, left: 16, right: 16, top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900, borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.grey.shade700),
                          ),
                          child: TextField(
                            controller: localChatCtrl, style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: "Chat with AI to brainstorm...", hintStyle: TextStyle(color: Colors.grey, fontSize: 14), 
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), border: InputBorder.none
                            ),
                            onSubmitted: (_) => sendLocalMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(icon: const Icon(Icons.arrow_upward, color: Colors.black), onPressed: () => sendLocalMessage()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: GlobalAppBar(
        isSearching: _isSearching,
        searchController: _searchController,
        onSearchChanged: (val) => setState(() {}),
        onCloseSearch: () => setState(() {
          _isSearching = false;
          _searchController.clear();
        }),
        onSearchTap: () => setState(() => _isSearching = true),
        onFilterTap: () {}, onSortTap: () {},
      ),
      drawer: const MainDrawer(currentRoute: '/Coach'),
      
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        icon: Icon(Icons.psychology, color: _goldColor),
        label: const Text("Main Coach", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showGlobalChatModal(context),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text("Life System", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1)),
        const SizedBox(height: 24),

            // 1. PRIME PURPOSE
            _buildFloatingCard(
              title: "Prime Purpose", icon: Icons.star, goldAccent: true,
              child: TextField(
                controller: _purposeController, maxLines: 3,
                style: const TextStyle(fontSize: 18, height: 1.5, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(border: InputBorder.none, hintText: "What is your ultimate mission?"),
              ),
            ),
            const SizedBox(height: 16),

            // 2. PRIORITIES
            _buildFloatingCard(
              title: "Top Priorities", icon: Icons.low_priority,
              child: _buildEditableWrap(
                items: _priorities, color: Colors.black,
                onAddRequest: () => _showBrainstormModal(
                  categoryTitle: "Priorities", aiContext: "Suggest broad life priorities.",
                  onAdd: (val) => setState(() => _priorities.add(val)),
                ),
                onDelete: (val) => setState(() => _priorities.remove(val)),
              ),
            ),
            const SizedBox(height: 16),

            // 3. CORE VALUES
            _buildFloatingCard(
              title: "Core Values", icon: Icons.diamond,
              child: _buildEditableWrap(
                items: _coreValues, color: _goldColor,
                onAddRequest: () => _showBrainstormModal(
                  categoryTitle: "Core Values", aiContext: "Suggest one-word core values.",
                  onAdd: (val) => setState(() => _coreValues.add(val)),
                ),
                onDelete: (val) => setState(() => _coreValues.remove(val)),
              ),
            ),
            const SizedBox(height: 16),

            // 4. IDENTITY STATEMENTS
            _buildFloatingCard(
              title: "Identity Statements", icon: Icons.fingerprint,
              child: Column(
                children: [
                  _buildIdentityRow("I am"), const Divider(),
                  _buildIdentityRow("I create"), const Divider(),
                  _buildIdentityRow("I never"),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. STRENGTHS & WEAKNESSES (Row)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildFloatingCard(
                    title: "Strengths", icon: Icons.bolt,
                    child: _buildEditableWrap(
                      items: _strengths, color: Colors.green.shade700,
                      onAddRequest: () => _showBrainstormModal(
                        categoryTitle: "Strengths", aiContext: "Suggest personal strengths needed for this mission.",
                        onAdd: (val) => setState(() => _strengths.add(val)),
                      ),
                      onDelete: (val) => setState(() => _strengths.remove(val)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFloatingCard(
                    title: "Weaknesses", icon: Icons.warning_amber_rounded,
                    child: _buildEditableWrap(
                      items: _weaknesses, color: Colors.red.shade700,
                      onAddRequest: () => _showBrainstormModal(
                        categoryTitle: "Weaknesses", aiContext: "Suggest blind spots that could hinder this mission.",
                        onAdd: (val) => setState(() => _weaknesses.add(val)),
                      ),
                      onDelete: (val) => setState(() => _weaknesses.remove(val)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 6. VICES TO CONQUER
            _buildFloatingCard(
              title: "Vices to Conquer", icon: Icons.shield_outlined,
              child: _buildEditableWrap(
                items: _vices, color: Colors.grey.shade800,
                onAddRequest: () => _showBrainstormModal(
                  categoryTitle: "Vices", aiContext: "Suggest bad habits that would destroy this mission.",
                  onAdd: (val) => setState(() => _vices.add(val)),
                ),
                onDelete: (val) => setState(() => _vices.remove(val)),
              ),
            ),
            const SizedBox(height: 16),

            // 7. GRATITUDE
            _buildFloatingCard(
              title: "Daily Gratitude", icon: Icons.favorite_border,
              child: _buildEditableWrap(
                items: _gratitudes, color: Colors.blue.shade700,
                onAddRequest: () => _showBrainstormModal(
                  categoryTitle: "Gratitude", aiContext: "Suggest broad things to be grateful for to maintain perspective.",
                  onAdd: (val) => setState(() => _gratitudes.add(val)),
                ),
                onDelete: (val) => setState(() => _gratitudes.remove(val)),
              ),
            ),
            const SizedBox(height: 16),

            // 8. INNER CIRCLE (No AI context needed for personal contacts)
            _buildFloatingCard(
              title: "Inner Circle", icon: Icons.groups,
              child: _buildEditableWrap(
                items: _innerCircle, color: Colors.purple.shade700,
                onAddRequest: () => _showBrainstormModal(
                  categoryTitle: "Inner Circle", aiContext: "The user is adding people close to them. Just encourage them.",
                  onAdd: (val) => setState(() => _innerCircle.add(val)),
                ),
                onDelete: (val) => setState(() => _innerCircle.remove(val)),
              ),
            ),

            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildEditableWrap({
    required List<String> items, 
    required Color color, 
    required Function(String) onDelete, 
    required VoidCallback onAddRequest
  }) {
    // Corrected to explicitly define the list as <Widget> to avoid SubType errors
    List<Widget> chips = items.map<Widget>((value) => InputChip( 
      label: Text(value, style: const TextStyle(fontSize: 12)),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      deleteIconColor: Colors.white70,
      onDeleted: () => onDelete(value),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    )).toList();

    // The "+ Add" Button
    chips.add(
      ActionChip(
        label: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: Colors.black),
            SizedBox(width: 4),
            Text("Add", style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
          ]
        ),
        backgroundColor: Colors.grey.shade200,
        onPressed: onAddRequest,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      )
    );

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget _buildFloatingCard({
    required String title, required IconData icon, required Widget child, bool goldAccent = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: goldAccent ? Border.all(color: _goldColor.withValues(alpha:0.5), width: 1.5) : Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: goldAccent ? _goldColor : Colors.grey.shade500),
              const SizedBox(width: 8),
              Text(title.toUpperCase(), style: TextStyle(color: goldAccent ? _goldColor : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildIdentityRow(String prefix) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("$prefix ", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 14)),
          Expanded(
            child: TextField(
              controller: _identityControllers[prefix],
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: "Type statement..."),
            ),
          ),
          IconButton(
            icon: Icon(Icons.auto_awesome, size: 18, color: _goldColor),
            onPressed: () => _showBrainstormModal(
              categoryTitle: "Identity: $prefix...",
              aiContext: "Help the user finish the identity statement starting with '$prefix'.",
              prefillAdd: _identityControllers[prefix]!.text, // Allows user to edit existing text in the modal
              onAdd: (val) => setState(() => _identityControllers[prefix]!.text = val),
            ),
          )
        ],
      ),
    );
  }

  // --- GLOBAL CHAT MODAL ---
  void _showGlobalChatModal(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(color: Color(0xFF1A1A1A), borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
            child: Column(
              children: [
                Container(margin: const EdgeInsets.only(top: 12, bottom: 8), height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2))),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.psychology, color: Color(0xFFBB8E13)), SizedBox(width: 8),
                      Text("AI Life Coach", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Divider(color: Colors.grey),
                Expanded(
                  child: _messages.isEmpty 
                    ? const Center(child: Text("Ask me anything about your purpose...", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        controller: _scrollController, padding: const EdgeInsets.all(16), itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return Align(
                            alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6), padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: msg.isUser ? const Color(0xFFBB8E13) : Colors.grey.shade800,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(msg.isUser ? 16 : 0), bottomRight: Radius.circular(msg.isUser ? 0 : 16),
                                ),
                              ),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              child: Text(msg.text, style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.white)),
                            ),
                          );
                        },
                      ),
                ),
                if (_isLoading) const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: Color(0xFFBB8E13))),
                Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, left: 16, right: 16, top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey.shade700)),
                          child: TextField(
                            controller: _textController, style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(hintText: "Type a message...", hintStyle: TextStyle(color: Colors.grey), contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), border: InputBorder.none),
                            onSubmitted: (_) => _sendGlobalMessage(setModalState),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(backgroundColor: const Color(0xFFBB8E13), child: IconButton(icon: const Icon(Icons.arrow_upward, color: Colors.white), onPressed: () => _sendGlobalMessage(setModalState))),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Future<void> _sendGlobalMessage(StateSetter updateModalState) async {
    final message = _textController.text.trim();
    if (message.isEmpty || _chat == null) return;

    updateModalState(() { _messages.add(ChatMessage(text: message, isUser: true)); _isLoading = true; });
    _textController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollController.jumpTo(_scrollController.position.maxScrollExtent));

    try {
      final response = await _chat!.sendMessage(Content.text(message));
      if (response.text != null && mounted) {
        updateModalState(() { _messages.add(ChatMessage(text: response.text!, isUser: false)); _isLoading = false; });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollController.jumpTo(_scrollController.position.maxScrollExtent));
      }
    } catch (e) {
      if (mounted) updateModalState(() { _messages.add(ChatMessage(text: "Error: $e", isUser: false)); _isLoading = false; });
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}