import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:flux_virtual/Theme.dart';

String _isoFromE164(String number) {
  if (number.startsWith('+44')) return 'GB';
  if (number.startsWith('+234')) return 'NG';
  if (number.startsWith('+61')) return 'AU';
  if (number.startsWith('+49')) return 'DE';
  if (number.startsWith('+33')) return 'FR';
  if (number.startsWith('+31')) return 'NL';
  if (number.startsWith('+46')) return 'SE';
  if (number.startsWith('+1')) return 'US';
  return 'US';
}

/// Returns the chosen active number, or null if the user has none / cancels.
/// Shows a picker sheet automatically when the user has more than one number.
Future<String?> pickActiveNumber(BuildContext context) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;

  final snap = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('numbers')
      .where('active', isEqualTo: true)
      .get();

  if (snap.docs.isEmpty) return null;

  if (snap.docs.length == 1) {
    return snap.docs.first.data()['phoneNumber'] as String?;
  }

  // Multiple numbers — show picker
  if (!context.mounted) return null;
  final numbers = snap.docs
      .map((d) => d.data()['phoneNumber'] as String? ?? '')
      .where((n) => n.isNotEmpty)
      .toList();

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _PickNumberSheet(numbers: numbers),
  );
}

class _PickNumberSheet extends StatelessWidget {
  const _PickNumberSheet({required this.numbers});
  final List<String> numbers;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Which number do you want to use?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          ...numbers.map(
            (num) => ListTile(
              leading: Flag.fromString(
                _isoFromE164(num),
                height: 24,
                width: 36,
              ),
              title: Text(
                num,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: AppColors.softOrange,
              ),
              onTap: () => Navigator.pop(context, num),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
