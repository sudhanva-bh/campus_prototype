import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    // Start animation on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showPlaceholder(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$feature is coming soon!"),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildAnimatedChild(Widget child, int index) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final double start = (index * 0.1).clamp(0.0, 1.0);
        final double end = (start + 0.4).clamp(0.0, 1.0);
        final curve = CurvedAnimation(
          parent: _animController,
          curve: Interval(start, end, curve: Curves.easeOutQuart),
        );
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(curve),
            child: child!,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // List of content to display
    final List<Widget> listItems = [
      // Dummy "Today" Section
      const Padding(
        padding: EdgeInsets.only(bottom: 12, left: 4),
        child: Text(
          "Today",
          style: TextStyle(
            color: AppColors.textMedium,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      _buildNotificationCard(
        context,
        title: "Upcoming Class: CS101",
        body: "Lecture starts in 15 minutes at Room 304B.",
        time: "10 mins ago",
        icon: Icons.event,
        color: Colors.blueAccent,
        isUnread: true,
      ),
      _buildNotificationCard(
        context,
        title: "Fee Payment Reminder",
        body: "Semester 2 fees are due by Dec 25th.",
        time: "2 hours ago",
        icon: Icons.payment,
        color: Colors.orangeAccent,
        isUnread: true,
      ),

      const SizedBox(height: 24),

      // Dummy "Earlier" Section
      const Padding(
        padding: EdgeInsets.only(bottom: 12, left: 4),
        child: Text(
          "Earlier",
          style: TextStyle(
            color: AppColors.textMedium,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      _buildNotificationCard(
        context,
        title: "Assignment Graded",
        body: "Your submission for 'Data Structures' has been graded.",
        time: "Yesterday",
        icon: Icons.grade,
        color: Colors.greenAccent,
        isUnread: false,
      ),
      _buildNotificationCard(
        context,
        title: "Campus Event: Hackathon",
        body: "Registration for the annual hackathon is now open.",
        time: "2 days ago",
        icon: Icons.campaign,
        color: Colors.purpleAccent,
        isUnread: false,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.playlist_add_check,
              color: AppColors.textMedium,
            ),
            onPressed: () => _showPlaceholder(context, "Mark All Read"),
            tooltip: "Mark all as read",
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.textMedium),
            onPressed: () => _showPlaceholder(context, "Filter Notifications"),
            tooltip: "Filter",
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: listItems.length,
        itemBuilder: (context, index) {
          return _buildAnimatedChild(listItems[index], index);
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context, {
    required String title,
    required String body,
    required String time,
    required IconData icon,
    required Color color,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread ? AppColors.surfaceElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.textHigh,
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                color: AppColors.textDisabled,
                fontSize: 12,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            body,
            style: const TextStyle(color: AppColors.textMedium),
          ),
        ),
        onTap: () => _showPlaceholder(context, "Notification Details"),
      ),
    );
  }
}
