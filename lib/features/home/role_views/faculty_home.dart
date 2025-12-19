import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class FacultyHome extends StatelessWidget {
  const FacultyHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Faculty Dashboard", style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        _buildStatGrid(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Upcoming Class", style: TextStyle(color: AppColors.textMedium)),
              SizedBox(height: 8),
              Text("CS101 - Intro to AI", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text("09:00 AM - Room 304"),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildStatGrid() {
    return Row(
      children: [
        Expanded(child: _statCard("Classes", "4")),
        const SizedBox(width: 12),
        Expanded(child: _statCard("Students", "120")),
      ],
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
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
          Text(label, style: const TextStyle(color: AppColors.textMedium)),
        ],
      ),
    );
  }
}