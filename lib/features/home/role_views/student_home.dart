import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Student Dashboard", style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        _buildActionCard(
          context,
          title: "Mark Attendance",
          icon: Icons.camera_alt,
          color: AppColors.primary,
        ),
        _buildActionCard(
          context,
          title: "My Courses",
          icon: Icons.book,
          color: AppColors.surfaceElevated,
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required IconData icon, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: AppColors.textHigh),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}