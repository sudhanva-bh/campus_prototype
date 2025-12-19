import 'package:campus_gemini_2/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'features/auth/splash_screen.dart';

// Note: Ensure you have run 'flutterfire configure' to generate firebase_options.dart
// import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (Uncomment below once firebase_options.dart is generated)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // await Firebase.initializeApp(); // For now, assuming default setup

  runApp(const CampusApp());
}

class CampusApp extends StatelessWidget {
  const CampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Campus',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme, // Enforcing Dark Theme
        home: const SplashScreen(),
      ),
    );
  }
}