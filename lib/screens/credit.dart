import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flux_virtual/Theme.dart';
import 'package:flux_virtual/screens/paystack_webview.dart';
import 'package:flux_virtual/services/api_service.dart';
import 'package:remixicon/remixicon.dart';
import 'package:url_launcher/url_launcher.dart';

class Credit extends StatefulWidget {
  const Credit({super.key});

  @override
  State<Credit> createState() => _CreditState();
}

class _CreditState extends State<Credit> {
  bool _isLoadingSession = false;

  Future<void> _openIOSPayment() async {
    setState(() => _isLoadingSession = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email ?? '';

      final session = await ApiService.createPaymentSession(
        amount: 0,
        email: email,
      );

      if (session['sessionId'] != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaystackWebView(
              authorizationUrl:
                  'https://flux-virtual-web.vercel.app?sessionId=${session['sessionId']}',
              reference: session['sessionId'],
              isSession: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingSession = false);
    }
  }

  final List<Map<String, dynamic>> _creditPackages = [
    {'amount': 500.0, 'label': '₦500', 'bonus': ''},
    {'amount': 1000.0, 'label': '₦1,000', 'bonus': ''},
    {'amount': 2000.0, 'label': '₦2,000', 'bonus': '+₦200 bonus'},
    {'amount': 5000.0, 'label': '₦5,000', 'bonus': '+₦700 bonus'},
  ];

  void _showAddCreditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddCreditSheet(packages: _creditPackages),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Credit'),
        actions: [
          // ✅ only show on Android
          if (Theme.of(context).platform != TargetPlatform.iOS)
            IconButton(
              icon: const Icon(RemixIcons.add_circle_line),
              onPressed: _showAddCreditSheet,
            ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final balance = snapshot.data?.exists == true
                    ? (snapshot.data!.get('creditBalance') as num?)
                              ?.toDouble() ??
                          0.0
                    : 0.0;

                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 16,
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.softOrange,
                            AppColors.softOrange.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.softOrange.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Balance',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₦${balance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // replace the Add Credit button in the balance card with this
                          if (Theme.of(context).platform != TargetPlatform.iOS)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _showAddCreditSheet,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.white,
                                  foregroundColor: AppColors.softOrange,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Add Credit',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: _isLoadingSession ? null : _openIOSPayment,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _isLoadingSession
                                    ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              color: AppColors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Loading...',
                                            style: TextStyle(
                                              color: AppColors.white,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: AppColors.white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Tap to add credit via our website',
                                              style: TextStyle(
                                                color: AppColors.white,
                                                fontSize: 13,
                                                decoration:
                                                    TextDecoration.underline,
                                                decorationColor:
                                                    AppColors.white,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: AppColors.white,
                                            size: 14,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Transaction History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('transactions')
                          .orderBy('createdAt', descending: true)
                          .limit(20)
                          .snapshots(),
                      builder: (context, txSnapshot) {
                        final transactions = txSnapshot.data?.docs ?? [];

                        if (transactions.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceVariant.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                'No transactions yet',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          );
                        }

                        return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceVariant.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: List.generate(transactions.length, (
                              index,
                            ) {
                              final tx =
                                  transactions[index].data()
                                      as Map<String, dynamic>;
                              final amount =
                                  (tx['amount'] as num?)?.toDouble() ?? 0.0;
                              final status = tx['status'] as String? ?? '';
                              final isLast = index == transactions.length - 1;

                              return Column(
                                children: [
                                  ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_downward,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      'Credit Added',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      status,
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    trailing: Text(
                                      '+₦${amount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  if (!isLast)
                                    Divider(
                                      height: 1,
                                      indent: 68,
                                      color: AppColors.darkBrown.withOpacity(
                                        0.08,
                                      ),
                                    ),
                                ],
                              );
                            }),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _AddCreditSheet extends StatefulWidget {
  final List<Map<String, dynamic>> packages;
  const _AddCreditSheet({required this.packages});

  @override
  State<_AddCreditSheet> createState() => _AddCreditSheetState();
}

class _AddCreditSheetState extends State<_AddCreditSheet> {
  final _customAmountController = TextEditingController();
  int _selectedIndex = -1;
  bool _isLoading = false;
  String? _errorMessage;
  bool _useCustom = false;

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  double get _selectedAmount {
    if (_useCustom) {
      return double.tryParse(_customAmountController.text) ?? 0.0;
    }
    if (_selectedIndex >= 0) {
      return widget.packages[_selectedIndex]['amount'] as double;
    }
    return 0.0;
  }

  Future<void> _pay() async {
    if (_selectedAmount < 1.0) {
      setState(() => _errorMessage = 'Minimum amount is ₦100');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email ?? '';

      final session = await ApiService.createPaymentSession(
        amount: _selectedAmount,
        email: email,
      );

      if (session['sessionId'] != null) {
        if (mounted) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaystackWebView(
                authorizationUrl:
                    'https://flux-virtual-web.vercel.app?sessionId=${session['sessionId']}',
                reference: session['sessionId'],
                isSession: true,
              ),
            ),
          );
        }
      } else {
        setState(() => _errorMessage = 'Failed to create payment session');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final surfaceVariant = theme.colorScheme.surfaceVariant;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ───────────────────────────────────────
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: onSurface.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          // ── Title ────────────────────────────────────────
          Text(
            'Add Credit',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: onSurface,
            ),
          ),

          const SizedBox(height: 20),

          // ── Package grid ─────────────────────────────────
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: widget.packages.length,
            itemBuilder: (context, index) {
              final package = widget.packages[index];
              final isSelected = !_useCustom && _selectedIndex == index;
              final bonus = package['bonus'] as String;

              return GestureDetector(
                onTap: () => setState(() {
                  _selectedIndex = index;
                  _useCustom = false;
                  _customAmountController.clear();
                }),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.softOrange.withOpacity(0.12)
                        : surfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.softOrange
                          : onSurface.withOpacity(0.1),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        package['label'] as String,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppColors.softOrange
                              : onSurface,
                        ),
                      ),
                      if (bonus.isNotEmpty)
                        Text(
                          bonus,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // ── Custom amount ─────────────────────────────────
          GestureDetector(
            onTap: () => setState(() {
              _useCustom = true;
              _selectedIndex = -1;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: _useCustom
                    ? AppColors.softOrange.withOpacity(0.12)
                    : surfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _useCustom
                      ? AppColors.softOrange
                      : onSurface.withOpacity(0.1),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '₦',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _useCustom
                          ? AppColors.softOrange
                          : onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _customAmountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 14,
                      ),
                      onTap: () => setState(() {
                        _useCustom = true;
                        _selectedIndex = -1;
                      }),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Enter custom amount',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: onSurface.withOpacity(0.35),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Error message ─────────────────────────────────
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Pay button ────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _pay,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.softOrange, // ✅ always orange
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _selectedAmount > 0
                          ? 'Pay ₦${_selectedAmount.toStringAsFixed(2)}'
                          : 'Select an amount',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}