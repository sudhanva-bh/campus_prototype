import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isScanning = false;
  bool _isSuccess = false;

  void _startScan() async {
    setState(() => _isScanning = true);
    
    // Simulate API/Processing Delay
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isScanning = false;
      _isSuccess = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            _isSuccess ? "Attendance Marked" : "Verify Identity",
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _isSuccess ? "You are checked in for today." : "Position your face within the frame",
            style: const TextStyle(color: Colors.white70),
          ),
          const Spacer(),
          
          // Camera Frame Simulation
          Center(
            child: Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(color: _isSuccess ? Colors.green : AppColors.primary, width: 4),
                borderRadius: BorderRadius.circular(20),
                color: Colors.grey[900], // Placeholder for camera feed
              ),
              child: _isScanning 
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _isSuccess
                  ? const Center(child: Icon(Icons.check_circle, color: Colors.green, size: 80))
                  : const Center(child: Icon(Icons.face, color: Colors.white24, size: 100)),
            ),
          ),
          
          const Spacer(),
          
          if (!_isSuccess && !_isScanning)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startScan,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text("Start Face Scan"),
                ),
              ),
            ),
          
          if (_isSuccess)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Done"),
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}