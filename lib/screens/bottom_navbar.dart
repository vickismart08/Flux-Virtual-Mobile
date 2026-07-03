import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flux_virtual/Theme.dart';
import 'package:flux_virtual/screens/Numbers.dart';
import 'package:flux_virtual/screens/Profile.dart';
import 'package:flux_virtual/screens/call.dart';
import 'package:flux_virtual/screens/calling_screen.dart';
import 'package:flux_virtual/screens/credit.dart';
import 'package:flux_virtual/screens/message.dart';
import 'package:flux_virtual/services/voice_service.dart';
import 'package:remixicon/remixicon.dart';
import 'package:twilio_voice/twilio_voice.dart';

class BottomNavbar extends StatefulWidget {
  const BottomNavbar({super.key});

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
  int currentIndex = 0;
  StreamSubscription<VoiceCallState>? _callSub;
  bool _callScreenVisible = false;

  final List<Widget> pages = [
    const Messages(),
    const CallsPage(),
    const NumbersScreen(),
    const Credit(),
    const Profile(),
  ];

  @override
  void initState() {
    super.initState();
    _initVoice();
  }

  Future<void> _initVoice() async {
    try {
      await VoiceService.instance.initialize();
    } catch (_) {
      // Not fatal — user can still make outgoing calls; log silently.
    }

    _callSub = VoiceService.instance.callStateStream.listen((state) {
      if (!mounted || _callScreenVisible) return;

      final isIncoming = VoiceService.instance.isIncomingCall;

      // Show in-app incoming call screen when the call arrives while
      // the app is in the foreground.
      if (state == VoiceCallState.incoming && isIncoming) {
        _showIncomingCall();
      }

      // Also handle the case where the user answered from the native
      // CallKit / Android screen while the app was in the background —
      // the app comes to foreground already connected.
      if (state == VoiceCallState.connected && isIncoming) {
        _showIncomingCall(alreadyConnected: true);
      }
    });
  }

  void _showIncomingCall({bool alreadyConnected = false}) {
    final activeCall = TwilioVoice.instance.call.activeCall;
    final callerNumber = activeCall?.from ?? 'Unknown';
    final toNumber = activeCall?.to ?? '';

    _callScreenVisible = true;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => CallingScreen(
              toNumber: callerNumber,
              fromNumber: toNumber,
              contactName: callerNumber,
              autoCall: false,
              isIncoming: true,
            ),
          ),
        )
        .then((_) => _callScreenVisible = false);
  }

  @override
  void dispose() {
    _callSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? AppColors.darkSurface : AppColors.white;
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.05);

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: navBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) => setState(() => currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: navBg,
            selectedItemColor: AppColors.softOrange,
            unselectedItemColor: isDark ? Colors.white38 : Colors.grey,
            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            items: [
              BottomNavigationBarItem(
                label: "Messages",
                icon: StreamBuilder<QuerySnapshot>(
                  stream: uid == null
                      ? null
                      : FirebaseFirestore.instance
                          .collection('messages')
                          .where('userId', isEqualTo: uid)
                          .snapshots(),
                  builder: (context, snap) {
                    final count = snap.data?.docs.where((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          return d['direction'] == 'inbound' &&
                              d['read'] != true;
                        }).length ??
                        0;

                    return Badge(
                      isLabelVisible: count > 0,
                      label: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: AppColors.softOrange,
                      child: const Icon(RemixIcons.chat_1_fill),
                    );
                  },
                ),
              ),
              const BottomNavigationBarItem(
                icon: Icon(RemixIcons.phone_fill),
                label: "Calls",
              ),
              const BottomNavigationBarItem(
                icon: Icon(RemixIcons.hashtag),
                label: "Numbers",
              ),
              const BottomNavigationBarItem(
                icon: Icon(RemixIcons.wallet_fill),
                label: "Credit",
              ),
              const BottomNavigationBarItem(
                icon: Icon(RemixIcons.user_3_fill),
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
