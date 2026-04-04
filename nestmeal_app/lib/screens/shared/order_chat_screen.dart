import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:nestmeal_app/config/theme.dart';
import 'package:nestmeal_app/models/chat_message.dart';
import 'package:nestmeal_app/providers/auth_provider.dart';
import 'package:nestmeal_app/providers/chat_provider.dart';

class OrderChatScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;

  /// Statuses where sending is disabled (order has ended).
  final bool isOrderClosed;

  const OrderChatScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.isOrderClosed,
  });

  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  late final ChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    _chatProvider = context.read<ChatProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatProvider.startPolling(widget.orderId);
    });
  }

  @override
  void dispose() {
    _chatProvider.stopPolling();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    final ok = await context
        .read<ChatProvider>()
        .sendMessage(widget.orderId, text);
    if (ok) _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        context.read<AuthProvider>().currentUser?.id.toString() ?? '';

    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      appBar: AppBar(
        backgroundColor: AppTheme.warmCream,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Chat',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkText,
              ),
            ),
            Text(
              '#${widget.orderNumber}',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.greyText,
                  fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Closed order banner
          if (widget.isOrderClosed)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.greyText.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.lock_outline,
                      size: 15, color: AppTheme.greyText),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This order has ended. You can read the chat history but cannot send new messages.',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.greyText),
                    ),
                  ),
                ],
              ),
            ),

          // Message list
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryOrange),
                  );
                }

                if (provider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 56,
                            color: AppTheme.greyText
                                .withValues(alpha: 0.35)),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 16,
                            color: AppTheme.greyText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Start the conversation below',
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.greyText),
                        ),
                      ],
                    ),
                  );
                }

                // Scroll to bottom when new messages arrive
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  itemCount: provider.messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = provider.messages[i];
                    final isMine = msg.senderId == currentUserId;
                    final showDateSep = i == 0 ||
                        _isDifferentDay(
                          provider.messages[i - 1].createdAt,
                          msg.createdAt,
                        );
                    return Column(
                      children: [
                        if (showDateSep) _DateSeparator(msg.createdAt),
                        _MessageBubble(
                            message: msg, isMine: isMine),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          if (!widget.isOrderClosed) _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 8,
            top: 10,
            bottom: MediaQuery.of(context).viewInsets.bottom + 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  maxLines: 4,
                  minLines: 1,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: const TextStyle(
                        color: AppTheme.greyText, fontSize: 14),
                    filled: true,
                    fillColor: AppTheme.warmCream,
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 6),
              provider.isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded),
                      color: AppTheme.primaryOrange,
                      iconSize: 26,
                    ),
            ],
          ),
        );
      },
    );
  }

  bool _isDifferentDay(String a, String b) {
    try {
      final da = DateTime.parse(a).toLocal();
      final db = DateTime.parse(b).toLocal();
      return da.year != db.year || da.month != db.month || da.day != db.day;
    } catch (_) {
      return false;
    }
  }
}

// ─── Date separator ───────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final String dateStr;
  const _DateSeparator(this.dateStr);

  @override
  Widget build(BuildContext context) {
    String label;
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day) {
        label = 'Today';
      } else if (dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day - 1) {
        label = 'Yesterday';
      } else {
        label = DateFormat('MMM d, yyyy').format(dt);
      }
    } catch (_) {
      label = dateStr;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
              child: Divider(color: AppTheme.greyText.withValues(alpha: 0.2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.greyText),
            ),
          ),
          Expanded(
              child: Divider(color: AppTheme.greyText.withValues(alpha: 0.2))),
        ],
      ),
    );
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    String timeStr;
    try {
      timeStr = DateFormat('h:mm a')
          .format(DateTime.parse(message.createdAt).toLocal());
    } catch (_) {
      timeStr = '';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.deepOrange.shade100,
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.deepOrange.shade700,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3, left: 2),
                    child: Text(
                      message.senderName,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.greyText,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine
                        ? AppTheme.primaryOrange
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMine ? 16 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMine ? Colors.white : AppTheme.darkText,
                      height: 1.4,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                  child: Text(
                    timeStr,
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.greyText),
                  ),
                ),
              ],
            ),
          ),
          if (isMine) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
