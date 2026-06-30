import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flux_virtual/Theme.dart';
import 'package:flux_virtual/services/api_service.dart';
import 'package:remixicon/remixicon.dart';

class NumbersScreen extends StatefulWidget {
  const NumbersScreen({super.key});

  @override
  State<NumbersScreen> createState() => _NumbersScreenState();
}

class _NumbersScreenState extends State<NumbersScreen> {
  bool _isExpired(Map<String, dynamic> data) {
    final expiresAt = data['expiresAt'];
    if (expiresAt == null) return false;
    DateTime date;
    if (expiresAt is Timestamp) {
      date = expiresAt.toDate();
    } else {
      date = DateTime.parse(expiresAt.toString());
    }
    return DateTime.now().isAfter(date);
  }

  bool _isInGracePeriod(Map<String, dynamic> data) {
    final expiresAt = data['expiresAt'];
    if (expiresAt == null) return false;
    DateTime date;
    if (expiresAt is Timestamp) {
      date = expiresAt.toDate();
    } else {
      date = DateTime.parse(expiresAt.toString());
    }
    final graceEnd = date.add(const Duration(days: 7));
    return DateTime.now().isAfter(date) && DateTime.now().isBefore(graceEnd);
  }

  bool _isExpiringSoon(Map<String, dynamic> data) {
    final expiresAt = data['expiresAt'];
    if (expiresAt == null) return false;
    DateTime date;
    if (expiresAt is Timestamp) {
      date = expiresAt.toDate();
    } else {
      date = DateTime.parse(expiresAt.toString());
    }
    final daysLeft = date.difference(DateTime.now()).inDays;
    return daysLeft <= 5 && daysLeft >= 0;
  }

  bool _shouldShowRenew(Map<String, dynamic> data) {
    return _isExpiringSoon(data) || _isExpired(data) || _isInGracePeriod(data);
  }

  Color _getStatusColor(Map<String, dynamic> data) {
    if (_isInGracePeriod(data)) return Colors.orange;
    if (_isExpired(data)) return Colors.red;
    if (_isExpiringSoon(data)) return Colors.orange;
    return Colors.green;
  }

  String _getStatusLabel(Map<String, dynamic> data) {
    if (_isInGracePeriod(data)) return 'Grace Period';
    if (_isExpired(data)) return 'Expired';
    if (_isExpiringSoon(data)) return 'Expiring Soon';
    return 'Active';
  }

  String _getExpiryText(Map<String, dynamic> data) {
    final expiresAt = data['expiresAt'];
    if (expiresAt == null) return '';
    DateTime date;
    if (expiresAt is Timestamp) {
      date = expiresAt.toDate();
    } else {
      date = DateTime.parse(expiresAt.toString());
    }

    if (_isInGracePeriod(data)) {
      final graceEnd = date.add(const Duration(days: 7));
      final daysLeft = graceEnd.difference(DateTime.now()).inDays;
      return 'Grace period ends in $daysLeft days';
    }
    if (_isExpired(data)) return 'Expired on ${_formatExpiry(expiresAt)}';
    final daysLeft = date.difference(DateTime.now()).inDays;
    if (daysLeft <= 5) return 'Expires in $daysLeft days';
    return 'Expires: ${_formatExpiry(expiresAt)}';
  }

  Color _getExpiryColor(Map<String, dynamic> data, BuildContext context) {
    if (_isInGracePeriod(data)) return Colors.orange;
    if (_isExpired(data)) return Colors.red;
    if (_isExpiringSoon(data)) return Colors.orange;
    return Theme.of(context).colorScheme.onSurface.withOpacity(0.4);
  }

