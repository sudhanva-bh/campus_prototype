import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/course_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../courses/course_form_screen.dart';
import '../../schedule/create_session_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  void _showPlaceholder(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$msg (Coming Soon)"),
        backgroundColor: AppColors.primaryVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userProfile;
    final firstName = user?['first_name'] ?? 'Admin';

    return CustomScrollView(
      slivers: [
        // 1. Header
        SliverAppBar(
          expandedHeight: 200.0,
          pinned: true,
          backgroundColor: AppColors.background,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text(
              "Admin Console",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  "https://images.unsplash.com/photo-1497366216548-37526070297c?q=80&w=1000&auto=format&fit=crop",
                  fit: BoxFit.cover,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome back,",
                  style: TextStyle(color: AppColors.textMedium),
                ),
                Text(
                  firstName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // --- WORKING FEATURES ---
                const Text(
                  "Core Operations",
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildOperationCard(
                  icon: Icons.add_business,
                  title: "Course Management",
                  subtitle: "Create and edit curriculum",
                  color: Colors.blueAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CourseFormScreen()),
                  ),
                ),
                _buildOperationCard(
                  icon: Icons.calendar_month_outlined,
                  title: "Schedule Sessions",
                  subtitle: "Manage master timetable",
                  color: Colors.orangeAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateSessionScreen(),
                    ),
                  ),
                ),
                _buildOperationCard(
                  icon: Icons.person_add_alt_1,
                  title: "Enroll Student",
                  subtitle: "Assign students to courses",
                  color: Colors.greenAccent,
                  onTap: () => _showEnrollDialog(context),
                ),

                // --- DUMMY FEATURES (MVP) ---
                const SizedBox(height: 32),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 16),

                const Text(
                  "Financial Management",
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildSquareBtn(
                        "Fee Reports",
                        Icons.receipt_long,
                        () => _showPlaceholder("Fee Reports"),
                      ),
                      _buildSquareBtn(
                        "Scholarships",
                        Icons.school,
                        () => _showPlaceholder("Scholarship Management"),
                      ), // Scholarship Management
                      _buildSquareBtn(
                        "Refunds",
                        Icons.replay_circle_filled,
                        () => _showPlaceholder("Refund Approvals"),
                      ), // Refund Processing
                      _buildSquareBtn(
                        "Payment Plans",
                        Icons.calendar_view_week,
                        () => _showPlaceholder("Installment Config"),
                      ), // Installment Plans
                      _buildSquareBtn(
                        "Payroll",
                        Icons.payments,
                        () => _showPlaceholder("Payroll"),
                      ),
                      _buildSquareBtn(
                        "Invoices",
                        Icons.description,
                        () => _showPlaceholder("Invoices"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  "Institution & Systems",
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildListOption(
                  Icons.admin_panel_settings,
                  "User Roles & Permissions",
                  () => _showPlaceholder("RBAC"),
                ),
                _buildListOption(
                  Icons.meeting_room,
                  "Room & Infrastructure",
                  () => _showPlaceholder("Infrastructure"),
                ),
                _buildListOption(
                  Icons.notifications_active,
                  "Notification Blast",
                  () => _showPlaceholder("Notifications"),
                ),
                _buildListOption(
                  Icons.analytics,
                  "System Analytics",
                  () => _showPlaceholder("Analytics"),
                ),
                _buildListOption(
                  Icons.security,
                  "Audit Logs",
                  () => _showPlaceholder("Audit Logs"),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOperationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHigh,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSquareBtn(String label, IconData icon, VoidCallback onTap) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.textHigh, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListOption(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: AppColors.surface,
        leading: Icon(icon, color: AppColors.textMedium),
        title: Text(title, style: const TextStyle(color: AppColors.textHigh)),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textDisabled,
        ),
      ),
    );
  }

  void _showEnrollDialog(BuildContext context) {
    final courseIdCtrl = TextEditingController();
    final studentIdCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text(
          "Enroll Student",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: courseIdCtrl,
              decoration: const InputDecoration(labelText: "Course ID"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: studentIdCtrl,
              decoration: const InputDecoration(labelText: "Student ID (UID)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await context
                  .read<CourseProvider>()
                  .enrollStudent(
                    courseIdCtrl.text.trim(),
                    studentIdCtrl.text.trim(),
                  );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(success ? "Enrolled" : "Failed")),
                );
              }
            },
            child: const Text("Enroll"),
          ),
        ],
      ),
    );
  }
}
