// file: lib/features/analytics/learning_insights_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../core/constants/app_colors.dart';
import '../../providers/analytics_provider.dart';
import '../../core/models/analytics_models.dart';

class LearningInsightsScreen extends StatefulWidget {
  const LearningInsightsScreen({super.key});

  @override
  State<LearningInsightsScreen> createState() => _LearningInsightsScreenState();
}

class _LearningInsightsScreenState extends State<LearningInsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().fetchTopicMastery();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Learning Intelligence"),
        backgroundColor: AppColors.background,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: "Topic Mastery"),
            Tab(text: "Learning Velocity"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MasteryListView(),
          _LearningCurveView(), // Fully Implemented
        ],
      ),
    );
  }
}

// ... (_MasteryListView and _MasteryCard remain unchanged) ...
class _MasteryListView extends StatelessWidget {
  const _MasteryListView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.topicMasteryList.isEmpty) {
      return const Center(
        child: Text(
          "No mastery data available yet.",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.topicMasteryList.length,
      itemBuilder: (context, index) {
        final mastery = provider.topicMasteryList[index];
        return _MasteryCard(mastery: mastery);
      },
    );
  }
}

class _MasteryCard extends StatelessWidget {
  final TopicMastery mastery;
  const _MasteryCard({required this.mastery});

  @override
  Widget build(BuildContext context) {
    Color barColor = Colors.redAccent;
    if (mastery.currentScore >= 80) {
      barColor = Colors.greenAccent;
    } else if (mastery.currentScore >= 50) {
      barColor = Colors.orangeAccent;
    }

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Topic ID: ${mastery.topicId}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${mastery.currentScore.toStringAsFixed(1)}%",
                  style: TextStyle(
                    color: barColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: mastery.currentScore / 100,
                backgroundColor: Colors.grey[800],
                color: barColor,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Trend: ${mastery.trend.toUpperCase()}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  "Assessments: ${mastery.contributingAssessments.length}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- PHASE 3 COMPLETE: Learning Curve Chart ---
class _LearningCurveView extends StatefulWidget {
  const _LearningCurveView();

  @override
  State<_LearningCurveView> createState() => _LearningCurveViewState();
}

class _LearningCurveViewState extends State<_LearningCurveView> {
  String? _selectedTopicId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();
    final topics = provider.topicMasteryList;

    return Column(
      children: [
        // Topic Selector
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTopicId,
              hint: const Text(
                "Select Topic to View Curve",
                style: TextStyle(color: Colors.white70),
              ),
              dropdownColor: AppColors.surfaceElevated,
              isExpanded: true,
              style: const TextStyle(color: Colors.white),
              items: topics.map((t) {
                return DropdownMenuItem(
                  value: t.topicId,
                  child: Text("Topic: ${t.topicId}"),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedTopicId = val);
                  provider.fetchLearningCurve(val);
                }
              },
            ),
          ),
        ),

        // Chart Area
        Expanded(
          child: _selectedTopicId == null
              ? const Center(
                  child: Text(
                    "Select a topic above",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : provider.learningCurve.isEmpty
              ? const Center(
                  child: Text(
                    "No data points found.",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _ChartPainter(
                      points: provider.learningCurve,
                      color: AppColors.primary,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<LearningCurvePoint> points;
  final Color color;

  _ChartPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Normalize Data
    // X-axis: Time (0 to width)
    // Y-axis: Mastery 0-100 (height to 0) - Inverted Y

    final startTime = points.first.date.millisecondsSinceEpoch;
    final endTime = points.last.date.millisecondsSinceEpoch;
    final timeRange = endTime - startTime;

    // Sort points just in case
    points.sort((a, b) => a.date.compareTo(b.date));

    final path = Path();

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      double x;
      if (timeRange == 0) {
        x = size.width / 2;
      } else {
        final t = point.date.millisecondsSinceEpoch - startTime;
        x = (t / timeRange) * size.width;
      }

      // Y: Mastery 0 is bottom (size.height), 100 is top (0)
      final y = size.height - (point.mastery / 100 * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw dot
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }

    canvas.drawPath(path, paint);

    // Draw Axis Lines (Optional aesthetic)
    final axisPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      axisPaint,
    );
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), axisPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
