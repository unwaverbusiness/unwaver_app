import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // --- STATE VARIABLES (Mock Data) ---
  
  // Delivery Methods
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _smsEnabled = false;

  // Alert Types
  bool _dailyReview = true;
  bool _goalReminders = true;
  bool _habitNudges = true;
  bool _aiCoachPrompts = false;
  bool _accountabilityAlerts = true;

  // Frequency & Timing
  double _notificationFrequency = 2; // 0=Low, 1=Medium, 2=High
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0); // 10:00 PM
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0); // 7:00 AM

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          
          // --- DELIVERY METHODS ---
          _buildSectionHeader("Delivery Methods"),
          _buildSettingsGroup([
            _buildSwitchTile(
              icon: Icons.notifications_active_outlined,
              title: "Push Notifications",
              subtitle: "Alerts directly on your device",
              value: _pushEnabled,
              onChanged: (val) => setState(() => _pushEnabled = val),
            ),
            _buildSwitchTile(
              icon: Icons.email_outlined,
              title: "Email Digests",
              subtitle: "Weekly summaries and major alerts",
              value: _emailEnabled,
              onChanged: (val) => setState(() => _emailEnabled = val),
            ),
            _buildSwitchTile(
              icon: Icons.sms_outlined,
              title: "SMS Text Messages",
              subtitle: "Urgent accountability updates only",
              value: _smsEnabled,
              onChanged: (val) => setState(() => _smsEnabled = val),
            ),
          ]),
          const SizedBox(height: 24),

          // --- ALERT TYPES ---
          _buildSectionHeader("Alert Types"),
          _buildSettingsGroup([
            _buildSwitchTile(
              icon: Icons.fact_check_outlined,
              title: "Daily Review",
              subtitle: "Evening prompt to log your day",
              value: _dailyReview,
              onChanged: (val) => setState(() => _dailyReview = val),
            ),
            _buildSwitchTile(
              icon: Icons.flag_outlined,
              title: "Goal Deadlines",
              value: _goalReminders,
              onChanged: (val) => setState(() => _goalReminders = val),
            ),
            _buildSwitchTile(
              icon: Icons.repeat,
              title: "Habit Nudges",
              value: _habitNudges,
              onChanged: (val) => setState(() => _habitNudges = val),
            ),
            _buildSwitchTile(
              icon: Icons.psychology_outlined,
              title: "AI Coach Insights",
              subtitle: "Proactive tips from your Life Coach",
              value: _aiCoachPrompts,
              onChanged: (val) => setState(() => _aiCoachPrompts = val),
            ),
            _buildSwitchTile(
              icon: Icons.handshake_outlined,
              title: "Accountability Updates",
              subtitle: "When a partner completes a goal",
              value: _accountabilityAlerts,
              onChanged: (val) => setState(() => _accountabilityAlerts = val),
            ),
          ]),
          const SizedBox(height: 24),

          // --- TIMING & FREQUENCY ---
          _buildSectionHeader("Timing & Frequency"),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune, color: Colors.black, size: 20),
                    SizedBox(width: 12),
                    Text("Notification Volume", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _frequencyLabel(_notificationFrequency), 
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)
                ),
                Slider(
                  value: _notificationFrequency,
                  min: 0,
                  max: 2,
                  divisions: 2,
                  activeColor: const Color(0xFFBB8E13), // Unwaver Gold
                  inactiveColor: Colors.grey.shade200,
                  onChanged: (val) => setState(() => _notificationFrequency = val),
                ),
                const Divider(height: 32),
                
                // Quiet Hours
                const Row(
                  children: [
                    Icon(Icons.do_not_disturb_alt, color: Colors.black, size: 20),
                    SizedBox(width: 12),
                    Text("Quiet Hours", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTimePickerButton("From", _quietHoursStart, (time) => setState(() => _quietHoursStart = time)),
                    const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
                    _buildTimePickerButton("To", _quietHoursEnd, (time) => setState(() => _quietHoursEnd = time)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  String _frequencyLabel(double val) {
    if (val == 0) return "Low (Only essential alerts and deadlines)";
    if (val == 1) return "Medium (Standard reminders and summaries)";
    return "High (All nudges, partner updates, and AI prompts)";
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final widget = entry.value;
          final isLast = index == children.length - 1;
          
          return Column(
            children: [
              widget,
              if (!isLast)
                Divider(height: 1, thickness: 1, color: Colors.grey.shade100, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.black, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: subtitle != null 
          ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)) 
          : null,
      value: value,
      onChanged: onChanged,
      activeTrackColor: Colors.black, 
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildTimePickerButton(String label, TimeOfDay time, Function(TimeOfDay) onTimeSelected) {
    return Expanded(
      child: InkWell(
        onTap: () async {
          final newTime = await showTimePicker(
            context: context,
            initialTime: time,
            builder: (context, child) {
              return Theme(
                data: ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Colors.black, // Header background color
                    onPrimary: Colors.white, // Header text color
                    onSurface: Colors.black, // Body text color
                  ),
                ),
                child: child!,
              );
            },
          );
          if (newTime != null) {
            onTimeSelected(newTime);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(time.format(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}