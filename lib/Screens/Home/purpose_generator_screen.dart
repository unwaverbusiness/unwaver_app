import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
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

  // Dynamic Lists for the Dashboard (Upgraded to Maps for interactive notes)
  List<Map<String, dynamic>> _coreValues = [];
  List<Map<String, dynamic>> _priorities = [];
  List<Map<String, dynamic>> _identityStatements = [];
  List<Map<String, dynamic>> _strengths = [];
  List<Map<String, dynamic>> _weaknesses = [];
  List<Map<String, dynamic>> _vices = [];
  List<Map<String, dynamic>> _gratitudes = [];
  List<Map<String, dynamic>> _innerCircle = [];
  List<Map<String, dynamic>> _innerCircleSections = [];
  List<Map<String, dynamic>> _aspirations = [];
  List<Map<String, dynamic>> _characteristics = [];

  // Card visibility preferences
  Map<String, bool> _cardVisibility = {
    'purpose': true,
    'priorities': true,
    'coreValues': true,
    'identityStatements': true,
    'strengthsAndWeaknesses': true,
    'vices': true,
    'gratitudes': true,
    'innerCircle': true,
    'aspirations': true,
    'characteristics': true,
  };

  // Card Expand/Collapse tracking
  final Map<String, bool> _cardExpanded = {
    'purpose': true,
    'priorities': true,
    'coreValues': true,
    'identityStatements': true,
    'strengthsAndWeaknesses': true,
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
    'strengthsAndWeaknesses', 
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
    'strengthsAndWeaknesses': {'title': 'Strengths & Weaknesses', 'icon': Icons.balance}, 
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

  void _setupAI() {
    try {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: ApiKeyManager.geminiKey,
        systemInstruction: Content.system(
          "You are an AI Life Coach helping the user align their life with their purpose. "
          "User's Goals: $_userGoals. User's Habits: $_userHabits. "
          "Provide thoughtful, personalized guidance based on their life context."
        ),
      );
      _chat = _model.startChat();
    } catch (e) {
      debugPrint("Error initializing AI: $e");
    }
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

  // Migration Helper: Converts old String lists to new Map lists automatically
  List<Map<String, dynamic>> _parseItemList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((e) {
        if (e is String) return {'title': e, 'notes': ''}; // Migrates old strings
        if (e is Map) return Map<String, dynamic>.from(e);
        return {'title': e.toString(), 'notes': ''};
      }).toList();
    }
    return [];
  }

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
          
          _coreValues = _parseItemList(data['coreValues']);
          _priorities = _parseItemList(data['priorities']);
          _identityStatements = _parseItemList(data['identityStatements']);
          _strengths = _parseItemList(data['strengths']);
          _weaknesses = _parseItemList(data['weaknesses']);
          _vices = _parseItemList(data['vices']);
          _gratitudes = _parseItemList(data['gratitudes']);
          _aspirations = _parseItemList(data['aspirations']);
          _characteristics = _parseItemList(data['characteristics']);
          
          // Custom parsing for Inner Circle to ensure categories exist
          _innerCircle = _parseItemList(data['innerCircle']).map((e) {
            if (!e.containsKey('category')) e['category'] = 'Friends'; // Default fallback
            return e;
          }).toList();
          
          _innerCircleSections = _parseItemList(data['innerCircleSections']);
          if (_innerCircleSections.isEmpty) {
            _innerCircleSections = [
              {'title': 'Partner', 'isHidden': false},
              {'title': 'Best Friend', 'isHidden': false},
              {'title': 'Parents', 'isHidden': false},
              {'title': 'Siblings', 'isHidden': false},
              {'title': 'Friends', 'isHidden': false},
              {'title': 'Extended Family', 'isHidden': false},
            ];
          }
          
          if (data['cardVisibility'] != null) {
            final visibility = Map<String, dynamic>.from(data['cardVisibility']);
            _cardVisibility = visibility.map((key, value) => MapEntry(key, value as bool));
            
            if (_cardVisibility.containsKey('strengths') || _cardVisibility.containsKey('weaknesses')) {
              _cardVisibility['strengthsAndWeaknesses'] = (_cardVisibility['strengths'] ?? true) || (_cardVisibility['weaknesses'] ?? true);
              _cardVisibility.remove('strengths');
              _cardVisibility.remove('weaknesses');
            }
          }
          
          if (data['cardOrder'] != null) {
            _cardOrder = List<String>.from(data['cardOrder']);
            
            if (_cardOrder.contains('strengths') || _cardOrder.contains('weaknesses')) {
              _cardOrder.remove('strengths');
              _cardOrder.remove('weaknesses');
              if (!_cardOrder.contains('strengthsAndWeaknesses')) {
                _cardOrder.insert(4, 'strengthsAndWeaknesses');
              }
            }
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

  void _savePurpose() => _saveFieldToFirebase('purpose', _purposeController.text.trim());
  void _saveCardVisibility() => _saveFieldToFirebase('cardVisibility', _cardVisibility);
  void _saveCardOrder() => _saveFieldToFirebase('cardOrder', _cardOrder);

  // --- UI INTERACTIVE DIALOGS ---

  void _showItemDetailDialog({
    required String categoryTitle,
    required Map<String, dynamic> item,
    required VoidCallback onSave,
  }) {
    final titleCtrl = TextEditingController(text: item['title']);
    final notesCtrl = TextEditingController(text: item['notes'] ?? "");
    double rank = (item['rank'] as num?)?.toDouble() ?? 7.0;
    Color selectedColor = item['color'] != null ? Color(item['color']) : _goldColor;
    int? selectedIconCode = item['icon'];

    List<String> traits = item['traits'] != null ? List<String>.from(item['traits']) : [];
    final traitCtrl = TextEditingController();

    final List<Color> palette = [
      _goldColor, Colors.black, Colors.grey.shade800, Colors.red.shade700, 
      Colors.green.shade700, Colors.blue.shade700, Colors.purple.shade700, Colors.orange.shade700, Colors.teal.shade700
    ];

    final List<IconData> iconOptions = [
      Icons.star, Icons.person, Icons.favorite, Icons.shield, Icons.workspace_premium, 
      Icons.gpp_good, Icons.flag, Icons.bolt, Icons.local_fire_department, Icons.diamond
    ];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(maxWidth: 500, maxHeight: MediaQuery.of(ctx).size.height * 0.9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (selectedIconCode != null) ...[Icon(IconData(selectedIconCode!, fontFamily: 'MaterialIcons'), color: selectedColor, size: 28), const SizedBox(width: 8)],
                          Text("Edit $categoryTitle", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          const Text("Title", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: titleCtrl,
                            decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                          ),
                          const SizedBox(height: 16),
                          const Text("Importance Rank (1-10)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Row(
                            children: [
                              Text(rank.toInt().toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: selectedColor)),
                              Expanded(
                                child: Slider(
                                  value: rank, min: 1, max: 10, divisions: 9,
                                  activeColor: selectedColor, inactiveColor: selectedColor.withValues(alpha: 0.2),
                                  onChanged: (val) => setDialogState(() => rank = val),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text("Visual Customization", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: palette.map((c) => GestureDetector(
                                onTap: () => setDialogState(() => selectedColor = c),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8), width: 36, height: 36,
                                  decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: selectedColor == c ? Colors.black : Colors.transparent, width: 2)),
                                ),
                              )).toList(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                  GestureDetector(
                                    onTap: () => setDialogState(() => selectedIconCode = null),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: selectedIconCode == null ? Colors.black : Colors.transparent)),
                                      child: const Text("None", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ...iconOptions.map((icon) => GestureDetector(
                                  onTap: () => setDialogState(() => selectedIconCode = icon.codePoint),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: selectedIconCode == icon.codePoint ? Colors.black : Colors.transparent)),
                                    child: Icon(icon, color: selectedColor),
                                  ),
                                )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text("Traits (Characteristics/Tags)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          if (traits.isNotEmpty)
                            Wrap(
                              spacing: 6, runSpacing: 6,
                              children: traits.map((t) => Chip(
                                label: Text(t, style: const TextStyle(fontSize: 12)),
                                deleteIcon: const Icon(Icons.close, size: 14),
                                onDeleted: () => setDialogState(() => traits.remove(t)),
                              )).toList(),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: traitCtrl,
                                  decoration: InputDecoration(hintText: "Add a trait...", filled: true, fillColor: Colors.grey.shade50, contentPadding: const EdgeInsets.symmetric(horizontal: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                                  onSubmitted: (val) {
                                    if (val.trim().isNotEmpty) {
                                      setDialogState(() { traits.add(val.trim()); traitCtrl.clear(); });
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.add_circle, color: selectedColor),
                                onPressed: () {
                                    if (traitCtrl.text.trim().isNotEmpty) {
                                      setDialogState(() { traits.add(traitCtrl.text.trim()); traitCtrl.clear(); });
                                    }
                                }
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text("Notes & Reflections", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: notesCtrl, maxLines: 5,
                            decoration: InputDecoration(hintText: "Why is this important?", filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: selectedColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        if (titleCtrl.text.trim().isNotEmpty) {
                          item['title'] = titleCtrl.text.trim();
                          item['notes'] = notesCtrl.text.trim();
                          item['rank'] = rank.toInt();
                          // ignore: deprecated_member_use
                          item['color'] = selectedColor.value;
                          item['icon'] = selectedIconCode;
                          item['traits'] = traits;
                          onSave();
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text("Save Value", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  void _showAddDialog({required String categoryTitle, required Function(Map<String, dynamic>) onAdd}) {
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
              if (addCtrl.text.trim().isNotEmpty) { 
                onAdd({'title': addCtrl.text.trim(), 'notes': ''}); 
                Navigator.pop(ctx); 
              }
            },
            child: const Text("Add", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddInnerCircleDialog({required String defaultCategory}) {
    final TextEditingController nameCtrl = TextEditingController();
    
    // Filter categories that have reached their limits
    final allCategories = _innerCircleSections.map((s) => s['title'] as String).toList();
    final availableCategories = allCategories.where((c) {
      final count = _innerCircle.where((e) => e['category'] == c).length;
      if (c == 'Partner' && count >= 1) return false;
      if (c == 'Best Friend' && count >= 3) return false;
      if (c == 'Parents' && count >= 4) return false;
      return true;
    }).toList();

    if (availableCategories.isEmpty) return; // Super edge case

    String selectedCategory = availableCategories.contains(defaultCategory) 
        ? defaultCategory 
        : availableCategories.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("Add to Inner Circle", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl, autofocus: true,
                  decoration: InputDecoration(labelText: "Name", filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 16),
                const Text("Relationship", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      items: availableCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                      onChanged: (val) { if (val != null) setDialogState(() => selectedCategory = val); },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () {
                  if (nameCtrl.text.trim().isNotEmpty) { 
                    setState(() {
                      _innerCircle.add({
                        'title': nameCtrl.text.trim(),
                        'category': selectedCategory,
                        'notes': ''
                      });
                      _saveFieldToFirebase('innerCircle', _innerCircle);
                    });
                    Navigator.pop(ctx); 
                  }
                },
                child: const Text("Add", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  // --- DYNAMIC CARD BUILDER ---

  Widget? _buildCardByKey(String key) {
    if (!(_cardVisibility[key] ?? true)) return null;

    switch (key) {
      case 'purpose':
        return _buildFloatingCard(
          cardKey: key, title: "Purpose", icon: Icons.star, goldAccent: true,
          onMagicWand: () => _showBrainstormModal(categoryTitle: "Purpose", buttonText: "Apply", aiContext: "Help the user write a single, powerful sentence that defines their ultimate purpose.", onAdd: (val) { setState(() => _purposeController.text = val); _savePurpose(); }),
          child: Focus(
            onFocusChange: (hasFocus) { if (!hasFocus) _savePurpose(); },
            child: TextField(controller: _purposeController, maxLines: 3, style: const TextStyle(fontSize: 18, height: 1.5, fontWeight: FontWeight.w500), decoration: InputDecoration(border: InputBorder.none, hintText: "What is your ultimate purpose?", hintStyle: TextStyle(color: Colors.grey.shade400))),
          ),
        );
      case 'priorities':
        return _buildFloatingCard(
          cardKey: key, title: "Top Priorities", icon: Icons.low_priority,
          onMagicWand: () => _showBrainstormModal(categoryTitle: "Priorities", aiContext: "Suggest broad, essential life priorities based on their purpose.", onAdd: (val) { setState(() => _priorities.add({'title': val, 'notes': ''})); _saveFieldToFirebase('priorities', _priorities); }),
          onCustomizeElements: () => _showElementsCustomizeDialog(categoryTitle: "Priorities", collectionKey: "priorities", items: _priorities),
          child: _buildEditableWrap(items: _priorities, color: Colors.black, categoryTitle: "Priority", collectionKey: "priorities"),
        );
      case 'coreValues':
        return _buildFloatingCard(
          cardKey: key, title: "Core Values", icon: Icons.diamond,
          onMagicWand: () => _showBrainstormModal(categoryTitle: "Core Values", aiContext: "Suggest one-word core values.", onAdd: (val) { setState(() => _coreValues.add({'title': val, 'notes': ''})); _saveFieldToFirebase('coreValues', _coreValues); }),
          onCustomizeElements: () => _showElementsCustomizeDialog(categoryTitle: "Core Values", collectionKey: "coreValues", items: _coreValues),
          child: _buildEditableWrap(items: _coreValues, color: _goldColor, categoryTitle: "Core Value", collectionKey: "coreValues"),
        );
      case 'identityStatements':
        return _buildFloatingCard(
          cardKey: key, title: "Identity Statements", icon: Icons.fingerprint,
          onMagicWand: () => _showBrainstormModal(categoryTitle: "Identity", aiContext: "Suggest powerful statements starting with 'I am', 'I will', or 'I create'.", onAdd: (val) { setState(() => _identityStatements.add({'title': val, 'notes': ''})); _saveFieldToFirebase('identityStatements', _identityStatements); }),
          onCustomizeElements: () => _showElementsCustomizeDialog(categoryTitle: "Identity Statements", collectionKey: "identityStatements", items: _identityStatements),
          child: _buildEditableWrap(items: _identityStatements, color: Colors.grey.shade800, categoryTitle: "Identity Statement", collectionKey: "identityStatements"),
        );
      case 'strengthsAndWeaknesses':
        return _buildFloatingCard(
          cardKey: key, title: "Strengths & Weaknesses", icon: Icons.balance,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("STRENGTHS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                          Row(
                            children: [
                              InkWell(
                                onTap: () => _showElementsCustomizeDialog(categoryTitle: "Strengths", collectionKey: "strengths", items: _strengths),
                                child: Icon(Icons.tune, size: 16, color: Colors.grey.shade500),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _showBrainstormModal(categoryTitle: "Strengths", aiContext: "Suggest personal strengths needed for this mission.", onAdd: (val) { setState(() => _strengths.add({'title': val, 'notes': ''})); _saveFieldToFirebase('strengths', _strengths); }),
                                child: Icon(Icons.auto_awesome, size: 16, color: _goldColor),
                              ),
                            ]
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildEditableWrap(items: _strengths, color: Colors.green.shade700, categoryTitle: "Strength", collectionKey: "strengths"),
                    ],
                  ),
                ),
                VerticalDivider(color: Colors.grey.shade200, thickness: 1, width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("WEAKNESSES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                          Row(
                            children: [
                              InkWell(
                                onTap: () => _showElementsCustomizeDialog(categoryTitle: "Weaknesses", collectionKey: "weaknesses", items: _weaknesses),
                                child: Icon(Icons.tune, size: 16, color: Colors.grey.shade500),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _showBrainstormModal(categoryTitle: "Weaknesses", aiContext: "Suggest typical blind spots.", onAdd: (val) { setState(() => _weaknesses.add({'title': val, 'notes': ''})); _saveFieldToFirebase('weaknesses', _weaknesses); }),
                                child: Icon(Icons.auto_awesome, size: 16, color: _goldColor),
                              ),
                            ]
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildEditableWrap(items: _weaknesses, color: Colors.red.shade700, categoryTitle: "Weakness", collectionKey: "weaknesses"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      case 'vices':
        return _buildFloatingCard(
          cardKey: key, title: "Vices to Conquer", icon: Icons.shield_outlined,
          onMagicWand: () => _showBrainstormModal(categoryTitle: "Vices", aiContext: "Suggest bad habits that would destroy this mission.", onAdd: (val) { setState(() => _vices.add({'title': val, 'notes': ''})); _saveFieldToFirebase('vices', _vices); }),
          onCustomizeElements: () => _showElementsCustomizeDialog(categoryTitle: "Vices", collectionKey: "vices", items: _vices),
          child: _buildEditableWrap(items: _vices, color: Colors.grey.shade800, categoryTitle: "Vice", collectionKey: "vices"),
        );
      case 'gratitudes':
        return _buildFloatingCard(
          cardKey: key, title: "Daily Gratitude", icon: Icons.favorite_border,
          onMagicWand: () => _showBrainstormModal(categoryTitle: "Gratitude", aiContext: "Suggest things to be grateful for to maintain perspective.", onAdd: (val) { setState(() => _gratitudes.add({'title': val, 'notes': ''})); _saveFieldToFirebase('gratitudes', _gratitudes); }),
          onCustomizeElements: () => _showElementsCustomizeDialog(categoryTitle: "Gratitudes", collectionKey: "gratitudes", items: _gratitudes),
          child: _buildEditableWrap(items: _gratitudes, color: Colors.blue.shade700, categoryTitle: "Gratitude", collectionKey: "gratitudes"),
        );
      case 'innerCircle':
        return _buildFloatingCard(
          cardKey: key, title: "Inner Circle", icon: Icons.groups,
          onCustomizeElements: () => _showElementsCustomizeDialog(categoryTitle: "Inner Circle Sections", collectionKey: "innerCircleSections", items: _innerCircleSections),
          child: _buildInnerCircleContent(),
        );
      case 'aspirations':
        return _buildFloatingCard(
          cardKey: key, title: "Aspirations", icon: Icons.star,
          onMagicWand: () => _showBrainstormModal(categoryTitle: "Aspirations", aiContext: "Suggest future ambitions and aspirations.", onAdd: (val) { setState(() => _aspirations.add({'title': val, 'notes': ''})); _saveFieldToFirebase('aspirations', _aspirations); }),
          onCustomizeElements: () => _showElementsCustomizeDialog(categoryTitle: "Aspirations", collectionKey: "aspirations", items: _aspirations),
          child: _buildEditableWrap(items: _aspirations, color: Colors.orange.shade700, categoryTitle: "Aspiration", collectionKey: "aspirations"),
        );
      case 'characteristics':
        return _buildFloatingCard(
          cardKey: key, title: "Characteristics", icon: Icons.person,
          onMagicWand: () => _showBrainstormModal(categoryTitle: "Characteristics", aiContext: "Suggest defining personal characteristics.", onAdd: (val) { setState(() => _characteristics.add({'title': val, 'notes': ''})); _saveFieldToFirebase('characteristics', _characteristics); }),
          onCustomizeElements: () => _showElementsCustomizeDialog(categoryTitle: "Characteristics", collectionKey: "characteristics", items: _characteristics),
          child: _buildEditableWrap(items: _characteristics, color: Colors.green.shade700, categoryTitle: "Characteristic", collectionKey: "characteristics"),
        );
      default:
        return null;
    }
  }

  void _showElementsCustomizeDialog({
    required String categoryTitle,
    required String collectionKey,
    required List<Map<String, dynamic>> items,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(maxWidth: 400, maxHeight: MediaQuery.of(context).size.height * 0.8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune, color: _goldColor, size: 24),
                          const SizedBox(width: 12),
                          Text("Customize $categoryTitle", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Drag to reorder • Tap eye to show/hide", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 8),
                  
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text("No items to customize yet.")),
                    )
                  else
                    Flexible(
                      child: ReorderableListView.builder(
                        shrinkWrap: true, buildDefaultDragHandles: false, itemCount: items.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final item = items.removeAt(oldIndex);
                            items.insert(newIndex, item);
                            _saveFieldToFirebase(collectionKey, items);
                          });
                          setDialogState(() {});
                        },
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final bool isVisible = !(item['isHidden'] == true);
                          
                          return Container(
                            key: ValueKey('${item['title']}_$index'),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isVisible ? Colors.white : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: ReorderableDragStartListener(
                                index: index,
                                child: Icon(Icons.drag_indicator, color: Colors.grey.shade400),
                              ),
                              title: Text(item['title'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: isVisible ? Colors.black : Colors.grey.shade500, decoration: isVisible ? null : TextDecoration.lineThrough)),
                              subtitle: item['category'] != null ? Text(item['category'], style: const TextStyle(fontSize: 12)) : null,
                              trailing: IconButton(
                                icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: isVisible ? _goldColor : Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    item['isHidden'] = isVisible;
                                    _saveFieldToFirebase(collectionKey, items);
                                  });
                                  setDialogState(() {});
                                },
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

  // --- HELPER WIDGETS ---

  // Refactored Wrap to handle the Maps, detailed editing, and dynamic saves
  Widget _buildEditableWrap({
    required List<Map<String, dynamic>> items, 
    required Color color, 
    required String categoryTitle, 
    required String collectionKey,
  }) {
    List<Widget> chips = items
      .where((item) => item['isHidden'] != true)
      .map<Widget>((item) {
        final chipColor = item['color'] != null ? Color(item['color']) : color;
        final iconCode = item['icon'];
        
        return InputChip(
          avatar: iconCode != null ? Icon(IconData(iconCode, fontFamily: 'MaterialIcons'), size: 16, color: Colors.white) : null,
          label: Text(item['title'], style: const TextStyle(fontSize: 12)), backgroundColor: chipColor,
          labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), deleteIconColor: Colors.white70,
          onPressed: () {
            _showItemDetailDialog(
              categoryTitle: categoryTitle, 
              item: item, 
              onSave: () {
                setState(() {});
                _saveFieldToFirebase(collectionKey, items);
              }
            );
          },
          onDeleted: () {
            setState(() => items.remove(item));
            _saveFieldToFirebase(collectionKey, items);
          }, 
          side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
      }).toList();

    chips.add(ActionChip(
      label: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 14, color: Colors.black), SizedBox(width: 4), Text("Add", style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold))]),
      backgroundColor: Colors.grey.shade200, 
      onPressed: () => _showAddDialog(
        categoryTitle: categoryTitle, 
        onAdd: (newItemMap) { 
          setState(() => items.add(newItemMap)); 
          _saveFieldToFirebase(collectionKey, items); 
        }
      ), 
      side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  // Specific builder for Inner Circle to organize by exact categories
  Widget _buildInnerCircleContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _innerCircleSections.where((s) => s['isHidden'] != true).map((sectionMap) {
        final cat = sectionMap['title'] as String;
        final categoryItems = _innerCircle.where((e) => e['category'] == cat).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 6, top: 8),
              child: Text(cat.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 0, 0, 0), letterSpacing: 0.5)),
            ),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                ...categoryItems.where((e) => e['isHidden'] != true).map((item) {
                  final chipColor = item['color'] != null ? Color(item['color']) : const Color.fromARGB(255, 0, 0, 0);
                  final iconCode = item['icon'];
                  
                  return InputChip(
                    avatar: iconCode != null ? Icon(IconData(iconCode, fontFamily: 'MaterialIcons'), size: 16, color: Colors.white) : null,
                    label: Text(item['title'], style: const TextStyle(fontSize: 12)), backgroundColor: chipColor,
                    labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), deleteIconColor: Colors.white70,
                    onPressed: () {
                      _showItemDetailDialog(
                        categoryTitle: "Relationship", 
                        item: item, 
                        onSave: () {
                          setState(() {});
                          _saveFieldToFirebase('innerCircle', _innerCircle);
                        }
                      );
                    },
                    onDeleted: () {
                      setState(() => _innerCircle.remove(item));
                      _saveFieldToFirebase('innerCircle', _innerCircle);
                    }, 
                    side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  );
                }),
                if ((cat == 'Partner' && categoryItems.isNotEmpty) ||
                    (cat == 'Best Friend' && categoryItems.length >= 3) ||
                    (cat == 'Parents' && categoryItems.length >= 4))
                  const SizedBox.shrink()
                else
                  ActionChip(
                    label: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 14, color: Colors.black), SizedBox(width: 4), Text("Add", style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold))]),
                    backgroundColor: Colors.grey.shade200, 
                    onPressed: () => _showAddInnerCircleDialog(defaultCategory: cat), 
                    side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  )
              ],
            ),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFloatingCard({required String cardKey, required String title, required IconData icon, required Widget child, bool goldAccent = false, VoidCallback? onMagicWand, VoidCallback? onCustomizeElements}) {
    bool isExpanded = _cardExpanded[cardKey] ?? true;

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
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: _goldColor.withValues(alpha:0.1), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [Icon(Icons.auto_awesome, size: 12, color: _goldColor), const SizedBox(width: 4), Text("Suggest", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _goldColor))]),
                  ),
                ),
              if (onCustomizeElements != null)
                InkWell(
                  onTap: onCustomizeElements,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(Icons.tune, size: 16, color: Colors.grey.shade500),
                  ),
                ),
              InkWell(
                onTap: () => setState(() => _cardExpanded[cardKey] = !isExpanded),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey.shade500),
                ),
              )
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isExpanded 
              ? Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: child,
                )
              : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  // --- BRAINSTORM MODAL (Updated) ---
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

  // --- SETTINGS AND GLOBAL CHAT MODALS ---
  
  void _showCardVisibilitySettings() {
    _cardFilterController.clear();
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: StatefulBuilder(
          builder: (ctx, setDialogState) {
            
            final filteredCardOrder = _cardOrder.where((key) {
              final metadata = _cardMetadata[key];
              final title = metadata?['title']?.toString().toLowerCase() ?? '';
              final searchTerm = _cardFilterController.text.toLowerCase();
              return title.contains(searchTerm);
            }).toList();

            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(maxWidth: 400, maxHeight: MediaQuery.of(context).size.height * 0.8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  
                  TextField(
                    controller: _cardFilterController, style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Search cards...", hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search, color: _goldColor),
                      suffixIcon: _cardFilterController.text.isNotEmpty ? IconButton(icon: Icon(Icons.clear, color: Colors.grey.shade400), onPressed: () { _cardFilterController.clear(); setDialogState(() {}); }) : null,
                      filled: true, fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 8),
                  
                  Flexible(
                    child: ReorderableListView.builder(
                      shrinkWrap: true, buildDefaultDragHandles: false, itemCount: filteredCardOrder.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final item = _cardOrder.removeAt(_cardOrder.indexOf(filteredCardOrder[oldIndex]));
                          final newActualIndex = newIndex == filteredCardOrder.length - 1 ? _cardOrder.length : _cardOrder.indexOf(filteredCardOrder[newIndex]);
                          _cardOrder.insert(newActualIndex, item);
                        });
                        setDialogState(() {}); _saveCardOrder();
                      },
                      itemBuilder: (context, index) {
                        final key = filteredCardOrder[index];
                        final metadata = _cardMetadata[key];
                        final title = metadata?['title'] ?? key;
                        final icon = metadata?['icon'] ?? Icons.card_membership;
                        final isVisible = _cardVisibility[key] ?? true;
                        
                        return Container(
                          key: ValueKey(key), margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(color: isVisible ? _goldColor.withValues(alpha: 0.05) : Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: isVisible ? _goldColor.withValues(alpha: 0.3) : Colors.grey.shade300, width: 1.5)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            child: Row(
                              children: [
                                ReorderableDragStartListener(index: index, child: Padding(padding: const EdgeInsets.only(right: 12), child: Icon(Icons.drag_indicator, size: 20, color: Colors.grey.shade400))),
                                Icon(icon, size: 20, color: isVisible ? _goldColor : Colors.grey.shade400),
                                const SizedBox(width: 12),
                                Expanded(child: GestureDetector(onTap: () { setState(() { _cardVisibility[key] = !isVisible; }); setDialogState(() {}); _saveCardVisibility(); }, behavior: HitTestBehavior.opaque, child: Text(title, style: TextStyle(fontSize: 15, fontWeight: isVisible ? FontWeight.w600 : FontWeight.normal, color: isVisible ? Colors.black87 : Colors.grey.shade500)))),
                                GestureDetector(onTap: () { setState(() { _cardVisibility[key] = !isVisible; }); setDialogState(() {}); _saveCardVisibility(); }, child: Container(padding: const EdgeInsets.all(4), color: Colors.transparent, child: Icon(isVisible ? Icons.visibility : Icons.visibility_off, size: 20, color: isVisible ? _goldColor : Colors.grey.shade400))),
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

  // --- MAIN UI LAYOUT ---
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
                    return Padding(padding: const EdgeInsets.only(bottom: 16), child: card);
                  }),
                  const SizedBox(height: 100), 
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