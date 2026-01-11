import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/course_model.dart';
import '../../../core/models/session_model.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/schedule_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/faculty_provider.dart'; // <--- NEW IMPORT
import '../../courses/course_form_screen.dart';

class FacultyHome extends StatefulWidget {
  const FacultyHome({super.key});

  @override
  State<FacultyHome> createState() => _FacultyHomeState();
}

class _FacultyHomeState extends State<FacultyHome>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isStartingSession = false;
  bool _isSessionActive = false;
  ClassSession? _cachedUpcomingSession; // Cache to keep UI stable

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _animController.forward();
      await Future.wait([
        context.read<CourseProvider>().fetchCourses(),
        context.read<ScheduleProvider>().fetchSessions(),
      ]);

      if (mounted) {
        _checkUpcomingSessionStatus();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkUpcomingSessionStatus() async {
    final scheduleProvider = context.read<ScheduleProvider>();
    final courseProvider = context.read<CourseProvider>();
    final facultyProvider = context.read<FacultyProvider>(); // <--- PHASE 5

    final now = DateTime.now();
    final todaysClasses = scheduleProvider.getSessionsForDate(now);

    todaysClasses.sort(
      (a, b) => (a.activeStartTime ?? now).compareTo(b.activeStartTime ?? now),
    );

    try {
      final upcoming = todaysClasses.firstWhere(
        (s) => s.activeEndTime != null && s.activeEndTime!.isAfter(now),
      );

      // Cache the session so we can use it in the UI even if logic re-runs
      _cachedUpcomingSession = upcoming;

      // Check if attendance is already running
      final isActive = await courseProvider.isAttendanceActive(
        upcoming.courseId,
        upcoming.id,
      );

      // --- PHASE 5: Fetch Pacing Intelligence ---
      // We fetch this for any upcoming/active session to guide the faculty
      facultyProvider.fetchPacing(upcoming.id);

      if (mounted) {
        setState(() {
          _isSessionActive = isActive;
        });
      }
    } catch (e) {
      // No upcoming session found
      if (mounted) {
        setState(() {
          _isSessionActive = false;
          _cachedUpcomingSession = null;
        });
      }
    }
  }

  Future<void> _endSession(String sessionId) async {
    if (_isSessionActive && !_isStartingSession) {
      setState(() {
        _isStartingSession = true;
      });

      final today = DateTime.now();
      final dateString =
          "${today.year.toString().padLeft(4, '0')}-"
          "${today.month.toString().padLeft(2, '0')}-"
          "${today.day.toString().padLeft(2, '0')}";

      // Close attendance session
      final success = await context.read<AttendanceProvider>().closeSession(
        sessionId: "${sessionId}_$dateString",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session Ended. Analyzing...')),
        );

        // --- PHASE 5: Post-Session Intelligence ---
        // Fetch insights (confusion points, grasping scores)
        await context.read<FacultyProvider>().fetchSessionInsights(sessionId);

        // Show the summary dialog
        if (mounted) _showSessionSummaryDialog();

        await _checkUpcomingSessionStatus();
        setState(() {
          _isStartingSession = false;
        });
      }
    }
  }

  // --- PHASE 5: Summary Dialog ---
  void _showSessionSummaryDialog() {
    final insights = context.read<FacultyProvider>().currentInsights;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          "Class Summary",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: insights.isEmpty
              ? [
                  const Text(
                    "No insights available.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ]
              : insights
                    .map(
                      (i) => ListTile(
                        title: Text(
                          i.metric,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        subtitle: Text(
                          i.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: Icon(
                          i.trend == "rising"
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: i.trend == "rising"
                              ? Colors.redAccent
                              : Colors.greenAccent,
                        ),
                      ),
                    )
                    .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showPlaceholder(String featureName) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Feature '$featureName' is under development."),
        backgroundColor: AppColors.primaryVariant,
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
    final scheduleProvider = context.watch<ScheduleProvider>();
    final courseProvider = context.watch<CourseProvider>();
    final facultyProvider = context.watch<FacultyProvider>(); // <--- PHASE 5
    final user = context.watch<AuthProvider>().userProfile;
    final firstName = user?['first_name'] ?? 'Faculty';

    final isLoading = courseProvider.isLoading || scheduleProvider.isLoading;

    final myCourses = courseProvider.courses;
    final totalStudents = myCourses.fold<int>(
      0,
      (sum, course) => sum + course.enrolledStudents.length,
    );
    final todaysClasses = scheduleProvider.getSessionsForDate(DateTime.now());

    // Use cached session to avoid UI flicker during rebuilds
    final upcomingSession = _cachedUpcomingSession;

    // Define content list for animation
    final List<Widget> contentWidgets = [
      // Stats Row
      if (isLoading)
        _buildShimmerStats()
      else
        Row(
          children: [
            Expanded(
              child: _statCard(
                "Classes Today",
                "${todaysClasses.length}",
                Icons.calendar_today,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                "Total Students",
                "$totalStudents",
                Icons.groups,
              ),
            ),
          ],
        ),
      const SizedBox(height: 24),

      // Upcoming Class Card
      const Text(
        "Live Status",
        style: TextStyle(
          color: AppColors.textDisabled,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),

      if (isLoading)
        _buildShimmerUpcomingCard()
      else
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.surfaceElevated, AppColors.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Upcoming Session",
                    style: TextStyle(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (upcomingSession != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "ON TIME",
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (upcomingSession != null) ...[
                Text(
                  upcomingSession.courseName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 18,
                      color: AppColors.textMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${DateFormat('h:mm a').format(upcomingSession.activeStartTime!)} - ${upcomingSession.room}",
                      style: const TextStyle(
                        color: AppColors.textHigh,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                // --- PHASE 5: Pacing Recommendation Widget ---
                if (facultyProvider.currentPacing != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          facultyProvider.currentPacing!.action == 'SLOW_DOWN'
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            facultyProvider.currentPacing!.action == 'SLOW_DOWN'
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          facultyProvider.currentPacing!.action == 'SLOW_DOWN'
                              ? Icons.warning_amber_rounded
                              : Icons.speed,
                          color:
                              facultyProvider.currentPacing!.action ==
                                  'SLOW_DOWN'
                              ? Colors.orange
                              : Colors.green,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "AI Insight: ${facultyProvider.currentPacing!.action.replaceAll('_', ' ')}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      facultyProvider.currentPacing!.action ==
                                          'SLOW_DOWN'
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                              ),
                              Text(
                                facultyProvider.currentPacing!.reasoning,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ----------------------------------------------
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    icon: _isStartingSession
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                          ),
                    label: Text(
                      _isStartingSession
                          ? "Processing..."
                          : (!_isSessionActive)
                          ? "Start Class & Attendance"
                          : "End Session",
                      style: const TextStyle(color: Colors.white),
                    ),
                    onPressed: _isStartingSession
                        ? null // Disable button while processing
                        : (_isSessionActive
                              ? () => _endSession(upcomingSession!.id)
                              : () async {
                                  setState(() => _isStartingSession = true);
                                  final success = await context
                                      .read<AttendanceProvider>()
                                      .startSession(
                                        courseId: upcomingSession!.courseId,
                                        classSessionId: upcomingSession!.id,
                                      );

                                  if (mounted) {
                                    await _checkUpcomingSessionStatus();
                                    setState(() {
                                      _isStartingSession = false;
                                    });
                                    if (success) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Session Started'),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Could not start session',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }),
                  ),
                ),
              ] else ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      "No immediate classes scheduled.",
                      style: TextStyle(color: AppColors.textDisabled),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

      const SizedBox(height: 32),

      // Assigned Courses
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "My Courses",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(onPressed: () {}, child: const Text("View All")),
        ],
      ),
      if (courseProvider.isLoading)
        _buildShimmerCourseList()
      else if (myCourses.isEmpty)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text("No courses assigned yet."),
        )
      else
        Column(
          children: myCourses
              .take(3)
              .map((course) => _buildCourseTile(context, course))
              .toList(),
        ),

      const SizedBox(height: 32),
      const Divider(color: AppColors.divider),
      const SizedBox(height: 16),

      const Text(
        "Teaching Tools",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      _buildToolGrid([
        _ToolOption("Gradebook", Icons.grade, Colors.orange),
        _ToolOption("Assignments", Icons.assignment, Colors.blue),
        _ToolOption("Course Materials", Icons.folder_copy, Colors.purple),
        _ToolOption("Student Analytics", Icons.insights, Colors.teal),
      ]),

      const SizedBox(height: 24),
      const Text(
        "Department & Admin",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      _buildToolGrid([
        _ToolOption("Leave Request", Icons.flight_takeoff, Colors.redAccent),
        _ToolOption("Exam Invigilation", Icons.remove_red_eye, Colors.indigo),
        _ToolOption("Notices", Icons.notifications_active, Colors.amber),
        _ToolOption("Profile", Icons.person_pin, Colors.green),
      ]),

      const SizedBox(height: 80),
    ];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          _animController.reset();
          _animController.forward();
          await context.read<CourseProvider>().fetchCourses();
          await context.read<ScheduleProvider>().fetchSessions();
        },
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              expandedHeight: 220.0,
              pinned: true,
              backgroundColor: AppColors.background,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  "Welcome, Prof. $firstName",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      "https://images.unsplash.com/photo-1541339907198-e08756dedf3f?q=80&w=1000&auto=format&fit=crop",
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.1),
                            AppColors.background,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: contentWidgets
                      .asMap()
                      .entries
                      .map(
                        (entry) => _buildAnimatedChild(entry.value, entry.key),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SHIMMER WIDGETS ---

  Widget _buildShimmerStats() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceElevated,
      highlightColor: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerUpcomingCard() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceElevated,
      highlightColor: AppColors.surface,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildShimmerCourseList() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceElevated,
      highlightColor: AppColors.surface,
      child: Column(
        children: List.generate(
          3,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  // --- EXISTING HELPERS ---

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseTile(BuildContext context, Course course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          course.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${course.code} • ${course.enrolledStudents.length} Students",
          style: const TextStyle(color: AppColors.textMedium),
        ),
      ),
    );
  }

  Widget _buildToolGrid(List<_ToolOption> tools) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tools.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemBuilder: (ctx, i) {
        return InkWell(
          onTap: () => _showPlaceholder(tools[i].label),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tools[i].color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(tools[i].icon, size: 20, color: tools[i].color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tools[i].label,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ToolOption {
  final String label;
  final IconData icon;
  final Color color;
  _ToolOption(this.label, this.icon, this.color);
}
