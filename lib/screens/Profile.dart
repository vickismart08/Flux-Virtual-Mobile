import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flux_virtual/Auth/loginscreen.dart';
import 'package:flux_virtual/Theme.dart';
import 'package:flux_virtual/screens/Appearance.dart';
import 'package:flux_virtual/screens/contact-support.dart';
import 'package:flux_virtual/screens/notification.dart';
import 'package:flux_virtual/screens/privacypolicy.dart';
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

  void _showEditProfileSheet(
    BuildContext context,
    String firstName,
    String lastName,
    String email,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        initialFirstName: firstName,
        initialLastName: lastName,
        initialEmail: email,
      ),
    );
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
                          Stack(
                            alignment: Alignment.bottomRight,
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
                              GestureDetector(
                                onTap: () => _showEditProfileSheet(
                                  context, firstName, lastName, email,
                                ),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: AppColors.softOrange,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).scaffoldBackgroundColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                ),
                              ),
                            ],
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

// ---------------------------------------------------------------------------
// Edit Profile Bottom Sheet
// ---------------------------------------------------------------------------

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.initialFirstName,
    required this.initialLastName,
    required this.initialEmail,
  });

  final String initialFirstName;
  final String initialLastName;
  final String initialEmail;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.initialFirstName);
    _lastNameCtrl = TextEditingController(text: widget.initialLastName);
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  bool get _nameChanged =>
      _firstNameCtrl.text.trim() != widget.initialFirstName ||
      _lastNameCtrl.text.trim() != widget.initialLastName;

  bool get _emailChanged =>
      _emailCtrl.text.trim().toLowerCase() !=
      widget.initialEmail.toLowerCase();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final updates = <String, dynamic>{};

      if (_nameChanged) {
        updates['firstName'] = _firstNameCtrl.text.trim();
        updates['lastName'] = _lastNameCtrl.text.trim();
      }

      final newEmail = _emailCtrl.text.trim();
      if (_emailChanged) {
        updates['email'] = newEmail;

        // Try to update Firebase Auth email (requires recent login).
        // For Google/Apple sign-in users this will silently fail — only
        // Firestore is updated, which is fine for display purposes.
        try {
          final user = FirebaseAuth.instance.currentUser!;
          await user.verifyBeforeUpdateEmail(newEmail);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'A verification link was sent to $newEmail. '
                  'Your login email will update once you verify it.',
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please log out and log back in, then try changing your email.',
                  ),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
          // Other errors (e.g. Google/Apple accounts) — still save to Firestore
        }
      }

      if (updates.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update(updates);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        controller: _firstNameCtrl,
                        label: 'First Name',
                        icon: Icons.person_outline_rounded,
                        validator: (v) =>
                            (v ?? '').trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        controller: _lastNameCtrl,
                        label: 'Last Name',
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: _emailCtrl,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final val = (v ?? '').trim();
                    if (val.isEmpty) return 'Required';
                    if (!val.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.softOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: keyboardType == null
          ? TextCapitalization.words
          : TextCapitalization.none,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}