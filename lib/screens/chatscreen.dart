import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flux_virtual/Theme.dart';
import 'package:flux_virtual/services/api_service.dart';

class Chatscreen extends StatefulWidget {
  final String otherNumber;
  final String fromNumber;

  const Chatscreen({
    super.key,
    required this.otherNumber,
    required this.fromNumber,
  });

  @override
  State<Chatscreen> createState() => _ChatscreenState();
}

class _ChatscreenState extends State<Chatscreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final result = await ApiService.sendSMS(
        to: widget.otherNumber,
        from: widget.fromNumber,
        body: text,
      );

      if (result['success'] != true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to send message'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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
              widget.otherNumber,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'From: ${widget.fromNumber}',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.darkBrown.withOpacity(0.5),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            color: Colors.green,
            onPressed: () {
              // navigate to keypad with this number
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
                    stream: FirebaseFirestore.instance
                        .collection('messages')
                        .where('userId', isEqualTo: uid)
                        .orderBy('createdAt', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final allMessages = snapshot.data?.docs ?? [];

                      // filter messages for this conversation
                      final messages = allMessages.where((doc) {
                        final data =
                            doc.data() as Map<String, dynamic>;
                        final from = data['from'] as String? ?? '';
                        final to = data['to'] as String? ?? '';
                        return from == widget.otherNumber ||
                            to == widget.otherNumber ||
                            from == widget.fromNumber ||
                            to == widget.fromNumber;
                      }).toList();

                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            'No messages yet\nSay hello! 👋',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.darkBrown.withOpacity(0.4),
                              fontSize: 16,
                            ),
                          ),
                        );
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController
                                .position.maxScrollExtent,
                            duration:
                                const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final data = messages[index].data()
                              as Map<String, dynamic>;
                          final direction =
                              data['direction'] as String? ?? '';
                          final body =
                              data['body'] as String? ?? '';
                          final isOutbound = direction == 'outbound';

                          return Align(
                            alignment: isOutbound
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width *
                                        0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isOutbound
                                    ? AppColors.softOrange
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceVariant
                                        .withOpacity(0.6),
                                borderRadius: BorderRadius.only(
                                  topLeft:
                                      const Radius.circular(16),
                                  topRight:
                                      const Radius.circular(16),
                                  bottomLeft: Radius.circular(
                                      isOutbound ? 16 : 4),
                                  bottomRight: Radius.circular(
                                      isOutbound ? 4 : 16),
                                ),
                              ),
                              child: Text(
                                body,
                                style: TextStyle(
                                  color: isOutbound
                                      ? AppColors.white
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                  fontSize: 15,
                                ),
                              ),
                            ),
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
              child: Row(
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
            ),
          ),
        ],
      ),
    );
  }
}