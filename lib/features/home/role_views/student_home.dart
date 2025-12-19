import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/course_model.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../attendance/attendance_screen.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().fetchCourses();
    });
  }

  void _showPlaceholder(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$featureName module is coming soon!"),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userProfile;
    final firstName = user?['first_name'] ?? 'Student';

    return RefreshIndicator(
      onRefresh: () => context.read<CourseProvider>().fetchCourses(),
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

          // 2. Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- WORKING FEATURES ---
                  _buildSectionHeader("Quick Actions"),
                  const SizedBox(height: 8), // Reduced gap
                  Row(
                    children: [
                      Expanded(
                        child: _BouncingButton(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AttendanceScreen(),
                              ),
                            );
                          },
                          child: _buildActionBtn(
                            Icons.camera_alt_outlined,
                            "Mark Attendance",
                            AppColors.primary,
                            isDark: false,
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
                  _buildSectionHeader("Enrolled Courses"),
                  Consumer<CourseProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (provider.courses.isEmpty) {
                        return _buildEmptyState("No courses enrolled yet.");
                      }
                      return Column(
                        children: provider.courses
                            .map(
                              (course) => _BouncingButton(
                                onTap: () {
                                  _showPlaceholder(
                                    "Course Details for ${course.code}",
                                  );
                                },
                                child: _buildCourseCard(course),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),

                  // --- DUMMY FEATURES (Based on MVP Document) ---
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 16),

                  _buildSectionHeader("Academic Registration"),
                  _buildGridMenu([
                    _MenuOption("Search Catalog", Icons.search),
                    _MenuOption("Waitlists", Icons.hourglass_empty),
                    _MenuOption("Prerequisites", Icons.rule),
                    _MenuOption("Cart / Enroll", Icons.shopping_cart_outlined),
                  ]),

                  const SizedBox(height: 24),

                  _buildSectionHeader("Learning Management"),
                  _buildGridMenu([
                    _MenuOption("Assignments", Icons.upload_file),
                    _MenuOption("Course Materials", Icons.library_books),
                    _MenuOption("Discussions", Icons.forum_outlined),
                    _MenuOption("Grades & Rubrics", Icons.grade),
                  ]),

                  const SizedBox(height: 24),

                  _buildSectionHeader("Examinations"),
                  _buildGridMenu([
                    _MenuOption("Exam Schedule", Icons.calendar_month),
                    _MenuOption("Seating Plan", Icons.event_seat),
                    _MenuOption("Hall Ticket", Icons.badge),
                    _MenuOption("Results", Icons.emoji_events),
                  ]),

                  const SizedBox(height: 24),

                  _buildSectionHeader("Financial Services"),
                  _buildGridMenu([
                    _MenuOption("Pay Fees", Icons.payment),
                    _MenuOption("Scholarships", Icons.school),
                    _MenuOption("Request Refund", Icons.money_off),
                    _MenuOption("Installment Plans", Icons.calendar_view_day),
                  ]),

                  const SizedBox(height: 24),
                  _buildSectionHeader("Campus Life"),
                  _buildGridMenu([
                    _MenuOption("Events Calendar", Icons.event),
                    _MenuOption("Bus Tracking", Icons.directions_bus),
                    _MenuOption("Cafeteria", Icons.fastfood_outlined),
                    _MenuOption("Clubs & Groups", Icons.groups_outlined),
                  ]),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Updated Spacing
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8), // Reduced from 12
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
          Icon(
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
        onTap: () {
          _showPlaceholder("Course Details for ${course.code}");
        },
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

// NEW: Tap Animation Widget
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
