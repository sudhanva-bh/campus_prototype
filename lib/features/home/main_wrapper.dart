import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import 'role_views/student_home.dart';
import 'role_views/faculty_home.dart';
import 'role_views/admin_home.dart';
import '../profile/profile_screen.dart'; // Import the new screen

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // Placeholder tabs for index 1 and 2
  final List<Widget> _intermediateTabs = [
    const Center(child: Text("Schedule/Calendar (Coming Soon)")),
    const Center(child: Text("Notifications (Coming Soon)")),
  ];

  @override
  Widget build(BuildContext context) {
    final role = context.select((AuthProvider p) => p.userRole);

    Widget bodyContent;

    // Logic to switch tabs
    if (_currentIndex == 0) {
      // HOME TAB: varies by role
      switch (role) {
        case 'student':
          bodyContent = const StudentHome();
          break;
        case 'faculty':
          bodyContent = const FacultyHome();
          break;
        case 'admin':
          bodyContent = const AdminHome();
          break;
        default:
          bodyContent = const Center(child: Text("Unknown Role"));
      }
    } else if (_currentIndex == 3) {
      // PROFILE TAB: Index 3
      bodyContent = const ProfileScreen();
    } else {
      // OTHER TABS
      bodyContent = _intermediateTabs[_currentIndex - 1];
    }

    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
              title: SvgPicture.asset('assets/logo.svg', height: 24),
              centerTitle: true,
              automaticallyImplyLeading: false, // Hide back button
            )
          : null, // Hide AppBar on Profile as it has its own
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: bodyContent,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: "Schedule",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: "Alerts",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
