import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flux_virtual/services/review_service.dart';
import 'package:flux_virtual/screens/calling_screen.dart';

class Keypad extends StatefulWidget {
  const Keypad({super.key});

  @override
  State<Keypad> createState() => _KeypadState();
}

class _KeypadState extends State<Keypad> {
  String _number = '';
  bool _isCalling = false;
  String? _errorMessage;

  void _press(String value) => setState(() {
    _number += value;
    _errorMessage = null;
  });

  void _delete() {
    if (_number.isNotEmpty) {
      setState(() => _number = _number.substring(0, _number.length - 1));
    }
  }

  Future<void> _call() async {
    if (_number.isEmpty) return;

    setState(() {
      _isCalling = true;
      _errorMessage = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => _errorMessage = 'Not logged in');
        return;
      }

      final numbersSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('numbers')
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      if (numbersSnap.docs.isEmpty) {
        setState(
          () => _errorMessage =
              'You need a virtual number to make calls. Get one in the Numbers tab.',
        );
        return;
      }

      final fromNumber = numbersSnap.docs.first.data()['phoneNumber'] as String;

      if (mounted) {
        ReviewService.requestReview();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallingScreen(
              toNumber: _number,
              fromNumber: fromNumber,
              contactName: '',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().contains('TimeoutException')
          ? 'Server is waking up — please try again in a few seconds.'
          : 'Error: $e');
    } finally {
      if (mounted) setState(() => _isCalling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),

          SizedBox(
            height: 50,
            child: Center(
              child: Text(
                _number.isEmpty ? '+  Enter number with country code' : _number,
                style: _number.isEmpty
                    ? TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.35),
                      )
                    : const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 4,
                      ),
              ),
            ),
          ),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ),
            ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [
                _Key(digit: '1', letters: '', isDark: isDark, onTap: _press),
                _Key(digit: '2', letters: 'ABC', isDark: isDark, onTap: _press),
                _Key(digit: '3', letters: 'DEF', isDark: isDark, onTap: _press),
                _Key(digit: '4', letters: 'GHI', isDark: isDark, onTap: _press),
                _Key(digit: '5', letters: 'JKL', isDark: isDark, onTap: _press),
                _Key(digit: '6', letters: 'MNO', isDark: isDark, onTap: _press),
                _Key(
                  digit: '7',
                  letters: 'PQRS',
                  isDark: isDark,
                  onTap: _press,
                ),
                _Key(digit: '8', letters: 'TUV', isDark: isDark, onTap: _press),
                _Key(
                  digit: '9',
                  letters: 'WXYZ',
                  isDark: isDark,
                  onTap: _press,
                ),
                _Key(digit: '*', letters: '', isDark: isDark, onTap: _press),
                _Key(
                  digit: '0',
                  letters: '+',
                  isDark: isDark,
                  onTap: _press,
                  onLongPress: () {
                    setState(() {
                      _number += '+';

                      _errorMessage = null;
                    });
                  },
                ),
                _Key(digit: '#', letters: '', isDark: isDark, onTap: _press),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(width: 60, height: 60),

                GestureDetector(
                  onTap: _isCalling ? null : _call,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isCalling ? Colors.grey : const Color(0xFF1DB954),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1DB954).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isCalling
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.call, color: Colors.white, size: 26),
                  ),
                ),

                _number.isNotEmpty
                    ? GestureDetector(
                        onTap: _delete,
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: Icon(
                            Icons.backspace_outlined,
                            size: 22,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      )
                    : const SizedBox(width: 60, height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.digit,
    required this.letters,
    required this.isDark,
    required this.onTap,
    this.onLongPress,
  });

  final String digit;
  final String letters;
  final bool isDark;
  final void Function(String) onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onTap(digit),
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              digit,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w300),
            ),
            if (letters.isNotEmpty)
              Text(
                letters,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