  Future<void> _renewNumber(String numberId, Map<String, dynamic> data) async {
    // check if past grace period
    if (_isExpired(data) && !_isInGracePeriod(data)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Grace period has ended. Please purchase a new number.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    try {
      final result = await ApiService.renewNumber(numberId: numberId);
      if (result['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Number renewed successfully for 30 days!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Renewal failed'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Something went wrong. Try again.'),
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

  String _formatExpiry(dynamic expiresAt) {
    try {
      DateTime date;
      if (expiresAt is Timestamp) {
        date = expiresAt.toDate();
      } else {
        date = DateTime.parse(expiresAt.toString());
      }
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  void _showSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SearchNumberSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
       automaticallyImplyLeading: false,
        title: const Text('Phone Numbers'),
        actions: [
          IconButton(
            icon: const Icon(RemixIcons.add_line),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Choose',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Virtual Numbers Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _showSearchSheet,
                            child: const Text('Virtual Numbers'),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // E-Sims Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);

                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Coming Soon'),
                                  content: const Text(
                                    'E-Sims will be available soon.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text('E-Sims'),
                          ),
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('numbers')
                  .orderBy('purchasedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                          const SizedBox(height: 12),
                          const Text(
                            'Failed to load numbers',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final numbers = snapshot.data?.docs ?? [];

                if (numbers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(RemixIcons.phone_line, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'No numbers yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to get a virtual number',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          // onPressed: _showSearchSheet,
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder: (context) {
                                return Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Choose',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Virtual Numbers Button
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _showSearchSheet,
                                          child: const Text('Virtual Numbers'),
                                        ),
                                      ),

                                      const SizedBox(height: 10),

                                      // E-Sims Button
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);

                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text(
                                                  'Coming Soon',
                                                ),
                                                content: const Text(
                                                  'E-Sims will be available soon.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text('OK'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          child: const Text('E-Sims'),
                                        ),
                                      ),

                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Get a number'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.softOrange,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  itemCount: numbers.length,
                  itemBuilder: (context, index) {
                    final data = numbers[index].data() as Map<String, dynamic>;
                    final phoneNumber = data['phoneNumber'] as String? ?? '';
                    final isoCountry = data['isoCountry'] as String? ?? 'US';
                    final active = data['active'] as bool? ?? false;
                    final monthlyRate = (data['monthlyRate'] as num?)?.toDouble() ?? 4999.0;

                    // in the ListView.builder replace the Card with this
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Flag.fromString(
                              isoCountry,
                              height: 24,
                              width: 36,
                            ),
                            title: Text(
                              phoneNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          data,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _getStatusLabel(data),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _getStatusColor(data),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '₦${monthlyRate.toStringAsFixed(0)}/mo',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                                if (data['expiresAt'] != null)
                                  Text(
                                    _getExpiryText(data),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _getExpiryColor(data, context),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Icon(
                              RemixIcons.arrow_right_wide_line,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),

                          // ✅ show renew button if expired or expiring soon
                          if (_shouldShowRenew(data))
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _renewNumber(numbers[index].id, data),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isInGracePeriod(data)
                                        ? Colors.orange
                                        : AppColors.softOrange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    _isInGracePeriod(data)
                                        ? 'Renew Now — ₦4,999 (Grace Period)'
                                        : 'Renew — ₦4,999',
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _SearchNumberSheet extends StatefulWidget {
  const _SearchNumberSheet();

  @override
  State<_SearchNumberSheet> createState() => _SearchNumberSheetState();
}

class _SearchNumberSheetState extends State<_SearchNumberSheet> {
  final List<Map<String, String>> _countries = [
    {'code': 'US', 'name': 'United States'},
    {'code': 'GB', 'name': 'United Kingdom'},
    {'code': 'CA', 'name': 'Canada'},
    {'code': 'AU', 'name': 'Australia'},
    {'code': 'DE', 'name': 'Germany'},
    {'code': 'FR', 'name': 'France'},
    {'code': 'NL', 'name': 'Netherlands'},
    {'code': 'SE', 'name': 'Sweden'},
  ];

  String _selectedCountry = 'US';
  String _searchedCountry = 'US';
  List<dynamic> _numbers = [];
  bool _isSearching = false;
  String? _purchasingNumber; // tracks which number is being purchased
  String? _errorMessage;

  Future<void> _search() async {
    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _numbers = [];
      _searchedCountry = _selectedCountry;
    });

    try {
      final numbers = await ApiService.searchNumbers(
        countryCode: _selectedCountry,
      );
      setState(() => _numbers = numbers);
    } catch (e) {
      final msg = e.toString();
      setState(() {
        if (msg.contains('TimeoutException') || msg.contains('timeout')) {
          _errorMessage = 'Server is starting up. Please try again in 30 seconds.';
        } else if (msg.contains('SocketException') || msg.contains('Connection')) {
          _errorMessage = 'No internet connection. Check your network and try again.';
        } else {
          _errorMessage = 'Failed to search numbers. Try again.';
        }
      });
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _confirmAndPurchase(String phoneNumber) async {
    final countryName = _countries.firstWhere(
      (c) => c['code'] == _searchedCountry,
      orElse: () => {'name': _searchedCountry},
    )['name'] ?? _searchedCountry;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmPurchaseDialog(
        phoneNumber: phoneNumber,
        countryCode: _searchedCountry,
        countryName: countryName,
        price: _getPrice(_searchedCountry),
      ),
    );

    if (confirmed != true) return;
    await _purchase(phoneNumber);
  }

  Future<void> _purchase(String phoneNumber) async {
    setState(() {
      _purchasingNumber = phoneNumber;
      _errorMessage = null;
    });

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _PurchaseLoadingDialog(),
      );
    }

    try {
      final stopwatch = Stopwatch()..start();

      final result = await ApiService.purchaseNumber(
        phoneNumber: phoneNumber,
        countryCode: _searchedCountry,
      );

      final remaining = const Duration(seconds: 10) - stopwatch.elapsed;
      if (remaining > Duration.zero) await Future.delayed(remaining);

      if (mounted) Navigator.pop(context); // close loading dialog

      if (result['success'] == true) {
        if (mounted) {
          Navigator.pop(context); // close search sheet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$phoneNumber purchased successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        setState(
          () =>
              _errorMessage = result['error'] ?? 'Purchase failed. Try again.',
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // close loading dialog
      setState(() => _errorMessage = 'Purchase failed. Try again.');
    } finally {
      if (mounted) setState(() => _purchasingNumber = null);
    }
  }
  Map<String, dynamic> _pricing = {'default': 4999};

@override
void initState() {
  super.initState();
  _loadPricing();
}

Future<void> _loadPricing() async {
  try {
    final pricing = await ApiService.getPricing();
    setState(() => _pricing = pricing);
  } catch (e) {
    // use default pricing
  }
}

double _getPrice(String countryCode) {
  final price = _pricing[countryCode] ?? _pricing['default'] ?? 4999;
  return (price as num).toDouble();
}

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
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
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Get a Number',
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        // color: AppColors.darkBrown.withOpacity(0.1),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCountry,
                        items: _countries.map((c) {
                          return DropdownMenuItem(
                            value: c['code'],
                            child: Row(
                              children: [
                                Flag.fromString(
                                  c['code']!,
                                  height: 20,
                                  width: 30,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  c['name']!,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedCountry = val!),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : _search,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.softOrange,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Search'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
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
            ),

          Expanded(
            child: _numbers.isEmpty && !_isSearching
                ? Center(
                    child: Text(
                      'Select a country and tap Search',
                      style: TextStyle(
                        // color: AppColors.darkBrown.withOpacity(0.4),
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _numbers.length,
                    itemBuilder: (context, index) {
                      final number = _numbers[index];
                      final phoneNumber =
                          number['phoneNumber'] as String? ?? '';
                      final region = number['region'] as String? ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Flag.fromString(
                            _searchedCountry,
                            height: 24,
                            width: 36,
                          ),
                          title: Text(
                            phoneNumber,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(region),
                          trailing: ElevatedButton(
                            onPressed: _purchasingNumber != null
                                ? null
                                : () => _confirmAndPurchase(phoneNumber),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.softOrange,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _purchasingNumber == phoneNumber
    ? const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
    : Text(
        Theme.of(context).platform == TargetPlatform.iOS
            ? '₦${_getPrice(_searchedCountry).toStringAsFixed(0)}/mo'
            : 'Buy ₦${_getPrice(_searchedCountry).toStringAsFixed(0)}',
        style: const TextStyle(fontSize: 13),
      ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmPurchaseDialog extends StatelessWidget {
  const _ConfirmPurchaseDialog({
    required this.phoneNumber,
    required this.countryCode,
    required this.countryName,
    required this.price,
  });

  final String phoneNumber;
  final String countryCode;
  final String countryName;
  final double price;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flag.fromString(countryCode, height: 44, width: 66),
          const SizedBox(height: 16),
          Text(
            phoneNumber,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            countryName,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.softOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '₦${price.toStringAsFixed(0)} / month',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.softOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'This number will be added to your account and renewed monthly from your credit balance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.softOrange,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Confirm — ₦${price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseLoadingDialog extends StatelessWidget {
  const _PurchaseLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 52,
              height: 52,
              child: CircularProgressIndicator(
                color: AppColors.softOrange,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Processing your purchase...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we set up\nyour new number.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
