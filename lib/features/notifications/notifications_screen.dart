import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/session_model.dart';
import '../../providers/course_provider.dart';
import '../../providers/schedule_provider.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isLoading =true;
  List<ClassSession>? _upcomingClasses;


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
      _checkUpcomingSessionStatus();
    });
  }


  Future<void> _checkUpcomingSessionStatus() async {
    _isLoading=true;
    final scheduleProvider = context.read<ScheduleProvider>();
    final courseProvider = context.read<CourseProvider>();

    final now = DateTime.now();
    final todaysClasses = scheduleProvider.getSessionsForDate(now);

    todaysClasses.sort((a, b) =>
        (a.activeStartTime ?? now).compareTo(b.activeStartTime ?? now)
    );

    try {
      _upcomingClasses = todaysClasses.where(
            (s) => s.activeEndTime != null && s.activeEndTime!.isAfter(now),
      ).toList();
      if (mounted) {
        setState(() {
          print(_upcomingClasses);
          print(_upcomingClasses!.length);          //_upcomingClasses is updated
        });
      }
    } catch (e) {
      // No upcoming session found; reset state if needed
      if (mounted) {
        setState(() {
          print("error");
        });
      }
    }
    _isLoading=false;
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
      if (_isLoading)
        _buildShimmerNotificationList()
      else if (_upcomingClasses != null && _upcomingClasses!.isNotEmpty)
      // usage of spread operator (...) to insert the list of widgets
        ..._upcomingClasses!.map((session) {

          // Helper logic to format time (Modify based on your needs)
          final startTime = session.activeStartTime;
          final timeString = startTime != null
              ? "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}"
              : "Soon";
          return _buildNotificationCard(
            context,
            title: "Upcoming Class: ${session.courseName ?? 'Session'}",
            body: "Lecture starts ${startTime==null?"soon": "at"} $timeString${session.room != null ? ' in room ${session.room}' : '.'}",
            time: "Now",
            icon: Icons.event,
            color: Colors.blueAccent,
            isUnread: true,
          );
        })
      else
      // Optional: Show a message if there are no classes today
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.primaryLight,
                  size: 20
              ),
              const SizedBox(width: 12),
              const Text(
                "No Upcoming classes for today",
                style: TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      // _buildNotificationCard(
      //   context,
      //   title: "Fee Payment Reminder",
      //   body: "Semester 2 fees are due by Dec 25th.",
      //   time: "2 hours ago",
      //   icon: Icons.payment,
      //   color: Colors.orangeAccent,
      //   isUnread: true,
      // ),

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

  Widget _buildShimmerNotificationList() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceElevated,
      highlightColor: AppColors.surface,
      child: Column(
        children: List.generate(
          3,
              (index) => Container(
            margin: const EdgeInsets.only(bottom: 8, top: 12),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
          ),
        ),
      ),
    );
  }
}
