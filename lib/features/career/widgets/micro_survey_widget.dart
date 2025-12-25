import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/career_provider.dart';

class MicroSurveyWidget extends StatefulWidget {
  const MicroSurveyWidget({super.key});

  @override
  State<MicroSurveyWidget> createState() => _MicroSurveyWidgetState();
}

class _MicroSurveyWidgetState extends State<MicroSurveyWidget> {
  double _confidenceValue = 5.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surfaceElevated, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                "Quick Check-in",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "How confident do you feel about your current career path?",
            style: TextStyle(color: AppColors.textMedium),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Unsure", style: TextStyle(fontSize: 10, color: AppColors.textDisabled)),
              Text(
                "${_confidenceValue.toInt()}/10",
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const Text("Confident", style: TextStyle(fontSize: 10, color: AppColors.textDisabled)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceElevated,
              thumbColor: Colors.white,
              overlayColor: AppColors.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: _confidenceValue,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (val) => setState(() => _confidenceValue = val),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                context.read<CareerProvider>().submitSurvey(_confidenceValue.toInt());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Thanks! Recommendations updated.")),
                );
              },
              child: const Text("Update Recommendations"),
            ),
          ),
        ],
      ),
    );
  }
}