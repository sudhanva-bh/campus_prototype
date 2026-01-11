import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/course_model.dart';
import '../../../core/models/session_model.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/schedule_provider.dart';
import '../../attendance/attendance_screen.dart';

// --- Phase 3 Imports ---
import '../../analytics/widgets/wellness_battery.dart';
import '../../analytics/learning_insights_screen.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isMarkingAttendance = false;
  bool _isLoading = true;
  List<ClassSession>? _upcomingClasses;

  @override
  void initState() {
    super.initState();

    // Initialize Animation
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Start Animation and Fetch Data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animController.forward();
      context.read<CourseProvider>().fetchCourses();
      _checkUpcomingSessionStatus();
    });
  }

  Future<void> _checkUpcomingSessionStatus() async {
    _isLoading = true;
    final scheduleProvider = context.read<ScheduleProvider>();

    final now = DateTime.now();
    final todaysClasses = scheduleProvider.getSessionsForDate(now);

    todaysClasses.sort(
      (a, b) => (a.activeStartTime ?? now).compareTo(b.activeStartTime ?? now),
    );

    try {
      _upcomingClasses = todaysClasses
          .where(
            (s) => s.activeEndTime != null && s.activeEndTime!.isAfter(now),
          )
          .toList();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    }
    _isLoading = false;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showPlaceholder(String featureName) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$featureName module is coming soon!"),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildAnimatedChild(Widget child, int index) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final double start = (index * 0.05).clamp(0.0, 1.0);
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
    final user = context.watch<AuthProvider>().userProfile;
    final firstName = user?['first_name'] ?? 'Student';

    final List<Widget> contentWidgets = [
      // --- Quick Actions ---
      _buildSectionHeader("Quick Actions"),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _BouncingButton(
              onTap: _isMarkingAttendance
                  ? () {}
                  : () async {
                      setState(() => _isMarkingAttendance = true);

                      try {
                        final courseProvider = context.read<CourseProvider>();
                        final activeCourse = await courseProvider
                            .identifyCurrentClass();

                        if (!mounted) return;

                        if (activeCourse == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("No Active Sessions"),
                              backgroundColor: AppColors.primary,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AttendanceScreen(activeCourses: activeCourse),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isMarkingAttendance = false);
                        }
                      }
                    },
              child: _buildActionBtn(
                Icons.camera_alt_outlined,
                "Mark Attendance",
                AppColors.primary,
                isDark: false,
                isLoading: _isMarkingAttendance,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _BouncingButton(
              onTap: () => _showPlaceholder("QR Scan Entry"),
              child: _buildActionBtn(
                Icons.qr_code_scanner,
                "Scan Entry",
                AppColors.surfaceElevated,
                isDark: true,
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 24),

      // --- Live Status ---
      _buildSectionHeader("Live Status"),
      const SizedBox(height: 8),

      if (_isLoading)
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
                  if (_upcomingClasses != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (_upcomingClasses == null ||
                                _upcomingClasses!.isEmpty)
                            ? Colors.transparent
                            : AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (_upcomingClasses == null || _upcomingClasses!.isEmpty)
                            ? ""
                            : "ON TIME",
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_upcomingClasses != null && _upcomingClasses!.isNotEmpty) ...[
                Row(
                  children: [
                    Text(
                      _upcomingClasses![0].courseName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _upcomingClasses![0].startTimeStr,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
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

      const SizedBox(height: 24),

      // --- PHASE 3: Learning Intelligence ---
      _buildSectionHeader("Learning Intelligence"),
      // 1. Wellness Battery
      const WellnessBattery(),
      const SizedBox(height: 12),
      // 2. Navigation Button
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.insights, size: 20),
          label: const Text("View Learning Intelligence"),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LearningInsightsScreen()),
            );
          },
        ),
      ),
      const SizedBox(height: 24),

      // --- Enrolled Courses ---
      _buildSectionHeader("Enrolled Courses"),
      Consumer<CourseProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return _buildShimmerCourseList();
          }
          if (provider.courses.isEmpty) {
            return _buildEmptyState("No courses enrolled yet.");
          }
          return Column(
            children: provider.courses
                .map(
                  (course) => _BouncingButton(
                    onTap: () {
                      _showPlaceholder("Course Details for ${course.code}");
                    },
                    child: _buildCourseCard(course),
                  ),
                )
                .toList(),
          );
        },
      ),

      const SizedBox(height: 12),
      const Divider(color: AppColors.divider),
      const SizedBox(height: 16),

      // --- Academic Registration ---
      _buildSectionHeader("Academic Registration"),
      _buildGridMenu([
        _MenuOption("Search Catalog", Icons.search),
        _MenuOption("My Waitlists", Icons.hourglass_empty),
        _MenuOption("Prerequisites", Icons.rule),
        _MenuOption("Cart / Enroll", Icons.shopping_cart_outlined),
      ]),

      const SizedBox(height: 24),

      // --- Financial Services ---
      _buildSectionHeader("Financial Services"),
      _buildGridMenu([
        _MenuOption("Fee Payment", Icons.payment),
        _MenuOption("Scholarships", Icons.school),
        _MenuOption("Request Refund", Icons.money_off),
        _MenuOption("Installments", Icons.calendar_month),
      ]),

      const SizedBox(height: 24),

      // --- Academic Records ---
      _buildSectionHeader("Academic Records"),
      _buildGridMenu([
        _MenuOption("Exam Results", Icons.pie_chart_outline),
        _MenuOption("Transcripts", Icons.description_outlined),
        _MenuOption("Library", Icons.menu_book),
        _MenuOption("Certificates", Icons.workspace_premium),
      ]),

      const SizedBox(height: 24),

      // --- Learning Management ---
      _buildSectionHeader("Learning Management"),
      _buildGridMenu([
        _MenuOption("Assignments", Icons.upload_file),
        _MenuOption("Course Materials", Icons.library_books),
        _MenuOption("Discussions", Icons.forum_outlined),
        _MenuOption("Grades & Rubrics", Icons.grade),
      ]),

      const SizedBox(height: 24),

      // --- Campus Life ---
      _buildSectionHeader("Campus Life"),
      _buildGridMenu([
        _MenuOption("Events", Icons.event),
        _MenuOption("Bus Tracking", Icons.directions_bus),
        _MenuOption("Cafeteria", Icons.fastfood_outlined),
        _MenuOption("Clubs", Icons.groups_outlined),
      ]),

      const SizedBox(height: 40),
    ];

    return RefreshIndicator(
      onRefresh: () async {
        _animController.reset();
        _animController.forward();
        await context.read<CourseProvider>().fetchCourses();
      },
      child: CustomScrollView(
        slivers: [
          // 1. Expanded Header
          SliverAppBar(
            expandedHeight: 180.0,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                "Hello, $firstName",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
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
                        colors: [Colors.transparent, AppColors.background],
                        stops: const [0.0, 0.95],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Animated Content Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: contentWidgets
                    .asMap()
                    .entries
                    .map((entry) => _buildAnimatedChild(entry.value, entry.key))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SHIMMER WIDGETS ---

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

  // --- WIDGET BUILDERS ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textHigh,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionBtn(
    IconData icon,
    String label,
    Color color, {
    required bool isDark,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          isLoading
              ? SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    color: isDark ? AppColors.textHigh : Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Icon(
                  icon,
                  color: isDark ? AppColors.textHigh : Colors.white,
                  size: 32,
                ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textHigh : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, top: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              course.code.substring(0, 2).toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          course.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textHigh,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.credit_card, size: 14, color: AppColors.textMedium),
              const SizedBox(width: 4),
              Text(
                "${course.credits} Credits",
                style: const TextStyle(color: AppColors.textMedium),
              ),
              const SizedBox(width: 12),
              Icon(Icons.person_outline, size: 14, color: AppColors.textMedium),
              const SizedBox(width: 4),
              Text(
                course.instructorId.isNotEmpty ? "Assigned" : "TBD",
                style: const TextStyle(color: AppColors.textMedium),
              ),
            ],
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textDisabled,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Center(
        child: Text(msg, style: const TextStyle(color: AppColors.textMedium)),
      ),
    );
  }

  Widget _buildGridMenu(List<_MenuOption> options) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, index) {
        final opt = options[index];
        return _BouncingButton(
          onTap: () => _showPlaceholder(opt.title),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(opt.icon, color: AppColors.primaryLight, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    opt.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHigh,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.fade,
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

class _MenuOption {
  final String title;
  final IconData icon;
  _MenuOption(this.title, this.icon);
}

class _BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _BouncingButton({required this.child, required this.onTap});

  @override
  State<_BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<_BouncingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
