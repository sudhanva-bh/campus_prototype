import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/career_provider.dart';

class CareerChatScreen extends StatefulWidget {
  const CareerChatScreen({super.key});

  @override
  State<CareerChatScreen> createState() => _CareerChatScreenState();
}

class _CareerChatScreenState extends State<CareerChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      "role": "system",
      "text":
          "Hi! I'm your Career Assistant. I can explain recommendations, compare career paths, or identify skill gaps. How can I help today?",
    },
  ];
  bool _isTyping = false;

  void _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": text});
      _msgCtrl.clear();
      _isTyping = true;
    });

    // Simulate AI Latency
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isTyping = false);

    // Dummy Logic for "Compare" intent
    if (text.toLowerCase().contains("compare")) {
      _addComparisonResponse();
    } else {
      setState(() {
        _messages.add({
          "role": "system",
          "text":
              "I can help with that. Would you like me to analyze your skill gaps or forecast scenarios for this path?",
        });
      });
    }
  }

  void _addComparisonResponse() {
    final provider = context.read<CareerProvider>();
    final data = provider.comparisonData;

    setState(() {
      _messages.add({
        "role": "system",
        "text":
            "Here is a comparison between your top recommendations based on skill alignment and market data:",
        "is_tool_output": true,
        "data": data,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              "Career Assistant",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Typing...",
                        style: TextStyle(
                          color: AppColors.textMedium,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  );
                }

                final msg = _messages[index];
                final isUser = msg['role'] == 'user';

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.85,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser
                            ? const Radius.circular(16)
                            : Radius.zero,
                        bottomRight: isUser
                            ? Radius.zero
                            : const Radius.circular(16),
                      ),
                      border: isUser
                          ? null
                          : Border.all(color: AppColors.border),
                    ),
                    child: msg['is_tool_output'] == true
                        ? _buildComparisonTool(msg['data'])
                        : Text(
                            msg['text'],
                            style: const TextStyle(
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: const InputDecoration(
                      hintText: "Ask about careers...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Visualizes the tool output
  Widget _buildComparisonTool(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "CAREER COMPARISON",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDisabled,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 12),
        _buildCompareRow(
          "Skill Alignment",
          "${(data['skill_alignment']['a'] * 100).toInt()}%",
          "${(data['skill_alignment']['b'] * 100).toInt()}%",
        ),
        _buildCompareRow(
          "Market Viability",
          "${(data['market_viability']['a'] * 100).toInt()}%",
          "${(data['market_viability']['b'] * 100).toInt()}%",
        ),
        _buildCompareRow(
          "Time to Ready",
          data['time_to_readiness']['a'],
          data['time_to_readiness']['b'],
        ),
        const Divider(color: AppColors.border, height: 24),
        const Text(
          "PROS & CONS",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        _buildProsCons(
          "Data Scientist",
          data['pros_cons']['career_a']['pros'][0],
          data['pros_cons']['career_a']['cons'][0],
        ),
        const SizedBox(height: 8),
        _buildProsCons(
          "Product Manager",
          data['pros_cons']['career_b']['pros'][0],
          data['pros_cons']['career_b']['cons'][0],
        ),
      ],
    );
  }

  Widget _buildCompareRow(String label, String valA, String valB) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
          ),
          Row(
            children: [
              Text(
                valA,
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "vs",
                style: TextStyle(color: AppColors.textDisabled, fontSize: 10),
              ),
              const SizedBox(width: 12),
              Text(
                valB,
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProsCons(String role, String pro, String con) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          role,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.check, color: Colors.green, size: 14),
            const SizedBox(width: 4),
            Text(pro, style: const TextStyle(fontSize: 12)),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.close, color: Colors.red, size: 14),
            const SizedBox(width: 4),
            Text(con, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
