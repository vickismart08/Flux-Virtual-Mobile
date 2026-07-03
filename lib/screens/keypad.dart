import 'package:flutter/material.dart';
import 'package:flux_virtual/Theme.dart';
import 'package:flux_virtual/screens/calling_screen.dart';
import 'package:flux_virtual/services/review_service.dart';
import 'package:flux_virtual/widget/pick_number_sheet.dart';

class Keypad extends StatefulWidget {
  const Keypad({super.key});

  @override
  State<Keypad> createState() => _KeypadState();
}

class _KeypadState extends State<Keypad> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isCalling = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _press(String value) {
    final text = _controller.text;
    final sel = _controller.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;

    final newText = text.replaceRange(start, end, value);
    final newOffset = start + value.length;

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  void _delete() {
    final text = _controller.text;
    if (text.isEmpty) return;

    final sel = _controller.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;

    if (start != end) {
      final newText = text.replaceRange(start, end, '');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start),
      );
    } else if (start > 0) {
      final newText = text.replaceRange(start - 1, start, '');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start - 1),
      );
    }
  }

  Future<void> _call() async {
    if (_controller.text.isEmpty) return;
    setState(() { _isCalling = true; _errorMessage = null; });

    try {
      final fromNumber = await pickActiveNumber(context);
      if (fromNumber == null) {
        setState(() => _errorMessage =
            'You need a virtual number to make calls. Get one in the Numbers tab.');
        return;
      }
      if (mounted) {
        ReviewService.requestReview();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallingScreen(
              toNumber: _controller.text,
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

  static const _rows = [
    [['1', ''],    ['2', 'ABC'],  ['3', 'DEF']],
    [['4', 'GHI'], ['5', 'JKL'],  ['6', 'MNO']],
    [['7', 'PQRS'],['8', 'TUV'],  ['9', 'WXYZ']],
    [['*', ''],    ['0', '+'],    ['#', '']],
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasText = _controller.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── TOP: instruction + number display ───────────
          Column(
            children: [
              const SizedBox(height: 16),
              Text(
                'Enter number with country code  e.g. +234 812 345 6789',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  readOnly: true,
                  showCursor: true,
                  textAlign: TextAlign.center,
                  enableInteractiveSelection: true,
                  cursorColor: AppColors.softOrange,
                  cursorWidth: 2,
                  cursorRadius: const Radius.circular(2),
                  style: TextStyle(
                    fontSize: hasText ? 24 : 14,
                    fontWeight: FontWeight.w300,
                    letterSpacing: hasText ? 2.5 : 0,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    hintText: '+ Enter number',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                    ),
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              ],
            ],
          ),

          // ── BOTTOM: keypad + call row ────────────────────
          Column(
            children: [
              // Keypad grid
              ..._rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < row.length; i++) ...[
                      _DialKey(
                        digit: row[i][0],
                        letters: row[i][1],
                        isDark: isDark,
                        onTap: () => _press(row[i][0]),
                        onLongPress: row[i][0] == '0' ? () => _press('+') : null,
                      ),
                      if (i < row.length - 1) const SizedBox(width: 22),
                    ],
                  ],
                ),
              )),

              const SizedBox(height: 8),

              // Call + Delete row
              SizedBox(
                width: 76.0 * 3 + 22.0 * 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Empty left slot
                    const SizedBox(width: 76, height: 76),

                    // Call button
                    GestureDetector(
                      onTap: _isCalling ? null : _call,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: _isCalling ? Colors.grey : const Color(0xFF1DB954),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1DB954).withOpacity(0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: _isCalling
                            ? const Padding(
                                padding: EdgeInsets.all(22),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.call_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                      ),
                    ),

                    // Delete / backspace
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: GestureDetector(
                        onTap: _delete,
                        onLongPress: () {
                          _controller.clear();
                          setState(() {});
                        },
                        child: Center(
                          child: Icon(
                            Icons.backspace_outlined,
                            size: 26,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(hasText ? 0.7 : 0.25),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ],
      ),
    );
  }
}

class _DialKey extends StatefulWidget {
  const _DialKey({
    required this.digit,
    required this.letters,
    required this.isDark,
    required this.onTap,
    this.onLongPress,
  });

  final String digit;
  final String letters;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<_DialKey> createState() => _DialKeyState();
}

class _DialKeyState extends State<_DialKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final baseColor = isDark
        ? Colors.white.withOpacity(0.1)
        : const Color(0xFFEDEDED);
    final pressedColor = isDark
        ? Colors.white.withOpacity(0.2)
        : const Color(0xFFD4D4D4);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      onLongPress: widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: _pressed ? pressedColor : baseColor,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.digit,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w400,
                height: 1,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (widget.letters.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                widget.letters,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.45),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
