import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/course_model.dart';
import '../../../providers/course_provider.dart';

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
    return RefreshIndicator(
      onRefresh: () => context.read<CourseProvider>().fetchCourses(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Student Dashboard",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          // Actions
          Row(
            children: [
              Expanded(
                child: _buildActionBtn(
                  Icons.camera_alt,
                  "Attendance",
                  AppColors.primary,
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
          Text("My Courses", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          // Course List
          Consumer<CourseProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading)
                return const Center(child: CircularProgressIndicator());
              if (provider.error != null)
                return Text(
                  provider.error!,
                  style: const TextStyle(color: Colors.red),
                );
              if (provider.courses.isEmpty)
                return const Text("No courses enrolled.");

              return Column(
                children: provider.courses
                    .map((course) => _buildCourseCard(course))
                    .toList(),
              );
            },
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
