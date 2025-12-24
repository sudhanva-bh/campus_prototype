import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/course_provider.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedCourseId;
  DateTime _date = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  final _roomCtrl = TextEditingController();
  String _type = "Lecture";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Ensure courses are loaded to populate dropdown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().fetchCourses();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCourseId == null) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    final auth = context.read<AuthProvider>();
    final profile = auth.userProfile;
    final facultyId = profile?['user_id'] ?? profile?['userid'];

    if (facultyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not determine faculty id")),
      );
      return;
    }

    String formatDate(DateTime d) =>
        "${d.year.toString().padLeft(4, '0')}-"
            "${d.month.toString().padLeft(2, '0')}-"
            "${d.day.toString().padLeft(2, '0')}";

    String formatTime(DateTime dt) =>
        "${dt.hour.toString().padLeft(2, '0')}:"
            "${dt.minute.toString().padLeft(2, '0')}";


    setState(() => _isLoading = true);

    // Combine Date + Time
    final startDateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _endTime.hour,
      _endTime.minute,
    );

    final success = await context.read<ScheduleProvider>().createSession({
      "course_id": _selectedCourseId,
      "day_of_week": startDateTime.weekday,
      "start_date": formatDate(_date),
      "end_date": formatDate(_date),
      "start_time": formatTime(startDateTime),
      "end_time": formatTime(endDateTime),
      "faculty_id": facultyId,
      "room": _roomCtrl.text.trim(),
      "recurring": false,
      "type": _type,
    });

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Session Created")));
      } else {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create session")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Class Session")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Course Dropdown
              Consumer<CourseProvider>(
                builder: (context, courseProvider, _) {
                  return DropdownButtonFormField<String>(
                    value: _selectedCourseId,
                    hint: const Text("Select Course"),
                    items: courseProvider.courses.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text("${c.code} - ${c.name}"),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCourseId = val),
                    validator: (v) => v == null ? "Required" : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Date Picker
              _buildPickerTile(
                icon: Icons.calendar_today,
                label: "Date: ${_date.toString().split(' ')[0]}",
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 30),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _date = d);
                },
              ),
              const SizedBox(height: 16),

              // Time Pickers
              Row(
                children: [
                  Expanded(
                    child: _buildPickerTile(
                      icon: Icons.access_time,
                      label: "Start: ${_startTime.format(context)}",
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (t != null) setState(() => _startTime = t);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPickerTile(
                      icon: Icons.access_time_filled,
                      label: "End: ${_endTime.format(context)}",
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _endTime,
                        );
                        if (t != null) setState(() => _endTime = t);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Room & Type
              TextFormField(
                controller: _roomCtrl,
                decoration: const InputDecoration(
                  labelText: "Room Number (e.g. 304B)",
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: "Session Type"),
                items: ["Lecture", "Lab", "Seminar", "Exam"].map((t) {
                  return DropdownMenuItem(value: t, child: Text(t));
                }).toList(),
                onChanged: (val) => setState(() => _type = val!),
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Schedule Session"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surface,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textMedium),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}