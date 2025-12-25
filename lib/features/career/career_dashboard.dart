import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/career_provider.dart';
import 'widgets/recommendation_card.dart';
import 'widgets/micro_survey_widget.dart';
import 'widgets/pathway_timeline.dart';
import 'widgets/skill_gap_chart.dart';
import 'widgets/simulation_console.dart'; // IMPORT
import 'screens/career_chat_screen.dart';

class CareerDashboardScreen extends StatefulWidget {
  const CareerDashboardScreen({super.key});

  @override
  State<CareerDashboardScreen> createState() => _CareerDashboardScreenState();
}

class _CareerDashboardScreenState extends State<CareerDashboardScreen> {
  void _showPlaceholder(String featureName) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$featureName will be implemented later."),
        backgroundColor: AppColors.primaryVariant,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // PHASE 5: Open Simulation Console
  void _openSimulationConsole() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SimulationConsole(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final careerProvider = context.watch<CareerProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "Career Intelligence",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu, color: AppColors.textMedium),
            onPressed: () => _showPlaceholder("History View"),
          ),
          IconButton(
            icon: const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.textMedium,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CareerChatScreen()),
              );
            },
          ),
        ],
      ),
      // PHASE 5: Floating Action Button for Simulations
      floatingActionButton: FloatingActionButton(
        onPressed: _openSimulationConsole,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.developer_mode, color: Colors.white),
        tooltip: "Simulate Events",
      ),
      body: careerProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGoalSelector(context, careerProvider),
                  const SizedBox(height: 24),

                  if (!careerProvider.isSurveyCompleted)
                    const MicroSurveyWidget(),

                  const Text(
                    "Recommended Pathways",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Based on your academics, skills, and market trends",
                    style: TextStyle(fontSize: 12, color: AppColors.textMedium),
                  ),
                  const SizedBox(height: 16),

                  if (careerProvider.currentRecommendations.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          "No recommendations match this goal.",
                          style: TextStyle(color: AppColors.textDisabled),
                        ),
                      ),
                    )
                  else
                    ...careerProvider.currentRecommendations.map(
                      (rec) => GestureDetector(
                        onTap: () => _showPlaceholder("Detailed Career View"),
                        child: RecommendationCard(
                          data: rec,
                        ), // Updates with Feedback
                      ),
                    ),

                  const SizedBox(height: 32),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 24),

                  // Forecast & Skill Gaps
                  const Row(
                    children: [
                      Icon(Icons.auto_graph, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        "Career Forecast",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PathwayTimeline(forecastData: careerProvider.currentForecast),

                  const SizedBox(height: 24),
                  SkillGapChart(skills: careerProvider.currentSkillGaps),

                  const SizedBox(height: 32),
                  _buildResourceSection(careerProvider),
                  const SizedBox(height: 80), // Extra space for FAB
                ],
              ),
            ),
    );
  }

  // ... (Keep existing _buildGoalSelector and _buildResourceSection from previous phases)
  Widget _buildGoalSelector(BuildContext context, CareerProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Current Target",
                  style: TextStyle(fontSize: 10, color: AppColors.textDisabled),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: provider.selectedGoal,
                    dropdownColor: AppColors.surfaceElevated,
                    isDense: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textMedium,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Data Scientist",
                        child: Text("Data Scientist"),
                      ),
                      DropdownMenuItem(
                        value: "Product Manager",
                        child: Text("Product Manager"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) provider.setGoal(val);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceSection(CareerProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Action Plan",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () => _showPlaceholder("Full Resource Library"),
              child: const Text(
                "See All",
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: provider.currentResources.length,
            itemBuilder: (context, index) {
              final res = provider.currentResources[index];
              return GestureDetector(
                onTap: () =>
                    _showPlaceholder("Resource Details: ${res['title']}"),
                child: Container(
                  width: 240,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (res['color'] as Color).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              res['tag'].toUpperCase(),
                              style: TextStyle(
                                color: res['color'],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: AppColors.textDisabled,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        res['title'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 12,
                            color: AppColors.textMedium,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            res['time'],
                            style: const TextStyle(
                              color: AppColors.textMedium,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
