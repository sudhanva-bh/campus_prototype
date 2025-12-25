import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/career_provider.dart';
import 'evaluation_dialog.dart';

class SimulationConsole extends StatelessWidget {
  const SimulationConsole({super.key});

  void _triggerEvent(
    BuildContext context,
    String eventType,
    String label,
  ) async {
    Navigator.pop(context); // Close sheet

    final provider = context.read<CareerProvider>();
    await provider.simulateEvent(eventType);

    if (context.mounted && provider.lastSimulationReport != null) {
      showDialog(
        context: context,
        builder: (_) =>
            EvaluationDialog(report: provider.lastSimulationReport!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.developer_mode, color: AppColors.primary),
              SizedBox(width: 12),
              Text(
                "Event Simulator (Dev)",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Trigger system events to test dynamic evaluation logic.",
            style: TextStyle(color: AppColors.textMedium, fontSize: 12),
          ),
          const SizedBox(height: 24),

          _buildSimButton(
            context,
            "exam_fail",
            "Simulate: Exam Failure",
            Colors.redAccent,
            Icons.cancel_outlined,
          ),
          _buildSimButton(
            context,
            "internship_offer",
            "Simulate: Internship Offer",
            Colors.greenAccent,
            Icons.work_outline,
          ),
          _buildSimButton(
            context,
            "market_crash",
            "Simulate: Market Crash",
            Colors.orangeAccent,
            Icons.trending_down,
          ),
        ],
      ),
    );
  }

  Widget _buildSimButton(
    BuildContext context,
    String id,
    String label,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => _triggerEvent(context, id, label),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
        tileColor: color.withOpacity(0.1),
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.play_arrow, color: AppColors.textDisabled),
      ),
    );
  }
}
