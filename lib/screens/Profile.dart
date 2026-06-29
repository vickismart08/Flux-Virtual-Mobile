import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flux_virtual/Auth/loginscreen.dart';
import 'package:flux_virtual/Theme.dart';
import 'package:flux_virtual/screens/Appearance.dart';
import 'package:flux_virtual/screens/contact-support.dart';
import 'package:flux_virtual/screens/notification.dart';
import 'package:flux_virtual/screens/privacypolicy.dart';
import 'package:flux_virtual/screens/settings.dart';
import 'package:flux_virtual/services/review_service.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flux_virtual/screens/settings.dart' as app_settings;

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  late final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': RemixIcons.user_settings_line,
  'label': 'Settings',
  'screen': const app_settings.Settings(),
    },
    {
      'icon': RemixIcons.palette_line,
      'label': 'Appearance',
      'screen': const Appearance(),
    },
    {
      'icon': RemixIcons.question_line,
      'label': 'Privacy Policy',
      'screen': const PrivacyPolicyPage(),
    },
    {
      'icon': RemixIcons.headphone_line,
      'label': 'Contact Support',
      'screen': const ContactSupportPage(),
    },
    {
  'icon': RemixIcons.star_line,
  'label': 'Rate the app',
  'screen': null,
  'onTap': () => ReviewService.openStoreListing(),
},
  ];

  void _navigate(BuildContext context, Map<String, dynamic> item) {
  if (item['onTap'] != null) {
    (item['onTap'] as Function)();
    return;
  }
  final screen = item['screen'] as Widget?;
  if (screen == null) return;
  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.darkBrown),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            child: const Text(
              'Log out',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profile'),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: uid == null
                ? null
                : FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('notifications')
                    .where('read', isEqualTo: false)
                    .snapshots(),
            builder: (context, snap) {
              final unread = snap.data?.docs.length ?? 0;
              return IconButton(
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  backgroundColor: AppColors.softOrange,
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationScreen(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final data =
                    snapshot.data?.data() as Map<String, dynamic>? ?? {};
                final firstName = data['firstName'] as String? ?? '';
                final lastName = data['lastName'] as String? ?? '';
                final email = data['email'] as String? ?? '';
                final balance =
                    (data['creditBalance'] as num?)?.toDouble() ?? 0.0;
                final fullName = '$firstName $lastName'.trim();
                final initials = [firstName, lastName]
                    .where((e) => e.isNotEmpty)
                    .map((e) => e[0].toUpperCase())
                    .join();

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  children: [
                    const SizedBox(height: 20),

                    // ── Avatar & name ───────────────────────
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor:
                                AppColors.softOrange.withOpacity(0.15),
                            child: Text(
                              initials.isNotEmpty ? initials : '?',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.softOrange,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            fullName.isNotEmpty ? fullName : 'User',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 14,
                             
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Balance chip ────────────────
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.softOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  RemixIcons.wallet_line,
                                  size: 16,
                                  color: AppColors.softOrange,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '₦${balance.toStringAsFixed(2)} balance',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.softOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Menu list ───────────────────────────
                    Material(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceVariant
                          .withOpacity(0.4),
                      borderRadius: BorderRadius.circular(14),
                      child: Column(
                        children: List.generate(_menuItems.length, (index) {
                          final item = _menuItems[index];
                          final isLast = index == _menuItems.length - 1;
                          final hasScreen = item['screen'] != null;

                          return Column(
                            children: [
                              ListTile(
                               onTap: () => _navigate(context, item),
                                leading: Icon(
                                  item['icon'] as IconData,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(hasScreen ? 0.7 : 0.3),
                                  size: 22,
                                ),
                                title: Text(
                                  item['label'] as String,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(hasScreen ? 1.0 : 0.4),
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(hasScreen ? 0.4 : 0.15),
                                  size: 20,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 2,
                                ),
                              ),
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  indent: 52,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.08),
                                ),
                            ],
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Log out ─────────────────────────────
                    Material(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceVariant
                          .withOpacity(0.4),
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        onTap: _showLogoutDialog,
                        leading: const Icon(
                          Icons.logout,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                        title: const Text(
                          'Log out',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
    );
  }
}