import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/micro_survey_model.dart';
import '../../providers/survey_provider.dart';

class SurveyScreen extends StatefulWidget {
  final MicroSurvey survey;

  const SurveyScreen({super.key, required this.survey});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  // Map to store answers: {question_id: value}
  final Map<String, dynamic> _answers = {};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SurveyProvider>();
    final isPreSession = widget.survey.type == 'pre_session';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isPreSession ? "Pre-Session Check-in" : "Post-Session Feedback"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    isPreSession ? Icons.accessibility_new : Icons.rate_review,
                    color: AppColors.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      isPreSession
                          ? "Help your instructor adjust the pace by sharing your preparedness."
                          : "Your feedback triggers real-time mastery updates.",
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...widget.survey.questions.map((q) => _buildQuestionCard(q)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: provider.isLoading ? null : _submit,
                child: provider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Feedback", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(SurveyQuestion q) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              q.text,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildInputForType(q),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForType(SurveyQuestion q) {
    if (q.type == 'scale') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(q.maxScale - q.minScale + 1, (index) {
          final val = q.minScale + index;
          final isSelected = _answers[q.id] == val;
          return GestureDetector(
            onTap: () => setState(() => _answers[q.id] = val),
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? AppColors.primary : Colors.grey),
              ),
              alignment: Alignment.center,
              child: Text(
                val.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      );
    } else if (q.type == 'text') {
      return TextField(
        onChanged: (val) => _answers[q.id] = val,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Type your answer here...",
          hintStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
    return const SizedBox();
  }

  Future<void> _submit() async {
    // Basic validation
    if (_answers.length < widget.survey.questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please answer all questions"), backgroundColor: Colors.orange),
      );
      return;
    }

    final success = await context.read<SurveyProvider>().submitSurveyResponse(
      widget.survey.id,
      _answers,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Feedback submitted successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Submission failed. Try again."), backgroundColor: Colors.red),
        );
      }
    }
  }
}