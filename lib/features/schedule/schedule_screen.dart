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

  // Helper to get start of the week (Monday)
  DateTime _getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final schedule = context.watch<ScheduleProvider>();
    final userRole = context.read<AuthProvider>().userRole;
    final canEdit = userRole == 'admin' || userRole == 'faculty';

    return Scaffold(
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
          // 1. Modern Header with Actions
          SliverAppBar(
            expandedHeight: 140.0,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _isWeekView ? "Weekly Overview" : "Daily Schedule",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
                          Colors.black.withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Toggle View Button
              IconButton(
                icon: Icon(
                  _isWeekView ? Icons.view_agenda : Icons.calendar_view_week,
                ),
                tooltip: _isWeekView
                    ? "Switch to Day View"
                    : "Switch to Week View",
                onPressed: () {
                  setState(() => _isWeekView = !_isWeekView);
                },
              ),
              // AI Button (Admin Only)
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  tooltip: "AI Auto-Schedule",
                  onPressed: () => _handleGenerateTimetable(context),
                ),
              // More Actions Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
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
                  const PopupMenuItem(
                    value: "Book Room",
                    child: Row(
                      children: [
                        Icon(
                          Icons.meeting_room,
                          size: 20,
                          color: AppColors.textMedium,
                        ),
                        SizedBox(width: 12),
                        Text("Book Room"),
                      ],
                    ),
                  ),
                  if (canEdit) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: "Check Conflicts",
                      child: Row(
                        children: [
                          Icon(
                            Icons.fact_check,
                            size: 20,
                            color: AppColors.textMedium,
                          ),
                          SizedBox(width: 12),
                          Text("Check Conflicts"),
                        ],
                      ),
                    ),
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

          // 2. Date Strip (Only visible in Day View)
          if (!_isWeekView)
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _buildDateStrip(),
              ),
            ),

          // 3. Loading State
          if (schedule.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          // 4. Content (Day vs Week)
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
        child: _buildEmptyState("No classes scheduled for today."),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return _buildSessionCard(sessions[index]);
        }, childCount: sessions.length),
      ),
    );
  }

  // --- WEEK VIEW WIDGETS ---

  Widget _buildWeekView(ScheduleProvider schedule) {
    final startOfWeek = _getStartOfWeek(_selectedDate);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final currentDate = startOfWeek.add(Duration(days: index));
            final sessions = schedule.getSessionsForDate(currentDate);
            final isToday =
                DateFormat.yMd().format(currentDate) ==
                DateFormat.yMd().format(DateTime.now());

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day Header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        DateFormat('EEEE').format(currentDate),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isToday
                              ? AppColors.primary
                              : AppColors.textHigh,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM d').format(currentDate),
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.textMedium,
                        ),
                      ),
                      if (isToday)
                        Container(
                          margin: const EdgeInsets.only(left: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "TODAY",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Sessions List for that Day
                if (sessions.isEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border.withOpacity(0.5),
                      ),
                    ),
                    child: const Text(
                      "No classes",
                      style: TextStyle(color: AppColors.textDisabled),
                    ),
                  )
                else
                  Column(
                    children: sessions
                        .map((s) => _buildSessionCard(s))
                        .toList(),
                  ),

                if (index < 6)
                  const Divider(color: AppColors.divider, height: 32),
              ],
            );
          },
          childCount: 7, // 7 days in a week
        ),
      ),
    );
  }

  // --- SHARED WIDGETS ---

  Widget _buildDateStrip() {
    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 14, // Next 2 weeks
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
              width: 60,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: isSelected ? null : Border.all(color: AppColors.border),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textHigh,
                      fontSize: 20,
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
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy,
              size: 48,
              color: AppColors.textDisabled,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(ClassSession session) {
    final duration =
        session.activeEndTime?.difference(session.activeStartTime!).inMinutes ??
        60;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time Column
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  session.startTimeStr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  session.endTimeStr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),

          // Timeline Line
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border.all(color: AppColors.primary, width: 2),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(child: Container(width: 2, color: AppColors.divider)),
              ],
            ),
          ),

          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          session.courseName.isNotEmpty
                              ? session.courseName
                              : session.courseId,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textHigh,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          session.type,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textMedium,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        session.room,
                        style: const TextStyle(color: AppColors.textMedium),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.textMedium,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${duration}min",
                        style: const TextStyle(color: AppColors.textMedium),
                      ),
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
        backgroundColor: AppColors.surfaceElevated,
        title: const Text(
          "AI Auto-Scheduler",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Generate optimal timetable based on faculty availability and room capacity?",
          style: TextStyle(color: AppColors.textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
