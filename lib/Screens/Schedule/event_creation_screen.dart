import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:unwaver/services/app_data_service.dart';
import 'schedule_screen.dart'; // To get ScheduleItem and ItemType

class EventCreationScreen extends StatefulWidget {
  const EventCreationScreen({super.key});

  @override
  State<EventCreationScreen> createState() => _EventCreationScreenState();
}

class _EventCreationScreenState extends State<EventCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _invitesController = TextEditingController();

  String _selectedPillar = '';
  final List<Tag> _selectedTags = [];

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
  
  Color _selectedColor = Colors.blue.shade600;
  bool _isSaving = false;

  final List<Color> _colorOptions = [
    Colors.blue.shade600,
    Colors.purple.shade400,
    Colors.green.shade600,
    Colors.red.shade400,
    Colors.orange.shade600,
    const Color(0xFFD4AF37), // Gold
    Colors.indigo.shade400,
    Colors.teal.shade500,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _invitesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, {required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _selectedColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Ensure end date is not before start date
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime(BuildContext context, {required bool isStart}) async {
    final initialTime = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _selectedColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _showTagPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeTags = context.read<AppDataService>().activeTags;
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Select Tags", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (activeTags.isEmpty)
                    const Text("No tags available. Create some in the Tags menu!")
                  else
                    Wrap(
                      spacing: 8,
                      children: activeTags.map((tag) {
                        final isSelected = _selectedTags.any((t) => t.id == tag.id);
                        return FilterChip(
                          label: Text(tag.name),
                          selected: isSelected,
                          selectedColor: tag.color.withValues(alpha: 0.3),
                          checkmarkColor: tag.color,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedTags.add(tag);
                              } else {
                                _selectedTags.removeWhere((t) => t.id == tag.id);
                              }
                            });
                            setModalState(() {});
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                      child: const Text("Done"),
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  void _saveEvent() {
    if (_formKey.currentState!.validate() && !_isSaving) {
      setState(() => _isSaving = true);
      FocusScope.of(context).unfocus();

      // Calculate duration
      final startDT = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
      final endDT = DateTime(_endDate.year, _endDate.month, _endDate.day, _endTime.hour, _endTime.minute);
      final duration = endDT.difference(startDT).inMinutes;

      final newItem = ScheduleItem(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        type: ItemType.event,
        scheduledDate: DateTime(_startDate.year, _startDate.month, _startDate.day),
        startTime: _startTime,
        durationMinutes: duration > 0 ? duration : 60,
        color: _selectedColor,
        isAllDay: false,
        isNativeSync: false,
      );

      // Pop and return the new item
      Navigator.of(context).pop(newItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("New Event", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveEvent,
            child: const Text("Save", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TITLE
              TextFormField(
                controller: _titleController,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Event Title",
                  hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
                  border: InputBorder.none,
                ),
                validator: (val) => val == null || val.trim().isEmpty ? "Title is required" : null,
              ),
              const SizedBox(height: 16),

              // COLOR SELECTOR
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colorOptions.length,
                  itemBuilder: (context, index) {
                    final color = _colorOptions[index];
                    final isSelected = color == _selectedColor;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 40,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // PILLAR SELECTOR
              _buildLabel("Life Pillar"),
              Consumer<AppDataService>(
                builder: (context, dataService, _) {
                  final pillars = dataService.pillars.map((p) => p.name).toList();
                  if (pillars.isEmpty) return const Text("No pillars available.");
                  if (_selectedPillar.isEmpty || !pillars.contains(_selectedPillar)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() => _selectedPillar = pillars.first);
                    });
                  }
                  return _buildDropdown(pillars, _selectedPillar, (val) => setState(() => _selectedPillar = val!));
                }
              ),
              const SizedBox(height: 20),

              // TAGS
              _buildLabel("Tags"),
              InkWell(
                onTap: _showTagPicker,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Wrap(
                    spacing: 8,
                    children: _selectedTags.isEmpty
                        ? [Text("Select tags...", style: TextStyle(color: Colors.grey.shade400))]
                        : _selectedTags.map((tag) => Chip(
                              label: Text(tag.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                              backgroundColor: tag.color,
                              onDeleted: () => setState(() => _selectedTags.removeWhere((t) => t.id == tag.id)),
                            )).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // TIMELINE
              _buildLabel("Timeline"),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildDateTimeRow("Starts", _startDate, _startTime, true),
                    const Divider(),
                    _buildDateTimeRow("Ends", _endDate, _endTime, false),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // INVITES
              _buildLabel("Invites"),
              TextFormField(
                controller: _invitesController,
                decoration: _inputDecoration("Add emails separated by commas...", Icons.people_outline),
              ),
              const SizedBox(height: 24),

              // DESCRIPTION
              _buildLabel("Notes / Description"),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _inputDecoration("Add details, links, or agenda...", Icons.notes),
              ),
              
              const SizedBox(height: 40),
              
              // CREATE BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSaving 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("CREATE EVENT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 40), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  // --- Helpers ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: Colors.grey.shade400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _selectedColor, width: 2)),
    );
  }

  Widget _buildDateTimeRow(String label, DateTime date, TimeOfDay time, bool isStart) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey))),
          Expanded(
            child: InkWell(
              onTap: () => _pickDate(context, isStart: isStart),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                child: Text(DateFormat('EEE, MMM d').format(date), style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => _pickTime(context, isStart: isStart),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                child: Text(time.format(context), style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String currentValue, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue.isEmpty ? (items.isNotEmpty ? items.first : null) : currentValue,
          isExpanded: true,
          items: items.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
