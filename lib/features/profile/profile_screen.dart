import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // Access the user profile data stored in auth provider (you might need to add a getter there)
    // For now, we'll assume we can get basic info or fetch it. 
    // Ideally AuthProvider should cache the full user object.
    
    // Placeholder for actual user data access:
    final user = auth.firebaseUser; 
    final role = auth.userRole;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              // Navigate to edit and wait for result to refresh if needed
               await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
              // Trigger a refresh of profile data
              if(context.mounted) auth.checkSession(); 
            },
          ),
           IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
               auth.logout();
               Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
             CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.surfaceElevated,
              backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null ? const Icon(Icons.person, size: 60, color: AppColors.textMedium) : null,
            ),
            const SizedBox(height: 24),
            Text(
              user?.displayName ?? "User Name",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary),
              ),
              child: Text(
                role?.toUpperCase() ?? "ROLE",
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(height: 40),
            
            _buildProfileItem(Icons.email_outlined, "Email", user?.email ?? "No Email"),
            const Divider(color: AppColors.divider),
            _buildProfileItem(Icons.badge_outlined, "User ID", user?.uid.substring(0,8) ?? "N/A"), // Just showing snippet of UID
             const Divider(color: AppColors.divider),
             // Add more fields here as you expand the user model in AuthProvider
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMedium, size: 28),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textMedium, fontSize: 14)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: AppColors.textHigh, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}