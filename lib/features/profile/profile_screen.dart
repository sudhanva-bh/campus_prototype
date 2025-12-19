import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch fresh data when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userProfile;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditProfileScreen(initialData: user),
            ),
          );
        },
        child: const Icon(Icons.edit),
      ),
      body: RefreshIndicator(
        onRefresh: () async => await auth.fetchProfile(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Avatar
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.surfaceElevated,
                backgroundImage:
                    (user['profile_photo_url'] != null &&
                        user['profile_photo_url'].isNotEmpty)
                    ? NetworkImage(user['profile_photo_url'])
                    : null,
                child:
                    (user['profile_photo_url'] == null ||
                        user['profile_photo_url'].isEmpty)
                    ? Text(
                        (user['first_name']?[0] ?? '') +
                            (user['last_name']?[0] ?? ''),
                        style: const TextStyle(
                          fontSize: 40,
                          color: AppColors.textMedium,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 24),

              // Name & Role
              Text(
                "${user['first_name']} ${user['last_name']}",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text(
                  (user['role'] ?? 'Unknown').toString().toUpperCase(),
                ),
                backgroundColor: AppColors.primaryVariant,
                labelStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 32),

              // Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      Icons.email_outlined,
                      "Email",
                      user['email'],
                    ),
                    const Divider(height: 32, color: AppColors.divider),
                    _buildDetailRow(
                      Icons.business,
                      "Institution",
                      user['institution_id'],
                    ),

                    // Conditional Rendering based on Role
                    if (user['role'] == 'student' &&
                        user['student_info'] != null) ...[
                      const Divider(height: 32, color: AppColors.divider),
                      _buildDetailRow(
                        Icons.badge_outlined,
                        "Student ID",
                        user['student_info']['student_id'],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        Icons.school_outlined,
                        "Program",
                        user['student_info']['program'],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        Icons.account_tree_outlined,
                        "Department",
                        user['student_info']['department'],
                      ),
                    ],

                    if (user['role'] == 'faculty' &&
                        user['faculty_info'] != null) ...[
                      const Divider(height: 32, color: AppColors.divider),
                      _buildDetailRow(
                        Icons.work_outline,
                        "Designation",
                        user['faculty_info']['designation'],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        Icons.star_outline,
                        "Specialization",
                        user['faculty_info']['specialization'],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                "Pull down to refresh",
                style: TextStyle(color: AppColors.textDisabled, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textMedium, size: 20),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textDisabled,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value ?? "N/A",
              style: const TextStyle(color: AppColors.textHigh, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }
}
