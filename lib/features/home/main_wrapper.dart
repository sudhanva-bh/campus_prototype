import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'role_views/student_home.dart';
import 'role_views/faculty_home.dart';
import 'role_views/admin_home.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // Generic pages for bottom nav tabs (to be implemented later)
  final List<Widget> _placeholderTabs = [
    const Center(child: Text("Schedule/Calendar")),
    const Center(child: Text("Notifications")),
    const Center(child: Text("Profile Settings")),
  ];

  @override
  Widget build(BuildContext context) {
    final role = context.select((AuthProvider p) => p.userRole);

    // Determine the main content based on Role
    Widget bodyContent;
    if (_currentIndex == 0) {
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
    } else {
      // Show placeholder tabs for other nav items
      bodyContent = _placeholderTabs[_currentIndex - 1]; // -1 because index 0 is Home
    }

    return Scaffold(
      appBar: AppBar(
        title: SvgPicture.asset('assets/logo.svg', height: 24),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
               context.read<AuthProvider>().logout();
               Navigator.of(context).pushReplacementNamed('/');
            },
          )
        ],
      ),
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