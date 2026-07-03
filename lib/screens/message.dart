import 'package:flag/flag_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flux_virtual/Theme.dart';
import 'package:flux_virtual/screens/chatscreen.dart';
import 'package:flux_virtual/screens/notification.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class Messages extends StatefulWidget {
  const Messages({super.key});

  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, String> _contactNames = {};

  @override
  void initState() {
    super.initState();
    _loadContactNames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContactNames() async {
    try {
      final status = await FlutterContacts.permissions.request(PermissionType.read);
      if (status != PermissionStatus.granted && status != PermissionStatus.limited) return;
      final contacts = await FlutterContacts.getAll(properties: {ContactProperty.phone});
      final map = <String, String>{};
      for (final c in contacts) {
        final name = c.displayName ?? '';
        if (name.isEmpty) continue;
        for (final phone in c.phones) {
          final digits = phone.number.replaceAll(RegExp(r'\D'), '');
          if (digits.isNotEmpty) {
            map[digits] = name;
            if (digits.length > 10) {
              map[digits.substring(digits.length - 10)] = name;
            }
          }
        }
      }
      if (mounted) setState(() => _contactNames = map);
    } catch (_) {}
  }

  // Returns the saved contact name for a phone number, or the number itself.
  String _contactName(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (_contactNames.containsKey(digits)) return _contactNames[digits]!;
    if (digits.length > 10) {
      final last10 = digits.substring(digits.length - 10);
      if (_contactNames.containsKey(last10)) return _contactNames[last10]!;
    }
    return number;
  }

  // Returns avatar text: initials when name is known, last 2 digits otherwise.
  String _avatarLabel(String number) {
    final name = _contactName(number);
    if (name != number) {
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }
    final len = number.length;
    return len >= 2 ? number.substring(len - 2) : number;
  }

  String _fmtConvTime(dynamic createdAt) {
    if (createdAt == null) return '';
    final dt = createdAt is Timestamp
        ? createdAt.toDate().toLocal()
        : DateTime.tryParse(createdAt.toString())?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    if (msgDay == today) {
      return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    }
    if (msgDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  // Groups messages into threads keyed by "{otherNumber}|{myVirtualNumber}".
  // Texts from the same person to different virtual numbers are kept separate.
  Map<String, Map<String, dynamic>> _groupMessages(
    List<QueryDocumentSnapshot> docs,
  ) {
    final Map<String, Map<String, dynamic>> conversations = {};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final direction = data['direction'] as String? ?? '';
      final from = data['from'] as String? ?? '';
      final to = data['to'] as String? ?? '';

      // otherNumber = the contact, myNumber = the user's virtual number
      final otherNumber = direction == 'inbound' ? from : to;
      final myNumber = direction == 'inbound' ? to : from;

      final key = '$otherNumber|$myNumber';

      if (!conversations.containsKey(key)) {
        conversations[key] = Map<String, dynamic>.from(data)
          ..['_hasUnread'] = false
          ..['_otherNumber'] = otherNumber
          ..['_myNumber'] = myNumber;
      }

      if (direction == 'inbound' && data['read'] != true) {
        conversations[key]!['_hasUnread'] = true;
      }
    }

    return conversations;
  }

  void _showNewMessageSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewMessageSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Messages'),
        leading: uid == null
            ? null
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
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
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── Search + compose ──────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search messages',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.softOrange,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showNewMessageSheet,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      RemixIcons.edit_box_line,
                      color: AppColors.softOrange,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Conversation list ─────────────────────────
            Expanded(
              child: uid == null
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<QuerySnapshot>(
                      // No orderBy — avoids composite index requirement.
                      // _groupMessages picks the latest message per thread.
                      stream: FirebaseFirestore.instance
                          .collection('messages')
                          .where('userId', isEqualTo: uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          );
                        }

                        // Sort descending by createdAt before grouping
                        final docs = List<QueryDocumentSnapshot>.from(
                          snapshot.data?.docs ?? [],
                        );
                        docs.sort((a, b) {
                          final aT = (a.data() as Map)['createdAt'] as Timestamp?;
                          final bT = (b.data() as Map)['createdAt'] as Timestamp?;
                          if (aT == null && bT == null) return 0;
                          if (aT == null) return 1;
                          if (bT == null) return -1;
                          return bT.compareTo(aT); // descending
                        });
                        final conversations = _groupMessages(docs);

                        if (conversations.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  RemixIcons.chat_1_line,
                                  size: 64,
                                 
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                   
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the compose button to send a message',
                                  style: TextStyle(
                                    fontSize: 14,
                                   
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final filtered = conversations.entries
                            .where((e) {
                              final otherNum = e.value['_otherNumber'] as String? ?? '';
                              final q = _searchQuery.toLowerCase();
                              return otherNum.contains(q) ||
                                  _contactName(otherNum).toLowerCase().contains(q);
                            })
                            .toList();

                        return ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final data = filtered[index].value;
                            final otherNumber = data['_otherNumber'] as String? ?? '';
                            final myNumber = data['_myNumber'] as String? ?? '';
                            final body = data['body'] as String? ?? '';
                            final direction = data['direction'] as String? ?? '';
                            final hasUnread = data['_hasUnread'] == true;
                            final timeLabel = _fmtConvTime(data['createdAt']);
                            final displayName = _contactName(otherNumber);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.softOrange
                                          .withOpacity(0.15),
                                      child: Text(
                                        _avatarLabel(otherNumber),
                                        style: TextStyle(
                                          color: AppColors.softOrange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    if (hasUnread)
                                      Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Theme.of(context).scaffoldBackgroundColor,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (timeLabel.isNotEmpty)
                                      Text(
                                        timeLabel,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: hasUnread
                                              ? AppColors.softOrange
                                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (myNumber.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 2),
                                        child: Text(
                                          'via $myNumber',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.softOrange.withOpacity(0.8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      '${direction == 'inbound' ? '' : 'You: '}$body',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: hasUnread
                                            ? Theme.of(context).colorScheme.onSurface
                                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                        fontSize: 13,
                                        fontWeight: hasUnread
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => Chatscreen(
                                        otherNumber: otherNumber,
                                        fromNumber: myNumber,
                                        contactName: displayName != otherNumber
                                            ? displayName
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── New message bottom sheet ──────────────────────────────────
class _NewMessageSheet extends StatefulWidget {
  const _NewMessageSheet();

  @override
  State<_NewMessageSheet> createState() => _NewMessageSheetState();
}

class _NewMessageSheetState extends State<_NewMessageSheet> {
  final _numberController = TextEditingController();
  List<Contact> _contacts = [];
  List<Contact> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
  try {
    final status = await FlutterContacts.permissions.request(
      PermissionType.read,
    );

    if (status != PermissionStatus.granted &&
        status != PermissionStatus.limited) {
      setState(() => _isLoading = false);
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
    setState(() => _isLoading = false);
  }
}
  void _search(String query) {
  setState(() {
    _filtered = _contacts
        .where((c) =>
            (c.displayName ?? '').toLowerCase().contains(query.toLowerCase()) ||
            c.phones.any((p) => p.number.contains(query)))
        .toList();
  });
}

  void _openChat(String toNumber, {String? contactName}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final numbersSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('numbers')
        .where('active', isEqualTo: true)
        .get();

    if (numbersSnap.docs.isEmpty) {
      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('No Virtual Number'),
            content: const Text(
              'You need a virtual number to send messages. Go to the Numbers tab to get one.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.darkBrown),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.softOrange,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Get a Number'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Only one number — use it directly
    if (numbersSnap.docs.length == 1) {
      final fromNumber =
          numbersSnap.docs.first.data()['phoneNumber'] as String;
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Chatscreen(
              otherNumber: toNumber,
              fromNumber: fromNumber,
              contactName: contactName,
            ),
          ),
        );
      }
      return;
    }

    // Multiple numbers — ask which one to send from
    if (!mounted) return;
    final fromNumber = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickFromNumberSheet(
        numbers: numbersSnap.docs
            .map((d) => d.data()['phoneNumber'] as String)
            .toList(),
      ),
    );

    if (fromNumber == null || !mounted) return;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Chatscreen(
          otherNumber: toNumber,
          fromNumber: fromNumber,
          contactName: contactName,
        ),
      ),
    );
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
                  'New Message',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // manual number input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _numberController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '+1234567890 (include country code)',
                      prefixIcon: const Icon(Icons.dialpad),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_numberController.text.isNotEmpty) {
                      _openChat(_numberController.text.trim());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.softOrange,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Go'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Search contacts',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final contact = _filtered[index];
                      if (contact.phones.isEmpty) return const SizedBox();
                      final phone = contact.phones.first.number;
                     final initials = (contact.displayName ?? '')
    .trim()
    .split(' ')
    .map((e) => e.isNotEmpty ? e[0] : '')
    .take(2)
    .join()
    .toUpperCase();



                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.softOrange.withOpacity(
                            0.15,
                          ),
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: AppColors.softOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                       title: Text(contact.displayName ?? ''),
                        subtitle: Text(phone),
                        onTap: () => _openChat(phone, contactName: contact.displayName),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PickFromNumberSheet extends StatelessWidget {
  const _PickFromNumberSheet({required this.numbers});

  final List<String> numbers;

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
            padding: const EdgeInsets.all(20),
            child: Text(
              'Send from which number?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...numbers.map((phoneNum) => ListTile(
                leading: Flag.fromString(
                  _isoFromE164(phoneNum),
                  height: 24,
                  width: 36,
                ),
                title: Text(phoneNum,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, phoneNum),
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
