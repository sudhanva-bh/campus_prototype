import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const EditProfileScreen({super.key, this.initialData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _photoUrlCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _firstNameCtrl.text = widget.initialData!['first_name'] ?? '';
      _lastNameCtrl.text = widget.initialData!['last_name'] ?? '';
      _photoUrlCtrl.text = widget.initialData!['profile_photo_url'] ?? '';
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    
    final success = await context.read<AuthProvider>().updateProfile({
      "first_name": _firstNameCtrl.text.trim(),
      "last_name": _lastNameCtrl.text.trim(),
      "profile_photo_url": _photoUrlCtrl.text.trim(),
    });

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<AuthProvider>().errorMessage ?? "Failed to update"),
            backgroundColor: AppColors.primaryVariant,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.surfaceElevated,
              backgroundImage: _photoUrlCtrl.text.isNotEmpty ? NetworkImage(_photoUrlCtrl.text) : null,
              child: _photoUrlCtrl.text.isEmpty ? const Icon(Icons.person, size: 50) : null,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _firstNameCtrl,
              decoration: const InputDecoration(labelText: "First Name"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameCtrl,
              decoration: const InputDecoration(labelText: "Last Name"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _photoUrlCtrl,
              decoration: const InputDecoration(labelText: "Profile Photo URL"),
              onChanged: (_) => setState(() {}), // Refresh avatar preview
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading ? const CircularProgressIndicator() : const Text("Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}