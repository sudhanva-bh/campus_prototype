import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class EvaluationDialog extends StatelessWidget {
  final Map<String, dynamic> report;

  const EvaluationDialog({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final decision = report['decision'] as String;
    Color statusColor;
    IconData statusIcon;

    switch (decision) {
      case "REINFORCE":
        statusColor = Colors.greenAccent;
        statusIcon = Icons.check_circle_outline;
        break;
      case "REDIRECT":
        statusColor = Colors.redAccent;
        statusIcon = Icons.warning_amber_rounded;
        break;
      case "ADJUST":
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.tune;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.info_outline;
    }

    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.terminal, color: AppColors.textMedium),
                const SizedBox(width: 8),
                const Text(
                  "SYSTEM EVALUATION REPORT",
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMedium,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.border, height: 24),

            // Decision Header
            Center(
              child: Column(
                children: [
                  Icon(statusIcon, color: statusColor, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    "DECISION: $decision",
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMetric("Old Conf.", report['old_confidence']),
                const Icon(Icons.arrow_forward, color: AppColors.textDisabled),
                _buildMetric("New Conf.", report['new_confidence']),
              ],
            ),
            const SizedBox(height: 24),

            // Rationale
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "RATIONALE:",
                    style: TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report['rationale'],
                    style: const TextStyle(
                      color: AppColors.textHigh,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Acknowledge Update"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, double val) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          "${(val * 100).toInt()}%",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
