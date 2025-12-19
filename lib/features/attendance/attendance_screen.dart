// lib/features/attendance/attendance_screen.dart

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/attendance_provider.dart';

class AttendanceScreen extends StatefulWidget {
  // You might want to pass the specific session ID here
  final String? sessionId;
  final String? courseId;

  const AttendanceScreen({super.key, this.sessionId, this.courseId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isScanning = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    // Use front camera
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (mounted) {
      setState(() => _isCameraInitialized = true);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _processFaceVerification() async {
    if (!_isCameraInitialized || _cameraController == null) return;

    setState(() => _isScanning = true);

    try {
      // 1. Capture Image
      final image = await _cameraController!.takePicture();

      // 2. Convert to Base64 (Optional, if sending to API)
      // final bytes = await File(image.path).readAsBytes();
      // final base64Image = base64Encode(bytes);

      // 3. Call API Provider
      // For prototype, we use hardcoded IDs if not provided
      final success = await context.read<AttendanceProvider>().markAttendance(
        courseId: widget.courseId ?? "demo_course_001",
        sessionId: widget.sessionId ?? "demo_session_001",
        // faceImageData: base64Image,
      );

      if (mounted) {
        setState(() {
          _isScanning = false;
          _isSuccess = success;
        });

        if (!success) {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<AttendanceProvider>().error ??
                    "Verification Failed",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Camera Error: $e");
      setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            _isSuccess ? "Attendance Marked" : "Verify Identity",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSuccess
                ? "You are checked in."
                : "Position your face within the frame",
            style: const TextStyle(color: Colors.white70),
          ),

          const Spacer(),

          // Camera Preview
          Container(
            width: 300,
            height: 400,
            decoration: BoxDecoration(
              border: Border.all(
                color: _isSuccess ? Colors.green : AppColors.primary,
                width: 4,
              ),
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey[900],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _isCameraInitialized
                  ? CameraPreview(_cameraController!)
                  : const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ),

          const Spacer(),

          // Action Button
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: _isSuccess
                  ? ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text("Done"),
                    )
                  : ElevatedButton(
                      onPressed: (_isScanning || !_isCameraInitialized)
                          ? null
                          : _processFaceVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: _isScanning
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Scan Face"),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
