import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/course_model.dart';
import '../../providers/course_provider.dart';

class CourseFormScreen extends StatefulWidget {
  final Course? course; // If null, create mode. If exists, edit mode.

  const CourseFormScreen({super.key, this.course});

  @override
  State<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends State<CourseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _creditsCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.course?.name ?? '');
    _codeCtrl = TextEditingController(text: widget.course?.code ?? '');
    _descCtrl = TextEditingController(text: widget.course?.description ?? '');
    _creditsCtrl = TextEditingController(text: widget.course?.credits.toString() ?? '3');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final provider = context.read<CourseProvider>();
    
    final data = {
      'name': _nameCtrl.text.trim(),
      'code': _codeCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'credits': int.tryParse(_creditsCtrl.text) ?? 3,
    };

    bool success;
    if (widget.course == null) {
      success = await provider.createCourse(data);
    } else {
      success = await provider.updateCourse(widget.course!.id, data);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Operation failed"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.course == null ? "Create Course" : "Edit Course")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _codeCtrl,
                decoration: const InputDecoration(labelText: "Course Code (e.g. CS101)"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Course Name"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _creditsCtrl,
                decoration: const InputDecoration(labelText: "Credits"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const CircularProgressIndicator() : const Text("Save Course"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}