import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';
import '../home/main_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Initialize Auth Check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  void _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Wait for animation slightly
    await Future.delayed(const Duration(seconds: 2));
    await authProvider.checkSession();

    if (!mounted) return;

    if (authProvider.status == AuthStatus.authenticated) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainWrapper(),
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ensure you have assets/logo.svg
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 46.0),
                child: SvgPicture.asset('assets/logo.svg', height: 120),
              ),
              const SizedBox(height: 10), // Increased spacing slightly
              // --- CHANGED TO LINEAR INDICATOR ---
              SizedBox(
                width: 200, // Constrain width to look good under the logo
                child: LinearProgressIndicator(
                  minHeight: 6, // Slightly thicker for better visibility
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                  // You can customize colors here if needed:
                  // backgroundColor: Colors.grey[300],
                  // color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
