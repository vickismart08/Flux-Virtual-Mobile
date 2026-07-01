import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flux_virtual/Theme.dart';
import 'package:flux_virtual/screens/calling_screen.dart';
import 'package:flux_virtual/services/api_service.dart';

class _PendingMsg {
  final String body;
  final DateTime sentAt;
  bool sending = true;

  _PendingMsg({required this.body, required this.sentAt});
}

class Chatscreen extends StatefulWidget {
  final String otherNumber;
  final String fromNumber;
  final String? contactName;

  const Chatscreen({
    super.key,
    required this.otherNumber,
    required this.fromNumber,
    this.contactName,
  });

  @override
  State<Chatscreen> createState() => _ChatscreenState();
}

class _ChatscreenState extends State<Chatscreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_PendingMsg> _pendingMsgs = [];

  bool get _isSending => _pendingMsgs.any((p) => p.sending);

  @override
  void initState() {
    super.initState();
    _markConversationRead();
  }

  Future<void> _markConversationRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final fromE164 = ApiService.toE164(widget.fromNumber);
    final otherE164 = ApiService.toE164(widget.otherNumber);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('messages')
          .where('userId', isEqualTo: uid)
          .get();
      final batch = FirebaseFirestore.instance.batch();
      bool hasPending = false;
      for (final doc in snap.docs) {
        final d = doc.data();
        if (d['direction'] == 'inbound' &&
            d['from'] == otherE164 &&
            d['to'] == fromE164 &&
            d['read'] != true) {
          batch.update(doc.reference, {'read': true});
          hasPending = true;
        }
      }
      if (hasPending) await batch.commit();
    } catch (_) {}
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _dateSeparatorLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  Widget _buildDateSeparator(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12))),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final pending = _PendingMsg(body: text, sentAt: DateTime.now());
    setState(() => _pendingMsgs.add(pending));

    try {
      final result = await ApiService.sendSMS(
        to: widget.otherNumber,
        from: widget.fromNumber,
        body: text,
      );

      if (!mounted) return;
      if (result['success'] != true) {
        setState(() => _pendingMsgs.remove(pending));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to send message'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        setState(() => pending.sending = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _pendingMsgs.remove(pending));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('TimeoutException')
                  ? 'Server is waking up — please try again in a few seconds.'
                  : 'Error: $e',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Widget _buildBubble({
    required BuildContext context,
    required String body,
    required bool isOutbound,
    String? statusText,
    bool isSending = false,
    bool isFailed = false,
  }) {
    Color statusColor;
    if (isFailed) {
      statusColor = Colors.redAccent;
    } else {
      statusColor =
          Theme.of(context).colorScheme.onSurface.withOpacity(0.45);
    }

    return Align(
      alignment: isOutbound ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isOutbound ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isOutbound
                  ? (isFailed
                      ? Colors.redAccent.withOpacity(0.15)
                      : AppColors.softOrange)
                  : Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.6),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isOutbound ? 16 : 4),
                bottomRight: Radius.circular(isOutbound ? 4 : 16),
              ),
            ),
            child: Text(
              body,
              style: TextStyle(
                color: isOutbound
                    ? (isFailed ? Colors.redAccent : AppColors.white)
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
          ),
          if (statusText != null) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSending)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.4),
                      ),
                    ),
                  ),
                if (isFailed)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.error_outline,
                        size: 12, color: Colors.redAccent),
                  ),
                Text(
                  statusText,
                  style: TextStyle(fontSize: 11, color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ] else
            const SizedBox(height: 4),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.contactName ?? widget.otherNumber,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.contactName != null
                  ? '${widget.otherNumber} · From: ${widget.fromNumber}'
                  : 'From: ${widget.fromNumber}',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            color: Colors.green,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CallingScreen(
                    toNumber: widget.otherNumber,
                    fromNumber: widget.fromNumber,
                    contactName: widget.contactName ?? widget.otherNumber,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages list ──────────────────────────────
          Expanded(
            child: uid == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    // No orderBy here — composite index not required this way.
                    // We sort the filtered list in memory instead.
                    stream: FirebaseFirestore.instance
                        .collection('messages')
                        .where('userId', isEqualTo: uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading messages:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        );
                      }

                      // Normalise both numbers to E.164 so they match what
                      // the backend stores (ApiService.sendSMS calls toE164).
                      final fromE164 = ApiService.toE164(widget.fromNumber);
                      final otherE164 = ApiService.toE164(widget.otherNumber);

                      final allMessages = snapshot.data?.docs ?? [];

                      // Only this conversation: outbound (us→them) or inbound (them→us)
                      final messages = allMessages.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final from = data['from'] as String? ?? '';
                        final to = data['to'] as String? ?? '';
                        return (from == fromE164 && to == otherE164) ||
                            (from == otherE164 && to == fromE164);
                      }).toList();

                      // Sort by createdAt ascending (nulls last)
                      messages.sort((a, b) {
                        final aT = (a.data() as Map)['createdAt'] as Timestamp?;
                        final bT = (b.data() as Map)['createdAt'] as Timestamp?;
                        if (aT == null && bT == null) return 0;
                        if (aT == null) return 1;
                        if (bT == null) return -1;
                        return aT.compareTo(bT);
                      });

                      // Mark any newly-arrived inbound messages as read
                      final unreadInbound = messages.where((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        return d['direction'] == 'inbound' &&
                            d['read'] != true;
                      }).toList();
                      if (unreadInbound.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          final batch = FirebaseFirestore.instance.batch();
                          for (final doc in unreadInbound) {
                            batch.update(doc.reference, {'read': true});
                          }
                          try { await batch.commit(); } catch (_) {}
                        });
                      }

                      // Remove pending messages that now exist in Firestore
                      _pendingMsgs.removeWhere((p) => messages.any((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        if ((d['direction'] ?? '') != 'outbound') return false;
                        if ((d['body'] ?? '') != p.body) return false;
                        final ts = (d['createdAt'] as Timestamp?)?.toDate();
                        if (ts == null) return false;
                        return ts.difference(p.sentAt).abs().inSeconds < 60;
                      }));

                      if (messages.isEmpty && _pendingMsgs.isEmpty) {
                        return Center(
                          child: Text(
                            'No messages yet\nSay hello! 👋',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                              fontSize: 16,
                            ),
                          ),
                        );
                      }

                      // Build flat item list inserting date separators
                      // Each item is either a String (separator label)
                      // or a QueryDocumentSnapshot or _PendingMsg.
                      final items = <Object>[];
                      DateTime? lastDay;

                      for (final doc in messages) {
                        final d = doc.data() as Map<String, dynamic>;
                        final ts = (d['createdAt'] as Timestamp?)?.toDate().toLocal();
                        if (ts != null) {
                          final day = DateTime(ts.year, ts.month, ts.day);
                          if (lastDay == null || day != lastDay) {
                            items.add(_dateSeparatorLabel(ts));
                            lastDay = day;
                          }
                        }
                        items.add(doc);
                      }

                      for (final p in _pendingMsgs) {
                        final day = DateTime(p.sentAt.year, p.sentAt.month, p.sentAt.day);
                        if (lastDay == null || day != lastDay) {
                          items.add(_dateSeparatorLabel(p.sentAt));
                          lastDay = day;
                        }
                        items.add(p);
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];

                          // Date separator
                          if (item is String) {
                            return _buildDateSeparator(item);
                          }

                          // Pending (optimistic) message
                          if (item is _PendingMsg) {
                            return _buildBubble(
                              context: context,
                              body: item.body,
                              isOutbound: true,
                              statusText: item.sending
                                  ? 'Sending'
                                  : 'Sent ${_fmtTime(item.sentAt)}',
                              isSending: item.sending,
                            );
                          }

                          // Firestore message
                          final doc = item as QueryDocumentSnapshot;
                          final data = doc.data() as Map<String, dynamic>;
                          final direction = data['direction'] as String? ?? '';
                          final body = data['body'] as String? ?? '';
                          final isOutbound = direction == 'outbound';
                          final ts = (data['createdAt'] as Timestamp?)
                              ?.toDate()
                              .toLocal();
                          final deliveryStatus = data['status'] as String? ?? '';
                          final isFailed = isOutbound &&
                              (deliveryStatus == 'failed' ||
                                  deliveryStatus == 'undelivered');

                          String? statusText;
                          if (isOutbound) {
                            if (isFailed) {
                              statusText = 'Not delivered';
                            } else if (deliveryStatus == 'delivered') {
                              statusText = ts != null
                                  ? 'Delivered ${_fmtTime(ts)}'
                                  : 'Delivered';
                            } else {
                              statusText = ts != null
                                  ? 'Sent ${_fmtTime(ts)}'
                                  : null;
                            }
                          } else {
                            statusText = ts != null ? _fmtTime(ts) : null;
                          }

                          return _buildBubble(
                            context: context,
                            body: body,
                            isOutbound: isOutbound,
                            statusText: statusText,
                            isFailed: isFailed,
                          );
                        },
                      );
                    },
                  ),
          ),

          // ── Message input ──────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // SMS cost indicator
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4, right: 4),
                      child: Text(
                        '₦${ApiService.smsRateForNumber(ApiService.toE164(widget.otherNumber))} per message',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          textCapitalization:
                              TextCapitalization.sentences,
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor:
                                Theme.of(context).colorScheme.surface,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _isSending ? null : _send,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: _isSending
                                ? Colors.grey
                                : AppColors.softOrange,
                            shape: BoxShape.circle,
                          ),
                          child: _isSending
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send,
                                  color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}