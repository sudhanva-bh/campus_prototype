import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/course_model.dart';
import '../../../core/models/session_model.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/schedule_provider.dart';
// import '../../../providers/auth_provider.dart';
import '../../courses/course_form_screen.dart';

class FacultyHome extends StatefulWidget {
  const FacultyHome({super.key});

  @override
  State<FacultyHome> createState() => _FacultyHomeState();
}

class _FacultyHomeState extends State<FacultyHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().fetchCourses();
      context.read<ScheduleProvider>().fetchSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final courseProvider = context.watch<CourseProvider>();
    // final authProvider = context.watch<AuthProvider>();

    // 1. Calculate Stats
    final myCourses = courseProvider
        .courses; // API filters this by faculty usually, or we filter locally:
    // .where((c) => c.instructorId == authProvider.userProfile?['uid']).toList();
    // *For prototype, we assume the API returned only relevant courses or we use all.*

    final totalStudents = myCourses.fold<int>(
      0,
      (sum, course) => sum + course.enrolledStudents.length,
    );

    final today = DateTime.now();
    final todaysClasses = scheduleProvider.getSessionsForDate(today);

    // 2. Find Upcoming Class
    ClassSession? upcomingSession;
    final now = DateTime.now();

    // Sort all sessions for today by time
    todaysClasses.sort(
      (a, b) => (a.activeStartTime ?? now).compareTo(b.activeStartTime ?? now),
    );

    // Find first one that hasn't ended yet
    try {
      upcomingSession = todaysClasses.firstWhere(
        (s) => s.activeEndTime != null && s.activeEndTime!.isAfter(now),
      );
    } catch (e) {
      upcomingSession = null;
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CourseFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<CourseProvider>().fetchCourses();
          await context.read<ScheduleProvider>().fetchSessions();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              "Faculty Dashboard",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Real Stats
            Row(
              children: [
                Expanded(
                  child: _statCard("Classes Today", "${todaysClasses.length}"),
                ),
                const SizedBox(width: 12),
                Expanded(child: _statCard("Total Students", "$totalStudents")),
              ],
            ),

            const SizedBox(height: 16),

            // Real Upcoming Class
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Upcoming Class",
                    style: TextStyle(color: AppColors.textMedium),
                  ),
                  const SizedBox(height: 8),
                  if (upcomingSession != null) ...[
                    Text(
                      upcomingSession.courseName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${DateFormat('h:mm a').format(upcomingSession.activeStartTime!)} - ${upcomingSession.room}",
                          style: const TextStyle(color: AppColors.textHigh),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Text(
                      "No more classes today",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDisabled,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text(
              "Assigned Courses",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            if (courseProvider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (myCourses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text("No courses assigned."),
              )
            else
              Column(
                children: myCourses
                    .map((course) => _buildCourseTile(context, course))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryLight,
            ),
          ),
          Text(label, style: const TextStyle(color: AppColors.textMedium)),
        ],
      ),
    );
  }

  Widget _buildCourseTile(BuildContext context, Course course) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(course.name),
        subtitle: Text(
          "${course.code} • ${course.enrolledStudents.length} Students",
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: AppColors.textMedium),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CourseFormScreen(course: course)),
          ),
        ),
      ),
    );
  }
}
