import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for Clipboard
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // --- FIREBASE / STATE ---
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _isDataLoading = true;

  final TextEditingController _purposeController = TextEditingController();

  // Dynamic Lists for the Dashboard
  List<String> _coreValues = [];
  List<String> _priorities = [];
  List<String> _identityStatements = [];
  List<String> _strengths = [];
  List<String> _weaknesses = [];
  List<String> _vices = [];
  List<String> _gratitudes = [];
  List<String> _innerCircle = [];
  final List<String> _aspirations = [];
  final List<String> _characteristics = [];

  // Card visibility preferences
  Map<String, bool> _cardVisibility = {
    'purpose': true,
    'priorities': true,
    'coreValues': true,
    'identityStatements': true,
    'strengths': true,
    'weaknesses': true,
    'vices': true,
    'gratitudes': true,
    'innerCircle': true,
    'aspirations': true,
    'characteristics': true,
  };

  // Card order for display
  List<String> _cardOrder = [
    'purpose',
    'priorities',
    'coreValues',
    'identityStatements',
    'strengths',
    'weaknesses',
    'vices',
    'gratitudes',
    'innerCircle',
    'aspirations',
    'characteristics',
  ];

  // Card metadata for settings dialog
  final Map<String, Map<String, dynamic>> _cardMetadata = {
    'purpose': {'title': 'Purpose', 'icon': Icons.star},
    'priorities': {'title': 'Top Priorities', 'icon': Icons.low_priority},
    'coreValues': {'title': 'Core Values', 'icon': Icons.diamond},
    'identityStatements': {'title': 'Identity Statements', 'icon': Icons.fingerprint},
    'strengths': {'title': 'Strengths', 'icon': Icons.bolt},
    'weaknesses': {'title': 'Weaknesses', 'icon': Icons.warning_amber_rounded},
    'vices': {'title': 'Vices to Conquer', 'icon': Icons.shield_outlined},
    'gratitudes': {'title': 'Daily Gratitude', 'icon': Icons.favorite_border},
    'innerCircle': {'title': 'Inner Circle', 'icon': Icons.groups},
    'aspirations': {'title': 'Aspirations', 'icon': Icons.star},
    'characteristics': {'title': 'Characteristics', 'icon': Icons.person},
  };

  final Color _goldColor = const Color(0xFFBB8E13);

  @override
  void initState() {
    super.initState();
    _setupAI();
    _loadUserData();
  }

  final TextEditingController _cardFilterController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _purposeController.dispose();
    _cardFilterController.dispose();
    super.dispose();
  }

  // --- FIREBASE LOGIC ---

  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> _loadUserData() async {
    final uid = currentUserId;
    if (uid == null) {
      setState(() => _isDataLoading = false);
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).collection('life_system').doc('main').get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _purposeController.text = data['purpose'] ?? "";
          _coreValues = List<String>.from(data['coreValues'] ?? []);
          _priorities = List<String>.from(data['priorities'] ?? []);
          _identityStatements = List<String>.from(data['identityStatements'] ?? []);
          _strengths = List<String>.from(data['strengths'] ?? []);
          _weaknesses = List<String>.from(data['weaknesses'] ?? []);
          _vices = List<String>.from(data['vices'] ?? []);
          _gratitudes = List<String>.from(data['gratitudes'] ?? []);
          _innerCircle = List<String>.from(data['innerCircle'] ?? []);
          
          if (data['cardVisibility'] != null) {
            final visibility = Map<String, dynamic>.from(data['cardVisibility']);
            _cardVisibility = visibility.map((key, value) => MapEntry(key, value as bool));
          }
          
          if (data['cardOrder'] != null) {
            _cardOrder = List<String>.from(data['cardOrder']);
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      setState(() => _isDataLoading = false);
    }
  }

  Future<void> _saveFieldToFirebase(String field, dynamic data) async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      await _firestore.collection('users').doc(uid).collection('life_system').doc('main').set(
        {field: data},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint("Error saving $field: $e");
    }
  }

  void _savePurpose() {
    _saveFieldToFirebase('purpose', _purposeController.text.trim());
  }

  void _saveCardVisibility() {
    _saveFieldToFirebase('cardVisibility', _cardVisibility);
  }

  void _saveCardOrder() {
    _saveFieldToFirebase('cardOrder', _cardOrder);
  }

  // --- CUSTOMIZE CARDS DIALOG ---
  
  void _showCardVisibilitySettings() {
    _cardFilterController.clear();
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: StatefulBuilder(
          builder: (ctx, setDialogState) {
            
            // Filter logic
            final filteredCardOrder = _cardOrder.where((key) {
              final metadata = _cardMetadata[key];
              final title = metadata?['title']?.toString().toLowerCase() ?? '';
              final searchTerm = _cardFilterController.text.toLowerCase();
              return title.contains(searchTerm);
            }).toList();

            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.dashboard_customize, color: _goldColor, size: 24),
                          const SizedBox(width: 12),
                          const Text("Customize Cards", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Drag to reorder • Tap to show/hide", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  const SizedBox(height: 16),
                  
                  // Search/Filter Field
                  TextField(
                    controller: _cardFilterController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Search cards...",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search, color: _goldColor),
                      suffixIcon: _cardFilterController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey.shade400),
                              onPressed: () {
                                _cardFilterController.clear();
                                setDialogState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 8),
                  
                  // Reorderable List
                  Flexible(
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      buildDefaultDragHandles: false, // Prevents the ugly double lines!
                      itemCount: filteredCardOrder.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final item = _cardOrder.removeAt(_cardOrder.indexOf(filteredCardOrder[oldIndex]));
                          final newActualIndex = newIndex == filteredCardOrder.length - 1
                              ? _cardOrder.length
                              : _cardOrder.indexOf(filteredCardOrder[newIndex]);
                          _cardOrder.insert(newActualIndex, item);
                        });
                        setDialogState(() {});
                        _saveCardOrder();
                      },
                      itemBuilder: (context, index) {
                        final key = filteredCardOrder[index];
                        final metadata = _cardMetadata[key];
                        final title = metadata?['title'] ?? key;
                        final icon = metadata?['icon'] ?? Icons.card_membership;
                        final isVisible = _cardVisibility[key] ?? true;
                        
                        return Container(
                          key: ValueKey(key),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isVisible ? _goldColor.withValues(alpha: 0.05) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isVisible ? _goldColor.withValues(alpha: 0.3) : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            child: Row(
                              children: [
                                // Left-side custom drag handle
                                ReorderableDragStartListener(
                                  index: index,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Icon(Icons.drag_indicator, size: 20, color: Colors.grey.shade400),
                                  ),
                                ),
                                Icon(icon, size: 20, color: isVisible ? _goldColor : Colors.grey.shade400),
                                const SizedBox(width: 12),
                                
                                // Title and Tappable Area
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _cardVisibility[key] = !isVisible;
                                      });
                                      setDialogState(() {}); // Force dialog refresh
                                      _saveCardVisibility(); // Sync to Firebase
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isVisible ? FontWeight.w600 : FontWeight.normal,
                                        color: isVisible ? Colors.black87 : Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Right-side Visibility Toggle
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _cardVisibility[key] = !isVisible;
                                    });
                                    setDialogState(() {}); // Force dialog refresh
                                    _saveCardVisibility(); // Sync to Firebase
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    color: Colors.transparent,
                                    child: Icon(
                                      isVisible ? Icons.visibility : Icons.visibility_off,
                                      size: 20,
                                      color: isVisible ? _goldColor : Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- AI LOGIC ---

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

  // --- BRAINSTORM MODAL ---
  void _showBrainstormModal({
    required String categoryTitle,
    required String aiContext,
    required Function(String) onAdd,
    String buttonText = "Add",
  }) {
    final TextEditingController addCtrl = TextEditingController();
    final TextEditingController localChatCtrl = TextEditingController();
    final ScrollController localScrollCtrl = ScrollController();
    List<ChatMessage> localChatHistory = [];
    bool isLocalTyping = false;

    late final ChatSession localChatSession;
    try {
      localChatSession = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: ApiKeyManager.geminiKey,
        systemInstruction: Content.system("You are helping the user define their '$categoryTitle'. Their Prime Purpose is: '${_purposeController.text}'. $aiContext Keep responses brief, conversational, and direct."),
      ).startChat();
      
      localChatHistory.add(ChatMessage(text: "Hi! Let's brainstorm your $categoryTitle. Tell me what's on your mind, or ask me for suggestions.", isUser: false));
    } catch(e) {
      localChatHistory.add(ChatMessage(text: "AI is currently offline.", isUser: false));
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.all(16),
        child: StatefulBuilder(
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

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, color: _goldColor, size: 20),
                            const SizedBox(width: 8),
                            Text("Brainstorm $categoryTitle", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey.shade200, height: 1),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: addCtrl,
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: "Type to $buttonText...",
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                              filled: true, fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: _goldColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                          onPressed: () {
                            if (addCtrl.text.trim().isNotEmpty) {
                              onAdd(addCtrl.text.trim());
                              Navigator.pop(ctx);
                            }
                          },
                          child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey.shade100, height: 1),

                  Expanded(
                    child: ListView.builder(
                      controller: localScrollCtrl, padding: const EdgeInsets.all(16), itemCount: localChatHistory.length,
                      itemBuilder: (context, index) {
                        final msg = localChatHistory[index];
                        final isAI = !msg.isUser;

                        return Align(
                          alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
                          child: Column(
                            crossAxisAlignment: isAI ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 6, bottom: 2), padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isAI ? Colors.grey.shade100 : _goldColor,
                                  border: isAI ? Border.all(color: Colors.grey.shade200) : null,
                                  borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isAI ? 0 : 16), bottomRight: Radius.circular(isAI ? 16 : 0)),
                                ),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                child: SelectableText(msg.text, style: TextStyle(fontSize: 14, height: 1.4, color: isAI ? Colors.black87 : Colors.white)),
                              ),
                              
                              if (isAI)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: msg.text));
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied to clipboard!")));
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: Text("Copy", style: TextStyle(fontSize: 11, color: _goldColor, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          String cleanText = msg.text.replaceAll(RegExp(r'^"|"$'), '').trim();
                                          addCtrl.text = cleanText;
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: Text("Use this", style: TextStyle(fontSize: 11, color: _goldColor, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  if (isLocalTyping) Padding(padding: const EdgeInsets.all(8.0), child: CircularProgressIndicator(color: _goldColor)),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey.shade200)),
                            child: TextField(
                              controller: localChatCtrl, style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(hintText: "Chat to brainstorm...", hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), border: InputBorder.none),
                              onSubmitted: (_) => sendLocalMessage(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(backgroundColor: _goldColor, child: IconButton(icon: const Icon(Icons.arrow_upward, color: Colors.white), onPressed: () => sendLocalMessage())),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  // --- MANUAL ADD DIALOG ---
  void _showAddDialog({required String categoryTitle, required Function(String) onAdd}) {
    final TextEditingController addCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Add to $categoryTitle", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: addCtrl, autofocus: true,
          decoration: InputDecoration(hintText: "Enter new item...", hintStyle: TextStyle(color: Colors.grey.shade400), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _goldColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              if (addCtrl.text.trim().isNotEmpty) { onAdd(addCtrl.text.trim()); Navigator.pop(ctx); }
            },
            child: const Text("Add", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: GlobalAppBar(
        isSearching: _isSearching, searchController: _searchController,
        onSearchChanged: (val) => setState(() {}),
        onCloseSearch: () => setState(() { _isSearching = false; _searchController.clear(); }),
        onSearchTap: () => setState(() => _isSearching = true),
        onFilterTap: _showCardVisibilitySettings, onSortTap: () {},
      ),
      drawer: const MainDrawer(currentRoute: '/Coach'),
      
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black, icon: Icon(Icons.psychology, color: _goldColor),
        label: const Text("Main Coach", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showGlobalChatPopup(context),
      ),

      body: Column(
        children: [
          if (_isDataLoading) LinearProgressIndicator(color: _goldColor, minHeight: 3, backgroundColor: Colors.transparent),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  ..._cardOrder.map((key) {
                    final card = _buildCardByKey(key);
                    if (card == null) return const SizedBox.shrink();
                    return Column(
                      children: [
                        card,
                        const SizedBox(height: 16),
                      ],
                    );
                  // ignore: unnecessary_to_list_in_spreads
                  }).toList(),

                  const SizedBox(height: 100), 
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- DYNAMIC CARD BUILDER ---

  Widget? _buildCardByKey(String key) {
    if (!(_cardVisibility[key] ?? true)) return null;

    switch (key) {
      case 'purpose':
        return _buildFloatingCard(
          title: "Purpose", icon: Icons.star, goldAccent: true,
          onMagicWand: () => _showBrainstormModal(categoryTitle: "Purpose", buttonText: "Apply", aiContext: "Help the user write a single, powerful sentence that defines their ultimate purpose.", onAdd: (val) { setState(() => _purposeController.text = val); _savePurpose(); }),
          child: Focus(
            onFocusChange: (hasFocus) { if (!hasFocus) _savePurpose(); },
            child: TextField(controller: _purposeController, maxLines: 3, style: const TextStyle(fontSize: 18, height: 1.5, fontWeight: FontWeight.w500), decoration: InputDecoration(border: InputBorder.none, hintText: "What is your ultimate purpose?", hintStyle: TextStyle(color: Colors.grey.shade400))),
          ),
        );
      case 'priorities':
        return _buildFloatingCard(
          title: "Top Priorities", icon: Icons.low_priority,
          onMagicWand: () => _showBrainstormModal(categoryTitle: "Priorities", aiContext: "Suggest broad, essential life priorities based on their purpose.", onAdd: (val) { setState(() => _priorities.add(val)); _saveFieldToFirebase('priorities', _priorities); }),
          child: _buildEditableWrap(items: _priorities, color: Colors.black, onAddRequest: () => _showAddDialog(categoryTitle: "Priorities", onAdd: (val) { setState(() => _priorities.add(val)); _saveFieldToFirebase('priorities', _priorities); }), onDelete: (val) { setState(() => _priorities.remove(val)); _saveFieldToFirebase('priorities', _priorities); }),
        );
      case 'coreValues':
        return _buildFloatingCard(
          title: "Core Values", icon: Icons.diamond,
          onMagicWand: () => _showBrainstormModal(categoryTitle: "Core Values", aiContext: "Suggest one-word core values.", onAdd: (val) { setState(() => _coreValues.add(val)); _saveFieldToFirebase('coreValues', _coreValues); }),
          child: _buildEditableWrap(items: _coreValues, color: _goldColor, onAddRequest: () => _showAddDialog(categoryTitle: "Core Values", onAdd: (val) { setState(() => _coreValues.add(val)); _saveFieldToFirebase('coreValues', _coreValues); }), onDelete: (val) { setState(() => _coreValues.remove(val)); _saveFieldToFirebase('coreValues', _coreValues); }),
        );
      case 'identityStatements':
        return _buildFloatingCard(
          title: "Identity Statements", icon: Icons.fingerprint,
          onMagicWand: () => _showBrainstormModal(categoryTitle: "Identity", aiContext: "Suggest powerful statements starting with 'I am', 'I will', or 'I create'.", onAdd: (val) { setState(() => _identityStatements.add(val)); _saveFieldToFirebase('identityStatements', _identityStatements); }),
          child: _buildEditableWrap(items: _identityStatements, color: Colors.grey.shade800, onAddRequest: () => _showAddDialog(categoryTitle: "Identity Statement", onAdd: (val) { setState(() => _identityStatements.add(val)); _saveFieldToFirebase('identityStatements', _identityStatements); }), onDelete: (val) { setState(() => _identityStatements.remove(val)); _saveFieldToFirebase('identityStatements', _identityStatements); }),
        );
      case 'strengths':
        return _buildFloatingCard(
          title: "Strengths", icon: Icons.bolt,
          onMagicWand: () => _showBrainstormModal(categoryTitle: "Strengths", aiContext: "Suggest personal strengths needed for this mission.", onAdd: (val) { setState(() => _strengths.add(val)); _saveFieldToFirebase('strengths', _strengths); }),
          child: _buildEditableWrap(items: _strengths, color: Colors.green.shade700, onAddRequest: () => _showAddDialog(categoryTitle: "Strengths", onAdd: (val) { setState(() => _strengths.add(val)); _saveFieldToFirebase('strengths', _strengths); }), onDelete: (val) { setState(() => _strengths.remove(val)); _saveFieldToFirebase('strengths', _strengths); }),
        );
      case 'weaknesses':
        return _buildFloatingCard(
          title: "Weaknesses", icon: Icons.warning_amber_rounded,
          onMagicWand: () => _showBrainstormModal(categoryTitle: "Weaknesses", aiContext: "Suggest typical blind spots.", onAdd: (val) { setState(() => _weaknesses.add(val)); _saveFieldToFirebase('weaknesses', _weaknesses); }),
          child: _buildEditableWrap(items: _weaknesses, color: Colors.red.shade700, onAddRequest: () => _showAddDialog(categoryTitle: "Weaknesses", onAdd: (val) { setState(() => _weaknesses.add(val)); _saveFieldToFirebase('weaknesses', _weaknesses); }), onDelete: (val) { setState(() => _weaknesses.remove(val)); _saveFieldToFirebase('weaknesses', _weaknesses); }),
        );
      case 'vices':
        return _buildFloatingCard(
          title: "Vices to Conquer", icon: Icons.shield_outlined,
          onMagicWand: () => _showBrainstormModal(categoryTitle: "Vices", aiContext: "Suggest bad habits that would destroy this mission.", onAdd: (val) { setState(() => _vices.add(val)); _saveFieldToFirebase('vices', _vices); }),
          child: _buildEditableWrap(items: _vices, color: Colors.grey.shade800, onAddRequest: () => _showAddDialog(categoryTitle: "Vices", onAdd: (val) { setState(() => _vices.add(val)); _saveFieldToFirebase('vices', _vices); }), onDelete: (val) { setState(() => _vices.remove(val)); _saveFieldToFirebase('vices', _vices); }),
        );
      case 'gratitudes':
        return _buildFloatingCard(
          title: "Daily Gratitude", icon: Icons.favorite_border,
          onMagicWand: () => _showBrainstormModal(categoryTitle: "Gratitude", aiContext: "Suggest things to be grateful for to maintain perspective.", onAdd: (val) { setState(() => _gratitudes.add(val)); _saveFieldToFirebase('gratitudes', _gratitudes); }),
          child: _buildEditableWrap(items: _gratitudes, color: Colors.blue.shade700, onAddRequest: () => _showAddDialog(categoryTitle: "Gratitude", onAdd: (val) { setState(() => _gratitudes.add(val)); _saveFieldToFirebase('gratitudes', _gratitudes); }), onDelete: (val) { setState(() => _gratitudes.remove(val)); _saveFieldToFirebase('gratitudes', _gratitudes); }),
        );
      case 'innerCircle':
        return _buildFloatingCard(
          title: "Inner Circle", icon: Icons.groups,
          onMagicWand: () => _showBrainstormModal(categoryTitle: "Inner Circle", aiContext: "The user is adding important people. Suggest categories like 'Mentor', 'Partner'.", onAdd: (val) { setState(() => _innerCircle.add(val)); _saveFieldToFirebase('innerCircle', _innerCircle); }),
          child: _buildEditableWrap(items: _innerCircle, color: Colors.purple.shade700, onAddRequest: () => _showAddDialog(categoryTitle: "Inner Circle", onAdd: (val) { setState(() => _innerCircle.add(val)); _saveFieldToFirebase('innerCircle', _innerCircle); }), onDelete: (val) { setState(() => _innerCircle.remove(val)); _saveFieldToFirebase('innerCircle', _innerCircle); }),
        );
      case 'aspirations':
        return _buildFloatingCard(
          title: "Aspirations", icon: Icons.star,
          onMagicWand: () => _showBrainstormModal(categoryTitle: "Aspirations", aiContext: "The user is adding their aspirations. Suggest categories like 'Career', 'Personal Growth'.", onAdd: (val) { setState(() => _aspirations.add(val)); _saveFieldToFirebase('aspirations', _aspirations); }),
          child: _buildEditableWrap(items: _aspirations, color: Colors.orange.shade700, onAddRequest: () => _showAddDialog(categoryTitle: "Aspirations", onAdd: (val) { setState(() => _aspirations.add(val)); _saveFieldToFirebase('aspirations', _aspirations); }), onDelete: (val) { setState(() => _aspirations.remove(val)); _saveFieldToFirebase('aspirations', _aspirations); }),
        );
      case 'characteristics':
        return _buildFloatingCard(
          title: "Characteristics", icon: Icons.person,
          onMagicWand: () => _showBrainstormModal(categoryTitle: "Characteristics", aiContext: "The user is adding their characteristics. Suggest categories like 'Strengths', 'Weaknesses'.", onAdd: (val) { setState(() => _characteristics.add(val)); _saveFieldToFirebase('characteristics', _characteristics); }),
          child: _buildEditableWrap(items: _characteristics, color: Colors.green.shade700, onAddRequest: () => _showAddDialog(categoryTitle: "Characteristics", onAdd: (val) { setState(() => _characteristics.add(val)); _saveFieldToFirebase('characteristics', _characteristics); }), onDelete: (val) { setState(() => _characteristics.remove(val)); _saveFieldToFirebase('characteristics', _characteristics); }),
        );
      default:
        return null;
    }
  }

  // --- HELPER WIDGETS ---

  Widget _buildEditableWrap({required List<String> items, required Color color, required Function(String) onDelete, required VoidCallback onAddRequest}) {
    List<Widget> chips = items.map<Widget>((value) => InputChip( 
      label: Text(value, style: const TextStyle(fontSize: 12)), backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), deleteIconColor: Colors.white70,
      onDeleted: () => onDelete(value), side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    )).toList();

    chips.add(ActionChip(
      label: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 14, color: Colors.black), SizedBox(width: 4), Text("Add", style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold))]),
      backgroundColor: Colors.grey.shade200, onPressed: onAddRequest, side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget _buildFloatingCard({required String title, required IconData icon, required Widget child, bool goldAccent = false, VoidCallback? onMagicWand}) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: goldAccent ? Border.all(color: _goldColor.withValues(alpha:0.5), width: 1.5) : Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: goldAccent ? _goldColor : Colors.grey.shade500), const SizedBox(width: 8),
              Text(title.toUpperCase(), style: TextStyle(color: goldAccent ? _goldColor : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0)),
              const Spacer(),
              if (onMagicWand != null)
                InkWell(
                  onTap: onMagicWand, borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: _goldColor.withValues(alpha:0.1), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [Icon(Icons.auto_awesome, size: 12, color: _goldColor), const SizedBox(width: 4), Text("Suggest", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _goldColor))]),
                  ),
                )
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // --- GLOBAL CHAT POPUP ---
  void _showGlobalChatPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          builder: (ctx, setDialogState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(children: [Icon(Icons.psychology, color: Color(0xFFBB8E13)), SizedBox(width: 8), Text("AI Life Coach", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold))]),
                        IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey.shade200, height: 1, thickness: 1),
                  Expanded(
                    child: _messages.isEmpty 
                      ? Center(child: Text("Ask me anything about your purpose...", style: TextStyle(color: Colors.grey.shade500)))
                      : ListView.builder(
                          controller: _scrollController, padding: const EdgeInsets.all(16), itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isAI = !msg.isUser;
                            
                            return Align(
                              alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6), padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: isAI ? Colors.grey.shade100 : _goldColor, border: isAI ? Border.all(color: Colors.grey.shade200) : null, borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isAI ? 0 : 16), bottomRight: Radius.circular(isAI ? 16 : 0))),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                child: SelectableText(msg.text, style: TextStyle(fontSize: 14, height: 1.4, color: isAI ? Colors.black87 : Colors.white)),
                              ),
                            );
                          },
                        ),
                  ),
                  if (_isLoading) const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: Color(0xFFBB8E13))),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey.shade200)),
                            child: TextField(
                              controller: _textController, style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(hintText: "Type a message...", hintStyle: TextStyle(color: Colors.grey.shade400), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), border: InputBorder.none),
                              onSubmitted: (_) => _sendGlobalMessage(setDialogState),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(backgroundColor: _goldColor, child: IconButton(icon: const Icon(Icons.arrow_upward, color: Colors.white), onPressed: () => _sendGlobalMessage(setDialogState))),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  Future<void> _sendGlobalMessage(StateSetter updateDialogState) async {
    final message = _textController.text.trim();
    if (message.isEmpty || _chat == null) return;
    updateDialogState(() { _messages.add(ChatMessage(text: message, isUser: true)); _isLoading = true; });
    _textController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollController.jumpTo(_scrollController.position.maxScrollExtent));
    try {
      final response = await _chat!.sendMessage(Content.text(message));
      if (response.text != null && mounted) {
        updateDialogState(() { _messages.add(ChatMessage(text: response.text!, isUser: false)); _isLoading = false; });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollController.jumpTo(_scrollController.position.maxScrollExtent));
      }
    } catch (e) {
      if (mounted) updateDialogState(() { _messages.add(ChatMessage(text: "Error: $e", isUser: false)); _isLoading = false; });
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}