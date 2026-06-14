import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flux_virtual/Theme.dart';
import 'package:remixicon/remixicon.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  String _filter = 'all'; // all, inbound, outbound, missed

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Column(
        children: [
          // ── Header ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recents',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              PopupMenuButton<String>(
                icon: const Icon(RemixIcons.menu_2_fill),
                onSelected: (val) => setState(() => _filter = val),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'all',
                    child: Text('All calls'),
                  ),
                  const PopupMenuItem(
                    value: 'outbound',
                    child: Text('Outgoing'),
                  ),
                  const PopupMenuItem(
                    value: 'inbound',
                    child: Text('Incoming'),
                  ),
                  const PopupMenuItem(
                    value: 'missed',
                    child: Text('Missed'),
                  ),
                ],
              ),
            ],
          ),

          // ── Call list ─────────────────────────────────────
          Expanded(
            child: uid == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('callHistory')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      var docs = snapshot.data?.docs ?? [];

                      // apply filter
                      if (_filter != 'all') {
                        docs = docs.where((doc) {
                          final data =
                              doc.data() as Map<String, dynamic>;
                          final status =
                              data['status'] as String? ?? '';
                          if (_filter == 'missed') {
                            return status == 'no-answer' ||
                                status == 'busy' ||
                                status == 'failed';
                          }
                          return status == _filter;
                        }).toList();
                      }

                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                RemixIcons.phone_line,
                                size: 64,
                                
                                  
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No call history',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                 
                              
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your call history will appear here',
                                style: TextStyle(
                                  fontSize: 14,
                                  
                                   
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          final to = data['to'] as String? ?? '';
                          final from = data['from'] as String? ?? '';
                          final status =
                              data['status'] as String? ?? '';
                          final createdAt =
                              data['createdAt'] as Timestamp?;

                          // determine direction
                          final isOutbound = data['direction'] == 'outbound' ||
                              data.containsKey('to');
                          final otherNumber = isOutbound ? to : from;

                          // initials from number
                          final initials = otherNumber.isNotEmpty
                              ? otherNumber[otherNumber.length - 1]
                              : '?';

                          // format time
                          final time = createdAt != null
                              ? _formatTime(createdAt.toDate())
                              : '';

                          // call icon color
                          Color iconColor;
                          IconData callIcon;
                         if (status == 'no-answer' ||
    status == 'busy' ||
    status == 'failed') {
  iconColor = Colors.red;
  callIcon = Icons.call_missed; // ✅ Material icon
} else if (isOutbound) {
  iconColor = Colors.blue;
  callIcon = Icons.call_made; // ✅ Material icon
} else {
  iconColor = Colors.green;
  callIcon = Icons.call_received; // ✅ Material icon
}

                          return Card(
                            margin:
                                const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: iconColor.withOpacity(0.1),
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    color: iconColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                otherNumber,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Row(
                                children: [
                                  Icon(callIcon,
                                      color: iconColor, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatStatus(status),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: iconColor,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                time,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      AppColors.darkBrown.withOpacity(0.45),
                                ),
                              ),
                              onTap: () {
                                // tap to call back
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
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$hour12:$minute $period';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'no-answer':
        return 'Missed';
      case 'busy':
        return 'Busy';
      case 'failed':
        return 'Failed';
      case 'initiated':
        return 'Outgoing';
      case 'ringing':
        return 'Ringing';
      default:
        return status;
    }
  }
}