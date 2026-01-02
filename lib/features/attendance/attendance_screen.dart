import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/attendance_provider.dart';

class AttendanceScreen extends StatefulWidget {
  final List<Map<String,String>?>? activeCourses;

  const AttendanceScreen({super.key, this.activeCourses,});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _scannedImage;
  bool _isScanning = false;
  bool _isSuccess = false;
  int _selectedIndex=0;
  String get selectedCourseId => widget.activeCourses?[_selectedIndex]?['courseId'] ?? "demo_course_001";
  String get selectedSessionId => widget.activeCourses?[_selectedIndex]?['sessionId'] ?? "demo_session_001";

  Future<void> _processFaceVerification() async {
    setState(() => _isScanning = true);

    try {
      final XFile? rawImage = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );

      if (rawImage == null) {
        setState(() => _isScanning = false);
        return;
      }

      final filePath = rawImage.path;
      final lastIndex = filePath.lastIndexOf(new RegExp(r'.jp'));
      final splitted = filePath.substring(0, (lastIndex));
      final outPath = "${splitted}_out${filePath.substring(lastIndex)}";

      final XFile? compressedImage = await FlutterImageCompress.compressAndGetFile(
        rawImage.path,
        outPath,
        minWidth: 1024,
        minHeight: 1364,
        quality: 50,
        rotate: 0,
      );

      if (compressedImage == null) {
        throw Exception("Image compression failed");
      }

      final File imageFile = File(compressedImage.path);
      setState(() => _scannedImage = imageFile);

      final provider = context.read<AttendanceProvider>();

      final isVerified = await provider.verifyFace(imageFile);

      if (isVerified) {
        final isMarked = await provider.markAttendance(
          courseId: widget.activeCourses![_selectedIndex]?['courseId'] ?? "demo_course_001",
          sessionId: widget.activeCourses![_selectedIndex]?['sessionId'] ?? "demo_session_001",
          imageFile: imageFile,
        );
        if (mounted) {
          setState(() {
            _isScanning = false;
            _isSuccess = isMarked;
          });
          if (!isMarked) {
            _showError(provider.error ?? "Marking Attendance Failed");
          }
        }
      } else {
        if (mounted) {
          setState(() => _isScanning = false);
          _showError(provider.error ?? "Face Verification Failed");
        }
      }
    } catch (e) {
      print("Camera/Compression Error: $e");
      if (mounted) {
        setState(() => _isScanning = false);
        _showError("Error: $e");
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
                : "Capture a clear photo of your face",
            style: const TextStyle(color: Colors.white70),
          ),

          const Spacer(),
          Text("Marking Attendance For-",style: const TextStyle(color: Colors.white70)),
          DropdownButton<int>(
            value: _selectedIndex,
            items: widget.activeCourses?.asMap().entries.map((entry) =>
                DropdownMenuItem(value: entry.key, child: Text(entry.value?['courseId'] ?? 'Unknown'))
            ).toList(),
            onChanged: (value) => setState(() => _selectedIndex = value!),
          ),
          // Image Preview Area
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
              child: _scannedImage != null
                  ? Image.file(
                _scannedImage!,
                fit: BoxFit.cover,
              )
                  : const Center(
                child: Icon(
                  Icons.camera_alt,
                  size: 64,
                  color: Colors.white24,
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
                onPressed: _isScanning ? null : _processFaceVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: _isScanning
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Open Camera"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}