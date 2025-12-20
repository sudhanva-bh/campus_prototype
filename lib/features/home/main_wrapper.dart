import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'role_views/student_home.dart';
import 'role_views/faculty_home.dart';
import 'role_views/admin_home.dart';
import '../profile/profile_screen.dart';
import '../schedule/schedule_screen.dart';
import '../notifications/notifications_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  // 1. Controller to handle sliding programmatically
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    setState(() => _currentIndex = index);
    // 2. Animate the PageView to the selected page
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic, // A smooth slide curve
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select((AuthProvider p) => p.userRole);

    // Determine Home Screen
    Widget homeScreen;
    switch (role) {
      case 'student':
        homeScreen = const StudentHome();
        break;
      case 'faculty':
        homeScreen = const FacultyHome();
        break;
      case 'admin':
        homeScreen = const AdminHome();
        break;
      default:
        homeScreen = const Center(child: Text("Unknown Role"));
    }

    // 3. Wrap pages in KeepAliveWrapper to save state (scroll position etc.)
    final List<Widget> pages = [
      KeepAliveWrapper(child: homeScreen),
      const KeepAliveWrapper(child: ScheduleScreen()),
      const KeepAliveWrapper(child: NotificationsScreen()),
      const KeepAliveWrapper(child: ProfileScreen()),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        // 4. Disable user swiping if you only want Nav Bar control (optional)
        // physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: pages,
      ),
      bottomNavigationBar: (role !='admin')?BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onBottomNavTapped,
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
      ):BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onBottomNavTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Home",
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

// --- HELPER WIDGET TO KEEP STATE ALIVE ---
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context); // This must be called
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true; // Prevents the page from being disposed
}
