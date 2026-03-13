import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LifeResumeScreen extends StatefulWidget {
  const LifeResumeScreen({super.key});

  @override
  State<LifeResumeScreen> createState() => _LifeResumeScreenState();
}

class _LifeResumeScreenState extends State<LifeResumeScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;

  final Color _goldColor = const Color(0xFFBB8E13);

  final Map<String, dynamic> _resume = {
    'name': 'Nick',
    'role': 'Founder, Unwaver App',
    'email': 'unwaver.business@gmail.com',
    'location': 'Erin, Ontario, Canada',
    'summary':
        'Driven to build a life of intention and discipline. Believes in continuous growth, resilience, and building tools that empower others to achieve their ultimate potential.',
    'strengths': ['Discipline', 'Vision', 'App Development', 'Leadership'],
    'talents': ['Problem Solving', 'Strategic Planning', 'Public Speaking'],
    'skills': ['Flutter', 'Dart', 'UI/UX Design', 'Project Management'],
    'growthAreas': ['Patience', 'Delegation', 'Work-life balance'],
    'accomplishments': [
      'Founded and developed the Unwaver App from scratch.',
      'Maintained a daily workout routine for 365 consecutive days.',
      'Graduated top 5% of university class.'
    ],
    'activeGoals': [
      'Launch Unwaver V1.0 by Q3.',
      'Read 24 books this year.',
      'Run a half-marathon.'
    ],
    'routine': [
      'Wake up at 5:00 AM',
      '1 hour of deep work before 8 AM',
      'Daily meditation and journaling'
    ],
    'history': [
      'Lead Developer and Founder | Unwaver | Jan 2024 - Present',
      'University of Technology | B.S. Computer Science | 2018 - 2022'
    ],
    'allies': ['Mentor A', 'Friend B', 'Partner C'],
    'books': [
      'Atomic Habits by James Clear',
      'Deep Work by Cal Newport',
      'The Obstacle is the Way by Ryan Holiday'
    ],
    'podcasts': ['The Huberman Lab', 'How I Built This', 'Severance (TV Show)'],
  };

  String? get _uid => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadResume();
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<String> _parseStringList(dynamic data) {
    if (data is! List) return [];
    return data.map((e) => e.toString()).toList();
  }

  Future<void> _loadResume() async {
    final uid = _uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('life_resume')
          .doc('main')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _resume['name'] = data['name'] ?? _resume['name'];
          _resume['role'] = data['role'] ?? _resume['role'];
          _resume['email'] = data['email'] ?? _resume['email'];
          _resume['location'] = data['location'] ?? _resume['location'];
          _resume['summary'] = data['summary'] ?? _resume['summary'];

          _resume['strengths'] = _parseStringList(data['strengths']);
          _resume['talents'] = _parseStringList(data['talents']);
          _resume['skills'] = _parseStringList(data['skills']);
          _resume['growthAreas'] = _parseStringList(data['growthAreas']);
          _resume['accomplishments'] = _parseStringList(data['accomplishments']);
          _resume['activeGoals'] = _parseStringList(data['activeGoals']);
          _resume['routine'] = _parseStringList(data['routine']);
          _resume['history'] = _parseStringList(data['history']);
          _resume['allies'] = _parseStringList(data['allies']);
          _resume['books'] = _parseStringList(data['books']);
          _resume['podcasts'] = _parseStringList(data['podcasts']);
        });
      }
    } catch (_) {
      // Keep defaults on load failure.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveField(String field, dynamic value) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('life_resume')
          .doc('main')
          .set({field: value}, SetOptions(merge: true));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save changes.')),
      );
    }
  }

  Future<void> _editTextField({
    required String title,
    required String field,
    int maxLines = 1,
  }) async {
    final controller = TextEditingController(text: (_resume[field] ?? '').toString());

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit $title', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: 'Enter $title',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              setState(() => _resume[field] = value);
              _saveField(field, value);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _addListItem({required String field, required String title}) async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add $title', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter value',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _goldColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              setState(() {
                final list = List<String>.from(_resume[field] as List<dynamic>);
                list.add(value);
                _resume[field] = list;
              });
              _saveField(field, _resume[field]);
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _editListItem({
    required String field,
    required int index,
    required String title,
  }) async {
    final list = List<String>.from(_resume[field] as List<dynamic>);
    final controller = TextEditingController(text: list[index]);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit $title', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Update item',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              setState(() {
                list[index] = value;
                _resume[field] = list;
              });
              _saveField(field, _resume[field]);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteListItem({required String field, required int index}) {
    setState(() {
      final list = List<String>.from(_resume[field] as List<dynamic>);
      list.removeAt(index);
      _resume[field] = list;
    });
    _saveField(field, _resume[field]);
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
    VoidCallback? onEdit,
    VoidCallback? onAdd,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _goldColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              if (onEdit != null)
                IconButton(
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
              if (onAdd != null)
                IconButton(
                  tooltip: 'Add',
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildEditableChips({
    required String field,
    required Color color,
    bool weakness = false,
  }) {
    final items = List<String>.from(_resume[field] as List<dynamic>);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return InputChip(
          label: Text(item, style: const TextStyle(fontSize: 12)),
          backgroundColor: weakness
              ? Colors.red.withValues(alpha: 0.1)
              : color.withValues(alpha: 0.14),
          side: BorderSide.none,
          deleteIconColor: Colors.grey.shade700,
          onPressed: () => _editListItem(field: field, index: index, title: field),
          onDeleted: () => _deleteListItem(field: field, index: index),
        );
      }).toList(),
    );
  }

  Widget _buildEditableBullets(String field) {
    final items = List<String>.from(_resume[field] as List<dynamic>);
    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(child: Text(item, style: const TextStyle(height: 1.4))),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _editListItem(field: field, index: index, title: field),
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _deleteListItem(field: field, index: index),
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Life Resume',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (_isLoading)
            LinearProgressIndicator(
              color: _goldColor,
              backgroundColor: Colors.transparent,
              minHeight: 3,
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _buildCard(
                  title: 'Identity',
                  icon: Icons.person_outline,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.black,
                        child: Text(
                          (_resume['name'] as String).isNotEmpty
                              ? (_resume['name'] as String)[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: _goldColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInlineEditableText('name', _resume['name'] as String),
                            const SizedBox(height: 4),
                            _buildInlineEditableText('role', _resume['role'] as String),
                            const SizedBox(height: 4),
                            _buildInlineEditableText('email', _resume['email'] as String),
                            const SizedBox(height: 4),
                            _buildInlineEditableText('location', _resume['location'] as String),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCard(
                  title: 'Executive Summary & Purpose',
                  icon: Icons.flag_outlined,
                  onEdit: () => _editTextField(
                    title: 'Summary',
                    field: 'summary',
                    maxLines: 6,
                  ),
                  child: Text(
                    _resume['summary'] as String,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
                _buildCard(
                  title: 'Core Competencies',
                  icon: Icons.workspace_premium_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSubLabel('Strengths', onAdd: () => _addListItem(field: 'strengths', title: 'Strength')),
                      _buildEditableChips(field: 'strengths', color: _goldColor),
                      const SizedBox(height: 10),
                      _buildSubLabel('Talents', onAdd: () => _addListItem(field: 'talents', title: 'Talent')),
                      _buildEditableChips(field: 'talents', color: Colors.blue),
                      const SizedBox(height: 10),
                      _buildSubLabel('Skills', onAdd: () => _addListItem(field: 'skills', title: 'Skill')),
                      _buildEditableChips(field: 'skills', color: Colors.black),
                      const SizedBox(height: 10),
                      _buildSubLabel('Areas for Growth', onAdd: () => _addListItem(field: 'growthAreas', title: 'Growth Area')),
                      _buildEditableChips(field: 'growthAreas', color: Colors.red, weakness: true),
                    ],
                  ),
                ),
                _buildCard(
                  title: 'Greatest Accomplishments',
                  icon: Icons.emoji_events_outlined,
                  onAdd: () => _addListItem(field: 'accomplishments', title: 'Accomplishment'),
                  child: _buildEditableBullets('accomplishments'),
                ),
                _buildCard(
                  title: 'Current Objectives',
                  icon: Icons.track_changes_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSubLabel('Active Goals', onAdd: () => _addListItem(field: 'activeGoals', title: 'Goal')),
                      _buildEditableBullets('activeGoals'),
                      const SizedBox(height: 8),
                      _buildSubLabel('Daily Routine & Habits', onAdd: () => _addListItem(field: 'routine', title: 'Habit')),
                      _buildEditableBullets('routine'),
                    ],
                  ),
                ),
                _buildCard(
                  title: 'History',
                  icon: Icons.history_outlined,
                  onAdd: () => _addListItem(field: 'history', title: 'History Item'),
                  child: _buildEditableBullets('history'),
                ),
                _buildCard(
                  title: 'Inner Circle & Environment',
                  icon: Icons.groups_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSubLabel('Location', onEdit: () => _editTextField(title: 'Location', field: 'location')),
                      Text(_resume['location'] as String),
                      const SizedBox(height: 12),
                      _buildSubLabel('Closest Allies', onAdd: () => _addListItem(field: 'allies', title: 'Ally')),
                      _buildEditableChips(field: 'allies', color: Colors.green),
                    ],
                  ),
                ),
                _buildCard(
                  title: 'Media & Consumption Diet',
                  icon: Icons.headphones_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSubLabel('Recently Read', onAdd: () => _addListItem(field: 'books', title: 'Book')),
                      _buildEditableBullets('books'),
                      const SizedBox(height: 8),
                      _buildSubLabel('Podcasts & Shows', onAdd: () => _addListItem(field: 'podcasts', title: 'Podcast/Show')),
                      _buildEditableBullets('podcasts'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineEditableText(String field, String value) {
    return InkWell(
      onTap: () => _editTextField(title: field, field: field),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          value,
          style: TextStyle(
            fontSize: field == 'name' ? 24 : 14,
            fontWeight: field == 'name' ? FontWeight.w800 : FontWeight.w500,
            color: field == 'email' ? Colors.grey.shade700 : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildSubLabel(String text, {VoidCallback? onAdd, VoidCallback? onEdit}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        if (onEdit != null)
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
        if (onAdd != null)
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline, size: 18),
          ),
      ],
    );
  }
}
