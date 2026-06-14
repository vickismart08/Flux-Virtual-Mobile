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
            unselectedItemColor: isDark
                ? Colors.white38        
                : Colors.grey,
            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(RemixIcons.chat_1_fill),
                label: "Messages",
              ),
              BottomNavigationBarItem(
                icon: Icon(RemixIcons.phone_fill),
                label: "Calls",
              ),
              BottomNavigationBarItem(
                icon: Icon(RemixIcons.hashtag),
                label: "Numbers",
              ),
              BottomNavigationBarItem(
                icon: Icon(RemixIcons.wallet_fill),
                label: "Credit",
              ),
              BottomNavigationBarItem(
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