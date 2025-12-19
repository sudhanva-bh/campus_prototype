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

  @override
  Widget build(BuildContext context) {
    // Get user name from AuthProvider
    final user = context.watch<AuthProvider>().userProfile;
    final firstName = user?['first_name'] ?? 'Student';

    return RefreshIndicator(
      onRefresh: () => context.read<CourseProvider>().fetchCourses(),
      child: CustomScrollView(
        slivers: [
          // 1. Sliver App Bar with Gradient & Image
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "Welcome, $firstName",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  Image.network(
                    "https://images.unsplash.com/photo-1541339907198-e08756dedf3f?q=80&w=1000&auto=format&fit=crop",
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) =>
                        Container(color: AppColors.surfaceElevated),
                  ),
                  // Gradient Overlay for readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.0, 0.6, 0.85, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Student Dashboard",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),

                  /// ACTION BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AttendanceScreen(),
                              ),
                            );
                          },
                          child: _buildActionBtn(
                            Icons.camera_alt,
                            "Attendance",
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionBtn(
                          Icons.qr_code,
                          "Scan QR",
                          AppColors.surfaceElevated,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Text(
                    "My Courses",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  /// COURSE LIST
                  Consumer<CourseProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (provider.error != null) {
                        return Text(
                          provider.error!,
                          style: const TextStyle(color: Colors.red),
                        );
                      }

                      if (provider.courses.isEmpty) {
                        return const Text("No courses enrolled.");
                      }

                      return Column(
                        children: provider.courses
                            .map((course) => _buildCourseCard(course))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 40), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textHigh, size: 28),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryVariant,
          child: Text(
            course.code.substring(0, 2),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        title: Text(
          course.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("${course.code} • ${course.credits} Credits"),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
