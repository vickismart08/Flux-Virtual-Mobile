import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flux_virtual/Auth/email_verification_screen.dart';
import 'package:flux_virtual/Auth/onboarding.dart';
import 'package:flux_virtual/Theme.dart';
import 'package:flux_virtual/screens/bottom_navbar.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
  await Future.delayed(const Duration(seconds: 3));
  if (mounted) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.emailVerified) {
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomNavbar()),
      );
    } else if (user != null && !user.emailVerified) {
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(email: user.email!),
        ),
      );
    } else {
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softOrange,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('lib/assets/images/Flux_virtual.png'),
            const SizedBox(height: 16),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Loading...',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 50),
            Text('version 1.0.0', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}