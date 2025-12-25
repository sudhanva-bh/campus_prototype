import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SkillGapChart extends StatelessWidget {
  final List<Map<String, dynamic>> skills;

  const SkillGapChart({super.key, required this.skills});

  Color _getColorForType(String type) {
    switch (type) {
      case "Critical":
        return Colors.redAccent;
      case "High Impact":
        return Colors.orangeAccent;
      case "Nice to Have":
        return Colors.blueAccent;
      case "Mastered":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Skill Gap Analysis",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...skills.map((skill) {
            final double progress = skill['progress'];
            final String type = skill['type'];
            final Color color = _getColorForType(type);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        skill['skill'],
                        style: const TextStyle(
                          color: AppColors.textHigh,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        type.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.surfaceElevated,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}