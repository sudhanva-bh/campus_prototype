import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.admin_panel_settings, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text("Admin Console", style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text("Manage users, courses, and system settings", style: TextStyle(color: AppColors.textMedium)),
        ],
      ),
    );
  }
}