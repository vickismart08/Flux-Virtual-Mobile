import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flux_virtual/Theme.dart';
import 'package:flux_virtual/screens/Numbers.dart';
import 'package:flux_virtual/screens/Profile.dart';
import 'package:flux_virtual/screens/call.dart';
import 'package:flux_virtual/screens/credit.dart';
import 'package:flux_virtual/screens/message.dart';
import 'package:remixicon/remixicon.dart';

class BottomNavbar extends StatefulWidget {
  const BottomNavbar({super.key});

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
  int currentIndex = 0;

  final List<Widget> pages = [
    const Messages(),
    const CallsPage(),
    const NumbersScreen(),
    const Credit(),
    const Profile(),
  ];

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
                    }).length ?? 0;

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