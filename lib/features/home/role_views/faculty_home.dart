import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/course_model.dart';
import '../../../providers/course_provider.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseFormScreen())),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<CourseProvider>().fetchCourses(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text("Faculty Dashboard", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            _buildStatSummary(context),
            const SizedBox(height: 24),
            Text("Assigned Courses", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Consumer<CourseProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                if (provider.courses.isEmpty) return const Text("No courses assigned.");

                return Column(
                  children: provider.courses.map((course) => _buildCourseTile(context, course)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatSummary(BuildContext context) {
    // This could be dynamic later
    return Row(
      children: [
        Expanded(child: _statCard("Total Classes", "12")),
        const SizedBox(width: 12),
        Expanded(child: _statCard("Avg Attendance", "85%")),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
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
        subtitle: Text(course.code),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: AppColors.textMedium),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CourseFormScreen(course: course))),
        ),
      ),
    );
  }
}