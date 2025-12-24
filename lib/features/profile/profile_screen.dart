import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    // 1. Initialize Animation Controller
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 2. Start Animation & Fetch Data
      _animController.forward();
      context.read<AuthProvider>().fetchProfile();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleLogout() {
    context.read<AuthProvider>().logout();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _showPlaceholder(String feature) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$feature is coming soon!"),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // 3. Animation Helper
  Widget _buildAnimatedChild(Widget child, int index) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final double start = (index * 0.1).clamp(0.0, 1.0);
        final double end = (start + 0.4).clamp(0.0, 1.0);
        final curve = CurvedAnimation(
          parent: _animController,
          curve: Interval(start, end, curve: Curves.easeOutQuart),
        );

        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(curve),
            child: child!,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userProfile;

    // Show shimmer if user data is null or loading
    if (user == null) {
      return _buildShimmerProfile();
    }

    // 4. Organize content into a list for animation
    final List<Widget> contentWidgets = [
      // Profile Header
      _buildProfileHeader(user),

      const SizedBox(height: 32),

      // Contact Info
      _buildSectionHeader("Contact Information"),
      _buildInfoCard([
        _buildDetailRow(Icons.email_outlined, "Email", user['email']),
        _buildDivider(),
        _buildDetailRow(
          Icons.phone_outlined,
          "Phone",
          user['phone'] ?? "Not provided",
        ),
        _buildDivider(),
        _buildDetailRow(Icons.location_on_outlined, "Address", "Campus Dorm A"),
      ]),

      const SizedBox(height: 24),

      // Role Specific Details
      if (user['role'] == 'student' && user['student_info'] != null) ...[
        _buildSectionHeader("Academic Details"),
        _buildInfoCard([
          _buildDetailRow(
            Icons.badge_outlined,
            "Student ID",
            user['student_info']['student_id'],
          ),
          _buildDivider(),
          _buildDetailRow(
            Icons.school_outlined,
            "Program",
            user['student_info']['program'],
          ),
          _buildDivider(),
          _buildDetailRow(
            Icons.account_tree_outlined,
            "Department",
            user['student_info']['department'],
          ),
        ]),
      ] else if (user['role'] == 'faculty' && user['faculty_info'] != null) ...[
        _buildSectionHeader("Faculty Details"),
        _buildInfoCard([
          _buildDetailRow(
            Icons.badge_outlined,
            "Employee ID",
            user['faculty_info']['employee_id'],
          ),
          _buildDivider(),
          _buildDetailRow(
            Icons.work_outline,
            "Designation",
            user['faculty_info']['designation'],
          ),
        ]),
      ],

      const SizedBox(height: 24),

      // Academic Records
      // _buildSectionHeader("Academic Records"),
      // _buildInfoCard([
      //   _buildClickableRow(
      //     Icons.description_outlined,
      //     "Transcripts",
      //     () => _showPlaceholder("Transcript Download"),
      //   ),
      //   _buildDivider(),
      //   _buildClickableRow(
      //     Icons.workspace_premium_outlined,
      //     "Certificates",
      //     () => _showPlaceholder("Certificates"),
      //   ),
      //   _buildDivider(),
      //   _buildClickableRow(
      //     Icons.history_edu,
      //     "Enrollment History",
      //     () => _showPlaceholder("Enrollment History"),
      //   ),
      // ]),

      const SizedBox(height: 24),

      // Settings & Privacy
      _buildSectionHeader("Settings & Privacy"),
      _buildInfoCard([
        _buildClickableRow(
          Icons.notifications_outlined,
          "Notification Preferences",
          () => _showPlaceholder("Notification Settings"),
        ),
        _buildDivider(),
        _buildClickableRow(
          Icons.language,
          "Language",
          () => _showPlaceholder("Language Selection"),
        ),
        _buildDivider(),
        _buildClickableRow(
          Icons.lock_outline,
          "Privacy & Data Export",
          () => _showPlaceholder("GDPR Data Export"),
        ),
      ]),

      const SizedBox(height: 24),

      // Account Actions
      _buildSectionHeader("Account"),
      _buildActionTile(
        icon: Icons.edit_outlined,
        title: "Edit Profile",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditProfileScreen(initialData: user),
            ),
          );
        },
      ),
      SizedBox(height: 4,),
      const SizedBox(height: 12),
      _buildActionTile(
        icon: Icons.logout,
        title: "Logout",
        isDestructive: true,
        onTap: _handleLogout,
      ),

      const SizedBox(height: 40),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _animController.reset();
          _animController.forward();
          await auth.fetchProfile();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            // 5. Map widgets to animation helper
            children: contentWidgets
                .asMap()
                .entries
                .map((entry) => _buildAnimatedChild(entry.value, entry.key))
                .toList(),
          ),
        ),
      ),
    );
  }

  // --- SHIMMER WIDGET ---
  Widget _buildShimmerProfile() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Shimmer.fromColors(
        baseColor: AppColors.surfaceElevated,
        highlightColor: AppColors.surface,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 150,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 32),
              Column(
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 20,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- EXISTING WIDGETS ---
  Widget _buildProfileHeader(Map<String, dynamic> user) {
    final String? photoUrl = user['profile_photo_url'];
    final bool hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final String initials =
        (user['first_name']?[0] ?? '') + (user['last_name']?[0] ?? '');

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: SizedBox(
              width: 100,
              height: 100,
              child: hasPhoto
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColors.surfaceElevated,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return _buildInitialsFallback(initials);
                      },
                    )
                  : _buildInitialsFallback(initials),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "${user['first_name']} ${user['last_name']}",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Text(
            (user['role'] ?? 'Unknown').toString().toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialsFallback(String initials) {
    return Container(
      color: AppColors.surfaceElevated,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(fontSize: 32, color: AppColors.textMedium),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.textMedium, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
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
                style: const TextStyle(
                  color: AppColors.textHigh,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClickableRow(IconData icon, String label, VoidCallback onTap) {
    return _BouncingButton(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.textHigh, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textHigh,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textDisabled,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Divider(height: 1, color: AppColors.divider),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return _BouncingButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDestructive
                ? Colors.red.withOpacity(0.3)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : AppColors.textHigh,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isDestructive ? Colors.red : AppColors.textHigh,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: isDestructive
                  ? Colors.red.withOpacity(0.5)
                  : AppColors.textDisabled,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _BouncingButton({required this.child, required this.onTap});

  @override
  State<_BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<_BouncingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
