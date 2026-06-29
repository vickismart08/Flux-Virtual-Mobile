import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flux_virtual/Theme.dart';
import 'package:flux_virtual/screens/calling_screen.dart';
import 'package:flux_virtual/screens/chatscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Contacts extends StatefulWidget {
  const Contacts({super.key});

  @override
  State<Contacts> createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {
  List<Contact> _contacts = [];
  List<Contact> _filtered = [];
  bool _isLoading = true;
  bool _permissionDenied = false;
  final TextEditingController _searchController = TextEditingController();
  String? _loadingPhone; // tracks which number has an in-progress action

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _permissionDenied = false;
    });

    try {
      final status = await FlutterContacts.permissions.request(
        PermissionType.read,
      );

      if (status != PermissionStatus.granted &&
          status != PermissionStatus.limited) {
        setState(() {
          _permissionDenied = true;
          _isLoading = false;
        });
        return;
      }

      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );

      contacts.sort(
        (a, b) => (a.displayName ?? '').compareTo(b.displayName ?? ''),
      );

      setState(() {
        _contacts = contacts;
        _filtered = contacts;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _permissionDenied = true;
        _isLoading = false;
      });
    }
  }

  void _search(String query) {
    setState(() {
      _filtered = _contacts
          .where(
            (c) =>
                (c.displayName ?? '').toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                c.phones.any((p) => p.number.contains(query)),
          )
          .toList();
    });
  }

  // ── Fetch the user's active virtual number ──────────────────
  Future<String?> _getActiveNumber() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('numbers')
        .where('active', isEqualTo: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data()['phoneNumber'] as String?;
  }

  // ── Call icon tapped from list ──────────────────────────────
  Future<void> _callContact(Contact contact) async {
    if (contact.phones.isEmpty) return;
    final phone = contact.phones.first.number;

    setState(() => _loadingPhone = phone);

    try {
      final fromNumber = await _getActiveNumber();
      if (fromNumber == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'You need a virtual number to make calls. Get one in the Numbers tab.',
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallingScreen(
              toNumber: phone,
              fromNumber: fromNumber,
              contactName: contact.displayName ?? '',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingPhone = null);
    }
  }

  // ── Message icon tapped from list ───────────────────────────
  Future<void> _openChatWith(Contact contact) async {
    if (contact.phones.isEmpty) return;
    final phone = contact.phones.first.number;

    setState(() => _loadingPhone = phone);

    try {
      final fromNumber = await _getActiveNumber();
      if (fromNumber == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'You need a virtual number to send messages. Get one in the Numbers tab.',
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                Chatscreen(otherNumber: phone, fromNumber: fromNumber),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingPhone = null);
    }
  }

  void _showContactSheet(Contact contact) {
    final phones = contact.phones;
    if (phones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${contact.displayName ?? 'Contact'} has no phone number',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContactActionSheet(contact: contact),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.contacts_outlined, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Contacts permission denied',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please allow contacts access in your device settings to use this feature.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadContacts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.softOrange,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_contacts.isEmpty) {
      return const Center(
        child: Text('No contacts found', style: TextStyle(fontSize: 16)),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: 'Search contacts',
              prefixIcon: const Icon(Icons.search, color: AppColors.softOrange),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _search('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_filtered.length} contacts',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        ),

        Expanded(
          child: ListView.builder(
            itemCount: _filtered.length,
            itemBuilder: (context, index) {
              final contact = _filtered[index];
              final name = contact.displayName ?? '';
              final initials = name.isNotEmpty
                  ? name
                        .trim()
                        .split(' ')
                        .map((e) => e.isNotEmpty ? e[0] : '')
                        .take(2)
                        .join()
                        .toUpperCase()
                  : '?';

              final phone = contact.phones.isNotEmpty
                  ? contact.phones.first.number
                  : null;
              final isLoading = _loadingPhone == phone;
              final anyLoading = _loadingPhone != null;

              return ListTile(
                onTap: () => _showContactSheet(contact),
                leading: CircleAvatar(
                  backgroundColor: AppColors.softOrange.withOpacity(0.15),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.softOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                title: Text(
                  contact.displayName ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                subtitle: phone != null
                    ? Text(
                        phone,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      )
                    : null,
                trailing: phone != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Call icon ────────────────────
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.green,
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.call,
                                      color: Colors.green,
                                      size: 22,
                                    ),
                                    onPressed: anyLoading
                                        ? null
                                        : () => _callContact(contact),
                                  ),
                          ),

                          const SizedBox(width: 4),

                          // ── Message icon ─────────────────
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.softOrange,
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.message,
                                      color: AppColors.softOrange,
                                      size: 22,
                                    ),
                                    onPressed: anyLoading
                                        ? null
                                        : () => _openChatWith(contact),
                                  ),
                          ),
                        ],
                      )
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Contact action bottom sheet ───────────────────────────────
class _ContactActionSheet extends StatefulWidget {
  final Contact contact;

  const _ContactActionSheet({required this.contact});

  @override
  State<_ContactActionSheet> createState() => _ContactActionSheetState();
}

class _ContactActionSheetState extends State<_ContactActionSheet> {
  bool _isCalling = false;
  bool _isMessaging = false;
  String? _errorMessage;
  String? _selectedPhone;

  @override
  void initState() {
    super.initState();
    if (widget.contact.phones.isNotEmpty) {
      _selectedPhone = widget.contact.phones.first.number;
    }
  }

  // ── Fetch active virtual number ─────────────────────────────
  Future<String?> _getActiveNumber() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('numbers')
        .where('active', isEqualTo: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data()['phoneNumber'] as String?;
  }

  Future<void> _call() async {
    if (_selectedPhone == null) return;

    setState(() {
      _isCalling = true;
      _errorMessage = null;
    });

    try {
      final fromNumber = await _getActiveNumber();
      if (fromNumber == null) {
        setState(
          () => _errorMessage = 'You need a virtual number to make calls.',
        );
        return;
      }

      if (mounted) {
        final nav = Navigator.of(context);
        nav.pop(); // close sheet
        nav.push(
          MaterialPageRoute(
            builder: (_) => CallingScreen(
              toNumber: _selectedPhone!,
              fromNumber: fromNumber,
              contactName: widget.contact.displayName ?? '',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isCalling = false);
    }
  }

  Future<void> _message() async {
    if (_selectedPhone == null) return;

    setState(() {
      _isMessaging = true;
      _errorMessage = null;
    });

    try {
      final fromNumber = await _getActiveNumber();
      if (fromNumber == null) {
        setState(
          () =>
              _errorMessage = 'You need a virtual number to send messages.',
        );
        return;
      }

      if (mounted) {
        // Capture navigator before async-induced disposal
        final nav = Navigator.of(context);
        nav.pop(); // close sheet
        nav.push(
          MaterialPageRoute(
            builder: (_) => Chatscreen(
              otherNumber: _selectedPhone!,
              fromNumber: fromNumber,
            ),
          ),
        );
      }
    } catch (_) {
      setState(() => _errorMessage = 'Something went wrong.');
    } finally {
      if (mounted) setState(() => _isMessaging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.contact.displayName ?? '';
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final initials = name.isNotEmpty
        ? name
              .trim()
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : '?';

    final isBusy = _isCalling || _isMessaging;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.softOrange.withOpacity(0.15),
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.softOrange,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            widget.contact.displayName ?? 'Unknown',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          if (widget.contact.phones.length > 1)
            DropdownButton<String>(
              value: _selectedPhone,
              items: widget.contact.phones.map((p) {
                return DropdownMenuItem(value: p.number, child: Text(p.number));
              }).toList(),
              onChanged: isBusy
                  ? null
                  : (val) => setState(() => _selectedPhone = val),
            )
          else if (widget.contact.phones.isNotEmpty)
            Text(
              widget.contact.phones.first.number,
              style: TextStyle(
                fontSize: 14,
                color: onSurface.withOpacity(0.5),
              ),
            ),

          const SizedBox(height: 24),

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
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // ── Call button ─────────────────────────────
              Column(
                children: [
                  GestureDetector(
                    onTap: isBusy ? null : _call,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: _isCalling
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.green,
                              ),
                            )
                          : const Icon(
                              Icons.call,
                              color: Colors.green,
                              size: 28,
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Call', style: TextStyle(fontSize: 12)),
                ],
              ),

              // ── Message button ──────────────────────────
              Column(
                children: [
                  GestureDetector(
                    onTap: isBusy ? null : _message,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.softOrange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: _isMessaging
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.softOrange,
                              ),
                            )
                          : const Icon(
                              Icons.message,
                              color: AppColors.softOrange,
                              size: 28,
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Message', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
