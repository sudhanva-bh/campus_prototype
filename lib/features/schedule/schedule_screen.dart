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
  bool _isWeekView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().fetchSessions();
    });
  }

  void _showPlaceholder(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$feature is coming soon!"),
        backgroundColor: AppColors.primaryVariant,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final schedule = context.watch<ScheduleProvider>();
    final userRole = context.read<AuthProvider>().userRole;
    final canEdit = userRole == 'admin' || userRole == 'faculty';

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text("New Session"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateSessionScreen()),
              ),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          // 1. Modern Header
          SliverAppBar(
            expandedHeight: 120.0,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                _isWeekView ? "Weekly Overview" : "Daily Schedule",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 5)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    "https://images.unsplash.com/photo-1506784983877-45594efa4cbe?q=80&w=1000&auto=format&fit=crop",
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.background.withOpacity(0.95),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isWeekView
                      ? Icons.view_agenda_outlined
                      : Icons.calendar_view_week_outlined,
                  color: Colors.white,
                ),
                tooltip: _isWeekView
                    ? "Switch to Day View"
                    : "Switch to Week View",
                onPressed: () => setState(() => _isWeekView = !_isWeekView),
              ),
              if (canEdit)
                IconButton(
                  icon: const Icon(
                    Icons.auto_awesome_outlined,
                    color: Colors.white,
                  ),
                  tooltip: "AI Auto-Schedule",
                  onPressed: () => _handleGenerateTimetable(context),
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) => _showPlaceholder(value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: "Export iCal",
                    child: Row(
                      children: [
                        Icon(
                          Icons.ios_share,
                          size: 20,
                          color: AppColors.textMedium,
                        ),
                        SizedBox(width: 12),
                        Text("Export iCal"),
                      ],
                    ),
                  ),
                  if (canEdit) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: "Publish Schedule",
                      child: Row(
                        children: [
                          Icon(
                            Icons.publish,
                            size: 20,
                            color: AppColors.textMedium,
                          ),
                          SizedBox(width: 12),
                          Text("Publish"),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // 2. Date Strip (Day View Only)
          if (!_isWeekView)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildDateStrip(),
              ),
            ),

          // 3. Content
          if (schedule.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_isWeekView)
            _buildWeekView(schedule)
          else
            _buildDayView(schedule),
        ],
      ),
    );
  }

  // --- DAY VIEW WIDGETS ---

  Widget _buildDayView(ScheduleProvider schedule) {
    final sessions = schedule.getSessionsForDate(_selectedDate);

    if (sessions.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState("No classes scheduled."),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final session = sessions[index];
          // Determine if this is the last item to handle the timeline line
          final isLast = index == sessions.length - 1;
          return _buildTimelineSessionItem(session, isLast);
        }, childCount: sessions.length),
      ),
    );
  }

  // --- NEW: Enhanced Timeline Session Item ---
  Widget _buildTimelineSessionItem(ClassSession session, bool isLast) {
    // Determine color based on session type
    Color typeColor = Colors.blueAccent;
    if (session.type.toLowerCase().contains("lab"))
      typeColor = Colors.purpleAccent;
    if (session.type.toLowerCase().contains("exam"))
      typeColor = Colors.redAccent;
    if (session.type.toLowerCase().contains("seminar"))
      typeColor = Colors.orangeAccent;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Time Column
          SizedBox(
            width: 55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  session.startTimeStr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textHigh,
                  ),
                ),
                Text(
                  session.endTimeStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),

          // 2. Timeline Line
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Timeline Dot
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border.all(color: typeColor, width: 3),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: typeColor.withOpacity(0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                // Timeline Line (Solid)
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            typeColor.withOpacity(0.5),
                            typeColor.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 3. Card Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    // Accent Color Strip
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 4,
                      child: Container(color: typeColor),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: typeColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  session.type.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: typeColor,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.more_horiz,
                                color: AppColors.textDisabled,
                                size: 18,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            session.courseName.isNotEmpty
                                ? session.courseName
                                : session.courseId,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textHigh,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildInfoTag(Icons.location_on, session.room),
                              const SizedBox(width: 12),
                              _buildInfoTag(
                                Icons.access_time,
                                _getDurationString(session),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textDisabled),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMedium,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getDurationString(ClassSession session) {
    final duration =
        session.activeEndTime?.difference(session.activeStartTime!).inMinutes ??
        60;
    return "${duration}min";
  }

  // --- WEEK VIEW WIDGETS ---

  Widget _buildWeekView(ScheduleProvider schedule) {
    final startOfWeek = _getStartOfWeek(_selectedDate);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final currentDate = startOfWeek.add(Duration(days: index));
          final sessions = schedule.getSessionsForDate(currentDate);
          final isToday =
              DateFormat.yMd().format(currentDate) ==
              DateFormat.yMd().format(DateTime.now());

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Text(
                      DateFormat('EEEE').format(currentDate),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isToday ? AppColors.primary : AppColors.textHigh,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM d').format(currentDate),
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textMedium,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.circle,
                        size: 8,
                        color: AppColors.primary,
                      ),
                    ],
                  ],
                ),
              ),
              if (sessions.isEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border.withOpacity(0.5),
                    ),
                  ),
                  child: const Text(
                    "No classes",
                    style: TextStyle(
                      color: AppColors.textDisabled,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                Column(
                  children: sessions
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildTimelineSessionItem(
                            s,
                            true,
                          ), // Reuse new card, simplified
                        ),
                      )
                      .toList(),
                ),
              if (index < 6)
                const Divider(color: AppColors.divider, height: 32),
            ],
          );
        }, childCount: 7),
      ),
    );
  }

  // --- SHARED WIDGETS ---

  Widget _buildDateStrip() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected =
              date.day == _selectedDate.day &&
              date.month == _selectedDate.month &&
              date.year == _selectedDate.year;

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 64,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date).toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textMedium,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textHigh,
                      fontSize: 22,
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: AppColors.textDisabled,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textMedium,
              fontWeight: FontWeight.w500,
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
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "AI Auto-Scheduler",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Generate optimal timetable based on faculty availability and room capacity?",
          style: TextStyle(color: AppColors.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppColors.textMedium),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Generate"),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await context
          .read<ScheduleProvider>()
          .generateTimetable();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? "Timetable Generated Successfully!"
                  : "Optimization Failed",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
