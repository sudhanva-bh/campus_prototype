import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/analytics_provider.dart';

class WellnessBattery extends StatefulWidget {
  const WellnessBattery({super.key});

  @override
  State<WellnessBattery> createState() => _WellnessBatteryState();
}

class _WellnessBatteryState extends State<WellnessBattery> {
  @override
  void initState() {
    super.initState();
    // Fetch wellness data on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().fetchWellness();
    });
  }

  @override
  Widget build(BuildContext context) {
    final wellness = context.watch<AnalyticsProvider>().wellness;

    if (wellness == null) return const SizedBox.shrink();

    // Color Logic based on Fatigue Score [cite: 264-266]
    // 0.0-0.3: Green, 0.3-0.6: Yellow, 0.6-0.8: Orange, >0.8: Red
    Color batteryColor = Colors.greenAccent;
    if (wellness.fatigueScore > 0.8) {
      batteryColor = Colors.redAccent;
    } else if (wellness.fatigueScore > 0.6) {
      batteryColor = Colors.orangeAccent;
    } else if (wellness.fatigueScore > 0.3) {
      batteryColor = Colors.yellowAccent;
    }

    // Inverse logic for "Energy Level" display (Low fatigue = High energy)
    final energyLevel = 1.0 - wellness.fatigueScore;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: batteryColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: batteryColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Battery Icon
          Icon(Icons.battery_charging_full, color: batteryColor, size: 32),
          const SizedBox(width: 16),
          
          // Text Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wellness.isOverloaded ? "⚠️ ACADEMIC OVERLOAD" : "Study Battery",
                  style: TextStyle(
                    color: wellness.isOverloaded ? Colors.redAccent : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: energyLevel,
                    backgroundColor: Colors.grey[800],
                    color: batteryColor,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  wellness.recommendation ?? "Energy Level: ${(energyLevel * 100).toInt()}%",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}