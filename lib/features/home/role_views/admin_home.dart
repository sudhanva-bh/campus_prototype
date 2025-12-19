import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/course_provider.dart';
import '../../courses/course_form_screen.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Admin Console", style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        
        _buildAdminOption(
          context,
          icon: Icons.add_box,
          title: "Create New Course",
          subtitle: "Define new curriculum entries",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourseFormScreen())),
        ),
        
        _buildAdminOption(
          context,
          icon: Icons.people_alt,
          title: "Enroll Student",
          subtitle: "Assign students to specific courses",
          onTap: () => _showEnrollDialog(context),
        ),

        _buildAdminOption(
          context,
          icon: Icons.settings,
          title: "System Settings",
          subtitle: "Configure global parameters",
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildAdminOption(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textMedium)),
        onTap: onTap,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  void _showEnrollDialog(BuildContext context) {
    final courseIdCtrl = TextEditingController();
    final studentIdCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Enroll Student"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: courseIdCtrl, decoration: const InputDecoration(labelText: "Course ID")),
            const SizedBox(height: 12),
            TextField(controller: studentIdCtrl, decoration: const InputDecoration(labelText: "Student ID")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final success = await context.read<CourseProvider>().enrollStudent(
                courseIdCtrl.text.trim(),
                studentIdCtrl.text.trim(),
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(success ? "Enrolled Successfully" : "Enrollment Failed")),
                );
              }
            },
            child: const Text("Enroll"),
          ),
        ],
      ),
    );
  }
}