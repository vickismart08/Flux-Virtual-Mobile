import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flux_virtual/Theme.dart';
import 'package:flux_virtual/screens/chatscreen.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // group messages by conversation (by phone number)
  Map<String, Map<String, dynamic>> _groupMessages(
    List<QueryDocumentSnapshot> docs,
  ) {
    final Map<String, Map<String, dynamic>> conversations = {};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final direction = data['direction'] as String? ?? '';
      final from = data['from'] as String? ?? '';
      final to = data['to'] as String? ?? '';

      // the other party's number
      final otherNumber = direction == 'inbound' ? from : to;

      if (!conversations.containsKey(otherNumber)) {
        conversations[otherNumber] = data;
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
                      stream: FirebaseFirestore.instance
                          .collection('messages')
                          .where('userId', isEqualTo: uid)
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];
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
                            .where((e) => e.key.contains(_searchQuery))
                            .toList();

                        return ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final number = filtered[index].key;
                            final data = filtered[index].value;
                            final body = data['body'] as String? ?? '';
                            final direction =
                                data['direction'] as String? ?? '';
                            final from = data['from'] as String? ?? '';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.softOrange
                                      .withOpacity(0.15),
                                  child: Text(
                                    number.isNotEmpty
                                        ? number[number.length - 1]
                                        : '?',
                                    style: TextStyle(
                                      color: AppColors.softOrange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  number,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${direction == 'inbound' ? '' : 'You: '}$body',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.darkBrown.withOpacity(0.5),
                                    fontSize: 13,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => Chatscreen(
                                        otherNumber: number,
                                        fromNumber: direction == 'inbound'
                                            ? data['to'] as String
                                            : from,
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

  void _openChat(String toNumber) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final numbersSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('numbers')
        .where('active', isEqualTo: true)
        .limit(1)
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

    final fromNumber = numbersSnap.docs.first.data()['phoneNumber'] as String;

    if (mounted) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              Chatscreen(otherNumber: toNumber, fromNumber: fromNumber),
        ),
      );
    }
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
              color: AppColors.darkBrown.withOpacity(0.2),
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
                    color: AppColors.darkBrown,
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
                      hintText: 'Enter phone number',
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
                        onTap: () => _openChat(phone),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
