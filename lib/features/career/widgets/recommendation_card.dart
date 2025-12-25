import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../../../core/constants/app_colors.dart';
import '../../../providers/career_provider.dart'; // Import CareerProvider

class RecommendationCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const RecommendationCard({super.key, required this.data});

  void _showContextualInsight(BuildContext context) {
    // ... (Same as Phase 4)
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary),
                const SizedBox(width: 12),
                const Text(
                  "AI Insight",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              data['ai_explanation'] ?? "Explanation unavailable.",
              style: const TextStyle(
                color: AppColors.textHigh,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Center(child: Text("Dismiss")),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double confidence = data['confidence'] ?? 0.0;
    final bool isHighMatch = confidence >= 0.7;
    final Color matchColor = isHighMatch
        ? Colors.greenAccent
        : Colors.orangeAccent;
    final int userFeedback = data['user_feedback'] ?? 0; // 0, 1, -1

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Market Viability: ${(data['market_viability'] * 100).toInt()}%",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showContextualInsight(context),
                  icon: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: matchColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: matchColor),
                      ),
                      child: Text(
                        "${(confidence * 100).toInt()}% Match",
                        style: TextStyle(
                          color: matchColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...List.generate((data['factors'] as List).length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(
                            Icons.circle,
                            size: 4,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data['factors'][index],
                            style: const TextStyle(
                              color: AppColors.textHigh,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // PHASE 5: FEEDBACK ACTION BAR
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const SizedBox(width: 8),
                const Text(
                  "Was this helpful?",
                  style: TextStyle(color: AppColors.textDisabled, fontSize: 12),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    userFeedback == 1
                        ? Icons.thumb_up
                        : Icons.thumb_up_outlined,
                    color: userFeedback == 1
                        ? Colors.green
                        : AppColors.textMedium,
                    size: 20,
                  ),
                  onPressed: () => context
                      .read<CareerProvider>()
                      .submitFeedback(data['id'], 1),
                ),
                IconButton(
                  icon: Icon(
                    userFeedback == -1
                        ? Icons.thumb_down
                        : Icons.thumb_down_outlined,
                    color: userFeedback == -1
                        ? Colors.red
                        : AppColors.textMedium,
                    size: 20,
                  ),
                  onPressed: () => context
                      .read<CareerProvider>()
                      .submitFeedback(data['id'], -1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
