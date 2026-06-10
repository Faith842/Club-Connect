import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/club_provider.dart';
import '../../theme/app_theme.dart';

class ChatRoomScreen extends StatefulWidget {
  final String clubId;
  final String clubName;
  const ChatRoomScreen({super.key, required this.clubId, required this.clubName});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isAnnouncement = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final chatProv = context.read<ChatProvider>();
    final user = auth.currentUser!;

    chatProv.sendMessage(
      clubId: widget.clubId,
      senderId: user.id,
      senderName: user.name,
      senderAvatar: user.avatar,
      senderRole: user.role,
      content: text,
      isAnnouncement: _isAnnouncement && user.isLeader,
    );

    _msgCtrl.clear();
    setState(() => _isAnnouncement = false);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chatProv = context.watch<ChatProvider>();
    final clubProv = context.watch<ClubProvider>();
    final user = auth.currentUser!;
    final messages = chatProv.getMessages(widget.clubId);
    final club = clubProv.findById(widget.clubId);
    final isLeader = club?.leaderId == user.id;

    Color color;
    try {
      color = Color(int.parse('FF${(club?.colorHex ?? '#1565C0').replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      color = AppColors.primary;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: color,
        title: Row(
          children: [
            Text(club?.emoji ?? '💬', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.clubName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(
                    '${club?.memberCount ?? 0} members',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('💬', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text('No messages yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                        Text('Be the first to say hello!', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final msg = messages[i];
                      final isMe = msg.senderId == user.id;
                      final showAvatar = i == 0 || messages[i - 1].senderId != msg.senderId;
                      final showName = showAvatar && !isMe;

                      if (msg.isAnnouncement) {
                        return _AnnouncementBubble(message: msg, color: color);
                      }

                      return _MessageBubble(
                        message: msg,
                        isMe: isMe,
                        showAvatar: showAvatar,
                        showName: showName,
                        color: color,
                      );
                    },
                  ),
          ),
          if (isLeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: GestureDetector(
                onTap: () => setState(() => _isAnnouncement = !_isAnnouncement),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isAnnouncement ? const Color(0x1FFF6D00) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isAnnouncement ? AppColors.accent : AppColors.cardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isAnnouncement ? Icons.campaign : Icons.campaign_outlined,
                        size: 18,
                        color: _isAnnouncement ? AppColors.accent : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isAnnouncement ? 'Sending as Announcement' : 'Send as Announcement',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isAnnouncement ? AppColors.accent : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          _InputBar(
            controller: _msgCtrl,
            onSend: _send,
            isAnnouncement: _isAnnouncement,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final dynamic message;
  final bool isMe;
  final bool showAvatar;
  final bool showName;
  final Color color;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.showName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            SizedBox(
              width: 32,
              child: showAvatar
                  ? CircleAvatar(
                      radius: 14,
                      backgroundColor: color.withValues(alpha: 0.12),
                      child: Text(message.senderAvatar as String, style: const TextStyle(fontSize: 14)),
                    )
                  : null,
            ),
          if (!isMe) const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showName)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.senderName as String,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        if ((message.senderRole as String) == 'club_leader')
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0x1FFF6D00),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Leader', style: TextStyle(fontSize: 9, color: AppColors.accent, fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? color : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: isMe ? null : Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    message.content as String,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Text(
                    _formatTime(message.timestamp as DateTime),
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 38),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) return DateFormat('h:mm a').format(dt);
    return DateFormat('MMM d, h:mm a').format(dt);
  }
}

class _AnnouncementBubble extends StatelessWidget {
  final dynamic message;
  final Color color;
  const _AnnouncementBubble({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                'Announcement · ${message.senderName}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
              ),
              const Spacer(),
              Text(
                _formatTime(message.timestamp as DateTime),
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.content as String,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) => DateFormat('MMM d, h:mm a').format(dt);
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isAnnouncement;
  final Color color;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.isAnnouncement,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: isAnnouncement ? 'Write an announcement...' : 'Message the club...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: isAnnouncement ? AppColors.accent : AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: isAnnouncement ? AppColors.accent : AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: isAnnouncement ? AppColors.accent : color, width: 2),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isAnnouncement ? AppColors.accent : color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
