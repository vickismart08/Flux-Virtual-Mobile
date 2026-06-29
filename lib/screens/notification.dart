import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flux_virtual/Theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = _uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications');
  }

  Future<void> _markAllRead(List<QueryDocumentSnapshot> docs) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['read'] != true) {
        batch.update(doc.reference, {'read': true});
      }
    }
    await batch.commit();
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  IconData _iconFor(String title) {
    final t = title.toLowerCase();
    if (t.contains('credit') || t.contains('added') || t.contains('topup')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (t.contains('number') || t.contains('activated')) {
      return Icons.phone_outlined;
    }
    if (t.contains('call')) return Icons.call_outlined;
    if (t.contains('message') || t.contains('sms')) return Icons.sms_outlined;
    if (t.contains('low')) return Icons.warning_amber_outlined;
    if (t.contains('expir') || t.contains('renew')) return Icons.update_outlined;
    if (t.contains('welcome')) return Icons.celebration_outlined;
    if (t.contains('login') || t.contains('sign')) return Icons.login_outlined;
    if (t.contains('payment') || t.contains('paid')) return Icons.receipt_outlined;
    return Icons.notifications_outlined;
  }

  void _openDetail(BuildContext context, QueryDocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    // mark read immediately
    if (data['read'] != true) {
      await doc.reference.update({'read': true});
    }
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _NotificationDetailScreen(
          title: data['title'] as String? ?? '',
          body: data['body'] as String? ?? '',
          icon: _iconFor(data['title'] as String? ?? ''),
          timestamp: data['createdAt'] as Timestamp?,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final col = _col;
    if (col == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.warmBeige,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: col.orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              final hasUnread = docs.any(
                (d) => (d.data() as Map)['read'] != true,
              );
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _markAllRead(docs),
                child: Text(
                  'Mark all read',
                  style: TextStyle(
                    color: AppColors.softOrange,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: col.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 56,
                    color: AppColors.darkBrown.withOpacity(0.18),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.darkBrown.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] as String? ?? '';
              final body = data['body'] as String? ?? '';
              final isRead = data['read'] == true;
              final ts = data['createdAt'] as Timestamp?;

              return GestureDetector(
                onTap: () => _openDetail(context, doc),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isRead
                        ? AppColors.white
                        : AppColors.softOrange.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isRead
                          ? AppColors.lightGray
                          : AppColors.softOrange.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isRead
                              ? AppColors.darkBrown.withOpacity(0.06)
                              : AppColors.softOrange.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _iconFor(title),
                          size: 20,
                          color: isRead
                              ? AppColors.darkBrown.withOpacity(0.4)
                              : AppColors.softOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isRead
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                      color: AppColors.darkBrown,
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(left: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.softOrange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            if (body.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.darkBrown.withOpacity(0.6),
                                  height: 1.4,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              _formatTime(ts),
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.darkBrown.withOpacity(0.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.darkBrown.withOpacity(0.25),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Full-page notification detail ─────────────────────────────
class _NotificationDetailScreen extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  final Timestamp? timestamp;

  const _NotificationDetailScreen({
    required this.title,
    required this.body,
    required this.icon,
    required this.timestamp,
  });

  String _fmtFull(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate().toLocal();
    const months = ['January','February','March','April','May','June',
        'July','August','September','October','November','December'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBeige,
      appBar: AppBar(
        backgroundColor: AppColors.warmBeige,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // icon circle
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.softOrange.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 34, color: AppColors.softOrange),
              ),
            ),
            const SizedBox(height: 24),

            // title
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBrown,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),

            // timestamp
            if (timestamp != null)
              Text(
                _fmtFull(timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.darkBrown.withOpacity(0.4),
                ),
              ),

            const SizedBox(height: 24),
            Divider(color: AppColors.lightGray),
            const SizedBox(height: 24),

            // full body
            Text(
              body,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.darkBrown.withOpacity(0.85),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
