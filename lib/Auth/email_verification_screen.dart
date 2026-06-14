import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flux_virtual/Theme.dart';
import 'package:flux_virtual/screens/bottom_navbar.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _checkTimer;
  Timer? _resendTimer;
  bool _isResendEnabled = false;
  int _resendCountdown = 60;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _startCheckingVerification();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  
  void _startCheckingVerification() {
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        _checkTimer?.cancel();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const BottomNavbar()),
          );
        }
      }
    });
  }

  
  void _startResendCountdown() {
    _resendCountdown = 60;
    _isResendEnabled = false;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_resendCountdown == 0) {
        _resendTimer?.cancel();
        setState(() => _isResendEnabled = true);
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  Future<void> _resendEmail() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      _startResendCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification email sent!'),
            backgroundColor: AppColors.softOrange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _checkManually() async {
    setState(() => _isChecking = true);
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.emailVerified) {
      _checkTimer?.cancel();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BottomNavbar()),
        );
      }
    } else {
      setState(() => _isChecking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Email not verified yet. Please check your inbox.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBeige,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),

              
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.softOrange.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 50,
                  color: AppColors.softOrange,
                ),
              ),

              const SizedBox(height: 32),

              
              Text(
                'Verify your email',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
              ),

              const SizedBox(height: 12),

              
              Text(
                'We sent a verification link to',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.darkBrown.withOpacity(0.5),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkBrown,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Click the link in the email to verify\nyour account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.darkBrown.withOpacity(0.5),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _checkManually,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBrown,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'I have verified my email',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              
              GestureDetector(
                onTap: _isResendEnabled ? _resendEmail : null,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: _isResendEnabled
                        ? AppColors.softOrange.withOpacity(0.1)
                        : AppColors.lightGray.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isResendEnabled
                          ? AppColors.softOrange.withOpacity(0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _isResendEnabled
                          ? 'Resend verification email'
                          : 'Resend in ${_resendCountdown}s',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _isResendEnabled
                            ? AppColors.softOrange
                            : AppColors.darkBrown.withOpacity(0.35),
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              
              GestureDetector(
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) Navigator.pop(context);
                },
                child: Text(
                  'Wrong email? Go back',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.darkBrown.withOpacity(0.4),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}