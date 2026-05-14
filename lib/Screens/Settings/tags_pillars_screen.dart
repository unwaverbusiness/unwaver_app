import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:unwaver/services/app_data_service.dart';

class TagsPillarsScreen extends StatefulWidget {
  const TagsPillarsScreen({super.key});

  @override
  State<TagsPillarsScreen> createState() => _TagsPillarsScreenState();
}

class _TagsPillarsScreenState extends State<TagsPillarsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tags & Pillars', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'Tags'),
            Tab(text: 'Pillars'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _TagsTab(),
          _PillarsTab(),
        ],
      ),
    );
  }
}

// === TAGS TAB ===
class _TagsTab extends StatelessWidget {
  const _TagsTab();

  void _showTagDialog(BuildContext context, {Tag? tag}) {
    final nameController = TextEditingController(text: tag?.name ?? '');
    Color selectedColor = tag?.color ?? Colors.blue;
    bool isArchived = tag?.isArchived ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(tag == null ? 'New Tag' : 'Edit Tag'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tag Name'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Color:'),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Pick a color'),
                            content: SingleChildScrollView(
                              child: BlockPicker(
                                pickerColor: selectedColor,
                                onColorChanged: (c) => selectedColor = c,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  setState(() {});
                                  Navigator.pop(context);
                                },
                                child: const Text('Select'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(color: selectedColor, shape: BoxShape.circle),
                      ),
                    ),
                  ],
                ),
                if (tag != null) ...[
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Archived'),
                    value: isArchived,
                    onChanged: (val) => setState(() => isArchived = val),
                  ),
                ]
              ],
            ),
          ),
          actions: [
            if (tag != null)
              TextButton(
                onPressed: () {
                  context.read<AppDataService>().deleteTag(tag.id);
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                
                final service = context.read<AppDataService>();
                if (tag == null) {
                  service.addTag(Tag(
                    id: 't_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    color: selectedColor,
                  ));
                } else {
                  service.updateTag(tag.copyWith(name: name, color: selectedColor, isArchived: isArchived));
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataService>(
      builder: (context, dataService, _) {
        final tags = dataService.tags;
        
        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 16),
              itemCount: tags.length,
              itemBuilder: (context, index) {
                final tag = tags[index];
                return ListTile(
                  leading: Icon(Icons.label, color: tag.color),
                  title: Text(tag.name, style: TextStyle(decoration: tag.isArchived ? TextDecoration.lineThrough : null)),
                  trailing: const Icon(Icons.edit, size: 20, color: Colors.grey),
                  onTap: () => _showTagDialog(context, tag: tag),
                );
              },
            ),
            Positioned(
              bottom: 16, right: 16,
              child: FloatingActionButton(
                onPressed: () => _showTagDialog(context),
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }
}

// === PILLARS TAB ===
class _PillarsTab extends StatelessWidget {
  const _PillarsTab();

  void _showPillarDialog(BuildContext context, {Pillar? pillar}) {
    final nameController = TextEditingController(text: pillar?.name ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pillar == null ? 'New Pillar' : 'Edit Pillar'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Pillar Name'),
        ),
        actions: [
          if (pillar != null)
            TextButton(
              onPressed: () {
                context.read<AppDataService>().deletePillar(pillar.id);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              
              final service = context.read<AppDataService>();
              if (pillar == null) {
                service.addPillar(Pillar(
                  id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                ));
              } else {
                service.updatePillar(pillar.copyWith(name: name));
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSubPillarDialog(BuildContext context, Pillar pillar) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Sub-Pillar'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Sub-Pillar Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              
              final updatedSubs = List<String>.from(pillar.subPillars)..add(name);
              context.read<AppDataService>().updatePillar(pillar.copyWith(subPillars: updatedSubs));
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataService>(
      builder: (context, dataService, _) {
        final pillars = dataService.pillars;
        
        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 16),
              itemCount: pillars.length,
              itemBuilder: (context, index) {
                final pillar = pillars[index];
                return ExpansionTile(
                  title: Text(pillar.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showPillarDialog(context, pillar: pillar),
                      ),
                      const Icon(Icons.expand_more),
                    ],
                  ),
                  children: [
                    for (var sub in pillar.subPillars)
                      ListTile(
                        contentPadding: const EdgeInsets.only(left: 40, right: 16),
                        title: Text(sub),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          onPressed: () {
                            final updatedSubs = List<String>.from(pillar.subPillars)..remove(sub);
                            context.read<AppDataService>().updatePillar(pillar.copyWith(subPillars: updatedSubs));
                          },
                        ),
                      ),
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 40, right: 16),
                      leading: const Icon(Icons.add, color: Colors.grey),
                      title: const Text('Add Sub-Pillar', style: TextStyle(color: Colors.grey)),
                      onTap: () => _showSubPillarDialog(context, pillar),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              bottom: 16, right: 16,
              child: FloatingActionButton(
                onPressed: () => _showPillarDialog(context),
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }
}
