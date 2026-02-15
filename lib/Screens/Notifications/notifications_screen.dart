import 'package:flutter/material.dart';

// --- 1. The Data Model ---
enum NotificationType { info, success, alert, message }

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

// --- 2. The Main Screen ---
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Dummy Data Generation
  List<NotificationItem> notifications = [
    NotificationItem(
      id: '1',
      title: 'System Update',
      body: 'Your application has been successfully updated to v2.0.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      type: NotificationType.info,
      isRead: false,
    ),
    NotificationItem(
      id: '2',
      title: 'Payment Received',
      body: 'You received \$50.00 from John Doe.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      type: NotificationType.success,
      isRead: false,
    ),
    NotificationItem(
      id: '3',
      title: 'Security Alert',
      body: 'New login attempt detected from an unknown device.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.alert,
      isRead: true,
    ),
    NotificationItem(
      id: '4',
      title: 'New Message',
      body: 'Hey, are we still on for the meeting tomorrow?',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      type: NotificationType.message,
      isRead: true,
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (var n in notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  void _deleteNotification(String id) {
    setState(() {
      notifications.removeWhere((n) => n.id == id);
    });
  }

  void _toggleReadStatus(NotificationItem item) {
    setState(() {
      item.isRead = !item.isRead;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Grouping Logic
    final newNotifications = notifications.where((n) => !n.isRead).toList();
    final earlierNotifications = notifications.where((n) => n.isRead).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for contrast
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (newNotifications.isNotEmpty) ...[
                  _buildSectionHeader('New'),
                  ...newNotifications.map((n) => _buildNotificationTile(n)),
                  const SizedBox(height: 20),
                ],
                if (earlierNotifications.isNotEmpty) ...[
                  _buildSectionHeader('Earlier'),
                  ...earlierNotifications.map((n) => _buildNotificationTile(n)),
                ],
              ],
            ),
    );
  }

  // --- 3. UI Components ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNotificationTile(NotificationItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(item.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _deleteNotification(item.id),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red[400],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        child: InkWell(
          onTap: () => _toggleReadStatus(item),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: item.isRead ? Colors.white : Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: item.isRead
                  ? Border.all(color: Colors.grey.shade200)
                  : Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIcon(item.type),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: item.isRead ? Colors.black87 : Colors.blue[900],
                            ),
                          ),
                          Text(
                            _formatTime(item.timestamp),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.body,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!item.isRead)
                  Container(
                    margin: const EdgeInsets.only(left: 10, top: 5),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.info:
        icon = Icons.info_outline;
        color = Colors.blue;
        break;
      case NotificationType.success:
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case NotificationType.alert:
        icon = Icons.warning_amber_rounded;
        color = Colors.orange;
        break;
      case NotificationType.message:
        icon = Icons.chat_bubble_outline;
        color = Colors.purple;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll let you know when something arrives.',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    // Simple time formatting logic
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}