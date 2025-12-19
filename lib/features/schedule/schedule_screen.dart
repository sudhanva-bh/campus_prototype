import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/session_model.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/auth_provider.dart';
import 'create_session_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().fetchSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final schedule = context.watch<ScheduleProvider>();
    final userRole = context.read<AuthProvider>().userRole;
    final canEdit = userRole == 'admin' || userRole == 'faculty';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Schedule"),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              tooltip: "Generate Timetable",
              onPressed: () => _handleGenerateTimetable(context),
            ),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateSessionScreen()),
              ),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          // Date Selector Strip
          _buildDateStrip(),
          
          const Divider(height: 1, color: AppColors.divider),
          
          // Sessions List
          Expanded(
            child: schedule.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => schedule.fetchSessions(),
                    child: _buildSessionList(schedule),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateStrip() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        // Simple implementation: Show next 14 days
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = date.day == _selectedDate.day && 
                           date.month == _selectedDate.month;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? null : Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textHigh,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionList(ScheduleProvider provider) {
    final sessions = provider.getSessionsForDate(_selectedDate);

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 64, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(
              "No classes scheduled for\n${DateFormat('MMMM d').format(_selectedDate)}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMedium),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        return _buildSessionCard(sessions[index]);
      },
    );
  }

  Widget _buildSessionCard(ClassSession session) {
    final duration = session.activeEndTime?.difference(session.activeStartTime!).inMinutes;
    // final timeFormat = DateFormat('h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column
          SizedBox(
            width: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  session.startTimeStr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  session.endTimeStr,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // Timeline Indicator
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 60, // approximate height needed
                color: AppColors.divider,
              ),
            ],
          ),
          const SizedBox(width: 12),
          
          // Card Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          session.courseName.isNotEmpty ? session.courseName : session.courseId,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "${duration}m",
                          style: const TextStyle(fontSize: 10, color: AppColors.textMedium),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMedium),
                      const SizedBox(width: 4),
                      Text(session.room, style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
                      const SizedBox(width: 16),
                      const Icon(Icons.class_outlined, size: 14, color: AppColors.textMedium),
                      const SizedBox(width: 4),
                      Text(session.type, style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleGenerateTimetable(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Generate Timetable?"),
        content: const Text("This will auto-generate sessions based on course configs."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Generate")),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await context.read<ScheduleProvider>().generateTimetable();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? "Timetable Generated!" : "Failed to generate")),
        );
      }
    }
  }
}