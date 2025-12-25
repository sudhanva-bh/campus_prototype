import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PathwayTimeline extends StatefulWidget {
  final Map<String, dynamic> forecastData;

  const PathwayTimeline({super.key, required this.forecastData});

  @override
  State<PathwayTimeline> createState() => _PathwayTimelineState();
}

class _PathwayTimelineState extends State<PathwayTimeline> {
  String _selectedHorizon = "short_term"; // short_term, medium_term, long_term

  @override
  Widget build(BuildContext context) {
    final currentData = widget.forecastData[_selectedHorizon];

    return Column(
      children: [
        // Horizon Selector
        Container(
          height: 40,
          margin: const EdgeInsets.only(bottom: 16),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildTab("Short Term (1y)", "short_term"),
              const SizedBox(width: 8),
              _buildTab("Medium Term (1-3y)", "medium_term"),
              const SizedBox(width: 8),
              _buildTab("Long Term (3y+)", "long_term"),
            ],
          ),
        ),

        // Scenarios
        if (currentData != null) ...[
          _buildScenarioCard(
            "Best Case",
            currentData['best_case'],
            Colors.greenAccent,
            currentData['prob_best'],
          ),
          _buildScenarioCard(
            "Likely Case",
            currentData['likely_case'],
            Colors.blueAccent,
            currentData['prob_likely'],
          ),
          _buildScenarioCard(
            "Risk Case",
            currentData['risk_case'],
            Colors.orangeAccent,
            null, // Risk doesn't usually get a "success probability" in the UI context
          ),
        ],
      ],
    );
  }

  Widget _buildTab(String label, String key) {
    final isSelected = _selectedHorizon == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedHorizon = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMedium,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildScenarioCard(String title, String outcome, Color color, double? probability) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.05), Colors.transparent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.timeline, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  outcome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (probability != null)
            Column(
              children: [
                Text(
                  "${(probability * 100).toInt()}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Text(
                  "Prob.",
                  style: TextStyle(color: AppColors.textDisabled, fontSize: 10),
                ),
              ],
            ),
        ],
      ),
    );
  }
}